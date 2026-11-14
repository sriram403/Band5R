"""T4 v2 small join verifier (speed research): a recorded take's parts -> one video, or a refusal.

  framemap <avi> <marker drawn frame> <fps> <out.json>
      Proves the drawn-frame -> movie-frame mapping: the walk's `marker` drew ONE magenta frame and
      logged Engine.get_frames_drawn(); find that frame in the movie (frames around it decoded) and
      record movie_index - drawn_frame. Exactly one magenta frame, else no proof.
  part <parts dir> <k> <run dir> <mp4> [speed text]
      Writes <parts>/part<k>.json: run, identity, profile, from_point, the steps it played with their
      drawn frames, its end (DONE / FAILED at <step>), the mp4's sha256 and ffprobe duration.
  verify <parts dir> [framemap.json]   -> exit 0 and the cut list, or exit 1 and every refusal
  join <parts dir> <out.mp4> [framemap.json]   verify, cut frame-exact, join, write joins.json/.txt
      and a frame pair either side of each join (joins_frames/) to look at.

Rules (verify): parts 1..n present, their mp4 bytes and durations as recorded; one game / test /
binary / schema / profile (rec25) across all parts; part 1 starts at step 1 fresh; part i+1 resumes
from a point written by part i's run at the step part i failed at (the failed step is cut out of part
i: it is played again in part i+1); the last part ends DONE; no step missing or played twice in the
kept ranges; every join's boundary SAME under walkgate.boundary (>= 2 resume receipts, D3 A, same
profile) from part i+1's receipt + GATE_ONLY receipts of the same point; any cut needs a proved frame
map for the profile. Cumulative join times come from the trimmed parts' ffprobe durations.
"""
import hashlib
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import walkgate  # noqa: E402

FPS = 25
# test-only (the join mechanics control, t4_controls.py `join`): verify everything but the gate verdict
WAIVED = os.environ.get("JOIN_GATE_WAIVED") == "1"


def sh(args):
    return subprocess.run(args, capture_output=True, text=True, errors="replace")


def sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for c in iter(lambda: f.read(1 << 20), b""):
            h.update(c)
    return h.hexdigest()[:16]


