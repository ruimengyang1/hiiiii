# Third redesign: one malfunctioning yard

Backup: the complete second redesign is committed at `2e1ea7d`. Preserve its
scripts and provide `scenes/foundry_second.tscn`; historical tests use that scene.
Unrelated blind-playtest artifacts stay untouched.

**Why it still felt authored:** four reset workshops, room labels and next-bay
doors separated causes from later consequences. Safe upper bypasses became a
repeatable recipe. The same actor instances existed, but their history did not.

**Replace with:** one persistent Player, Can, three-position Cart, cycling
Crusher, weight-operated catwalk and weak exit partition. No room transitions,
progress flags, levers or checklist. One goal: escape. Keep the fast charge /
rebound / impact code, air control, industrial art and full local recovery.

**Topology (world roughly 576 px wide):**

```text
              loft         weight catwalk       high approach
             /    \___________/   \________________/    \
START --- Can ---- A ---- B / PRESS ---- C ---- weak wall -- EXIT
                       \__maintenance well__/      \__low steps_/
```

All systems coexist from spawn. A supplies the loft, B supplies lasting catwalk
support and catches the press, C supplies forward height but exposes the press.
Can's magnetic service lane crosses the shallow well. The player can recover
below a lost catwalk and reconnect locally. Breaking the weak partition opens
the shared low lane for worker and Can, rather than setting a completion flag.

**Fun hypothesis:** an incoming charge can rebound the worker, relocate Can,
move Cart, remove support and expose the press in one chain. A safe roof can
become a route to deliberate baiting. Build the objective-free version first;
probe and capture chains before enabling escape. Tests establish consistency,
not voluntary experimentation or human enjoyment.

**Danger:** readable charge/press contact; misplaced roof and lost support;
the reasonable heuristics “forward is progress” and “safer Can is better” fail
in visible, recoverable ways. No surprise spikes or invisible instant kills.
Ordinary stomp remains short; only environment creates safe heavy Can.

**Failure teaches:** losing support drops into a short recovery path; a
grounded Can cannot supply immediate force; roof position also changes shielding.
Death quickly returns the player while preserving physical discoveries. R
rewinds the whole starting configuration; Shift+R starts a fresh run.

**Expression to discover, not prescribe:** preserve height for upper escape;
trade force for temporary catwalk support; keep Can active for a force passage.
Encode input-only examples only after inspecting the constructed sandbox.
Novices handle consequences separately; experts combine them and need fewer
state changes. First-time 5–7 minutes and a 60–90-second mastery payoff remain
human timing targets, never forced timers or filler.
