# Foundry / Future States

One persistent malfunctioning factory. One objective: **escape**. Manipulate a
predictable charging robot while a Cart, cycling press, weight catwalk and weak
partition keep affecting the same space.

Open in **Godot 4.7** and run `scenes/foundry.tscn`. The entire yard fits one
576×324 view. The green exit is visible from spawn. There are no room resets,
levers, delivery tasks or progress checklist.

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | A/D or arrows | Left stick / D-pad |
| Jump | Space | A / Cross |
| Airborne stomp | J / X | X / Square |
| Rewind whole yard | R | Y / Triangle |
| Fresh run | Shift+R; R after escape | Y after escape |
| Pause | Escape | Start |
| Recall controls | H | — |

Can searches autonomously, locks a red charge direction for 0.55 seconds and
commits at 230 px/s. Descending onto it rebounds automatically; J/X connects
faster. A rebound during a charge preserves its motion. Ordinary stomp causes
only 0.38 seconds of stagger. Environmental contact creates a safe, solid,
heavy shell for 3.4 seconds, shown by green eyes and a shrinking bar.

Cart moves one reversible 100-pixel rail position per impact in about half a
second. A supports the loft; B supplies nearby bridge weight and catches the
press; C gives exit-side height while exposing the press and losing weight.
Ghost roofs show the alternatives. A poor configuration can be reversed.
Grounded Can can supply the same plate weight. The press's top is rideable,
its teeth hurt the worker and ground Can, and it keeps cycling.

Weak material accepts strong force from either direction. Breaking it creates
a permanent low passage; a physical upper bypass is also valid. Escape checks
only arrival on the green exit's landing. Death returns the worker quickly
while preserving world changes. R deliberately restores all starting objects.

[THIRD_REDESIGN_SPEC.md](THIRD_REDESIGN_SPEC.md) describes the short design.
[THIRD_REDESIGN_REPORT.md](THIRD_REDESIGN_REPORT.md) documents three validated
plans, tradeoffs, heuristic reversals, metrics, screenshots and limitations.
Automated expert routes take roughly 6–7 seconds. Human fun, first-time length
and the 5–7 minute target remain unmeasured; there is no forced delay.

Run `scenes/yard_sandbox.tscn` for the same connected space without escape or
instructions. Preserved versions:

- `scenes/foundry_second.tscn`: four-arena redesign, checkpoint `2e1ea7d`.
- `scenes/impact_lab.tscn`: second redesign's isolated core playground.
- `scenes/foundry_legacy.tscn`: first redesign, checkpoint `340aed6`.
- `scenes/kinetic_prototype.tscn`: System Link.
- `scenes/game.tscn`: original Foundry and Relay Shaft.

## Verification

```sh
godot --headless --path . --fixed-fps 60 --script res://tests/third_sandbox.gd
godot --headless --path . --fixed-fps 60 --script res://tests/third_systems.gd
godot --headless --path . --fixed-fps 60 --script res://tests/third_route.gd
godot --headless --path . --fixed-fps 60 --script res://tests/third_route.gd -- --ground
godot --headless --path . --fixed-fps 60 --script res://tests/third_route.gd -- --force
```

Routes use only player inputs after fresh spawn. System and sandbox probes use
explicit fixtures. JSON evidence records completion, charges, impacts, rebounds,
grounding, reversals, resets, deaths, hits, idle and state traces under
`artifacts/third_redesign/`. Tests prove consistent interactions and completion,
not enjoyment.

With graphics, run `tests/capture_third.gd` for ten staged relationship captures.
Run `tests/third_route.gd -- --force --capture` for the actual input-only
signature/fracture/escape captures. Images are in
`artifacts/third_redesign/screenshots/`. Historical tests target preserved
scenes and remain runnable.