def duration(p):
    r = sh(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", p])
    try:
        return float(r.stdout.strip())
    except ValueError:
        return None


def frames_rgb(video, a, b, w=16, h=9):
    """Mean RGB of decoded frames a..b (inclusive), by decode index."""
    r = subprocess.run(["ffmpeg", "-v", "error", "-i", video, "-vf",
                        "select='between(n\\,%d\\,%d)',scale=%d:%d" % (a, b, w, h), "-vsync", "0",
                        "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], capture_output=True)
    data = r.stdout
    n = w * h * 3
    out = []
    for i in range(len(data) // n):
        px = data[i * n:(i + 1) * n]
        out.append(tuple(sum(px[c::3]) / (w * h) for c in range(3)))
    return out


def is_magenta(c):
    return c[0] > 200 and c[1] < 60 and c[2] > 200


def framemap(avi, drawn, fps, out):
    drawn = int(drawn)
    lo = max(0, drawn - 12)
    cols = frames_rgb(avi, lo, drawn + 12)
    hits = [lo + i for i, c in enumerate(cols) if is_magenta(c)]
    res = {"profile": "rec25", "fps": int(fps), "marker_drawn_frame": drawn, "magenta_movie_frames": hits,
           "window": [lo, drawn + 12], "video": os.path.basename(avi)}
    if len(hits) == 1:
        res["offset"] = hits[0] - drawn
        res["proved"] = True
    else:
        res["proved"] = False
        res["why"] = "expected exactly one magenta frame near drawn frame %d, found %s" % (drawn, hits)
    with open(out, "w", encoding="utf-8") as f:
        json.dump(res, f, indent=1)
    print("FRAMEMAP:", json.dumps(res))
    return 0 if res["proved"] else 1


STEP = re.compile(r"^step (.*) \((\d+) s, frame (\d+)\)$")


def part(pdir, k, rdir, mp4, speed=""):
    rj = walkgate.load(os.path.join(rdir, "run.json"))
    lines = open(os.path.join(rdir, "walk.log"), encoding="utf-8").read().splitlines()
    steps = [(m.group(1), int(m.group(3))) for m in (STEP.match(x) for x in lines) if m]
    end = "DONE" if any(x.startswith("DONE ") for x in lines) else ("FAILED" if any(x.startswith("FAILED ") for x in lines) else "UNFINISHED")
    failed_step = ""
    if end == "FAILED":
        lf = [x for x in lines if x.startswith("FAIL ")]
        failed_step = steps[-1][0] if steps else ""
        lfp = os.path.join(os.path.dirname(rdir), "%s_last_fail.json" % rj.get("walk", ""))
        if os.path.exists(lfp):
            d = walkgate.load(lfp)
            if d.get("run") == rj.get("run"):
                failed_step = d.get("step", failed_step)
    gate = None
    if rj.get("from_point"):
        gp = [os.path.join(rdir, x) for x in os.listdir(rdir) if x.endswith(".gate.json")]
        gate = gp[0] if gp else None
    d = {"k": int(k), "run": rj.get("run"), "run_dir": os.path.abspath(rdir), "identity": rj.get("identity"),
         "from": rj.get("from", ""), "from_point": rj.get("from_point", ""), "steps": steps, "end": end,
         "failed_step": failed_step, "gate_receipt": gate, "mp4": os.path.abspath(mp4), "sha": sha(mp4),
         "duration": duration(mp4), "speed": speed}
    with open(os.path.join(pdir, "part%d.json" % int(k)), "w", encoding="utf-8") as f:
        json.dump(d, f, indent=1)
    print("PART %d: %s, %d steps, %s%s, %.2f s, %s" % (int(k), d["run"], len(steps), end,
          (" at '%s'" % failed_step) if failed_step else "", d["duration"] or -1, speed))
    return 0


def verify(pdir, fmap=None, walk=None):
    why, cuts = [], []
    ks = sorted(int(m.group(1)) for m in (re.match(r"part(\d+)\.json$", x) for x in os.listdir(pdir)) if m)
    if not ks:
        return ["no parts"], []
    if ks != list(range(1, len(ks) + 1)):
        why.append("parts not 1..n: %s" % ks)
    parts = []
    for k in ks:
        p = walkgate.load(os.path.join(pdir, "part%d.json" % k))
        if not os.path.exists(p["mp4"]):
            why.append("part %d: video absent (%s)" % (k, p["mp4"]))
        else:
            if sha(p["mp4"]) != p["sha"]:
                why.append("part %d: video bytes changed since recorded" % k)
            dd = duration(p["mp4"])
            if dd is None or p["duration"] is None or abs(dd - p["duration"]) > 0.05:
                why.append("part %d: duration %s != recorded %s" % (k, dd, p["duration"]))
        parts.append(p)
    if why:
        return why, []
    ids = [p.get("identity") or {} for p in parts]
    for key in ("game", "test", "bin", "schema", "profile"):
        vals = set(str(i.get(key)) for i in ids)
        if len(vals) != 1:
            why.append("parts differ in %s: %s" % (key, sorted(vals)))
    if ids[0].get("profile") != "rec25":
        why.append("profile %s is not the recording profile rec25" % ids[0].get("profile"))
    if parts[0]["from_point"] or not parts[0]["steps"] or parts[0]["steps"][0][0] != (walk["steps"][0]["name"] if walk else parts[0]["steps"][0][0]):
        why.append("part 1 must start fresh at step 1")
    if parts[-1]["end"] != "DONE":
        why.append("the last part is %s, not DONE" % parts[-1]["end"])
    fm = walkgate.load(fmap) if fmap and os.path.exists(fmap) else None
    proved = bool(fm and fm.get("proved") and fm.get("profile") == "rec25")
    kept = []
    for i, p in enumerate(parts):
        nxt = parts[i + 1] if i + 1 < len(parts) else None
        names = [s[0] for s in p["steps"]]
        a_frame = 0
        if p["from_point"]:
            a_frame = p["steps"][0][1] if p["steps"] else None
        b_frame = None
        if nxt is not None:
            if p["end"] != "FAILED":
                why.append("part %d is %s but part %d follows it" % (p["k"], p["end"], nxt["k"]))
                continue
            prun, pidx = (nxt["from_point"].rsplit("/", 1) + [""])[:2] if nxt["from_point"] else ("", "")
            if prun != p["run"]:
                why.append("part %d resumes from %s, not from part %d's run %s" % (nxt["k"], nxt["from_point"] or "nothing", p["k"], p["run"]))
                continue
            if nxt["from"] != p["failed_step"]:
                why.append("part %d resumes at '%s' but part %d failed at '%s'" % (nxt["k"], nxt["from"], p["k"], p["failed_step"]))
            if nxt["from"] not in names:
                why.append("part %d never reached '%s'" % (p["k"], nxt["from"]))
                continue
            b_frame = p["steps"][names.index(nxt["from"])][1]
            kept += names[:names.index(nxt["from"])]
            # the join's gate: part i+1's receipt + GATE_ONLY receipts of the same point
            runs = [nxt["run_dir"]]
            gr = os.path.join(pdir, "gate_runs")
            if os.path.exists(gr):
                for ln in open(gr, encoding="utf-8").read().split():
                    try:
                        if walkgate.load(os.path.join(ln, "run.json")).get("from_point") == nxt["from_point"]:
                            runs.append(ln)
                    except OSError:
                        why.append("gate run %s unreadable" % ln)
            b = walkgate.boundary(os.path.join(os.path.dirname(nxt["run_dir"]), prun), int(pidx), runs)
            nxt["_gate"] = b
            if b["verdict"] != "SAME" and WAIVED:
                print("TEST ONLY (JOIN_GATE_WAIVED=1): join part %d -> %d gate %s ignored: this is a mechanics control, never a video or a clean walk" % (p["k"], nxt["k"], b["verdict"]))
            elif b["verdict"] != "SAME":
                why.append("join part %d -> %d at '%s': gate %s (%s)" % (p["k"], nxt["k"], nxt["from"], b["verdict"],
                           "; ".join("%s: %s" % (r["resume_run"], r["failed_layers"]) for r in b["resumes"])))
        else:
            kept += names
        if a_frame is None:
            why.append("part %d: no step line to cut at" % p["k"])
            continue
        if (a_frame or b_frame is not None) and not proved:
            why.append("part %d needs a cut but the drawn-frame -> movie-frame mapping is not proved (%s)" % (p["k"], fmap or "no framemap"))
            continue
        off = fm["offset"] if proved else 0
        a = (a_frame + off) if a_frame else 0
        b = (b_frame + off) if b_frame is not None else None
        if b is not None and b <= a:
            why.append("part %d: empty or reversed range %s..%s" % (p["k"], a, b))
        if p["duration"] is not None and a / FPS > p["duration"] - 1.0 / FPS:
            why.append("part %d: cut start frame %d at or past its end (%.2f s)" % (p["k"], a, p["duration"]))
        if b is not None and p["duration"] is not None and b / FPS > p["duration"] + 0.04:
            why.append("part %d: cut %d past its end (%.2f s)" % (p["k"], b, p["duration"]))
        cuts.append({"k": p["k"], "mp4": p["mp4"], "from_frame": a, "to_frame": b, "run": p["run"],
                     "first_step": names[0] if names else "", "gate": (p.get("_gate") or {}).get("point")})
    if walk is not None:
        want = [s["name"] for s in walk["steps"]]
        if kept != want:
            missing = [x for x in want if x not in kept]
            dup = sorted(set(x for x in kept if kept.count(x) > 1))
            why.append("kept steps differ from the walk: missing %s, twice %s" % (missing, dup))
    return why, cuts


def mmss(t):
    return "%02d:%06.3f" % (int(t // 60), t - 60 * int(t // 60))


def join(pdir, out, fmap=None):
    if WAIVED and "TESTONLY" not in os.path.basename(out):
        print("JOIN REFUSED: JOIN_GATE_WAIVED=1 (a test-only control) needs an output named *TESTONLY*")
        return 1
    pj = walkgate.load(os.path.join(pdir, "part1.json"))
    wj = os.path.join(pj["run_dir"], "walk.json")
    walk = walkgate.load(wj) if os.path.exists(wj) else None
    why, cuts = verify(pdir, fmap, walk)
    if why:
        print("JOIN REFUSED:")
        for x in why:
            print("  - " + x)
        return 1
    tdir = os.path.join(pdir, "trim")
    os.makedirs(tdir, exist_ok=True)
    trimmed = []
    for c in cuts:
        t = os.path.join(tdir, "t%d.mp4" % c["k"])
        vf = "trim=start_frame=%d%s,setpts=PTS-STARTPTS" % (c["from_frame"], (":end_frame=%d" % c["to_frame"]) if c["to_frame"] is not None else "")
        af = "atrim=start=%.4f%s,asetpts=PTS-STARTPTS" % (c["from_frame"] / FPS, (":end=%.4f" % (c["to_frame"] / FPS)) if c["to_frame"] is not None else "")
        r = sh(["ffmpeg", "-v", "error", "-y", "-i", c["mp4"], "-vf", vf, "-af", af, "-c:v", "libx264", "-preset", "medium",
                "-crf", "23", "-pix_fmt", "yuv420p", "-r", str(FPS), "-c:a", "aac", "-b:a", "128k", "-ar", "48000", t])
        if r.returncode:
            print("JOIN REFUSED: trim of part %d failed: %s" % (c["k"], r.stderr[-300:]))
            return 1
        c["trimmed"] = t
        c["trimmed_s"] = duration(t)
        trimmed.append(t)
    lst = os.path.join(tdir, "list.txt")
    with open(lst, "w", encoding="utf-8") as f:
        for t in trimmed:
            f.write("file '%s'\n" % t.replace("\\", "/"))
    r = sh(["ffmpeg", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", lst, "-c", "copy", "-movflags", "+faststart", out])
    if r.returncode:
        print("JOIN REFUSED: concat failed: " + r.stderr[-300:])
        return 1
    joins, t = [], 0.0
    fr = os.path.join(pdir, "joins_frames")
    os.makedirs(fr, exist_ok=True)
    for i, c in enumerate(cuts):
        if i > 0:
            a = os.path.join(fr, "join%d_before.png" % i)
            b = os.path.join(fr, "join%d_after.png" % i)
            sh(["ffmpeg", "-v", "error", "-y", "-sseof", "-0.08", "-i", cuts[i - 1]["trimmed"], "-frames:v", "1", a])
            sh(["ffmpeg", "-v", "error", "-y", "-i", c["trimmed"], "-frames:v", "1", b])
            joins.append({"at": mmss(t), "at_s": round(t, 3), "step": c["first_step"], "part": c["k"], "gate": c["gate"],
                          "before_png": a, "after_png": b})
        t += c["trimmed_s"] or 0.0
    total = duration(out)
    res = {"video": out, "sha": sha(out), "duration": total, "sum_of_parts": round(t, 3), "joins": joins,
           "parts": [{"k": c["k"], "run": c["run"], "frames": [c["from_frame"], c["to_frame"]], "trimmed_s": c["trimmed_s"]} for c in cuts]}
    with open(os.path.join(pdir, "joins.json"), "w", encoding="utf-8") as f:
        json.dump(res, f, indent=1)
    with open(os.path.join(pdir, "joins.txt"), "w", encoding="utf-8") as f:
        for j in joins:
            f.write("%s -> step '%s', part %d, gate %s\n" % (j["at"], j["step"], j["part"], j["gate"]))
    print("JOINED %d part(s) -> %s (%.3f s; parts sum %.3f s); joins:" % (len(cuts), out, total or -1, t))
    for j in joins:
        print("  %s -> step '%s', part %d, gate %s (look: %s | %s)" % (j["at"], j["step"], j["part"], j["gate"], j["before_png"], j["after_png"]))
    if total is not None and abs(total - t) > 0.1:
        print("WARNING: joined length %.3f differs from the parts' sum %.3f" % (total, t))
        return 1
    return 0


def mean_db(video, start, dur):
    r = sh(["ffmpeg", "-v", "info", "-ss", "%.3f" % start, "-t", "%.3f" % dur, "-i", video, "-vn", "-af", "volumedetect", "-f", "null", "-"])
    m = re.search(r"mean_volume: (-?[\d.]+|-inf) dB", r.stderr)
    return float(m.group(1)) if m and m.group(1) != "-inf" else -200.0


def sound(video, quiet_s, loud_s, dur=1.5, need_db=10.0):
    """The known captured sound, decoded: the window after a known sound's start (loud_s) must be at
    least need_db louder than a quiet window (quiet_s). A missing audio stream fails."""
    r = sh(["ffprobe", "-v", "error", "-select_streams", "a", "-show_entries", "stream=codec_name,sample_rate,channels", "-of", "csv=p=0", video])
    if not r.stdout.strip():
        print("SOUND: FAIL, no audio stream in %s" % video)
        return 1
    q, l = mean_db(video, float(quiet_s), dur), mean_db(video, float(loud_s), dur)
    ok = l - q >= need_db
    print("SOUND: %s, audio %s; quiet window %.2f s: %.1f dB, known sound window %.2f s: %.1f dB (%.1f dB louder, need %.0f)"
          % ("PASS" if ok else "FAIL", r.stdout.strip(), float(quiet_s), q, float(loud_s), l, l - q, need_db))
    return 0 if ok else 1


def main(a):
    if a[0] == "sound":
        return sound(a[1], a[2], a[3])
    if a[0] == "framemap":
        return framemap(a[1], a[2], a[3], a[4])
    if a[0] == "part":
        return part(a[1], a[2], a[3], a[4], a[5] if len(a) > 5 else "")
    if a[0] == "verify":
        pj = walkgate.load(os.path.join(a[1], "part1.json"))
        wj = os.path.join(pj["run_dir"], "walk.json")
        why, cuts = verify(a[1], a[2] if len(a) > 2 else None, walkgate.load(wj) if os.path.exists(wj) else None)
        print(json.dumps({"refused": why, "cuts": cuts}, indent=1, default=str))
        return 1 if why else 0
    if a[0] == "join":
        return join(a[1], a[2], a[3] if len(a) > 3 else None)
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:] or ["help"]))
