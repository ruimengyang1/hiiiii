# Can campaign redesign specification

## Current project audit

The project launch scene ran the single-screen **Foundry / Future States** yard,
while `kinetic_prototype.tscn` contained the earlier continuous **System Link**
level selected for replacement. Both use a responsive `CharacterBody2D` player with acceleration, coyote time, jump
buffering, variable jump height, and an airborne downward strike. A persistent
kinetic ram uses idle, telegraph/direction lock, committed charge, collision,
stun, and recovery states. The ram can rebound the player and transfer force
into a deterministic passenger cart. The cart powers a rail, gates progression,
and carries an engineer. Supporting infrastructure includes collision layers,
hazards, procedural particles and sound, pixel UI, camera feedback, quick
rewinds, and automated interaction/route tests.

The original two-stage dexterity platformer remains in `scenes/game.tscn`.
The seven-level Can campaign replaces System Link inside
`scenes/kinetic_prototype.tscn` and becomes the new launch flow. The previous
Foundry iterations remain available as preserved scenes.

## Reused code and presentation

- `player.gd`: movement, buffered/coyote jump, downward strike, rebound,
  damage, and reset behavior.
- `enemy.gd`: the Can's readable telegraph, direction lock, charge, collision,
  stun/recovery, and generic ram-receiver interaction.
- `effects.gd` and `sfx.gd`: impact particles, generated audio, and feedback.
- Existing collision-layer conventions and programmatic gray-box rendering.
- `pixel_ui.gd`: crisp non-antialiased HUD and instruction typography.
- The current fast retry philosophy and deterministic interaction tests.

The cart/engineer campaign logic is removed from the launch flow. Its reusable
lesson—discrete, observable world state—is retained in switches, fans, laser
orientation, sensors, bridges, and per-level reset.

## New core mechanic loop

> Position the player to choose the Can's committed charge, let the Can collide
> with a consistent world property, then use the resulting persistent state to
> traverse or trigger the exit.

The Can remains dangerous, but also functions as bounce target, force source,
heavy switch weight, wedged state resource, and laser-rotator input.

## Level progression

1. **Read the Can** — learn notice, telegraph, locked charge, dodge, and bounce.
2. **Heavy Current** — park the Can on a pressure plate to sustain a large fan,
   then ride its updraft to the exit.
3. **Useful Jam** — guide the Can into a clamp where it stays wedged, holds a
   switch, and remains a fixed bounce point.
4. **Before You Commit** — use the roaming Can for upper access before wedging
   it on the fan switch. Committing it early causes a fast, explained reset.
5. **Angle of Attack** — strike a rotatable emitter support with the Can until
   its beam reaches a sensor and extends a bridge.
6. **Power and Aim** — combine sustained switch/fan state with laser rotation;
   laser-first and fan-first orders are both viable but create different Can
   recovery paths.
7. **System Mastery** — combine bounce, a held switch, fan traversal, laser
   rotation, sensor response, and bridge access without introducing a new rule.

## I Wanna-inspired danger philosophy

Surprises expose stable relationships rather than arbitrary traps. Level 4
challenges “put the Can on a switch immediately”: doing so removes the roaming
bounce resource needed first, and the reset explicitly preserves that lesson.
Level 6 challenges “leave every successful activation alone”: the player must
recognize whether the Can's current held position or its force is the resource
needed next. Hazards are visible, the Can's locked direction is explicit, and
failure returns the player to the current short stage quickly.

## Files to change

- Replace `scripts/kinetic_prototype.gd` with the seven-level campaign manager.
- Add reusable pressure-switch, fan, and laser/sensor mechanism scripts.
- Extend `enemy.gd` only where generic wedging/receiver behavior requires it.
- Extend `sfx.gd` for fan, laser, sensor, and level-complete cues.
- Update `tests/kinetic.gd`, `tests/kinetic_route.gd`, and visual captures for
  the new interactions and complete campaign route.
- Update `README.md`, `CHANGELOG.md`, and design/report documentation.
