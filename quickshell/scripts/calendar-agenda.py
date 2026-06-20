#!/usr/bin/env python3
"""
Fetch and parse ICS calendar(s) — e.g. a Proton Calendar shared link — and emit
upcoming events as compact JSON for the Monoland shell agenda.

Proton Calendar has no public API. The supported way to read it is its shared
"Share with anyone" link (Proton Calendar -> Settings -> Calendars -> Share ->
copy the secret .ics link). Sources are stored one URL per line in:

    $XDG_DATA_HOME/monoland/calendar.url   (default ~/.local/share/...)

Lines starting with # are ignored. Local .ics paths and the env var
MONOLAND_ICS_URLS (whitespace separated) are also honoured.

Usage:
  calendar-agenda.py                 emit upcoming events as JSON
  calendar-agenda.py add <url>       add a source, then emit events
  calendar-agenda.py remove <url>    remove a source, then emit events

Output (single line):
  {"configured": bool,
   "events": [{id,title,date,time,allDay,location,start}, ...],
   "error": str?}
"""

import os
import sys
import json
import hashlib
import calendar as _cal
import urllib.request
from datetime import datetime, date, timedelta, timezone

try:
    from zoneinfo import ZoneInfo
except Exception:
    ZoneInfo = None

LOOKAHEAD_DAYS = 21
MAX_EVENTS = 60

HOME = os.path.expanduser("~")
DATA_HOME = os.environ.get("XDG_DATA_HOME", os.path.join(HOME, ".local", "share"))
CONFIG = os.path.join(DATA_HOME, "monoland", "calendar.url")
CACHE_DIR = os.path.join(
    os.environ.get("XDG_CACHE_HOME", os.path.join(HOME, ".cache")),
    "monoland", "agenda")

LOCAL_TZ = datetime.now().astimezone().tzinfo
WEEKMAP = {"MO": 0, "TU": 1, "WE": 2, "TH": 3, "FR": 4, "SA": 5, "SU": 6}


def read_urls():
    urls = []
    for tok in os.environ.get("MONOLAND_ICS_URLS", "").replace("\n", " ").split():
        urls.append(tok.strip())
    if os.path.isfile(CONFIG):
        with open(CONFIG, "r", encoding="utf-8") as f:
            for line in f:
                s = line.strip()
                if s and not s.startswith("#"):
                    urls.append(s)
    seen, out = set(), []
    for u in urls:
        if u and u not in seen:
            seen.add(u)
            out.append(u)
    return out


def read_file_urls():
    """URLs stored in the config file only (no env, no comments)."""
    urls = []
    if os.path.isfile(CONFIG):
        with open(CONFIG, "r", encoding="utf-8") as f:
            for line in f:
                s = line.strip()
                if s and not s.startswith("#"):
                    urls.append(s)
    return urls


def add_url(url):
    url = url.strip()
    if not url or url in read_file_urls():
        return
    os.makedirs(os.path.dirname(CONFIG), exist_ok=True)
    prefix = ""
    if os.path.isfile(CONFIG):
        with open(CONFIG, "r", encoding="utf-8") as f:
            cur = f.read()
        if cur and not cur.endswith("\n"):
            prefix = "\n"
    with open(CONFIG, "a", encoding="utf-8") as f:
        f.write(prefix + url + "\n")


def remove_url(url):
    url = url.strip()
    if not os.path.isfile(CONFIG):
        return
    with open(CONFIG, "r", encoding="utf-8") as f:
        lines = f.readlines()
    with open(CONFIG, "w", encoding="utf-8") as f:
        f.writelines([ln for ln in lines if ln.strip() != url])


def fetch(url):
    """Fetch ICS text; cache last good copy and fall back to it on failure."""
    os.makedirs(CACHE_DIR, exist_ok=True)
    cache = os.path.join(CACHE_DIR, hashlib.sha1(url.encode()).hexdigest() + ".ics")
    try:
        if url.startswith(("http://", "https://")):
            req = urllib.request.Request(url, headers={"User-Agent": "Monoland/1.0"})
            with urllib.request.urlopen(req, timeout=8) as r:
                data = r.read().decode("utf-8", "replace")
        else:
            with open(os.path.expanduser(url), "r", encoding="utf-8", errors="replace") as f:
                data = f.read()
        if data:
            with open(cache, "w", encoding="utf-8") as f:
                f.write(data)
        return data
    except Exception:
        if os.path.isfile(cache):
            with open(cache, "r", encoding="utf-8", errors="replace") as f:
                return f.read()
        return None


