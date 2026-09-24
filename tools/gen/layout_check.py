# Checks a world layout before it is built in the game: road grades, the gap
# between roads, river crossings and sea level, using the same height maths as
# Landscape.gd / Route.gd. Draws design/greybox_layout.png (hill shade + roads).
# Run: python tools/gen/layout_check.py
# The layout data here must match LevelBuilder.gd (it is copied across by hand).
import math
from PIL import Image, ImageDraw, ImageFont

EXTENT = 4000.0
SEA_Y = -2.0

# --- layout ---------------------------------------------------------------------
V = lambda x, z: (float(x), float(z))

HOMESTEAD = V(-1600, 1480)
J1 = V(-600, 950)
J2 = V(100, 420)
ROSE_CENTRE = V(1720, 640)

COAST = [V(1850, -2100), V(1800, -1500), V(1740, -1000), V(1770, -500), V(1840, 0), V(1900, 400),
         V(1930, 700), V(1890, 1200), V(1900, 2100)]

PONDS = [
    {"pos": V(-850, 660), "radius": 110.0, "depth": 7.0},   # Mirror Lake
    {"pos": V(-1600, 1545), "radius": 20.0, "depth": 2.4},  # homestead duck pond
]
MOUNDS = [
    {"pos": ROSE_CENTRE, "radius": 90.0, "height": 6.0, "plateau": 30.0},  # the roses' dune
    {"pos": V(-330, 640), "radius": 210.0, "height": 30.0},     # Pine Ridge (ridge track over it)
    {"pos": V(-600, -1300), "radius": 240.0, "height": 55.0},   # Radio Hill
    {"pos": V(0, -1520), "radius": 240.0, "height": 48.0},      # Tunnel Hill
    {"pos": V(990, -320), "radius": 320.0, "height": 110.0},   # Ghat north peak
    {"pos": V(1180, 190), "radius": 320.0, "height": 95.0},     # Ghat south peak
    {"pos": V(1380, -60), "radius": 380.0, "height": 30.0},     # Ghat east shoulder
    {"pos": V(600, 1320), "radius": 280.0, "height": 45.0},     # South hills (river source)
    {"pos": V(-1300, 900), "radius": 300.0, "height": 30.0},    # Watchtower hill
    {"pos": V(-1900, 250), "radius": 260.0, "height": 50.0},    # West hill
    {"pos": V(-1050, -350), "radius": 300.0, "height": 35.0},
    {"pos": V(-250, -650), "radius": 260.0, "height": 30.0},
    {"pos": V(1250, 1150), "radius": 260.0, "height": 35.0},
    {"pos": V(750, -1000), "radius": 220.0, "height": 28.0},
]
TUNNEL_MOUND = 3
RIVER = [V(600, 1130), V(560, 900), V(520, 650), V(482, 380), V(466, 150), V(456, -100), V(462, -400),
         V(480, -900), V(455, -1250), V(560, -1420), V(900, -1470), V(1300, -1520), V(1760, -1480), V(1950, -1470)]

HOME_LANE = [V(-1565, 1452), V(-1500, 1540), V(-1400, 1590), V(-1250, 1585), V(-1100, 1560), V(-950, 1620),
             V(-800, 1690), V(-650, 1695), V(-555, 1640), V(-525, 1500), V(-550, 1300), V(-585, 1100), J1]
VALLEY_ROAD = [J1, V(-700, 925), V(-850, 875), V(-960, 780), V(-1005, 640), V(-985, 500), V(-900, 385),
               V(-760, 305), V(-600, 262), V(-430, 250), V(-250, 285), V(-80, 330), V(40, 385), J2]
RIDGE_TRACK = [J1, V(-520, 830), V(-430, 720), V(-340, 610), V(-220, 520), V(-60, 465), J2]
PUMP_HOUSE_ROAD = [J2, V(210, 300), V(290, 160), V(338, 20), V(360, -90), V(362, -170), V(372, -215),
                   V(410, -240), V(460, -250), V(515, -252), V(560, -250)]
J3 = V(560, -250)
# hairpins up the west face of the Ghat saddle
GHAT_ROAD = [J3, V(650, -230), V(730, -160), V(790, -95), V(850, -45), V(900, -5), V(955, 20), V(985, 0),
             V(965, -40), V(930, -70), V(935, -100), V(985, -105), V(1020, -90), V(1050, -80)]
PASS = V(1050, -80)
BEACH_ROAD = [PASS, V(1150, -70), V(1260, -60), V(1380, -40), V(1470, 40), V(1530, 200), V(1570, 380),
              V(1610, 520)]
