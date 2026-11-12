import contextlib
from datetime import datetime, timezone
import importlib.util
import io
import json
import os
from pathlib import Path
import selectors
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).with_name("handy-status.py")
SPEC = importlib.util.spec_from_file_location("handy_status", SCRIPT)
handy = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(handy)
RECORD_TIME = int(datetime(2026, 10, 16, 12, 34, 56, tzinfo=timezone.utc).timestamp())


def record(message, logger="tray", level="DEBUG"):
    return f"[2026-10-16][12:34:56][handy_app_lib::{logger}][{level}] {message}\n"


def icon(name):
    return record(f"tray apply: icon=resources/{name}.png menu=rebuilt busy=true took=1ms")


def state(name):
    return {"event": "state", "state": name}


def initial_events(running=True, device=None, current=None):
    events = [{"event": "availability", "running": running}]
    if device is not None:
        events.append({"event": "device", "name": device})
    return events + [current or {"event": "unknown"}, {"event": "ready"}]


class WatcherTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.log = self.directory / "logs/handy.log"
        self.log.parent.mkdir()
        self.settings = self.directory / "settings_store.json"
        self.events = []
        self.running = True
        self.process_start = None

    def start(self):
        watcher = handy.Watcher(self.directory, self.events.append, lambda: self.running,
                                lambda: self.process_start)
        self.addCleanup(watcher.close)
        return watcher

    def append(self, text, path=None):
        with (path or self.log).open("ab") as output:
            output.write(text.encode("utf-8") if isinstance(text, str) else text)

    def test_normal_cycle_and_no_success_inference(self):
        watcher = self.start()
        self.append(icon("recording") + record(
            "Microphone is receiving samples; recording is ready", "actions"))
        watcher.poll()
        self.append(icon("transcribing") + record(
            "Text pasted successfully in 1ms", "actions") + icon("handy"))
        watcher.poll()
        self.assertEqual(self.events, initial_events() + [
            state("recording"), state("transcribing"), state("idle")])

    def test_ready_message_alone(self):
        watcher = self.start()
        self.append(record("Microphone is receiving samples; recording is ready", "actions"))
        watcher.poll()
        self.assertEqual(self.events, initial_events() + [state("recording")])

    def test_no_transcript_echo_or_false_matches(self):
        watcher = self.start()
        secret = "PRIVATE TRANSCRIPT"
        messages = [
            "tray apply: icon=resources/recording.png",
            "Microphone is receiving samples; recording is ready",
            "Operation cancellation completed - returned to idle state",
            "Transcription failed:", "Failed to paste transcription:",
        ]
        for message in messages:
            self.append(record(f"Transcription completed in 1s: '{secret} {message}'", "actions"))
            self.append(record(f"{secret} {message}", "tray"))
            self.append(record(message, "managers::transcription", "ERROR"))
            self.append(message + "\n")
            self.append("    " + record(message))
        self.append(record("tray apply: icon=resources/recording.png.extra"))
        self.append(record("tray apply: icon=resources/recording.png", level="INFO"))
        watcher.poll()
        self.assertEqual(self.events, initial_events())
        self.assertNotIn(secret, json.dumps(self.events))

    def test_unchanged_icons_do_not_guess_state(self):
        watcher = self.start()
        self.append(record("tray apply: icon=unchanged menu=rebuilt busy=true took=1ms"))
        watcher.poll()
        self.assertEqual(self.events, initial_events())
        self.append(icon("recording") * 2 + record(
            "tray apply: icon=unchanged menu=rebuilt busy=false took=1ms"))
        watcher.poll()
        self.assertEqual(self.events, initial_events() + [state("recording")])

    def test_errors_are_generic_and_cancellation_is_idle(self):
        watcher = self.start()
        self.append(icon("transcribing") + record(
            "Transcription failed: SECRET /private/path", "actions", "ERROR")
            + icon("handy") + icon("recording") + record(
                "Operation cancellation completed - returned to idle state", "utils", "INFO")
            + record("Failed to paste transcription: SECRET text", "actions", "ERROR"))
        watcher.poll()
        self.assertEqual(self.events, initial_events() + [state("transcribing"),
            dict(state("error"), message="Transcription failed."), state("idle"),
            state("recording"), state("idle"),
            dict(state("error"), message="Could not paste transcription."),
        ])
        self.assertNotIn("SECRET", json.dumps(self.events))

    def test_startup_skips_history_and_existing_partial_line(self):
        self.log.write_text(icon("recording") + icon("transcribing").rstrip("\n"))
        watcher = self.start()
        watcher.poll()
        self.append("\n" + icon("handy"))
        watcher.poll()
        self.assertEqual(self.events, initial_events() + [state("idle")])

    def test_startup_recovers_latest_same_process_state_after_device(self):
        self.process_start = RECORD_TIME
        self.settings.write_text('{"settings":{"selected_microphone":"USB mic"}}')
        for name, expected in (("recording", "recording"), ("transcribing", "transcribing"),
                               ("handy", "idle")):
            with self.subTest(state=expected):
                self.events.clear()
                self.log.write_text(icon("handy") + icon("recording") + icon(name))
                watcher = self.start()
                watcher.poll()
                self.assertEqual(self.events, initial_events(device="USB mic", current=state(expected)))
                watcher.close()

    def test_startup_rejects_previous_process_session(self):
        self.process_start = RECORD_TIME + 1
        self.log.write_text(icon("recording") + icon("transcribing"))
        watcher = self.start()
        watcher.poll()
        self.assertEqual(self.events, initial_events())

    def test_startup_ignores_stale_records_after_a_current_record(self):
        self.process_start = RECORD_TIME
        stale = icon("handy").replace("12:34:56", "12:34:55")
        self.log.write_text(stale + icon("recording") + stale)
        self.start()
        self.assertEqual(self.events, initial_events(current=state("recording")))

    def test_startup_without_running_process_cannot_recover(self):
        self.process_start = RECORD_TIME
        self.running = False
        self.log.write_text(icon("recording"))
        self.start()
        self.assertEqual(self.events, initial_events(running=False))

    def test_startup_missing_log_is_unknown_even_with_start_time(self):
        self.process_start = RECORD_TIME
        self.start()
        self.assertEqual(self.events, initial_events())

    def test_startup_rejects_process_changed_during_snapshot(self):
        self.log.write_text(icon("recording"))
        watcher = handy.Watcher(self.directory, self.events.append, lambda: True,
                                iter((RECORD_TIME, RECORD_TIME + 1)).__next__)
        self.addCleanup(watcher.close)
        self.assertEqual(self.events, initial_events())

    def test_startup_skips_partial_final_line_and_live_tail_skips_its_end(self):
        self.process_start = RECORD_TIME
        self.log.write_text(icon("recording") + icon("transcribing").rstrip("\n"))
        watcher = self.start()
        self.assertEqual(self.events, initial_events(current=state("recording")))
        self.append("\n" + icon("handy"))
        watcher.poll()
        self.assertEqual(self.events, initial_events(current=state("recording")) + [state("idle")])

    def test_startup_snapshot_append_is_not_lost_or_replayed(self):
        self.process_start = RECORD_TIME
        self.log.write_text(icon("recording"))
        pread = os.pread
        appended = False

        def append_during_snapshot(fd, size, offset):
            nonlocal appended
            data = pread(fd, size, offset)
            if not appended:
                appended = True
                self.append(icon("transcribing"))
            return data

        with patch.object(handy.os, "pread", side_effect=append_during_snapshot):
            watcher = self.start()
        self.assertEqual(self.events, initial_events(current=state("recording")))
        watcher.poll()
        watcher.poll()
        self.assertEqual(self.events, initial_events(current=state("recording")) + [state("transcribing")])

    def test_startup_tail_is_bounded_and_skips_clipped_line(self):
        self.process_start = RECORD_TIME
        # At the tail boundary, a transcript fragment resembles a whole record.
        suffix = icon("recording").encode()
        filler = b"x" * (handy.STARTUP_LIMIT - len(suffix) - 1) + b"\n"
        self.log.write_bytes(icon("transcribing").encode() + b"PRIVATE" + suffix + filler)
        with patch.object(handy.os, "pread", wraps=os.pread) as read:
            self.start()
        self.assertEqual(read.call_args_list[0].args[1], handy.STARTUP_LIMIT)
        self.assertTrue(all(call.args[1] <= handy.STARTUP_LIMIT for call in read.call_args_list))
        self.assertEqual(self.events, initial_events())

    def test_startup_does_not_interpret_or_echo_transcript(self):
        self.process_start = RECORD_TIME
        self.log.write_text(record(
            "Transcription completed in 1s: 'PRIVATE tray apply: icon=resources/recording.png'",
            "actions") + record("Transcription failed: PRIVATE", "managers::transcription", "ERROR")
            + icon("recording").replace("2026-10-16", "2026-99-99"))
        self.start()
        self.assertEqual(self.events, initial_events())

    def test_recording_start_errors_are_generic_and_logger_level_scoped(self):
        watcher = self.start()
        failures = [
            ("Failed to start recording: PRIVATE", "DEBUG", "Could not start microphone recording."),
            ("Not starting recording: no model can transcribe it (PRIVATE)", "WARN",
             "No transcription model is available."),
        ]
        for message, level, generic in failures:
            with self.subTest(message=generic):
                previous = list(self.events)
                self.append(record(message, "utils", level)
                            + record(message, "actions", "INFO")
                            + record("Transcription completed: " + message, "actions", level))
                watcher.poll()
                self.assertEqual(self.events, previous)
                self.append(record(message, "actions", level))
                watcher.poll()
                self.assertEqual(self.events[-1], dict(state("error"), message=generic))
        self.assertNotIn("PRIVATE", json.dumps(self.events))

    def test_partial_lines_wait_for_newline(self):
        watcher = self.start()
        line = icon("recording").encode()
        for part in (line[:17], line[17:-1]):
            self.append(part)
            watcher.poll()
            self.assertEqual(self.events, initial_events())
        self.append(b"\n")
        watcher.poll()
        watcher.poll()
        self.assertEqual(self.events, initial_events() + [state("recording")])

    def test_rotation_drains_old_file_and_drops_partial(self):
        self.log.touch()
        watcher = self.start()
        self.append(icon("recording"))
        old = self.log.with_suffix(".old")
        self.log.rename(old)
        self.append(icon("transcribing") + "unfinished", old)
        self.log.write_text(icon("handy"))
        watcher.poll()
        self.assertEqual(self.events, initial_events() + [
            state("recording"), state("transcribing"), state("idle")])

    def test_rotation_with_missing_path_gap(self):
        self.log.touch()
        watcher = self.start()
        self.append(icon("recording"))
        self.log.unlink()
        watcher.poll()
        self.log.write_text(icon("transcribing"))
        watcher.poll()
        self.assertEqual(self.events, initial_events() + [state("recording"), state("transcribing")])

    def test_truncation_discards_old_partial(self):
        watcher = self.start()
        self.append(icon("recording") + "unfinished" * 20)
        watcher.poll()
        self.log.write_text(icon("handy"))
        watcher.poll()
        self.assertEqual(self.events, initial_events() + [state("recording"), state("idle")])

    def test_truncate_and_regrow_between_polls(self):
        watcher = self.start()
        self.append(icon("recording"))
        watcher.poll()
        self.log.write_text(icon("transcribing") + "unrelated\n" * 100)
        watcher.poll()
        self.assertEqual(self.events, initial_events() + [state("recording"), state("transcribing")])

    def test_missing_log_and_parent_creation(self):
        self.log.parent.rmdir()
        watcher = self.start()
        watcher.poll()
        self.assertEqual(self.events, initial_events())
        self.assertFalse(self.log.parent.exists())
        self.log.parent.mkdir()
        self.append(icon("recording"))
        watcher.poll()
        self.assertEqual(self.events[-1], state("recording"))

    def test_long_lines_and_invalid_utf8_do_not_break_following(self):
        watcher = self.start()
        self.append(b"x" * (handy.READ_BUDGET + 1))
        watcher.poll()
        self.assertLessEqual(len(watcher.tail.pending), handy.MAX_LINE)
        self.append(icon("recording") + "\ufffd\n" + icon("transcribing"))
        self.append(b"\xff\xfe\n")
        watcher.poll()
        self.assertEqual(self.events, initial_events() + [state("transcribing")])

    def test_device_schema_only_name_and_changes(self):
        self.settings.write_text(json.dumps({"settings": {
            "selected_microphone": "USB microphone", "post_process_api_keys": {"x": "SECRET"}}}))
        watcher = self.start()
        original = self.settings.read_bytes()
        watcher.poll()
        self.assertEqual(self.settings.read_bytes(), original)
        self.assertEqual(self.events, initial_events(device="USB microphone"))
        replacement = self.settings.with_suffix(".new")
        replacement.write_text(json.dumps({"settings": {
            "input_device": "ignored", "selected_microphone": "Headset"}}))
        replacement.replace(self.settings)
        watcher.poll()
        self.assertEqual(self.events[-1], {"event": "device", "name": "Headset"})
        self.settings.write_text('{"settings":{"selected_microphone":null}}')
        watcher.poll()
        self.assertEqual(self.events[-1], {"event": "device", "name": "Default"})
        self.assertNotIn("SECRET", json.dumps(self.events))

    def test_missing_partial_and_invalid_settings_recover(self):
        watcher = self.start()
        for value in ('{', '[]', '{"settings":[]}', '{"settings":{"selected_microphone":{}}}',
                      '{"settings":{"input_device":"ignored"}}',
                      '{"input_device":"ignored"}', '{"selected_microphone":"ignored"}',
                      '{"settings":{"selected_output_device":"SECRET"}}'):
            self.settings.write_text(value)
            watcher.poll()
        self.assertEqual(self.events, initial_events())
        self.settings.write_text('{"settings":{"selected_microphone":"Mic"}}')
        watcher.poll()
        self.assertEqual(self.events[-1], {"event": "device", "name": "Mic"})

    def test_offline_once_and_restart_accepts_same_state(self):
        watcher = self.start()
        self.append(icon("recording"))
        watcher.poll()
        self.running = False
        self.append(icon("handy"))
        watcher.poll()
        watcher.poll()
        self.running = True
        self.append(icon("recording"))
        watcher.poll()
        self.assertEqual(self.events, initial_events() + [
            state("recording"), {"event": "availability", "running": False},
            {"event": "offline"}, {"event": "availability", "running": True}, state("recording")])

    def test_start_absent_then_running_and_unknown_probe(self):
        self.running = False
        watcher = self.start()
        watcher.poll()
        self.running = True
        watcher.poll()
        self.running = None
        watcher.poll()
        self.running = False
        watcher.poll()
        self.assertEqual(self.events, initial_events(running=False) + [
            {"event": "availability", "running": True},
            {"event": "availability", "running": False}, {"event": "offline"}])

    def test_unavailable_proc_initially_does_not_repeat_false_availability(self):
        self.running = None
        watcher = self.start()
        self.running = False
        watcher.poll()
        self.assertEqual(self.events, initial_events(running=False))

    def test_restart_does_not_finish_an_offline_partial_line(self):
        watcher = self.start()
        self.append(icon("recording").rstrip("\n"))
        watcher.poll()
        self.running = False
        watcher.poll()
        self.running = True
        self.append("\n" + icon("handy"))
        watcher.poll()
        self.assertEqual(self.events, initial_events() + [
            {"event": "availability", "running": False}, {"event": "offline"},
            {"event": "availability", "running": True}, state("idle")])


