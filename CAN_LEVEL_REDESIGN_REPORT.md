# Can campaign implementation report

## Final progression

1. **Read the Can** isolates telegraph, locked direction, dodge, and bounce.
2. **Heavy Current** introduces weight: a wedged Can holds a switch, which keeps
   a large fan active so the player can ride its updraft.
3. **Useful Jam** teaches that the Can's resting state can be more useful than
   another charge: the clamp holds it as both weight and fixed bounce point.
4. **Before You Commit** asks the player to use the roaming Can to strike the
   upper preparation latch before spending it on the switch.
5. **Angle of Attack** generalizes force: a charge rotates an emitter, the beam
   reaches a sensor, and the sensor extends a bridge over visible spikes.
6. **Power and Aim** recombines the held switch/fan and laser/sensor loops. The
   mechanisms can be approached in either order, though clean Can placement is
   faster and safer.
7. **System Mastery** chains switch, fan, upper power latch, laser rotation,
   sensor, bridge, and final traversal without introducing a new object.

## Fair expectation reversals

- Level 4 challenges “pressing the obvious switch immediately is progress.”
  Early commitment consumes the only roaming bounce/force resource. The game
  names the missed preparation step and resets the compact room quickly.
- Level 7 challenges “the familiar laser should rotate immediately.” The first
  unpowered impact is rejected with visible/audio feedback; the stable rule is
  that the fan route must power the rig before Can force can aim it.

Both surprises expose deterministic dependencies and make the second attempt
more informed; neither relies on an invisible or random trap.

## Reused and added systems

Reused: player movement, coyote time, jump buffering, downward strike, Can
search/telegraph/locked charge, bounce and impact dispatch, collision layers,
procedural effects/audio, pixel UI, and rapid reset infrastructure.

Added: reusable Can pressure switch, animated fan/updraft, force-rotated laser
rig and geometric sensor evaluation, sensor-driven bridge, persistent Can wedge
state with strike release, campaign cards, compact per-level state, contextual
hints, and seven-stage progression.

## Core causal loops

**Switch/fan:** bait the Can into the marked clamp → proximity captures it in a
wedged state → its weight depresses the switch → the switch powers the fan →
the active airflow applies consistent upward lift → the player reaches the high
route. Releasing the Can releases the switch and turns the fan off.

**Laser/sensor:** bait a committed Can charge into the labeled emitter support
→ sufficient impact advances one of three fixed orientations → the visible beam
is geometrically tested against the sensor → alignment lights the sensor and
extends a solid bridge → the player crosses. An unarmed rig rejects rotation,
making its power dependency explicit.

## Escalation and validation

Difficulty moves from reading one actor, to using weight, to valuing persistent
state, to sequencing, then to indirect orientation and finally recombination.
All seven rooms are compact and use the same visual/state vocabulary.

Automated checks cover the ten requested areas: direction lock, player bounce,
switch holding, fan state/lift, force-driven laser rotation, beam/sensor
response, deterministic bridge creation, useful wedging, fresh construction and
completion of every level, and later multi-system combinations.

## Remaining weaknesses

- Automated routes validate state transitions rather than human execution or
  first-time comprehension; external playtesting is still needed for tuning.
- Levels use deliberate gray-box geometry and generated sound rather than final
  authored art/audio.
- The campaign stores no between-session level-select progress; the current
  scope favors a short continuous run and fast local retry.
- Level 6 permits either action order by design, but real players may still
  discover one order much more readily.

## Files changed

- `project.godot`, `README.md`, `CHANGELOG.md`
- `CAN_LEVEL_REDESIGN_SPEC.md`, `CAN_LEVEL_REDESIGN_REPORT.md`
- `scripts/kinetic_prototype.gd`, `scripts/enemy.gd`, `scripts/sfx.gd`
- `scripts/can_pressure_switch.gd`, `scripts/can_fan.gd`,
  `scripts/can_laser_rig.gd`
- `tests/kinetic.gd`, `tests/kinetic_route.gd`, `tests/capture_kinetic.gd`