BESSI_LOOP_SHAPE = [V(0, -150), V(85, -128), V(140, -55), V(150, 30), V(112, 105), V(35, 152), V(-48, 148),
                    V(-120, 95), V(-152, 15), V(-130, -70), V(-62, -140)]
BESSI_CENTRE = ROSE_CENTRE
BESSI_SCALE = 0.85
COAST_ROAD = [V(1735, 520), V(1730, 300), V(1720, 60), V(1700, -250), V(1660, -600), V(1640, -900),
              V(1610, -1150), V(1570, -1350), V(1550, -1600), V(1450, -1720), V(1250, -1760),
              V(950, -1740), V(650, -1680), V(400, -1640), V(180, -1560), V(-150, -1490), V(-400, -1470),
              V(-650, -1560), V(-900, -1400), V(-1200, -1180), V(-1450, -1020), V(-1650, -900)]
NARESH_HOME = V(-1650, -900)
WEST_ROAD = [NARESH_HOME, V(-1720, -700), V(-1745, -420), V(-1700, -150), V(-1640, 150), V(-1590, 480),
             V(-1560, 800), V(-1575, 1050), V(-1610, 1250), V(-1640, 1380)]
TOWER_ROAD = [V(-1560, 800), V(-1420, 870), V(-1270, 980), V(-1100, 1100), V(-900, 1270), V(-720, 1450),
              V(-560, 1580)]

ROADS = [
    ("home_lane", HOME_LANE, False, "asphalt", 150, None),
    ("valley_road", VALLEY_ROAD, False, "asphalt", 150, None),
    ("ridge_track", RIDGE_TRACK, False, "gravel", 80, None),
    ("pump_house_road", PUMP_HOUSE_ROAD, False, "asphalt", 150, None),
    ("ghat_road", GHAT_ROAD, False, "asphalt", 150, 0.09),
    ("beach_road", BEACH_ROAD, False, "asphalt", 150, None),
    ("coast_road", COAST_ROAD, False, "asphalt", 150, None),
    ("west_road", WEST_ROAD, False, "asphalt", 150, None),
    ("tower_road", TOWER_ROAD, False, "asphalt", 150, None),
]

PLACES = {
    "P1 home": HOMESTEAD, "P2 home": V(-470, 1620), "Town fuel": V(-1250, 1625), "J1 windmill": J1,
    "Lake": V(-850, 660), "Barn": V(-500, 205), "Lookout": V(-340, 665), "J2 Last Fuel": J2,
    "Water works": V(405, -150), "Bridge": V(440, -245), "Coast tower": V(1395, -85), "Roses": ROSE_CENTRE,
    "Fishing village": V(1700, -600), "Salt pans": V(1680, -1100), "Estuary bridge": V(1560, -1490),
    "Rail tunnel": V(0, -1520), "Radio mast": V(-600, -1300), "Naresh home": NARESH_HOME,
    "End tower": V(-1300, 900),
}


# --- height maths (Landscape.gd / Route.gd) ------------------------------------
def smoothstep(e0, e1, x):
    if e0 == e1:
        return 0.0 if x < e0 else 1.0
    t = min(1.0, max(0.0, (x - e0) / (e1 - e0)))
    return t * t * (3 - 2 * t)


def lerp(a, b, t):
    return a + (b - a) * t


def ground_noise(x, z):
    h = 0.0
    h += math.sin(x * 0.0125 + 1.7) * math.cos(z * 0.0104 - 0.4) * 9.0
    h += math.sin(x * 0.0281 - 2.1) * math.cos(z * 0.0233 + 1.1) * 3.4
    h += math.sin((x + z) * 0.0071 + 0.6) * 4.6
    h += math.sin(x * 0.0605 + 0.3) * math.cos(z * 0.0518 - 1.9) * 0.9
    return h


def mound_raise(x, z):
    lift = 0.0
    for m in MOUNDS:
        c = m["pos"]
        d = math.hypot(x - c[0], z - c[1])
        if d < m["radius"]:
            lift += m["height"] * (1 - smoothstep(0, m["radius"], d))
    return lift


def pond_carve(x, z):
    drop = 0.0
    for p in PONDS:
        c = p["pos"]
        d = math.hypot(x - c[0], z - c[1])
        if d < p["radius"]:
            drop += p["depth"] * smoothstep(p["radius"], p["radius"] * 0.55, d)
    return drop


def coast_x(z):
    for (x0, z0), (x1, z1) in zip(COAST, COAST[1:]):
        if z0 <= z <= z1:
            return lerp(x0, x1, (z - z0) / (z1 - z0))
    return COAST[-1][0] if z > COAST[-1][1] else COAST[0][0]


