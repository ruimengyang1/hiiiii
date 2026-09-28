# Clockwork Ascent: System Link

The project launches **System Link**, a continuous real-time puzzle-platformer
built from the original Clockwork Ascent movement, rebound, enemy, cart,
effects, and audio systems.

A clockwork ram pursues the player, but its charge direction locks after a
clear windup. The player uses position to aim that charge, downward-strikes the
ram for height, and sends it into a five-stop passenger cart. The cart carries
an NPC and also acts as a platform, circuit weight, and progression key. A live
rail, a visible danger bay, an elevated safety cut-off, and a ram-only final
lock turn object position and interaction order into the main resources.

The original two-level dexterity game remains available in
`scenes/game.tscn`. The redesigned systemic experience is the launch scene in
`scenes/kinetic_prototype.tscn`.

## Play

Open the project in Godot 4.7 and run it, or run `godot --path .`.

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Move | A/D or arrow keys | Left stick or D-pad |
| Jump | Space | A / Cross |
| Downward strike | J or X, in midair | X / Square |
| Recall current hint | H | — |
| Rewind to stable dock | R | Y / Triangle |

The intended learning path is: avoid the ram, bounce from it, notice that its
locked charge moves the cart, then plan where the ram and cart must be after
each use. Pushing right at every opportunity fails at the live danger bay; the
cart must first be staged as a platform so the player can reach its cut-off.

On launch, a rescue briefing names the engineer, destination, and indirect
control chain. During play, the top panel keeps the mission and factory states
visible while the lower panel teaches only the currently relevant action.
Large red charge arrows show the ram's committed direction; gold wiring shows
which cart stop powers the live rail; red machinery is unsafe or locked and
green machinery is ready. The first accidental ram contact is recoverable so
the overhead-strike lesson can be learned without an immediate restart.

See [SYSTEMIC_LEVEL_DESIGN.md](SYSTEMIC_LEVEL_DESIGN.md) for the audit,
interaction matrix, five-beat structure, and intended route. Historical design
work is preserved in [GAME_PLAN.md](GAME_PLAN.md) and
[KINETIC_LEVEL_DESIGN.md](KINETIC_LEVEL_DESIGN.md).

[CHARACTERISTICS_ALIGNMENT.md](CHARACTERISTICS_ALIGNMENT.md) maps the prototype
to the course framework: deterministic versus stochastic play, observability,
real-time granularity, play length, system types, player structure, heuristics,
depth versus entropy, and strategy versus dexterity. The completion screen's
Plan Quality rating rewards fewer unsafe actions and rewinds without penalizing
time spent thinking.

## Checks

Run the integration checks from this directory:

```sh
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/route.gd
godot --headless --path . --script res://tests/interactions.gd
godot --headless --path . --script res://tests/rebound.gd
godot --headless --path . --script res://tests/dash.gd
godot --headless --path . --script res://tests/kinetic.gd
godot --headless --path . --script res://tests/kinetic_route.gd
```

The first five checks protect the preserved original game. The two kinetic
checks cover System Link's shared rules, safety gates, checkpoint restore, and
complete state route. Optional capture scripts save screenshots to the system
temporary folder when a graphics display is available.
