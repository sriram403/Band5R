"""F5 (fix round): the lane sentinel judges its own workload. Lane b's walks are the sentinel's second
workload; a failed one is a failed sentinel, not a footnote.
  python tools/method/sentinel_workers.py <lane b walk log>
-> prints "lane b walks: <ok> ok of <n>"; exit 0 only if n >= 1 and every walk ended "RESULT: ok".
"""
import sys


def judge(text):
    res = [ln for ln in text.replace("\r", "").split("\n") if ln.startswith("RESULT")]
    ok = sum(1 for ln in res if ln.startswith("RESULT: ok"))
    return ok, len(res)


def main(a):
    ok, n = judge(open(a[0], encoding="utf-8", errors="replace").read())
    good = n >= 1 and ok == n
    print("lane b walks: %d ok of %d%s" % (ok, n, "" if good else " (a sentinel needs every worker walk ok)"))
    return 0 if good else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