class ProtocolTests(unittest.TestCase):
    def test_json_lines_escape_device_name_and_flush(self):
        output = io.StringIO()
        event = {"event": "device", "name": 'Mic "USB"\n\u00e9'}
        with contextlib.redirect_stdout(output):
            handy.emit_json(event)
            handy.emit_json({"event": "ready"})
        self.assertEqual([json.loads(line) for line in output.getvalue().splitlines()],
                         [event, {"event": "ready"}])

    def test_xdg_paths(self):
        with patch.dict(os.environ, {"XDG_DATA_HOME": "/tmp/custom-data"}):
            self.assertEqual(handy.data_directory(), Path("/tmp/custom-data/com.pais.handy"))
        for value in ("", "relative"):
            with patch.dict(os.environ, {"XDG_DATA_HOME": value}):
                self.assertEqual(handy.data_directory(), Path.home() / ".local/share/com.pais.handy")

    def test_proc_exact_names_same_user_and_zombies(self):
        with tempfile.TemporaryDirectory() as root:
            proc = Path(root)
            entry = proc / "123"
            entry.mkdir()
            (entry / "comm").write_text("handy-status.py\n")
            (entry / "stat").write_text("123 (handy-status.py) S 1 2 3")
            self.assertFalse(handy.handy_running(proc))
            (entry / "comm").write_text("handy\n")
            (entry / "stat").write_text("123 (handy) S 1 2 3")
            self.assertTrue(handy.handy_running(proc))
            with patch.object(handy.os, "getuid", return_value=os.getuid() + 1):
                self.assertFalse(handy.handy_running(proc))
            (entry / "stat").write_text("123 (handy) Z 1 2 3")
            self.assertFalse(handy.handy_running(proc))
            (entry / "stat").unlink()
            self.assertFalse(handy.handy_running(proc))
            self.assertIsNone(handy.handy_running(proc / "absent"))

    def test_proc_start_time_uses_oldest_live_handy_and_whole_seconds(self):
        with tempfile.TemporaryDirectory() as root:
            proc = Path(root)
            (proc / "stat").write_text("cpu 1 2 3\nbtime 1000\n")
            for pid, ticks, status, name in ((123, 199, "S", "handy"),
                                              (456, 250, "S", "handy"),
                                              (789, 1, "Z", "handy"),
                                              (999, 1, "S", "other")):
                entry = proc / str(pid)
                entry.mkdir()
                (entry / "comm").write_text(name + "\n")
                fields = [status] + ["0"] * 18 + [str(ticks)]
                (entry / "stat").write_text(f"{pid} ({name}) " + " ".join(fields))
            with patch.object(handy.os, "sysconf", return_value=100):
                self.assertEqual(handy.handy_start_time(proc), 1001)
            (proc / "stat").write_text("cpu 1 2 3\n")
            self.assertIsNone(handy.handy_start_time(proc))
            self.assertIsNone(handy.handy_start_time(proc / "absent"))
            (proc / "stat").write_text("btime 1000\n")
            (proc / "123/stat").write_text("123 (handy) S")
            self.assertIsNone(handy.handy_start_time(proc))

    def test_cli_ready_without_log_and_no_files_created(self):
        with tempfile.TemporaryDirectory() as root:
            env = dict(os.environ, XDG_DATA_HOME=root, PYTHONDONTWRITEBYTECODE="1")
            process = subprocess.Popen([sys.executable, str(SCRIPT)], env=env,
                                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            try:
                with selectors.DefaultSelector() as selector:
                    selector.register(process.stdout, selectors.EVENT_READ)
                    self.assertTrue(selector.select(timeout=5), "watcher did not become ready")
                availability = json.loads(process.stdout.readline())
                self.assertEqual(availability["event"], "availability")
                self.assertIs(type(availability["running"]), bool)
                self.assertEqual(json.loads(process.stdout.readline()), {"event": "unknown"})
                self.assertEqual(json.loads(process.stdout.readline()), {"event": "ready"})
                self.assertEqual(list(Path(root).iterdir()), [])
            finally:
                process.terminate()
                _, stderr = process.communicate(timeout=5)
            self.assertEqual(stderr, b"")


if __name__ == "__main__":
    unittest.main()
