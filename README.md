# Can / Useful Danger

A seven-stage puzzle-platformer about turning a dangerous autonomous Can into
a tool. Read its telegraph, choose where it commits, then use its force or final
position to make the level react.

Open the project in Godot and run it. The launch scene is
`scenes/kinetic_prototype.tscn`; each stage fits one 384×216 screen and restarts
immediately.

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | A/D or arrows | Left stick / D-pad |
| Jump / start | Space | A / Cross |
| Downward strike | J / X | X / Square |
| Reset current stage | R | Y / Triangle |
| Recall current hint | H | — |

## Campaign

1. **Read the Can** — read its locked charge and use it as a bounce target.
2. **Heavy Current** — wedge it on a weight switch to sustain an updraft.
3. **Useful Jam** — make its final, trapped position the traversal tool.
4. **Before You Commit** — use the roaming bounce before spending it on a switch.
5. **Angle of Attack** — rotate a laser into a sensor to extend a bridge.
6. **Power and Aim** — combine a held switch, fan, laser, and sensor.
7. **System Mastery** — chain the full vocabulary without a new rule.

The Can follows a stable search → telegraph → direction lock → charge → collide
→ recover loop. Once locked, it does not track the player. Cyan means wedged,
green mechanisms are active, and the red laser always shows its current path.
Hints describe object properties and can be recalled with H; they do not cover
the live playfield.

[CAN_LEVEL_REDESIGN_SPEC.md](CAN_LEVEL_REDESIGN_SPEC.md) records the audit and
implementation plan. [CAN_LEVEL_REDESIGN_REPORT.md](CAN_LEVEL_REDESIGN_REPORT.md)
summarizes the final design and known limitations.

## Verification

```sh
godot --headless --path . --script res://tests/kinetic.gd
godot --headless --path . --script res://tests/kinetic_route.gd
```

The interaction suite covers direction lock, bounce, wedge/release, switch,
fan, laser, sensor, bridge, and reversal behavior. The route suite constructs
all seven levels from fresh state, checks their completion transitions, and
tests the two later combination chains. These are deterministic system checks,
not a substitute for first-time human playtesting.

Older experiments remain available as separate scenes:

- `scenes/foundry.tscn`: persistent factory-yard redesign.
- `scenes/foundry_second.tscn`: four-arena Foundry redesign.
- `scenes/foundry_legacy.tscn`: first connected Foundry redesign.
- `scenes/game.tscn`: original two-stage platformer.