def coast_shape(x, z, h):
    d = coast_x(z) - x   # metres inland of the waterline
    if d > 320:
        return h
    if d >= 0:
        prof = SEA_Y + 0.4 + d * 0.035
    else:
        prof = max(SEA_Y - 14.0, SEA_Y + 0.4 + d * 0.12)
    # never below the beach line near the sea: no dry hollows under sea level
    v = lerp(prof, h, smoothstep(50.0, 320.0, d))
    return lerp(max(v, prof), v, smoothstep(200.0, 320.0, d))


def raw_height(x, z):
    return coast_shape(x, z, ground_noise(x, z) + mound_raise(x, z) - pond_carve(x, z))


def plateau_height(m):
    return raw_height(*m["pos"])


def base_height(x, z):
    h = raw_height(x, z)
    for m in MOUNDS:
        if "plateau" not in m:
            continue
        c = m["pos"]
        d = math.hypot(x - c[0], z - c[1])
        pr = m["plateau"]
        if d < pr + 18.0:
            h = lerp(plateau_height(m), h, smoothstep(pr, pr + 18.0, d))
    return h


def catmull(p0, p1, p2, p3, t):
    t2, t3 = t * t, t * t * t
    return tuple(0.5 * ((2 * p1[k]) + (-p0[k] + p2[k]) * t + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t2
                        + (-p0[k] + 3 * p1[k] - 3 * p2[k] + p3[k]) * t3) for k in (0, 1))


def sample(ctrl, closed):
    pts = []
    n = len(ctrl)
    segs = n if closed else n - 1
    for i in range(segs):
        p0 = ctrl[(i - 1) % n] if (closed or i > 0) else (2 * ctrl[0][0] - ctrl[1][0], 2 * ctrl[0][1] - ctrl[1][1])
        p1 = ctrl[i]
        p2 = ctrl[(i + 1) % n]
        p3 = ctrl[(i + 2) % n] if (closed or i + 2 < n) else (2 * ctrl[-1][0] - ctrl[-2][0], 2 * ctrl[-1][1] - ctrl[-2][1])
        steps = max(2, round(math.dist(p1, p2) / 2.0))
        for s in range(steps):
            pts.append(catmull(p0, p1, p2, p3, s / steps))
    if not closed:
        pts.append(ctrl[-1])
    return pts


def box3(e, w, closed):
    """Three box blurs of width w (odd): close to a Gaussian, O(n) each.
    Open lines are extended antisymmetrically so values pinned to 0 at the
    ends stay 0."""
    n = len(e)
    r = w // 2
    for _ in range(3):
        if closed:
            ext = e[-r:] + e + e[:r]
        else:
            left = [-e[min(k, n - 1)] for k in range(r, 0, -1)]
            right = [-e[max(n - 1 - k, 0)] for k in range(1, r + 1)]
            # odd reflection about the end samples: e(-k) = 2e(0) - e(k)
            left = [2 * e[0] - e[min(k, n - 1)] for k in range(r, 0, -1)]
            right = [2 * e[-1] - e[max(n - 1 - k, 0)] for k in range(1, r + 1)]
            ext = left + e + right
        acc = [0.0]
        for v in ext:
            acc.append(acc[-1] + v)
        e = [(acc[i + w] - acc[i]) / w for i in range(n)]
    return e


def elevate(pts, closed, smooth_m, pin_s=None, pin_e=None, max_grade=None, hfn=None):
    """Road profile: the ground smoothed along the line, then limited to
    max_grade (cut and fill where the land is steeper), ends pinned."""
    hfn = hfn or base_height
    n = len(pts)
    raw = [hfn(x, z) for x, z in pts]
    if closed:
        return box3(raw, max(3, int(smooth_m / 2.0) | 1), True)
    s0 = pin_s if pin_s is not None else raw[0]
    s1 = pin_e if pin_e is not None else raw[-1]
    w = max(3, int(smooth_m / 2.0) | 1)
    ramp = [lerp(s0, s1, i / (n - 1)) for i in range(n)]
    e = [raw[i] - ramp[i] for i in range(n)]
    e[0] = 0.0
    e[-1] = 0.0
    e = box3(e, w, False)
    h = [ramp[i] + e[i] for i in range(n)]
    if max_grade:
        step = max_grade * 2.0
        for i in range(1, n):
            h[i] = min(max(h[i], h[i - 1] - step), h[i - 1] + step)
        for i in range(n - 2, -1, -1):
            h[i] = min(max(h[i], h[i + 1] - step), h[i + 1] + step)
        # round off the kinks the limiter leaves (keeps the grade limit)
        e = [h[i] - ramp[i] for i in range(n)]
        e = box3(e, 15, False)
        h = [ramp[i] + e[i] for i in range(n)]
    return h


