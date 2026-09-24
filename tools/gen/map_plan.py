# Draws design/map_plan_v1.png: the proposed 4 x 4 km layout for the demo.
# World coordinates as in the game: x east, z south, metres, origin at the centre.
# Run: python tools/gen/map_plan.py
from PIL import Image, ImageDraw, ImageFont
import math

S = 0.25            # pixels per metre (4 km -> 1000 px)
PAD = 40
W = int(4000 * S) + PAD * 2 + 340
H = int(4000 * S) + PAD * 2


def px(x, z):
    return (PAD + (x + 2000) * S, PAD + (z + 2000) * S)


img = Image.new("RGB", (W, H), (236, 228, 204))
d = ImageDraw.Draw(img)
try:
    f = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 13)
    fb = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 15)
    ft = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 20)
except OSError:
    f = fb = ft = ImageFont.load_default()

# land tint and the sea on the east
d.rectangle([px(-2000, -2000), px(2000, 2000)], fill=(214, 226, 180))
coast = [(1850, -2000), (1800, -1500), (1720, -1000), (1760, -500), (1840, 0), (1880, 600), (1860, 1200), (1900, 2000)]
sea = [px(*c) for c in coast] + [px(2000, 2000), px(2000, -2000)]
d.polygon(sea, fill=(150, 196, 222))
# the beach strip along Bessi
d.line([px(1850, -100), px(1870, 400), px(1885, 900), px(1860, 1250)], fill=(238, 214, 150), width=16)

# hills / mountains (circles, darker = higher)
hills = [((-1300, 900), 260, ""), ((1100, -50), 380, "Ghat hills"),
         ((-600, -1300), 240, ""), ((0, -1500), 330, ""),
         ((-200, 150), 200, ""), ((600, 1300), 280, "South hills (river source)"), ((-1700, 200), 250, "")]
for (x, z), r, name in hills:
    d.ellipse([px(x - r, z - r), px(x + r, z + r)], fill=(190, 196, 150), outline=(150, 150, 110))
    if name:
        d.text(px(x - r * 0.6, z - 30), name, fill=(110, 110, 80), font=f)

# the river: from the northern hills, south through the middle, then east to the sea
river = [(600, 1150), (520, 800), (470, 300), (450, -150), (460, -400), (480, -900), (450, -1400)]
d.line([px(-300, -2000), px(100, -1750), px(450, -1400)], fill=(110, 160, 200), width=4)   # a stream from the north
estuary = [(450, -1400), (900, -1470), (1300, -1520), (1760, -1480)]
d.line([px(*p) for p in river], fill=(110, 160, 200), width=7)
d.line([px(*p) for p in estuary], fill=(110, 160, 200), width=9)
d.ellipse([px(-900, 550), px(-650, 750)], fill=(120, 170, 205))   # Mirror Lake
d.text(px(-930, 770), "Mirror Lake", fill=(60, 90, 120), font=f)

# storm over the old road on the way back
storm = [px(300, -450), px(1500, -450), px(1500, 350), px(300, 350)]
d.polygon(storm, fill=(160, 160, 175))
d.text(px(620, 290), "STORM on the way back", fill=(80, 80, 95), font=fb)


def road(pts, col, width=5, dash=False):
    q = [px(*p) for p in pts]
    if not dash:
        d.line(q, fill=col, width=width, joint="curve")
        return
    for a, b in zip(q, q[1:]):
        L = math.dist(a, b)
        n = max(1, int(L / 12))
        for i in range(0, n, 2):
            t0, t1 = i / n, min(1, (i + 1) / n)
            d.line([(a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0),
                    (a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1)], fill=col, width=width)


GREEN = (40, 140, 60)     # the opening: P1 alone to P2
ORANGE = (220, 120, 30)   # the way out
PURPLE = (120, 60, 160)   # the way back
BLUE = (40, 90, 200)      # the drive home

# 0-1: P1 home -> P2 home (tutorial drive)
road([(-1600, 1500), (-1400, 1600), (-1100, 1550), (-800, 1700), (-500, 1650)], GREEN, 6)
# 3: the way out: P2 -> J1 -> (valley long | ridge short) -> J2 -> bridge -> ghat -> beach
road([(-500, 1650), (-550, 1300), (-600, 950)], ORANGE)
road([(-600, 950), (-950, 800), (-1000, 500), (-700, 300), (-300, 380), (100, 420)], ORANGE, 5)        # valley (long)
road([(-600, 950), (-350, 600), (-150, 380), (100, 420)], ORANGE, 5, dash=True)                         # ridge (short)
road([(100, 420), (300, 150), (380, -150), (450, -180)], ORANGE)
road([(450, -180), (650, -150), (800, -300), (850, -100), (1000, -250), (1050, -50), (1150, -150)], ORANGE)  # hairpins
road([(1150, -150), (1350, 100), (1500, 350), (1650, 450)], ORANGE)
# 8: the way back: along the coast, over the estuary, west across the north
road([(1650, 450), (1700, 0), (1650, -600), (1600, -1100), (1550, -1480), (1300, -1650),
      (900, -1700), (400, -1600), (0, -1500), (-400, -1450), (-800, -1250), (-1200, -1100), (-1650, -900)], PURPLE, 5, dash=True)
