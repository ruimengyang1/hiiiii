# Foundry / Future States

## Audit of the actual starting build

Inspected both scenes, project settings, every gameplay script and test, README,
three design documents, the course alignment, changelog, and archived requests.
The launch scene was System Link, not the older momentum relay described in its
historical audit. It uses procedural pixel drawings and generated WAV sounds;
there are no imported character animations, projectile systems, or separate NPC
scenes to preserve.

1. **Player:** run, buffered/coyote jump, airborne downward strike; rebound over
   an entrance ledge, bait four rightward cart pushes, strike an elevated cut-off,
   bait a leftward lock hit, deliver the passenger, walk to the exit.
2. **Can:** an Area2D ram with idle/windup/coast/recovery/stun. Windup locks its
   direction, but coasting lasts until friction stops it. Stomping transfers the
   player's horizontal velocity into it. It moves horizontally without checking
   level solids and has cart-specific and switch-specific contact paths.
3. **Cart:** solid animated platform, five deterministic stops, decorative but
   expressive passenger. Its position triggers circuit and progression flags.
   Two scripted prerequisites refuse moves rather than allowing their costs.
4. **Works well:** responsive movement, fixed rebound, solid passenger support,
   clear direction arrow, NPC poses, sound, particles, camera, short reset.
5. **Reusable systemically:** actor states, force transfer, roof rebound, heavy
   cart, crusher with safe top/separate spike shapes, strike switches, snapshots.
6. **Isolated:** original spikes, patrols, drones, rebound devices, crushers and
   dash chains; System Link does not connect most of these to the Can or cart.
7. **Dexterity:** original two levels mostly test rebound height, timed crushers,
   gaps, moving catches and aimed dash chains. System Link's first ledge is also
   an execution lesson.
8. **Existing strategy:** locked aim, cart as roof and circuit weight, safety
   ordering, bringing the ram back to a lock, persistent cart stops.
9. **Arbitrary:** stage-index prerequisites, automatic transition stuns, an
   electrically "weighted" stop that stays powered after its weight leaves,
   direct stomp steering, ram travel through solid geometry, and a score that
   discourages experiments. The opening briefing reveals the first discovery.
10. **Missing relationships:** impact→breakable; crusher→Can; stunned Can→plate;
    reversible cart→lost roof access; moving weight→closing gate; lasting impact
    state→later routing. Original checkpoints rebuild the level; the launch
    scene instead restores a small set of flags inferred from cart index.

Keep both previous scenes runnable. The redesign becomes a new launch scene.

## Five rules

1. **Readable routine:** Can searches slowly; a nearby player on its level causes
   a 0.78 s arrow/sound windup, then a straight 1.65 s charge. No homing after lock.
   Raised safe perches let the player think and lure a searching Can underneath
   the raised cart chassis. Its impact forks are lowered outside a charge.
2. **Force:** sufficient committed momentum calls the same `receive_impact`
   contract on transport and fractured bulkheads. Solids stop it. A broken wall
   stays broken. Cart motion is rail-constrained, reversible, and deterministic.
3. **State:** stomp always rebounds and stuns Can for six seconds. Crusher spikes
   hurt the player and stun Can. Stunned shell is safe and heavy; recovery is safe
   but does not hold a plate. Stomp spends charge availability rather than aims it.
   Its active magnetic suspension is visibly lit; the disabled shell settles
   onto the floor and supplies its full weight.
4. **Cart:** roof/platform/rebound, passenger transport, and persistent heavy
   weight. The open undercarriage admits a searching Can; raised charging forks
   engage its bumper. Moving the roof changes which high routes are reachable.
5. **Circuit:** plates inspect physical weight continuously, accept Cart OR
   stunned Can, and release after a short visible grace. Wires show their gates.
   Strike switches latch. A closed gate physically stalls transport, which
   resumes when powered or can be driven back. No cart-index permission checks.
   Small levers provide no rebound energy. Can/Cart rebounds use a fixed launch
   surface, so early/late strike timing cannot replace a positional plan.