def unfold(text):
    """RFC5545 line unfolding: a leading space/tab continues the previous line."""
    out = []
    for raw in text.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        if raw[:1] in (" ", "\t") and out:
            out[-1] += raw[1:]
        else:
            out.append(raw)
    return out


def parse_prop(line):
    if ":" not in line:
        return None
    head, value = line.split(":", 1)
    parts = head.split(";")
    params = {}
    for p in parts[1:]:
        if "=" in p:
            k, v = p.split("=", 1)
            params[k.upper()] = v
    return parts[0].upper(), params, value


def unescape(v):
    return (v.replace("\\n", "\n").replace("\\N", "\n")
             .replace("\\,", ",").replace("\\;", ";").replace("\\\\", "\\"))


def parse_dt(params, value):
    """Return (date|datetime, all_day)."""
    value = value.strip()
    is_date = params.get("VALUE", "").upper() == "DATE" or (len(value) == 8 and "T" not in value)
    if is_date:
        try:
            return date(int(value[0:4]), int(value[4:6]), int(value[6:8])), True
        except Exception:
            return None, True
    tz = None
    val = value
    if val.endswith("Z"):
        tz, val = timezone.utc, val[:-1]
    elif "TZID" in params and ZoneInfo:
        try:
            tz = ZoneInfo(params["TZID"])
        except Exception:
            tz = None
    d = None
    for fmt in ("%Y%m%dT%H%M%S", "%Y%m%dT%H%M"):
        try:
            d = datetime.strptime(val, fmt)
            break
        except Exception:
            continue
    if d is None:
        return None, False
    if tz is not None:
        d = d.replace(tzinfo=tz)
    return d, False


def to_local(d):
    """Normalize an aware datetime to local naive; pass dates through."""
    if isinstance(d, datetime):
        if d.tzinfo is not None:
            d = d.astimezone(LOCAL_TZ)
        return d.replace(tzinfo=None)
    return d


def parse_rrule(value):
    r = {}
    for kv in value.split(";"):
        if "=" in kv:
            k, v = kv.split("=", 1)
            r[k.upper()] = v.upper()
    return r


def add_months(d, months):
    y = d.year + (d.month - 1 + months) // 12
    m = (d.month - 1 + months) % 12 + 1
    day = min(d.day, _cal.monthrange(y, m)[1])
    if isinstance(d, datetime):
        return d.replace(year=y, month=m, day=day)
    return date(y, m, day)


def expand(start, rrule, exdates, win_start, win_end):
    """Yield occurrence starts within [win_start, win_end] (date or datetime)."""
    occ = []
    is_dt = isinstance(start, datetime)

    def keep(o):
        od = o.date() if isinstance(o, datetime) else o
        if od < win_start or od > win_end:
            return
        if od.isoformat() in exdates:
            return
        occ.append(o)

    freq = rrule.get("FREQ")
    if not freq:
        keep(start)
        return occ

    interval = int(rrule.get("INTERVAL", "1") or 1)
    count = int(rrule["COUNT"]) if rrule.get("COUNT") else None
    until_dt = None
    if rrule.get("UNTIL"):
        u, _ = parse_dt({}, rrule["UNTIL"])
        if u is not None:
            until_dt = to_local(u) if isinstance(u, datetime) else datetime(u.year, u.month, u.day)

    def cmp(o):
        return o if isinstance(o, datetime) else datetime(o.year, o.month, o.day)

    byday = [WEEKMAP[d] for d in rrule.get("BYDAY", "").split(",") if d in WEEKMAP]
    MAX = 3000
    emitted = 0

    if freq == "WEEKLY" and byday:
        weekstart = start - timedelta(days=start.weekday())
        for _ in range(MAX):
            for wd in sorted(byday):
                o = weekstart + timedelta(days=wd)
                if o < start:
                    continue
                if until_dt and cmp(o) > until_dt:
                    return occ
                if (o.date() if is_dt else o) > win_end:
                    return occ
                keep(o)
                emitted += 1
                if count and emitted >= count:
                    return occ
            weekstart += timedelta(weeks=interval)
            if (weekstart.date() if is_dt else weekstart) > win_end:
                break
        return occ

    cur = start
    for _ in range(MAX):
        if until_dt and cmp(cur) > until_dt:
            break
        if (cur.date() if is_dt else cur) > win_end:
            break
        keep(cur)
        emitted += 1
        if count and emitted >= count:
            break
        if freq == "DAILY":
            cur += timedelta(days=interval)
        elif freq == "WEEKLY":
            cur += timedelta(weeks=interval)
        elif freq == "MONTHLY":
            cur = add_months(cur, interval)
        elif freq == "YEARLY":
            cur = add_months(cur, 12 * interval)
        else:
            break
    return occ


