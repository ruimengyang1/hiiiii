# Second redesign: play with the malfunction

Backup: the working first redesign is committed at `340aed6`. Its scene and
tests remain runnable as `scenes/foundry_legacy.tscn`; unrelated untracked
blind-playtest artifacts are preserved.

**Boring now:** a 3,600-pixel escort line, eight stops, seven levers, repeated
gates, a full-facility return trip, six-second stomp downtime, and consequences
separated from their causes. Much of the apparent strategy is mandatory order.

**Remove from launch:** escort/delivery objective, eight-stop railway, latching
lever chains, gate corridors, service backtracking, long ordinary stun, verbose
mission HUD. Keep the historical implementation and changelog.

**Preserve:** industrial pixel art, sound generator, movement/coyote/buffer,
direction-locked Can, shared force, reversible Cart, physical weight, Crusher,
fractures, complete local rewind. No new abilities or enemy roster.

**Loop:** bait → evade or rebound → committed impact → immediately exploit.
Tune an objective-free fixture first: ~0.55-second anticipation, brisk charge,
automatic forgiving descending bounce, ~0.4-second ordinary stagger, charge
continuing under a bouncing player, sub-second impact/reuse. Only environmental
impacts ground the Can (3.4 seconds). Grounded Can is solid, safe and heavy;
ordinary bounce never supplies heavy weight. Feedback ships with the loop.

**Four connected, screen-sized maintenance bays:**

1. **Sparks:** play with Can; smash one visible weak partition and follow it.
2. **Crossroads:** three-stop Cart; A supplies a high launch, B extends a nearby
   weight bridge, C supplies a forward step. High and low routes are visible.
3. **Press:** same Cart/bridge plus one Crusher. Keep force available or ground
   Can on the plate; grounded shell also supplies safe footing. Cart under the
   press physically shields the bot, changing the available conversion.
4. **Freeform:** reach the clearly visible exit beyond one weak partition.
   Cart starts forward, off its plate. Reverse for durable bridge, use Crusher
   weight and Cart height, or retain forward roof/shield and launch across.
   No levers and no new rule. Keep other valid physical solutions.

Each bay fits the original 384×216 viewport; short freight-door transitions
bring the same actors into the next local workshop, without escort walking.
Progress and mutations survive local rewind through full entry snapshots.
First-time 6–8 minutes is a target to measure with humans, not a forced timer.

**Depth:** force versus safe weight; roof versus bridge versus hazard shielding;
which side Can ends on; permanent fractures versus temporary support. A move
changes nearby collision and visible mechanics immediately. Poor configurations
recover by opposite-side charge or local R. Expert skill saves state changes,
not pixel-perfect execution. Document benefit/cost/recovery in the report.

**Evidence gate:** core physics/feel probes before strategic construction;
system tests A–K, at least two input-only fresh completions, metrics (time,
charges, impacts, rebounds, grounding, reversals, resets and idle), four rendered
room captures. Automated responsiveness cannot establish subjective human fun.
