# Third redesign: the malfunctioning yard

Implemented in `scenes/foundry.tscn`. One persistent space and one physical
escape destination replace the four reset workshops. Three different
fresh-spawn, input-only escape plans pass. This establishes systemic
possibilities, **not human fun, learning or a 5–7 minute first-time duration**.

## 1. Why the four-arena version still felt authored

Each door rebuilt the machinery and rehomed the actors. Consequences stopped at
the workshop boundary. Room names and separate Cart, press and mastery setups
encouraged solving one exercise and moving on. Safe upper bypasses became a
repeatable procedure. The faster underlying interaction was useful, but the
world's history was disposable.

The existing second build was already committed at `2e1ea7d`. Its scripts remain
unchanged; `scenes/foundry_second.tscn` and its redirected tests preserve it.
The unrelated `artifacts/blind_playtest/` material was not used or edited.

## 2. What was removed

Removed from launch: four-bay layout, freight doors, transitions, room titles,
per-bay actor respawns and snapshots, intermediate objectives, and explanatory
room HUD. There are zero switches, levers or gate mechanisms in the yard.
There is no engineer delivery or return trip. The second version already
removed eight docks and long stomp downtime; this redesign keeps those removals.

Death now returns only the worker after approximately 0.3 seconds. Cart, Can,
fractures and press phase persist. Deliberate R rewinds the whole yard; Shift+R
also clears run metrics. No solved-room traversal is required for recovery.

## 3. New interconnected map

```text
  loft at 174                 exit approach at 180       far ledge
  [===========]                  [======]     |weak|     [======]
          \     weight catwalk at 218          |wall|          \ EXIT
           \  [======================]        |    |       [landing]
                  | PRESS                     |    |   [low step]
START--Can----A----B/plate------C---------------|    |------------
                  \__maintenance well__/      |____|
                   steps reconnect both sides

rail:         160     260      360                  width: 576 px
```

All relevant systems fit a 576×324 camera. The shallow lower well provides
recoverable falling space and steps back onto the central rail deck. The upper
path crosses the same press, support and partition seen at ground level. It is
not another tutorial room. Can runs on the visibly drawn magnetic service lane.

| Cart configuration | Immediate utility | Cost / conflict |
|---|---|---|
| A | loft launch and starting height | no plate weight; press exposed |
| B | durable catwalk weight; catches press above Can; central launch | loft launch moved away; safe press cannot ground Can below it |
| C | forward launch toward exit approach | loses weight and shielding; incoming force is intercepted at the right rail stop |

Opposite-side charges reverse positions. Searching Can can pass under the
raised chassis; charging Can strikes its force forks. At a rail limit the Cart
still catches force: staying behind it is not equivalent to breaking the wall.

## 4. Core loop

Observe → bait → locked direction → evade or rebound → continuing charge →
impact → exploit the resulting configuration. The next action depends on
where Can, Cart, worker and press actually ended up.

Retained tuning: 0.55-second anticipation, 230 px/s charge, 1.15-second maximum
charge, 0.38-second ordinary stagger, 0.20-second collision recovery and
3.4-second environmental grounding. Cart's 100-pixel step takes about 0.5
seconds. Its roof launches at −365; Can launches at −305. Air control is 1700,
with inherited coyote time, jump buffer and generous descending rebound.

## 5. Moment-to-moment fun

The objective-free `yard_sandbox.tscn` was built and inspected before launch
escape was enabled. A real descending player rebound during a committed charge
was observed together with Cart movement, roof relocation and shielding loss.
Temporary bridge loss dropped the worker into recoverable space. The exposed
press then grounded Can and restored support through weight. That chain was
kept when it contradicted the probe's initial expectation of a closed bridge.

Feedback occurs during these actions: anticipation arrow and sound, red charge
lane, rebound launch and brief hit pause, impact particles/shake, fast Cart
travel, green grounded shell and timer. Hurt protection now pulses an outline
instead of hiding the worker during a chain. Existing industrial art and sound
generation were reused; no cutscenes or dialogue were added.

These are reasons the interaction might encourage experimentation. No human
has yet demonstrated voluntary two-minute play or enjoyment. Passing probes
cannot establish that the fun hypothesis succeeded.

## 6. Spelunky principle: overlapping simple systems

One charge can change worker height, Can position, Cart position, catwalk
support and press exposure. Grounding can then change Can's mass and restore
the same catwalk. These are shared force, collision and weight rules, not an
event that says “finish this room.” The same machinery remains present.

## 7. Into the Breach principle: visible intent, conflicting consequences

The red arrow and dashed lane commit in one direction. The player can see a
roof they might lose, weight they might gain, the press that might become
exposed, and the exit approach. Cart B creates safety and support while also
preventing environmental grounding beneath the press. That conflict matters
before the incoming charge, rather than forty seconds later.