No abilities, inventory, weapon, additional enemy roster or upgrades.

## Continuous route and encounter audit

Target first run: 10–15 minutes including observation/experimentation; expert:
roughly 3–5. These are design targets pending independent human timing. One
horizontal facility, continuous rail and overlapping overhead service routes;
one persistent Can and one passenger cart. Earlier machinery stays live.

| Beat / start and objects | Goal, novice model, actions and consequences | Future options / heuristic / expert insight | Reset / reuse |
|---|---|---|---|
| **React**: worker and Can; high one-way inspection shelf; sealed orange service wall behind spawn | Reach inspection lever. Dodge committed charge or stomp for shelf access. Can is danger; stomp creates height but six seconds without force. | H0→H1: intent can be read. A clear safe shelf offers a thinking position. Expert baits once and spends one stun. | Entrance snapshot; controller, ram art, switch, sound. |
| **Discover**: stranded engineer at first rail dock; ground path leads naturally beyond cart | Reach transfer dock. Walking past the cart exposes the player and causes the following Can's charge to hit it. One further purposeful charge moves it into the freight line. | H2: attack helps. Stomp is also useful for taking the roof but delays the push. Cart and Can no longer occupy their starting positions. | Transfer checkpoint; existing cart/passenger/bounce. |
| **Generalize**: cart parked behind player; fractured tall bulkhead ahead of Can | Open passage. Stomp toward a high inspection perch or stand beyond the visibly cracked material and dodge. No explanatory Can→wall tutorial. | H3: force is general. Breaking wall spends force but creates a permanent lower route; bounce preserves wall and gives observation. Expert reads matching impact language. | Entry to press section; shared impact contract, solids. |
| **Reverse**: Can, existing cyclic crusher, high freight lever; no cart in the local view | Release freight gate. Dodge/stomp directly or lure Can beneath crusher then use inert shell. Either creates the same safe bounce window. | H4/H5: world changes actor state. Crusher stun offers safety but removes immediate force. Expert watches hazard phase rather than reacts. | Press checkpoint; original crusher spike polygons/safe body. |
| **Choose**: Cart arrives at roof dock A; high ventilation switch; nearby weight dock B | Open a route and stage cargo. Roof strike at A reaches ventilation; charge advances to B and opens weight gate. Both are real progress. Stomp Can for lower traversal also delays transport. | H5/H6: spend charge, roof, or weight. Switch persists; roof does not. Expert consumes roof access before relocating it. | Strategic yard entry snapshot, not after each push. |
| **Refine**: A roof vs B weight vs C forward bay; same Can and circuits | Get through freight gate with future transport intact. Moving to B early removes high access; reverse Cart to A to recover it. Moving B→C removes gate weight and can strand Can on its old side. | H7/H8: progress can consume an option. Cart weight is lasting; Can weight is temporary. Expert preserves roof first, then predicts Can's side after the gate closes. | R restores yard entry; reversals and reopened gate also recover without reset. |
| **Return**: forward service catwalk loops back along existing rail to the orange wall seen at spawn; cart stays in bay | Restore the evacuation pump behind the early wall. Player now recognizes a force receiver. Can must be brought back rather than discarded after cargo movement. | H9: route state and actor position matter. Same abilities reinterpret earlier scenery. Early pump activation is a valid expert shortcut, not forbidden by stage flags. | Forward bay checkpoint; broken walls and switches from earlier beats persist. |
| **Mastery**: staged cart, high isolation lever, crusher, physical plate/gate, far-side release lever | Deliver engineer through final gate. (A) preserve roof, isolate crusher, park Cart on plate, cross and latch release, return Can for transport. (B) send Cart away and replace its weight with a stomp/crusher-stunned Can; traverse before weight wakes. | H9/H10: simulate force→position→plate→gate→route. A is durable but requires travel; B chains actions and commits Can. Expert avoids needless repositioning. Novice sees a stalled Cart and diagnoses lost weight. No exact password. | Final-yard entry snapshot; only taught systems. |
| **Payoff**: delivered passenger, original-looking charge corridor, evacuation bulkhead | Lure the same Can into the last fractured door and bounce/dodge into the terminal. Short action sequence, no new puzzle. | Beginning charge=danger; final charge=chosen opportunity. | Delivery checkpoint; force/bounce feedback and finish. |

