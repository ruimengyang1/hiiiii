# Foundry / Future States

A compact action-platformer about playing with a malfunctioning charging robot:
**bait → evade / bounce → impact → exploit**. Four maintenance bays replace the
old escort route. No levers, gate sequence, or long return trip.

Open in **Godot 4.7** and run `scenes/foundry.tscn`. Reach each bay’s green door,
then the final exit. Can still wants to attack you.

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | A/D or arrows | Left stick / D-pad |
| Jump | Space | A / Cross |
| Airborne stomp | J / X | X / Square |
| Rewind current bay | R | Y / Triangle |
| Fresh run | Shift+R; R after completion | Y after completion |
| Pause | Escape | Start |
| Recall controls | H | — |

Descending onto Can automatically rebounds. J/X connects faster. Ordinary
contact gives a short 0.38-second stagger; during a committed charge the robot
keeps charging beneath your rebound. The red arrow locks direction during
0.55-second anticipation. Can cannot turn after commitment.

Environmental impacts create the green grounded shell: safe, solid and heavy
for 3.4 seconds. Plates accept grounded Can or Cart. Ordinary stomp cannot
supply weight. A shrinking bar shows the shell’s remaining state.

Cart moves one reversible 80-pixel position per impact in 0.4 seconds. Its three
positions supply high roof access, bridge weight / press shielding, and forward
roof access. Ghost roofs and rail symbols show them. The plate is wired to a
nearby telescoping bridge. Orange weak partitions break permanently from charge
force; valid upper bypasses also work.

The final exit needs a real supported landing. Always pushing Cart right does
not solve it. Complete input-only routes validate durable Cart support and
Can’s temporary environmental weight while Cart stays forward.

[SECOND_REDESIGN_SPEC.md](SECOND_REDESIGN_SPEC.md) contains the short design.
[SECOND_REDESIGN_REPORT.md](SECOND_REDESIGN_REPORT.md) contains walkthroughs,
tradeoffs, tests, screenshots and limitations. Human enjoyment and the 6–8 minute
first-run target are unmeasured. Automated routes finish in 16–18 seconds;
there is no extra walking or timer to manufacture the intended duration.

Run `scenes/impact_lab.tscn` for the objective-free core playground. Preserved:

- `scenes/foundry_legacy.tscn`: first redesign, backed up at `340aed6`.
- `scenes/kinetic_prototype.tscn`: System Link passenger-Cart prototype.
- `scenes/game.tscn`: original Foundry and Relay Shaft.

## Verification

```sh
godot --headless --path . --fixed-fps 60 --script res://tests/second_core.gd
godot --headless --path . --fixed-fps 60 --script res://tests/second_systems.gd
godot --headless --path . --fixed-fps 60 --script res://tests/second_route.gd
godot --headless --path . --fixed-fps 60 --script res://tests/second_route.gd -- --can
godot --headless --path . --fixed-fps 60 --script res://tests/second_route.gd -- --high --can
```

Routes use only player inputs after fresh spawn. Core/system checks use explicit
fixtures. Successful routes write time, charges, impacts, rebounds, grounding,
reversals, resets, idle and room states to `artifacts/second_redesign/route_*.json`.
Headless audio is suppressed; graphical play retains generated sounds.

With graphics, run `tests/capture_second.gd` to regenerate six staged native
captures in `artifacts/second_redesign/screenshots/`. Historical tests continue
to target their preserved scenes. Captures are separate from completion evidence.
