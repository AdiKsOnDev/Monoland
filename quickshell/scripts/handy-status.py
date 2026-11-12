#!/usr/bin/env python3

import hashlib
import json
import os
from datetime import datetime, timezone
from pathlib import Path
import re
import stat
import sys
import time


POLL_SECONDS = 0.5
MAX_LINE = 4096
READ_BUDGET = 256 * 1024
STARTUP_LIMIT = 500_000
HEADER = re.compile(
    r"\[\d{4}-\d{2}-\d{2}\]\[\d{2}:\d{2}:\d{2}\]"
    r"\[handy_app_lib::(tray|actions|utils)\]\[(DEBUG|INFO|WARN|ERROR)\] "
    r"([^\r\n]*)"
)
TRAY = re.compile(
    r"tray apply: icon=resources/(recording|transcribing|handy)\.png(?: |$)"
)


def parse_line(line):
    match = HEADER.fullmatch(line.rstrip("\r\n"))
    if not match:
        return None
    logger, level, message = match.groups()
    state = None
    error = None
    if logger == "tray" and level == "DEBUG":
        icon = TRAY.match(message)
        if icon:
            state = {"handy": "idle", "recording": "recording",
                     "transcribing": "transcribing"}[icon[1]]
    elif logger == "actions":
        if (level == "DEBUG" and message ==
                "Microphone is receiving samples; recording is ready"):
            state = "recording"
        elif level == "DEBUG" and message.startswith("Failed to start recording:"):
            error = "Could not start microphone recording."
        elif level == "WARN" and message.startswith(
                "Not starting recording: no model can transcribe it ("):
            error = "No transcription model is available."
        elif level == "ERROR":
            if message.startswith("Transcription failed:"):
                error = "Transcription failed."
            elif message.startswith("Failed to paste transcription:"):
                error = "Could not paste transcription."
    elif (logger == "utils" and level == "INFO" and message ==
          "Operation cancellation completed - returned to idle state"):
        state = "idle"
    if error:
        return {"event": "state", "state": "error", "message": error}
    if state:
        return {"event": "state", "state": state}
    return None


def data_directory():
    data_home = os.environ.get("XDG_DATA_HOME", "")
    base = Path(data_home) if data_home.startswith("/") else Path.home() / ".local/share"
    return base / "com.pais.handy"


def _handy_process_stats(proc):
    processes = []
    try:
        with os.scandir(proc) as entries:
            for entry in entries:
                if not entry.name.isdecimal():
                    continue
                try:
                    if entry.stat().st_uid != os.getuid():
                        continue
                    path = Path(entry.path)
                    name = (path / "comm").read_text().strip()
                    if name not in ("handy", "Handy", ".handy-wrapped"):
                        continue
                    # Zombies still have a /proc entry, but are no longer running.
                    fields = (path / "stat").read_text().rsplit(")", 1)[1].split()
                    if fields[0] not in ("Z", "X"):
                        processes.append(fields)
                except (OSError, UnicodeError, IndexError):
                    continue
    except OSError:
        return None
    return processes


def handy_running(proc=Path("/proc")):
    processes = _handy_process_stats(proc)
    return None if processes is None else bool(processes)


def handy_start_time(proc=Path("/proc")):
    processes = _handy_process_stats(proc)
    if not processes:
        return None
    try:
        # The main single-instance process predates short-lived Handy invocations.
        ticks = min(int(fields[19]) for fields in processes)  # /proc stat field 22
        with (proc / "stat").open() as source:
            boot = next(int(line.split()[1]) for line in source if line.startswith("btime "))
        return boot + ticks // os.sysconf("SC_CLK_TCK")
    except (OSError, ValueError, UnicodeError, IndexError, StopIteration):
        return None


def startup_state(data, process_start, clipped=False):
    if process_start is None:
        return None
    lines = data.split(b"\n")
    # A clipped first line and an unfinished final line are never records.
    for raw in reversed(lines[1 if clipped else 0:-1]):
        if len(raw) > MAX_LINE:
            continue
        line = raw.decode("utf-8", errors="replace")
        event = parse_line(line)
        if event is None:
            continue
        try:
            timestamp = datetime.strptime(line[:22], "[%Y-%m-%d][%H:%M:%S]")
            seconds = int(timestamp.replace(tzinfo=timezone.utc).timestamp())
        except ValueError:
            continue
        if seconds >= process_start:
            return event
    return None


