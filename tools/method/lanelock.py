"""The lane lock (autoq, GPT re-check B2, 2026-11-24): ONE owner per lane for everything that writes a lane's walk
records (<walk>_last_fail.json, <walk>_autoq.json): an ordinary walk (tools/play_walk.sh) holds it for its whole run,
autoq holds it while it qualifies (or inherits a walk's ownership through its token), qualification / probe children
run under their parent's token. So no game can write or delete last_fail while autoq decides and publishes.

    python tools/method/lanelock.py acquire <owner> <windows pid> <walk>   -> prints the token; exit 3 if busy
    python tools/method/lanelock.py verify <token>                         -> exit 0 if that token owns the lane
    python tools/method/lanelock.py release <token>                        -> removes the lock if the token owns it
    python tools/method/lanelock.py check                                  -> exit 3 if a live owner holds the lane

A stale lock (its owner's process is gone) is taken over under a second, short-lived takeover lock, after re-reading
that it is still the same stale record: two callers can't both win, and a live lock is never removed.
"""
import json
import os
import sys
import time
import uuid

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))


SAFE_TAKEOVER = True     # autoq_controls.py switches it off to see two callers both win a stale lock


def live_dir():
    lane = os.environ.get("LANE", "")
    return os.environ.get("AUTOQ_LIVE") or os.path.join(ROOT, "appdata", "playtest" + ("_" + lane if lane else ""), "FindingNaresh", "live")


def lock_path(live=None):
    return os.path.join(live or live_dir(), "lane.lock")


def pid_alive(pid):
    """Windows. Alive unless the system says the process does not exist (OpenProcess fails with ERROR_INVALID_PARAMETER,
    87) or it has exited (exit code != STILL_ACTIVE, 259). Any other failure (e.g. access denied) counts as ALIVE:
    fail closed, never a second owner."""
    try:
        pid = int(pid)
    except (TypeError, ValueError):
        return False
    if pid <= 0:
        return False
    try:
        import ctypes
        k32 = ctypes.WinDLL("kernel32", use_last_error=True)
        h = k32.OpenProcess(0x1000, False, pid)           # PROCESS_QUERY_LIMITED_INFORMATION
        if not h:
            return ctypes.get_last_error() != 87
        code = ctypes.c_ulong()
        ok = k32.GetExitCodeProcess(h, ctypes.byref(code))
        k32.CloseHandle(h)
        return (not ok) or code.value == 259
    except (OSError, AttributeError):
        return True


def read(live=None):
    try:
        with open(lock_path(live), encoding="utf-8") as f:
            d = json.load(f)
        return d if isinstance(d, dict) else {"token": None, "pid": -1, "why": "not a record"}
    except FileNotFoundError:
        return None
    except (OSError, ValueError):
        return {"token": None, "pid": -1, "why": "unreadable"}


def _create(path, rec):
    fd = os.open(path, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
    try:
        os.write(fd, json.dumps(rec).encode())
    finally:
        os.close(fd)


def acquire(owner, pid, walk="", live=None):
    """-> (token, None) on success, (None, holder record) if a live owner holds the lane."""
    live = live or live_dir()
    os.makedirs(live, exist_ok=True)
    path = lock_path(live)
    tok = uuid.uuid4().hex
    rec = {"token": tok, "pid": int(pid), "owner": owner, "walk": walk, "at": time.strftime("%Y-%m-%d %H:%M:%S")}
    for _ in range(20):
        try:
            _create(path, rec)
            return tok, None
        except FileExistsError:
            pass
        h = read(live)
        if h is None:
            continue                                     # released meanwhile: try again
        if pid_alive(h.get("pid")):
            return None, h
        if not SAFE_TAKEOVER:                            # controls only: the old remove-and-create (two winners)
            for _ in range(3):
                try:
                    os.remove(path)
                except OSError:
                    pass
                try:
                    _create(path, rec)
                    break
                except OSError:
                    time.sleep(0.005)
            return tok, None
        # stale: take it over under the takeover lock, after checking it is STILL that stale record
        tko = path + ".takeover"
        try:
            _create(tko, {"pid": os.getpid(), "at": time.time()})
        except FileExistsError:
            try:
                if time.time() - os.path.getmtime(tko) > 10:     # a takeover holder that died mid-way (microseconds)
                    os.remove(tko)
            except OSError:
                pass
            time.sleep(0.02)
            continue
        try:
            h2 = read(live)
            if h2 is not None and h2.get("token") == h.get("token") and not pid_alive(h2.get("pid")):
                os.remove(path)
                _create(path, rec)
                return tok, None
        except (FileExistsError, OSError):
            pass
        finally:
            try:
                os.remove(tko)
            except OSError:
                pass
    h = read(live)
    return None, h or {"pid": -1, "why": "could not acquire"}


def verify(token, live=None):
    h = read(live)
    return bool(token) and h is not None and h.get("token") == token and pid_alive(h.get("pid"))


def release(token, live=None):
    h = read(live)
    if h is not None and token and h.get("token") == token:
        try:
            os.remove(lock_path(live))
        except OSError:
            pass


def holder(live=None):
    """-> the live owner's record, or None (free, or stale)."""
    h = read(live)
    return h if h is not None and pid_alive(h.get("pid")) else None


def main(a):
    if a[:1] == ["acquire"] and len(a) >= 3:
        tok, h = acquire(a[1], a[2], a[3] if len(a) > 3 else "")
        if tok:
            print(tok)
            return 0
        print("[lane] the lane is busy: %s pid %s (%s, since %s)" % (h.get("owner"), h.get("pid"), h.get("walk"), h.get("at")), file=sys.stderr)
        return 3
    if a[:1] == ["verify"] and len(a) == 2:
        return 0 if verify(a[1]) else 3
    if a[:1] == ["release"] and len(a) == 2:
        release(a[1])
        return 0
    if a[:1] == ["check"]:
        h = holder()
        if h:
            print("[lane] the lane is busy: %s pid %s (%s, since %s)" % (h.get("owner"), h.get("pid"), h.get("walk"), h.get("at")))
            return 3
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
