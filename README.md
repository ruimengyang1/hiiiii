# Can / Useful Danger

A focused four-level puzzle-platformer about learning to manipulate one
dangerous autonomous Can. The player gains no abilities; their understanding of
the same readable rules deepens from direction, to force and weight, to timing,
to multi-state planning.

Open the project in Godot and run it. The default launch scene is
`scenes/kinetic_prototype.tscn`; every level fits one 384×216 screen.

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | A/D or arrows | Left stick / D-pad |
| Jump / start | Space | A / Cross |
| Downward strike / bounce | J or X | X / Square |
| Restart current level | R | Y / Triangle |

## Four-level demo

1. **Redirect** — where the player stands determines the Can's locked line.
2. **Weight** — Can force rolls a Boulder onto a button, powering a fan and a
   visible cargo consequence.
3. **Timing** — the laser rotates while the Can occupies its rotator. Reaching
   the sensor grants a visible one-second lock window; bait the Can away during
   that countdown to hold the angle and raise the exit lift.
4. **Combine** — Boulder, button, fan, rotator, sensor, and lift overlap without
   adding a new rule.

The Can follows a stable search → telegraph/lock → straight charge → impact →
short recovery loop. Once locked, it never tracks mid-charge. Buttons read
general heavy mass, the Boulder is movable/heavy/blocking, and beam/sensor
alignment is geometric. Green mechanisms are active; target ghosts show where
moving platforms will finish.

The first-time play target is approximately 4–5 minutes, but this remains a
human-playtest target rather than an automated result.

[FINAL_DEMO_DESIGN.md](FINAL_DEMO_DESIGN.md) records the verified audit and
pre-implementation plan. [FINAL_DEMO_REPORT.md](FINAL_DEMO_REPORT.md) contains
maps, knowledge transfer, reversals, validation, captures, and limitations. The
seven-level predecessor is preserved at local commit `4a70afd` and documented
by the earlier `CAN_LEVEL_REDESIGN_*.md` files.

## Verification

```sh
godot --headless --path . --script res://tests/kinetic.gd
godot --headless --path . --script res://tests/kinetic_route.gd
```

The system suite covers Can intent/lock/non-tracking, impact and rebound,
Boulder force/weight, fan behavior, continuous laser duration, sensor, platform,
and the physical Level 2 chain. The route suite covers four fresh solved states,
anti-skip exits and jump heights, actual R restart, death recovery, and retained
progression. These deterministic checks do not prove fun or first-time timing.

Run `tests/capture_kinetic.gd` with graphics to regenerate the fifteen review
images in `artifacts/final_demo/screenshots/`.

Older prototypes remain available as separate scenes:

- `scenes/foundry.tscn`: persistent factory-yard redesign.
- `scenes/foundry_second.tscn`: four-arena Foundry redesign.
- `scenes/foundry_legacy.tscn`: first connected Foundry redesign.
- `scenes/game.tscn`: original two-stage platformer.