## 8. Hitman principle: stable actor, many manipulations

Can retains search → locked telegraph → fixed charge → collision → short
recovery. Ground-level detection is within 310 horizontal pixels and 25
vertical pixels, excluding the immediate 24-pixel dead zone. Normal search
moves at 92 px/s; when the worker is directly above it, Can continues a 72 px/s
lane sweep instead of parking like an unused player ability.

Position, height and the side occupied by the worker manipulate this actor.
There is no activation button, escalating AI or room-specific behavior. Upper
perches do suppress charges: they are genuine safety, although the press
continues cycling and Can keeps searching below.

## 9. BOTW principle: generic properties

Force receivers expose an impact rectangle and accept signed momentum. Cart
moves one deterministic step; weak material breaks at force 80 or higher in either
direction. Weight mechanisms inspect overlap and mass: Cart supplies 3,
grounded Can 2, active/staggered Can 0. Solids supply platforms and blockers.
The press's actual tooth region affects both worker and Can; Cart catches its
descent. Breaking material continues Can momentum.

The exit requires only physical arrival on its landing. No wall-broken,
Cart-index, grounding, switch or delivery flag overrides visible geometry.
The implementation deliberately remains a small deterministic system, not a
general physics simulator.

## 10. I Wanna principle: failure refines the model

Expectation reversals use existing geometry and visible reactions. They do not
spawn spikes or punish an invisible flag. A closed catwalk, green weight state,
stopped charge or moved roof communicates the incomplete assumption. A failed
plan can continue in the same yard.

## 11. Danger and difficulty audit

| Difficult situation | Physical | Systemic | Cognitive |
|---|---|---|---|
| Incoming committed charge | dodge / rebound | choose resulting Can side | a locked attack can be useful |
| Cart leaves B | avoid newly exposed press | lose weight and shielding together | forward is not unconditional progress |
| Can is grounded | safe shell / foothold | temporary support replaces force | safe is not always the resource needed |
| Charge hits Cart at C | visible recoil | force fails to reach wall | forward Cart can obstruct a force plan |
| Upper bypass | broad running jumps | support must exist long enough | breaking material is optional |

Contact damage is readable and recoverable. Three hits or leaving the bottom
cost a short worker respawn, not the world history. Losing support normally
lands in the shallow well. The strongest intended difficulty is predicting
configuration changes. Whether humans find those changes memorable remains
unmeasured.

## 12. Implemented heuristic reversals

| Initial heuristic | Why reasonable | Challenging situation | Failure | Revealed rule | Different second attempt |
|---|---|---|---|---|---|
| Move Cart toward exit | exit is visibly right | push B→C before using support | bridge retracts; press exposed | Cart carries roof, weight and shielding together | preserve B, cross during release grace, or deliberately replace weight with Can |
| Ground Can whenever possible | green Can is safe | arrive at low partition while Can is grounded | no immediate force to fracture it | safety spends mobile force | preserve active Can or use the already supported upper route |
| Crusher is only bad | visible teeth hurt worker | support unavailable with Cart A/C | avoiding machine leaves catwalk absent | teeth transform Can into weight; machine top is rideable | ride/avoid teeth while arranging Can beneath it |
| A forward Cart helps every plan | C gives exit-side height | bait ground-level charge from behind C | Cart catches the charge instead of wall | solid force interception still applies at rail limit | reverse Cart, bring searching Can past it from a perch, or use C's roof |

The B→C loss/restoration is recorded in the sandbox samples. Grounding and
active-force alternatives are recorded in full routes. Opposite impacts and
world-preserving recovery are fixture-tested. These are implemented reversal
opportunities; actual novice surprise and improved second attempts have not
been human-playtested. Staying far away was not turned into a separate trap.

## 13. Player expression and tradeoffs

Three recognizable approaches are validated: upper support rush, press/weight
traversal and active-force low passage. They make different configurations and
do not require a route-selection switch.

| Action | Benefit | Cost | Recovery | Expert advantage |
|---|---|---|---|---|
| Preserve A | reuse loft/press approach | no durable bridge | ground Can or later move Cart | escape without transporting Cart |
| Push into B | bridge plus shielding | moves starting launch; denies press grounding | opposite-side force | stop unnecessary pushes and keep useful support |
| Push B→C | forward roof, exposes useful press | support loss and new hazard | reverse or substitute Can weight | combine launch with the temporary support window |
| Ground Can on plate | safe support and bridge | force unavailable for 3.4 seconds | traverse upper route; exploit subsequent wake-up | spend grounding only when its position helps |
| Retain active Can | rapid fracture / movement force | continuing physical threat | evade or use press if safety becomes valuable | rebound and fracture in one charge |