def pin_height(p, r=50.0):
    """Junction height: the mean ground over a disk, so no road has to
    climb to meet a bump the others smooth away."""
    tot, cnt = 0.0, 0
    for dx in range(-int(r), int(r) + 1, 10):
        for dz in range(-int(r), int(r) + 1, 10):
            if dx * dx + dz * dz <= r * r:
                tot += base_height(p[0] + dx, p[1] + dz)
                cnt += 1
    return tot / cnt


def river_line():
    pts = sample(RIVER, False)
    h = elevate(pts, False, 60)
    for i in range(1, len(h)):
        h[i] = min(h[i], h[i - 1])
    return pts, h


def main():
    loop_ctrl = [(BESSI_CENTRE[0] + p[0] * BESSI_SCALE, BESSI_CENTRE[1] + p[1] * BESSI_SCALE) for p in BESSI_LOOP_SHAPE]
    built = {}
    loop_pts = sample(loop_ctrl, True)
    built["bessi_loop"] = (loop_pts, elevate(loop_pts, True, 120), "asphalt", True)
    bh = lambda p: base_height(*p)
    pins = {"j1": pin_height(J1), "j2": pin_height(J2), "j3": pin_height(J3), "pass": pin_height(PASS, 30), "naresh": pin_height(NARESH_HOME)}

    def nearest_on(name, p):
        pts, hs = built[name][0], built[name][1]
        i = min(range(len(pts)), key=lambda k: math.dist(pts[k], p))
        return pts[i], hs[i]

    for name, ctrl, closed, surf, passes, prof in ROADS:
        ctrl = list(ctrl)
        ps = pe = None
        if name == "home_lane":
            pe = pins["j1"]
        elif name in ("valley_road", "ridge_track"):
            ps, pe = pins["j1"], pins["j2"]
        elif name == "pump_house_road":
            ps, pe = pins["j2"], pins["j3"]
        elif name == "ghat_road":
            ps, pe = pins["j3"], pins["pass"]
        elif name == "beach_road":
            ps = pins["pass"]
            jp, jh = nearest_on("bessi_loop", ctrl[-1])
            ctrl.append(jp)
            pe = jh
        elif name == "coast_road":
            jp, jh = nearest_on("bessi_loop", ctrl[0])
            ctrl.insert(0, jp)
            ps, pe = jh, pins["naresh"]
        elif name == "west_road":
            ps = pins["naresh"]
            jp, jh = nearest_on("home_lane", ctrl[-1])
            ctrl.append(jp)
            pe = jh
        elif name == "tower_road":
            jp, jh = nearest_on("west_road", ctrl[0])
            ctrl.insert(0, jp)
            ps = jh
            jp2, jh2 = nearest_on("home_lane", ctrl[-1])
            ctrl.append(jp2)
            pe = jh2
        pts = sample(ctrl, closed)
        hfn = None
        if name == "coast_road":
            # the road runs under Tunnel Hill rather than over it
            tm = MOUNDS[TUNNEL_MOUND]
            hfn = lambda x, z: base_height(x, z) - tm["height"] * (1 - smoothstep(0, tm["radius"], math.hypot(x - tm["pos"][0], z - tm["pos"][1])))
        grade = 0.15 if surf == "gravel" else (prof or 0.10)
        built[name] = (pts, elevate(pts, closed, passes, ps, pe, grade, hfn), surf, closed)

    rpts, rh = river_line()
    print("river: %.0f m, source %.1f m, mouth %.1f m" % (len(rpts) * 2, rh[0], rh[-1]))
    total = 0.0
    problems = []
    for name, (pts, hs, surf, closed) in built.items():
        n = len(pts)
        L = n * 2.0
        total += L
        worst, wi = 0.0, 0
        for i in range(n - 5):
            g = abs(hs[i + 5] - hs[i]) / 10.0
            if g > worst:
                worst, wi = g, i
        low = min(hs)
        dev = [base_height(*pts[i]) - hs[i] for i in range(n)]
        tunnel = sum(2.0 for v in dev if v > 9.0)
        cut = max([v for v in dev if v <= 9.0] + [0.0]) if name == "coast_road" else max(dev)
        fill = -min(dev)
        cross = []
        inside = False
        for i, p in enumerate(pts):
            d = min(math.dist(p, q) for q in rpts[::3])
            if d < 16 and not inside:
                cross.append((round(p[0]), round(p[1])))
            inside = d < 16
        limit = 0.155 if surf == "gravel" else 0.105
        print("%-16s %5.0f m %4.1f min  grade %4.1f%% at (%d,%d)  h %.0f..%.0f  cut %.1f fill %.1f tunnel %.0f  river x%d %s" % (
            name, L, L / 750.0, worst * 100, pts[wi][0], pts[wi][1], min(hs), max(hs), cut, fill, tunnel, len(cross), cross))
        if cut > 12 or fill > 12:
            problems.append("%s cut %.0f / fill %.0f m" % (name, cut, fill))
        if worst > limit:
            problems.append("%s too steep (%.1f%%)" % (name, worst * 100))
        if any(hs[i] < SEA_Y + 0.5 and coast_x(pts[i][1]) - pts[i][0] < 400 for i in range(n)):
            problems.append("%s dips to sea level" % name)
    # gaps between different roads (away from shared ends)
    names = list(built)
    for a in range(len(names)):
        for b in range(a + 1, len(names)):
            pa, pb = built[names[a]][0], built[names[b]][0]
            ends = [pa[0], pa[-1], pb[0], pb[-1]]
            best = (1e9, None)
            for p in pa[::4]:
                if min(math.dist(p, e) for e in ends) < 90:
                    continue
                for q in pb[::4]:
                    if min(math.dist(q, e) for e in ends) < 90:
                        continue
                    d = math.dist(p, q)
                    if d < best[0]:
                        best = (d, p)
            if best[0] < 60:
                problems.append("%s and %s only %.0f m apart near (%d,%d)" % (names[a], names[b], best[0], best[1][0], best[1][1]))
    # the same road folding back on itself (hairpin legs), away from the tips
    for name, (pts, hs, surf, closed) in built.items():
        n = len(pts)
        worst = (1e9, 0, 0)
        for i in range(0, n, 3):
            for j in range(i + 60, n, 3):
                if closed and n - j + i < 60:
                    continue
                d = math.dist(pts[i], pts[j])
                if d < worst[0]:
                    worst = (d, i, j)
        if worst[0] < 45:
            i, j = worst[1], worst[2]
            problems.append("%s legs %.0f m apart (%d,%d) h %.0f/%.0f" % (name, worst[0], pts[i][0], pts[i][1], hs[i], hs[j]))
    for nm, p in PLACES.items():
        print("  %-15s ground %6.1f  coast %5.0f m" % (nm, base_height(*p), coast_x(p[1]) - p[0]))
    print("total road %.1f km" % (total / 1000))
    print("PROBLEMS:" if problems else "no problems")
    for p in problems:
        print("  - " + p)
    import sys
    if "--draw" in sys.argv:
        draw(built, rpts)