## Interaction matrix

| Pair | General rule / state | Later value |
|---|---|---|
| Player–Can | overhead strike → fixed bounce + stun; active body contact damages | height versus charge availability/weight duration |
| Can–Cart | charge momentum → next rail stop; search passes below chassis | transport, changed roof, new plate occupancy, different Can side |
| Can–bulkhead | sufficient impact → permanent fracture | path, shortcut, input to later charge |
| Crusher–Player/Can | actual spike region → damage / durable stun | safe top traversal; available weight versus moving force |
| Cart/stunned Can–plate | enough physical mass → gate power | Cart free for transport only if replacement weight or latch is prepared |
| Player–switch | overhead strike → lasting circuit | preserves route after actor moves |
| Gate–Cart/Can/Player | shared solid when unpowered | transport stalls; actor side and alternate upper access matter |
| Cart–Player/NPC | solid moving roof/passenger | movement, access and rescue objective |

## Greybox first

Build the final-yard fixture before full route geometry. Verify both weight
solutions, roof loss/reversal, stalled-cart recovery, locked intent and stomp
cost. Do not compensate for weak results with content. Then build teaching and
transfer around those exact rules. Polish comes last.

## Recovery and verification

R restores the current encounter's complete snapshot: Can position/state/timer,
Cart position/current target, each fracture/lever, crusher phase and plate/gate
state. Entering a new working bay saves the preceding results. Death uses that
same restore after 0.4 s. Shift+R starts fresh; Escape pauses; H recalls a short
property/goal hint, never a later action recipe. Snapshots are spatial encounter
entries, not rewards for every individual impact.

Verify A–J with actual physics: blind right pushes lose roof/weight and stall;
normal jump cannot reach high switches; transfer needs impact, not a Can ID;
two final-yard solutions; mutations persist until explicit rewind; recoverable
reverse/stall states; fresh input-driven route, not setter-only completion.
Record measured bot routes separately from unmeasured first-time human pacing.

## Verified implementation refinements

- The greybox passes force/bounce/weight tradeoffs, both weight sources, reversal,
  physical stalls, crusher stun, and complete restore before the new scene was
  promoted to the launch scene.
- The freight pin is raised above a visible service gap. It stops cargo before
  the transfer bulkhead while workers and searching Cans fit underneath. This
  keeps the Cart out of the force-transfer encounter without a scripted reset.
- Foundry air acceleration is higher than in the preserved scenes. Movement
  speed and abilities are unchanged; reversing after a bounce is forgiving.
- Can rebounds place feet on its top surface at y=280; Cart rebounds place feet
  on its roof at y=268. With the same launch speed, the high y=214 balconies need
  the Cart roof. Ground Can rebounds cannot replace it.
- Isolating the final press trades safety for the loss of automatic Can stun.
  A player choosing this state must supply their own stomp for temporary weight.
- A stalled Cart creates a new high platform near the gate. A complete fresh
  run validated using that new position to recover through the upper route.
- The final yard also passes a complete fresh run using a stomp-stunned Can as
  replacement weight, then latching the far release afterward.
- Entry snapshots wait for the Can to reach the delivery yard as well as cargo
  and player. Gate safety strips delay closure around occupants.
- Hint panels sit above the playfield actors; factory warning lamps remain near
  the floor even while press heads are raised out of the camera's view.