Preserving B is physically supported and tested as a configuration; it is not
claimed as a fourth full validated escape route. The three recorded routes do
not prove long-term balance or that all configurations are equally attractive.

## 14. Novice versus expert

Expected novice behavior: retreat, try the roof, push experimentally, lose a
route, notice the plate/press relationship and recover through the well. The
exit remains visible. A player can choose upper traversal while Can is green
instead of waiting for force. Death keeps a discovered fracture open.

Expected expert behavior: choose a useful lock side, remain close enough to
rebound, predict impact position and preserve the needed resource. In recorded
examples, Cart can remain at A for the entire escape; the force plan combines
player launch and wall fracture, while the weight plan uses a machine's top
and changes Can state. The difference is planning and combined consequences,
not faster run speed. This is a learning hypothesis, not observed human data.

## 15. Emergent solutions retained

Kept the environmental restoration chain that surprised the sandbox probe.
Kept riding the ordinary solid top of the press. Kept the upper bypass of the
partition. Kept the brief B→C support rush even though it uses neither durable
Cart weight nor grounding at the exit. None violate visible collision rules.
No “correct solution” flag closes these alternatives.

## 16. Example escape routes and metrics

These were encoded after the objective-free map and chain inspection. They
document possibilities, not instructions embedded in the game.

1. **Support rush:** bait rightward Cart impacts, rebound into the catwalk's
   brief support window, jump to the upper approach, go over the partition,
   then descend to the green landing. Cart ends C; Can remains active.
2. **Press weight:** keep A, roof-rebound to the loft, jump onto the press top,
   lead searching Can beneath the teeth, use its weight-supported catwalk and
   the upper bypass. Cart never moves. Can remains grounded at escape.
3. **Force chain:** keep A, use its loft, descend toward the lower central
   lane, bait a right charge and rebound while it continues to fracture the
   partition. Follow the low passage and climb the two exit steps. No grounding.

| Input-only fresh route | Seconds¹ | Charges | Cart impacts | Rebounds | Charging rebounds | Environmental stuns | Reversals | Resets / deaths | Hits | Idle² |
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|
| Support rush | 6.10 | 2 | 2 | 1 | 0 | 0 | 0 | 0 / 0 | 2 | 0.35 |
| Press weight | 7.07 | 0 | 0 | 1 | 0 | 1 | 0 | 0 / 0 | 0 | 0.97 |
| Force chain | 5.55 | 2 | 0 | 2 | 1 | 0 | 0 | 0 / 0 | 1 | 0.52 |

¹ Simulated game time with fixed 60 FPS, not wall-clock runtime or a human
estimate. ² Worker near-stationary time, including useful machine riding and
planning; it is not a precise measure of passive waiting. Charges include
autonomous attacks that are not required for the escape. JSON event/position
traces are in `artifacts/third_redesign/route_*.json`.

The support rush pushes right twice and is valid. It is not removed to enforce
a preferred strategy. It uses more Cart changes and takes more damage than the
force plan; whether it is too dominant for humans is still an open question.

## 17. System tests

| Requirement | Evidence |
|---|---|
| A locked intent | move worker across during telegraph; charge retains direction |
| B continuing rebound | duration/speed preserved; real sandbox and fresh force-route rebounds |
| C generic force | actual Cart impact and fracture; signed source-independent force threshold |
| D reversible Cart | real right/right/left/left charge contacts |
| E spatial utility | A loft; B bridge and shield; C forward roof with both losses |
| F Crusher grounds | actual tooth overlap, not merely a stun method call |
| G safe/heavy/stationary | collision layer, mass, zero speed, live state samples |
| H active useful | full low fracture route without grounding |
| I simultaneous changes | sandbox rebound + Can travel + Cart movement / support / shielding |
| J distinct escapes | three complete fresh input-only examples |
| K no grounding required | support and force routes: zero environmental stuns |
| L grounding benefits route | ground route asserts actual landing on catwalk while Can supplies weight |
| M recover without restart | opposite impacts; death preserves fracture/Cart; full snapshot rewind separate |
| N visible rules | upper escape with intact wall; escape with bridge retracted; no prerequisite checks |
| O fresh completion | all three routes have zero deaths and rewinds |

`third_systems.gd`: 28 checks. `third_sandbox.gd`: objective-free chain probe.
`third_route.gd`: three full runs. Sixteen preserved regression runs pass:
original smoke/route/interactions/rebound/dash, kinetic rules/route, first
Foundry depth/rules and two full routes, second core/systems and three full
routes. Logs are in `artifacts/third_redesign/regression_results.json`.

