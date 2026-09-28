# Foundry / Future States

A continuous systemic platformer built from Clockwork Ascent. One malfunctioning
maintenance Can, one engineer's transport, and a small set of industrial rules
turn intent into force, lasting state, and future options.

Run the project in **Godot 4.7**. The launch scene is `scenes/foundry.tscn`.
Deliver the engineer and restore evacuation power. The first-run design target
is 10–15 minutes; independent human timing is still needed. Two input-only
expert routes complete in approximately 3:12 and 3:18.

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | A/D or arrows | Left stick / D-pad |
| Jump | Space | A / Cross |
| Airborne stomp | J / X | X / Square |
| Rewind current encounter | R | Y / Triangle |
| Fresh run | Shift + R; R after completion | Y after completion |
| Pause / resume | Escape | Start |
| Recall property hint | H | — |

A red arrow announces a locked charge. The Can searches with lowered forks and
magnetic suspension; a stomp or press impact grounds it for six seconds. Its
stunned shell is safe, rebounds the player, and loads heavy plates. Cart wheels
load the same plates. The roof also rebounds the player, so moving transport
can remove useful access. Levers latch circuits without returning a bounce.

Broken bulkheads, transport position, actor state, and circuit changes persist.
R restores the complete local encounter snapshot. Death does the same after
0.4 seconds. Safe upper perches give thinking space while the Can searches.

[DESIGN_SPEC.md](DESIGN_SPEC.md) contains the pre-implementation audit, five
rules, encounter consequences, interaction matrix, and implementation
refinements. [REDESIGN_REPORT.md](REDESIGN_REPORT.md) contains the final audit,
learning curve, inspirations, novice/expert walkthroughs, test evidence,
alternative strategies, changed files, and remaining problems.

The earlier experiences remain runnable:

- `scenes/kinetic_prototype.tscn`: prior System Link passenger-cart prototype.
- `scenes/game.tscn`: original Foundry and Relay Shaft levels, including dash.

`GAME_PLAN.md`, `KINETIC_LEVEL_DESIGN.md`, `SYSTEMIC_LEVEL_DESIGN.md`, and
`CHARACTERISTICS_ALIGNMENT.md` describe those historical iterations.

## Verification

Run from this directory, using your Godot executable:

```sh
godot --headless --path . --fixed-fps 60 --script res://tests/foundry_depth.gd
godot --headless --path . --fixed-fps 60 --script res://tests/foundry_rules.gd
godot --headless --path . --fixed-fps 60 --script res://tests/foundry_route.gd
godot --headless --path . --fixed-fps 60 --script res://tests/foundry_route.gd -- --weight
```

The route checks start fresh and use only player inputs: no teleports, cart
station setters, scripted impacts, switch activation calls, or progression
flag writes. Depth/rule checks use deliberate fixtures to probe failures and
recovery. Headless checks suppress audio playback because accelerated physics
does not advance the real-time audio mixer; normal graphical play retains all
existing generated sounds.

The preserved regression checks are `smoke.gd`, `route.gd`, `interactions.gd`,
`rebound.gd`, `dash.gd`, `kinetic.gd`, and `kinetic_route.gd` in `tests/`.

With a graphics display, run `tests/capture_foundry.gd` to refresh the seven
fixture screenshots in `artifacts/screenshots/`. Those are visual inspections,
not substitutes for the fresh input-only routes.
