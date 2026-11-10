R = r"D:\mine\Agentics\T3_Code_Works\MPG_dev"


def patch(rel, pairs):
    P = R + "\\" + rel
    s = open(P, encoding="utf-8", newline="").read()
    nl = "\r\n" if "\r\n" in s else "\n"
    for a, b in pairs:
        a = a.replace("\n", nl); b = b.replace("\n", nl)
        assert s.count(a) == 1, (rel, a[:80])
        s = s.replace(a, b)
    open(P, "w", encoding="utf-8", newline="").write(s)
    print("patched", rel)


# the stall drag measured as almost nothing (32 m vs 36 m of coasting after the
# boil, prove run 2026-11-09 23:31): deleted, not tested
patch(r"FindingNaresh\scripts\vehicle\Camper.gd", [
    ('''	# boiled dry, the dead engine is still in gear: it drags the van to a stop
	# (a jerk and a crawl, not a coast over the pass)
	if boiled_dry and not engine_on and not Plant.on("no_stall_drag"):
		b += STALL_DRAG
''', ''),
    ('''const STALL_DRAG := 18.0           ## brake from a dead engine left in gear
''', ''),
])
# the window-lean plant: at 2.3 m the face measured 0.14 m outside the glass;
# 2.0 m puts it through, which is what the check is for
patch(r"FindingNaresh\scripts\world\Ghat.gd", [
    ('''		lk.x = signf(lk.x) * 2.3''', '''		lk.x = signf(lk.x) * 2.0'''),
])
patch(r"FindingNaresh\scripts\core\Plant.gd", [
    ('''##   no_stall_drag   a boiled engine in gear doesn't drag the van to a stop
''', ''),
    ('''##   lean_close      it leans in at the windows from 2.3 m: its face goes through the glass''',
     '''##   lean_close      it leans in at the windows from 2.0 m: its face goes through the glass'''),
])
patch(r"tools\method\prove_ghat.py", [
    ('''    "stall_hud": ("ghat_heat", "no_stall_drag,hud_heat,one_flat", {"no_stall_drag": ["it comes to rest before the pass, in the fog"],
                                                                     "hud_heat": ["hot with it watching: no TEMP / COOL bars"]}),''',
     '''    "stall_hud": ("ghat_heat", "hud_heat,one_flat", {"hud_heat": ["hot with it watching: no TEMP / COOL bars"]}),'''),
    ('''    "looks": ("ghat_looks", "lean_close,fast_turn", {"lean_close": ["its face stays outside the glass"], "fast_turn": ["it turns away slowly"]}),''',
     '''    "looks": ("ghat_looks", "lean_close,fast_turn", {"lean_close": ["its face stays outside the glass"], "fast_turn": ["it turns away slowly"]}),
    "lean": ("ghat_looks", "lean_close", {"lean_close": ["its face stays outside the glass"]}),'''),
])