def draw(built, rpts):
    S = 0.25
    W = int(EXTENT * S)
    img = Image.new("RGB", (W, W))
    px = img.load()
    for j in range(W):
        for i in range(W):
            x = -EXTENT / 2 + (i + 0.5) / S
            z = -EXTENT / 2 + (j + 0.5) / S
            h = base_height(x, z)
            hr = base_height(x + 4, z)
            hd = base_height(x, z + 4)
            if x > coast_x(z):
                px[i, j] = (120, 170, 205)
                continue
            shade = max(0.0, min(1.0, 0.55 + (h - hr) * 0.12 + (h - hd) * 0.12))
            base = (200, 214, 160) if h > SEA_Y + 3 else (232, 214, 160)
            t = max(0.0, min(1.0, h / 120.0))
            col = tuple(int(lerp(base[k], (150, 140, 110)[k], t) * (0.7 + 0.45 * shade)) for k in range(3))
            if int(h // 10) != int(hr // 10):
                col = tuple(int(c * 0.85) for c in col)
            px[i, j] = col
    d = ImageDraw.Draw(img)
    try:
        f = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 12)
    except OSError:
        f = ImageFont.load_default()
    P = lambda p: ((p[0] + EXTENT / 2) * S, (p[1] + EXTENT / 2) * S)
    d.line([P(p) for p in rpts], fill=(60, 120, 190), width=4)
    for name, (pts, hs, surf, closed) in built.items():
        q = [P(p) for p in pts] + ([P(pts[0])] if closed else [])
        d.line(q, fill=(150, 110, 60) if surf == "gravel" else (50, 50, 55), width=3)
    for nm, p in PLACES.items():
        a, b = P(p)
        d.ellipse([a - 4, b - 4, a + 4, b + 4], fill=(200, 50, 40))
        d.text((a + 6, b - 7), nm, fill=(20, 20, 20), font=f)
    img.save("design/greybox_layout.png")
    print("saved design/greybox_layout.png")


main()