Tests validate consistency, recovery and completion. They do not establish
fun, subjective sound quality, novice learning or absence of every soft lock.

## 18. Screenshots and visual inspection

Ten staged native captures isolate relationships; they are not completion
proof. Three additional images come from the real graphical input-only force
route. All were inspected at native resolution.

| Image | Readability inspected |
|---|---|
| [01 initial](artifacts/third_redesign/screenshots/01_initial_space.png) | worker, Can, Cart, press, routes, weak wall and exit in one view |
| [02 intent](artifacts/third_redesign/screenshots/02_locked_intent.png) | locked arrow through Cart; press and later consequences visible |
| [03 rebound](artifacts/third_redesign/screenshots/03_rebound_continuing_charge.png) | airborne worker and Can continuing toward Cart |
| [04 A](artifacts/third_redesign/screenshots/04_cart_A_loft.png) | roof under loft; other roofs etched on rail |
| [05 B](artifacts/third_redesign/screenshots/05_cart_B_support_shield.png) | green plate/catwalk; Cart catches press |
| [06 threat](artifacts/third_redesign/screenshots/06_shared_crusher_threat.png) | exposed teeth over worker and Can; Cart displaced |
| [07 grounded](artifacts/third_redesign/screenshots/07_grounded_weight_route.png) | green heavy Can supports catwalk beneath traversing worker |
| [08 force](artifacts/third_redesign/screenshots/08_active_force_retained.png) | active arrow aimed into visible fractured material |
| [09 reversal](artifacts/third_redesign/screenshots/09_forward_cost_missing_bridge.png) | forward roof gained; dashed catwalk lost; local recovery below |
| [10 chain](artifacts/third_redesign/screenshots/10_bounce_cart_chain.png) | worker launched as Cart moves after impact |
| [11 live rebound](artifacts/third_redesign/screenshots/11_live_signature.png) | fresh-route rebound during continuing charge |
| [12 live fracture](artifacts/third_redesign/screenshots/12_live_escape_force.png) | same charge creates low passage while worker is airborne |
| [13 live escape](artifacts/third_redesign/screenshots/13_live_escape.png) | physical arrival after the force chain |

Ghost roofs, plate wire, green support, red charge lane, hatching and press
lamp communicate relationships without a paragraph of HUD. The worker is
small relative to the machine; color/shape readability needs human testing.
The pressure/weight wiring is functional but visually schematic.

## 19. Human playtest status

**No new human playtest completed.** Existing blind-playtest files were not
treated as evidence for this changed map. There was native rendering inspection
and automated motion inspection. No claim that a person would experiment for
two minutes, learn a heuristic or want another attempt is supported yet.

Next human session should begin with the objective-free scene and no coaching.
Observe whether they voluntarily attempt a second interaction, understand the
locked arrow, notice B's lost utilities and recover without R. Then measure a
fresh launch run, explanation of one failure, and a changed second plan.

## 20. Remaining weaknesses and files

- Expert escapes are extremely short. The requested 5–7 minute first-time
  experience and 60–90 second mastery payoff are unverified and may be missed
  substantially. No traversal or timer padding was added.
- Upper safety suppresses Can charges, and the press-weight route can escape
  without a committed attack. This offers real expression but may reduce the
  dangerous-machine fantasy for cautious players. A human session must assess it.
- The support rush still uses two forward pushes. It is a valid emergent plan;
  competing approaches exist, but comparative appeal and dominant strategy
  are not established. No complete reversal escape was encoded.
- Force and support controllers take damage. Three-hit health makes their
  execution recoverable, but clean human routes and controller quality need work.
- State changes are deterministic and often dense; extended improvisation and
  soft-lock exploration are not exhaustive. Can follows a horizontal service
  rail, not the worker into the lower well or onto every platform.
- The industrial geometry remains spare, and actor size, pressure wiring,
  sound mix and pleasure of repeated rebounds need human evaluation.
- There is no separate urgency phase at the end. Temporary weight/support and
  cycling machinery provide urgency within the existing world; whether that
  supplies the requested mastery payoff is unproven.

Changed/added gameplay: `scripts/yard.gd`, `yard_can.gd`, `yard_cart.gd`,
`yard_player.gd`, `scenes/foundry.tscn`, `yard_sandbox.tscn`,
`foundry_second.tscn`. Tests: `third_sandbox.gd`, `third_systems.gd`,
`third_route.gd`, `capture_third.gd`, `capture_yard_initial.gd`, plus second
test/capture scene paths. Documentation: this report, concise third spec,
README and new CHANGELOG entries preserving every historical entry. Evidence:
third-redesign JSON traces, sandbox image and thirteen native screenshots.