def process_event(cur, events, win_start, win_end, source=0):
    start = cur.get("start")
    if start is None:
        return
    title = cur.get("title", "(no title)")
    location = cur.get("location", "")
    allday = cur.get("allday", False)
    start_local = to_local(start)
    for o in expand(start_local, cur.get("rrule") or {}, cur.get("exdates", set()), win_start, win_end):
        if isinstance(o, datetime):
            d_date, tstr, start_iso = o.date(), o.strftime("%H:%M"), o.isoformat()
        else:
            d_date, tstr, start_iso = o, "", o.isoformat()
        if d_date < win_start or d_date > win_end:
            continue
        events.append({
            "id": hashlib.sha1((cur.get("uid", "") + start_iso + title).encode()).hexdigest()[:12],
            "title": title,
            "date": d_date.isoformat(),
            "time": "" if allday else tstr,
            "allDay": bool(allday),
            "location": location,
            "start": start_iso,
            "source": source,
            "_sort": (d_date.isoformat(), "0" if allday else (tstr or "00:00")),
        })


def main():
    # Optional management subcommands; all paths still emit the event list after.
    args = sys.argv[1:]
    if len(args) > 1 and args[0] == "add":
        add_url(args[1])
    elif len(args) > 1 and args[0] == "remove":
        remove_url(args[1])

    urls = read_urls()
    result = {"configured": len(urls) > 0, "events": []}
    if not urls:
        print(json.dumps(result, separators=(",", ":")))
        return

    today = date.today()
    win_start, win_end = today, today + timedelta(days=LOOKAHEAD_DAYS)
    events, err = [], None

    for source, url in enumerate(urls):
        raw = fetch(url)
        if not raw:
            err = "fetch failed"
            continue
        cur = None
        for ln in unfold(raw):
            u = ln.upper()
            if u.startswith("BEGIN:VEVENT"):
                cur = {"exdates": set()}
            elif u.startswith("END:VEVENT"):
                if cur is not None:
                    try:
                        process_event(cur, events, win_start, win_end, source)
                    except Exception:
                        pass
                cur = None
            elif cur is not None:
                pp = parse_prop(ln)
                if not pp:
                    continue
                name, params, value = pp
                if name == "SUMMARY":
                    cur["title"] = unescape(value)
                elif name == "LOCATION":
                    cur["location"] = unescape(value)
                elif name == "UID":
                    cur["uid"] = value
                elif name == "DTSTART":
                    cur["start"], cur["allday"] = parse_dt(params, value)
                elif name == "DTEND":
                    cur["end"], _ = parse_dt(params, value)
                elif name == "RRULE":
                    cur["rrule"] = parse_rrule(value)
                elif name == "EXDATE":
                    d, _ = parse_dt(params, value)
                    if d is not None:
                        dd = to_local(d)
                        cur["exdates"].add((dd.date() if isinstance(dd, datetime) else dd).isoformat())

    events.sort(key=lambda e: e["_sort"])
    for e in events:
        e.pop("_sort", None)
    result["events"] = events[:MAX_EVENTS]
    if err and not events:
        result["error"] = err
    print(json.dumps(result, separators=(",", ":")))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(json.dumps({"configured": False, "events": [], "error": str(e)},
                         separators=(",", ":")))
