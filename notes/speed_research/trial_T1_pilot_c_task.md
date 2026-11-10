# Stage 3, pilot P1c (draw only at screenshot moments), Claude-run. Written by the referee.

Same READ FIRST / DO NOT READ lists and rules as trial_T1_pilot_task.md (read it first), then
MPG_speed_t1\notes\speed_research\pilot_P1b.md. Work only in D:\mine\Agentics\T3_Code_Works\MPG_speed_t1.
Budget: <= 3 game minutes. Watch every run. Game code untouched (test code / tools only).
1. A windowed fast run (fixed-fps 60, no cap) where drawing is switched off between screenshots and on
   for the frames a shot needs (Godot: e.g. RenderingServer.render_loop_enabled, or the viewport's
   update mode UPDATE_DISABLED / UPDATE_ONCE; find what works in 4.7.1, say which), on ghat_heat
   (same speed_probe measure): the ratio, same checks, and are the shots correct (look at them: same
   framing and content as the 1x shots, not black or stale)?
2. If it works, one ghat_net run the same way (its 3 pixel checks must give the same verdicts as at 1x).
WRITE MPG_speed_t1\notes\speed_research\pilot_P1c.md (ratios, shots compared side by side, verdict).
Commit locally on speed-t1. Reply with a 6-line summary.