# 10: the drive home from Naresh's house
road([(-1650, -900), (-1750, -400), (-1650, 200), (-1550, 800), (-1600, 1500)], BLUE, 5)
road([(-1550, 800), (-1100, 1100), (-500, 1650)], BLUE, 3)

# places
places = [
    ((-1600, 1500), "P1's home (today's homestead)", (200, 60, 40)),
    ((-500, 1650), "P2's home", (200, 60, 40)),
    ((-1650, -900), "Naresh's home (mother, sister)", (200, 60, 40)),
    ((-1300, 900), "Watchtower (the ending view)", (60, 60, 60)),
    ((-1250, 1560), "Town fuel", (60, 60, 60)),
    ((-600, 950), "J1 Windmill (choose a road)", (60, 60, 60)),
    ((-500, 250), "Barn", (60, 60, 60)),
    ((-200, 200), "Lookout", (60, 60, 60)),
    ((100, 420), "J2 Last Fuel (traffic ends)", (60, 60, 60)),
    ((380, -150), "Water works", (60, 60, 60)),
    ((450, -180), "Bridge (the gate)", (60, 60, 60)),
    ((1150, -150), "Coast watchtower (see the beach)", (60, 60, 60)),
    ((1650, 450), "BESSI BEACH", (180, 40, 120)),
    ((1860, 700), "Five Roses", (180, 40, 120)),
    ((1650, -600), "Fishing village", (60, 60, 60)),
    ((1600, -1100), "Salt pans", (60, 60, 60)),
    ((1550, -1480), "Estuary bridge", (60, 60, 60)),
    ((0, -1500), "Old rail tunnel (underground)", (60, 60, 60)),
    ((-600, -1300), "Radio mast", (60, 60, 60)),
]
for (x, z), name, col in places:
    a, b = px(x, z)
    d.ellipse([a - 6, b - 6, a + 6, b + 6], fill=col, outline=(20, 20, 20))
    d.text((a + 9, b - 8), name, fill=(20, 20, 20), font=fb if name.isupper() or "home" in name else f)

# frame, scale, north
d.rectangle([px(-2000, -2000), px(2000, 2000)], outline=(80, 70, 50), width=2)
a, b = px(-1900, 1930)
d.line([a, b, a + 1000 * S, b], fill=(40, 40, 40), width=3)
d.text((a, b - 18), "1 km", fill=(40, 40, 40), font=f)
d.text(px(1880, -1980), "N ^", fill=(40, 40, 40), font=fb)
d.text(px(1600, -1960), "SEA", fill=(40, 80, 120), font=ft)

# legend
lx = PAD + 4000 * S + 20
y = PAD
d.text((lx, y), "Map plan v1 (4 x 4 km)", fill=(20, 20, 20), font=ft); y += 36
for col, label, dash in [(GREEN, "Opening: P1 drives alone to P2", False),
                         (ORANGE, "The way out (bright, traffic)", False),
                         (ORANGE, "Ridge shortcut", True),
                         (PURPLE, "The way back with Naresh", True),
                         (BLUE, "The drive home (full sun)", False)]:
    if dash:
        for i in range(0, 40, 12):
            d.line([(lx + i, y + 8), (lx + i + 6, y + 8)], fill=col, width=5)
    else:
        d.line([(lx, y + 8), (lx + 40, y + 8)], fill=col, width=5)
    d.text((lx + 50, y), label, fill=(20, 20, 20), font=f); y += 24
y += 12
d.text((lx, y), "Rough driving times", fill=(20, 20, 20), font=fb); y += 22
for line in ["P1 -> P2: ~2.5 min", "P2 -> J1: ~1 min", "J1 -> J2 valley: ~2.5 min",
             "J1 -> J2 ridge: ~1.5 min", "J2 -> bridge: ~1 min", "bridge -> coast tower: ~2 min",
             "tower -> beach: ~1.5 min", "beach -> Naresh's home: ~8 min",
             "Naresh's home -> home: ~3.5 min", "(plus stops, puzzles, walking)"]:
    d.text((lx, y), line, fill=(40, 40, 40), font=f); y += 19
img.save("design/map_plan_v1.png")
print("saved")
