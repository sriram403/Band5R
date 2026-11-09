"""Apply exact replacements to a file, its line endings kept: python patch.py target spec.txt
spec.txt: blocks separated by lines '<<<<', '====', '>>>>' (old between <<<< and ====, new between ==== and >>>>).
Every old text must occur exactly once, or nothing is written."""
import sys
target, spec = sys.argv[1], sys.argv[2]
s = open(target, encoding="utf-8", newline="").read()
src = open(spec, encoding="utf-8", newline="").read().replace("\r\n", "\n")
blocks = []
for part in src.split("<<<<\n")[1:]:
    old, rest = part.split("\n====\n", 1)
    new = rest.split("\n>>>>", 1)[0]
    blocks.append((old, new))
NL, CRNL = "\n", "\r\n"
if CRNL in s:
    blocks = [(o.replace(NL, CRNL), n.replace(NL, CRNL)) for o, n in blocks]
for old, new in blocks:
    n = s.count(old)
    if n != 1:
        print("NOT APPLIED: found %d times:\n%s" % (n, old[:200]))
        sys.exit(1)
    s = s.replace(old, new)
open(target, "w", encoding="utf-8", newline="").write(s)
print("applied %d block(s) to %s" % (len(blocks), target))
