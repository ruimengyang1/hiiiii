# Final four-level demo design

## Verified current state

The launch scene is `kinetic_prototype.tscn`, a programmatic seven-stage Can
campaign. The actual launch script currently uses the shared `player.gd`
controller, the `enemy.gd` systemic Can, generated effects/audio, pixel UI,
proximity-based Can wedging, a binary pressure switch/fan, and a three-angle
impact-stepped laser. Its route tests set solved state directly; they establish
deterministic state transitions, not input-only human routes.

The player controller already supplies responsive acceleration, air control,
0.11-second coyote time, 0.12-second jump buffering, variable jump height, a
generous downward-strike query, damage recovery, and rebound support. The Can
already has the desired search → 0.52-second telegraph/direction lock → straight
charge → collision → short recovery loop. Direction is selected once at the
start of telegraph and is not updated during the charge.

The preserved second and third redesigns contain reusable physical conventions:
generic force receivers, deterministic rail motion, weight rectangles/mass,
moving solid platforms, impact feedback, snapshots, and fast failure recovery.
They also confirm that the old Cart escort, Crushers, giant yard, NPC objective,
multi-stop route, and verbose state HUD are not needed in this focused demo.

The seven-level build is preserved locally at commit `4a70afd` before this pass.
No remote operation is part of this work.

## Reuse and removal

Reuse:

- `player.gd`: movement, coyote/buffer, air strike, damage, and rebound.
- `enemy.gd`: readable locked-direction Can and generic force-receiver scan.
- `effects.gd`, `sfx.gd`, and `pixel_ui.gd`: feedback and crisp presentation.
- Existing world collision layers and programmatic single-screen construction.
- Generic weight, rail, and platform ideas from preserved Foundry code.

Remove from the main flow:

- Seven-stage cards, wedging tutorial sequence, discrete click-to-rotate laser,
  power-latch puzzle, rank/plan-quality scoring, and verbose status readout.
- Cart, engineer, Crusher, gates, escort goals, old Foundry yard, and legacy HUD.
  These stay available in their preserved scenes and history.

## Exact progression

### 1 — Redirect (45–60 seconds)

The first safe charge hits a wall and demonstrates commitment. The room then
presents a broad force-reactive slide block in front of a visibly closed exit.
Standing beyond the block aims the Can through it; one useful impact slides the
block aside. A second short lane asks the player to reproduce the positioning
idea before physically reaching the exit.

- Old knowledge required: movement and jumping only.
- New variable: player position determines locked Can direction.
- Heuristic: **Stand where you want the Can to charge.**
- Expected novice: dodges reactively, watches one harmless wall impact, then
  experiments with standing beyond the highlighted target.
- Expected expert: stages the first useful rightward charge immediately and
  clears with minimal waiting.
- Reused later: every Boulder, rotator, and final-state setup.

### 2 — Weight (60–75 seconds)

The player reuses charge positioning to drive the Can through a broad Boulder.
The Boulder rolls deterministically into a forgiving weight button, stays
there, and immediately powers a fan. The same button also starts one clearly
visible hanging cargo platform crossing the fan column. The novice's reasonable
immediate ascent can collide with it; observing its one deterministic transit
reveals the safe moment. The high exit cannot be reached by a normal jump.

- Old knowledge required: Level 1 charge-direction control.
- New variables: force changes Boulder position; heavy position persists as
  world state; one activation can have more than one visible consequence.
- Heuristics: **Think about where the object will finish** and **held weight
  keeps the connected world active.**
- First I Wanna reversal: Fan ON also starts the wired cargo crossing. The
  causal wire, moving object, and stable replay make the second attempt smarter.
- Expected novice: solves Can → Boulder → button, commits to airflow early,
  then waits for the visible crossing on retry.
- Expected expert: predicts the generous stop zone and times the fan entry
  during the same activation without precision placement.
- Reused later: Boulder weight, persistent button/fan state, multi-consequence
  planning, and moving mechanisms.

### 3 — Timing (75–90 seconds)

The player immediately uses Level 1 positioning to guide the Can onto a broad
laser rotator. While the Can occupies it, the beam turns clockwise at a steady
visible rate. When the beam reaches the sensor it pauses for one second: the
sensor turns gold, a bar and numeric timer count down, and the HUD says to bait
the Can away. If the Can leaves during that window, the angle freezes and
continuous sensor contact holds a fast vertical platform at the useful height.
If the Can remains, the beam resumes rotating and the lift retracts.

- Old knowledge required: choose charge side; understand persistent physical
  state from Level 2.
- New variable: duration, expressed as a visible action window.
- Heuristic: **Where the Can stays, and for how long, determines world state.**
- Expected novice: sees the lock and reacts during the generous countdown; if
  they wait, the explicit release message explains why the beam continues.
- Expected expert: positions early and removes the Can near the start of the
  lock, freezing alignment in one cycle.
- Reused later: continuous rotator timing and sensor-controlled platform.

### 4 — Combine (90–120 seconds)

The opening combines the familiar Can, Boulder, weight button, and fan. The
straight novice sequence works: move Boulder to weight, ride the fan, then use
the familiar rotator and sensor to raise the final platform. The geometry also
supports a rebound during the Boulder charge and leaves the Can near the next
setup, rewarding compound play. The Boulder temporarily blocks part of the
laser line before it reaches the button, demonstrating MOVABLE + HEAVY +
BLOCKING without a puzzle flag.

The rotator sits on the final lift. A late bait leaves the Can on that lift when
the beam reaches the sensor, so the platform visibly carries it into the upper
player lane and its next locked charge becomes an immediate threat. Preparing
the Can's departure before alignment avoids the threat. The exit is a visible
physical doorway reached only from the raised final structure.

- Old knowledge required: all Level 1–3 relationships.
- New variable: none; only overlapping consequences and opportunity cost.
- Final heuristic: **Ask what state the action creates, not only what it solves.**
- Second I Wanna reversal: laser → sensor → lift also changes Can position and
  charge access. The platform physically carries the Can; no spawn or rule
  change occurs.
- Expected novice: performs Boulder/fan and laser/platform sequentially, then
  learns to prepare for the lifted Can.
- Expected expert: rebounds during the useful charge, predicts Boulder and Can
  endpoints, begins the laser bait early, and keeps the Can off the rising lift.

## Scope and feel targets

Only Player, Can, Boulder, weight button, fan, continuous laser/rotator, sensor,
deterministic moving platforms, ordinary geometry, and the two visible moving
dangers are present. No new ability, enemy, inventory, key, or switch category
is introduced. Level completion always requires reaching a visible exit through
state-dependent collision geometry; normal jump height is audited against every
critical ledge.

Transitions use roughly 0.75 seconds of success feedback and a brief nonblocking
level title. Death restarts only the current room in under one second. Expected
first-time total is 4–5 minutes based on the decision budget above; this remains
a human-playtest target rather than an automated claim.