class LogTail:
    def __init__(self, path, process_start=None):
        self.path = Path(path)
        self.file = None
        self.pending = b""
        self.discard = False
        self.anchor = None
        self.initial_state = None
        self._open(at_end=True, process_start=process_start)

    def _open(self, at_end=False, process_start=None):
        try:
            fd = os.open(self.path, os.O_RDONLY | os.O_NONBLOCK)
            if not stat.S_ISREG(os.fstat(fd).st_mode):
                os.close(fd)
                return
            self.file = os.fdopen(fd, "rb", buffering=0)
            self.pending = b""
            self.discard = False
            if at_end:
                position = self.file.seek(0, os.SEEK_END)
                size = min(position, STARTUP_LIMIT)
                data = os.pread(fd, size, position - size)
                # Snapshot, cursor, partial-line flag and checkpoint share this EOF.
                self.discard = bool(position and not data.endswith(b"\n"))
                self.anchor = hashlib.blake2s(data[-64:]).digest()
                if len(data) == size and self.anchor == self._checkpoint():
                    self.initial_state = startup_state(data, process_start, position > size)
            else:
                self.anchor = self._checkpoint()
        except OSError:
            self.close()

    def close(self):
        if self.file is not None:
            self.file.close()
            self.file = None
        self.pending = b""
        self.discard = False
        self.anchor = None

    def _checkpoint(self):
        position = self.file.tell()
        size = min(position, 64)
        return hashlib.blake2s(os.pread(self.file.fileno(), size, position - size)).digest()

    def _drain(self):
        size = os.fstat(self.file.fileno()).st_size
        # The checkpoint also catches copy-truncate followed by rapid regrowth.
        if size < self.file.tell() or self.anchor != self._checkpoint():
            self.file.seek(0)
            self.pending = b""
            self.discard = False
        remaining = READ_BUDGET
        while remaining:
            chunk = self.file.read(min(65536, remaining))
            if not chunk:
                break
            remaining -= len(chunk)
            parts = chunk.split(b"\n")
            for index, part in enumerate(parts):
                complete = index < len(parts) - 1
                if not self.discard:
                    if len(self.pending) + len(part) <= MAX_LINE:
                        self.pending += part
                    else:
                        self.pending = b""
                        self.discard = True
                if complete:
                    if not self.discard:
                        yield self.pending.decode("utf-8", errors="replace")
                    self.pending = b""
                    self.discard = False
        self.anchor = self._checkpoint()

    def poll(self):
        try:
            if self.file is None:
                self._open()
            if self.file is None:
                return
            yield from self._drain()
            # Finish complete lines on the old descriptor before switching files.
            old = os.fstat(self.file.fileno())
            if self.file.tell() < old.st_size:
                return
            current = self.path.stat()
            if (old.st_dev, old.st_ino) != (current.st_dev, current.st_ino):
                self.close()
                self._open()
                if self.file is not None:
                    yield from self._drain()
        except OSError:
            # A rename/create gap or temporarily unreadable path is retried.
            return


class Watcher:
    def __init__(self, directory, emit, running=handy_running, start_time=handy_start_time):
        self.was_running = running()
        process_start = start_time() if self.was_running is True else None
        self.tail = LogTail(Path(directory) / "logs/handy.log", process_start)
        self.settings_path = Path(directory) / "settings_store.json"
        self.emit = emit
        self.running = running
        self.last_state = self.tail.initial_state
        if process_start is not None and start_time() != process_start:
            self.last_state = None
        self.device = None
        self.settings_signature = None
        device = self._read_device()
        self.emit({"event": "availability", "running": self.was_running is True})
        self._device_event(device)
        self.emit(self.last_state or {"event": "unknown"})
        self.emit({"event": "ready"})

    def _read_device(self):
        try:
            metadata = self.settings_path.stat()
            signature = (metadata.st_dev, metadata.st_ino, metadata.st_size,
                         metadata.st_mtime_ns, metadata.st_ctime_ns)
            if signature == self.settings_signature:
                return None
            with self.settings_path.open("rb") as source:
                raw = source.read(1024 * 1024 + 1)
            self.settings_signature = signature
            if len(raw) > 1024 * 1024:
                return None
            store = json.loads(raw)
            if not isinstance(store, dict):
                return None
            settings = store.get("settings")
            if not isinstance(settings, dict):
                return None
            # Official v0.9.8 uses settings.selected_microphone: Option<String>.
            if "selected_microphone" not in settings:
                return None
            name = settings["selected_microphone"]
            if name is None or name == "":
                return "Default"
            if isinstance(name, str):
                return name
        except (OSError, ValueError, UnicodeError, RecursionError):
            pass
        return None

    def _device_event(self, name):
        if name is not None and name != self.device:
            self.device = name
            self.emit({"event": "device", "name": name})

    def poll(self):
        running = self.running()
        if running is not None:
            if running != (self.was_running is True):
                self.emit({"event": "availability", "running": running})
            if self.was_running is True and not running:
                self.last_state = None
                self.emit({"event": "offline"})
            self.was_running = running
        self._device_event(self._read_device())
        for line in self.tail.poll():
            if self.was_running is False:
                continue
            event = parse_line(line)
            if event is not None and event != self.last_state:
                self.last_state = event
                self.emit(event)
        if self.was_running is False and self.tail.pending:
            self.tail.pending = b""
            self.tail.discard = True

    def close(self):
        self.tail.close()


def emit_json(event):
    print(json.dumps(event, ensure_ascii=True, separators=(",", ":")), flush=True)


def main():
    watcher = None
    try:
        watcher = Watcher(data_directory(), emit_json)
        while True:
            watcher.poll()
            time.sleep(POLL_SECONDS)
    except KeyboardInterrupt:
        pass
    except BrokenPipeError:
        # Avoid a second broken-pipe error when Python flushes stdout at exit.
        sys.stdout = open(os.devnull, "w")
    finally:
        if watcher is not None:
            watcher.close()


if __name__ == "__main__":
    main()
