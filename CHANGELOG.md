# Game changelog

This file records the history of the game, including discarded prototypes. It is
ordered newest first within each date. Commit links use abbreviated local Git
revisions because the repository may be moved or forked.

## Unreleased

- Replaced the launch experience with **Foundry / Future States**, a connected
  inspection, freight, service-return, delivery, and evacuation route centered
  on one persistent Can and engineer transport. Earlier prototype scenes remain
  available.
- Added a deterministic Can search, longer readable direction lock, bounded
  straight charge, safe recovery, and six-second stomp stun. Stomping now spends
  charge availability in the new demo instead of directly steering the Can.
- Added a shared force-receiver contract for rail transport and permanently
  fractured bulkheads; solid gates and level geometry now stop the Can.
- Made transport movement reversible and physically stall at closed machinery.
  Moving a useful roof or plate weight changes later access; stalled transport
  resumes when its route reopens and can be driven back to recover its roof.
- Added physical weight plates that accept either the Cart or a stunned Can,
  visible release timers and wires, and lasting strike-operated gate releases.
- Reused the original crushers as shared hazards: their actual spike regions
  stun the Can and hurt the player, their body blocks transport, and their top
  remains a safe platform. An isolated crusher no longer hurts the player.
- Added complete encounter snapshots, automatic short death rewinds, deliberate
  R rewind, Shift+R fresh restart, Escape pause, and optional H property hints.
  Removed experiment-penalizing rank scoring from the new demo.
- Added raised transport chassis and visible Can impact forks to communicate
  why a searching Can can pass underneath while a charging Can transfers force.
- Made stalled transport roofs useful recovery platforms, increased clearance
  and warning time at the foundry presses, added fixed warning lamps and sound,
  widened stomp detection, and made gates wait for occupants before closing.
- Kept the delivery checkpoint local to both the player and Can so a rewind
  cannot leave the useful actor far back in an earlier section.
- Made foundry levers latch without supplying rebound energy, keeping height
  dependent on the Can and Cart; fixed broad stomps catching the Cart's underside
  or corner when the player aims for a nearby floor lever.
- Anchored foundry Can and Cart rebounds to the struck top surface, eliminating
  effective height differences between early and late hits; retuned ledges to
  provide forgiving, distinct Can and Cart traversal roles.
- Increased foundry air control so a sound bounce plan is easier to execute
  when the player changes direction; the preserved older scenes retain their
  existing movement tuning.
- Added a visible passenger bracing pose during transport impacts and movement.
- Moved hints above the active characters and exposed separate circuit wires
  above the floor, making machine dependencies readable without HUD obstruction.

- Fixed the activated RAM LOCK repeatedly reversing the ram and behaving like
  a permanent wall; its first hit still rebounds for clear feedback, while an
  active green lock now lets later ram movement pass through unchanged.
- Fixed the empty completion panel remaining visible during play, where it
  appeared as a large blank box over the level.
- Changed contextual instructions from a permanently obstructive panel to a
  temporary prompt shown after relevant state changes; players can recall the
  current hint at any time with H.
- Aligned System Link with the course characteristics framework: gameplay is
  deterministic, relevant machine state is surfaced in the HUD, and real-time
  play now includes safe thinking space outside ram range plus one-second
  planning windows after major cart transitions.
- Added a live ram readout for off-screen position, charge direction, and stun
  state so strategic uncertainty comes from composing known rules rather than
  hidden information.
- Added a completion Plan Quality rating based on unsafe pushes, contact hits,
  deaths, and rewinds; elapsed time is deliberately unscored so careful thought
  outperforms fast brute force.
- Revised later contextual prompts to communicate goals and object properties
  without giving away the complete action sequence, preserving strategic depth
  after the initial vocabulary tutorial.
- Added an opening rescue briefing that identifies the stranded engineer,
  destination, indirect-control premise, and player→ram→cart relationship
  before the first input.
- Reworked the in-game guidance into a persistent mission/status panel and
  context-sensitive two-line instructions that explain the next interaction,
  its required positioning, and why a blocked action failed.
- Added explicit cause-and-effect announcements for checkpoints, the cart power
  plate, CUT-OFF, the danger bay, RAM LOCK, and engineer delivery.
- Enlarged and labeled the engineer, added readable ram direction arrows and
  stun feedback, renamed rail stops, exposed factory wiring, and strengthened
  red/green danger and destination language.
- Made early ram contact deal recoverable damage and demonstrate the safe
  overhead strike instead of immediately resetting an unfamiliar player.
- Replaced blurry fallback UI text with a non-antialiased monospaced font,
  integer-aligned panels, stronger contrast, and larger instructional text.
- Rebuilt the launch experience as **System Link**, a continuous systemic
  puzzle-platformer centered on indirectly steering one persistent clockwork
  ram, a five-stop passenger cart, and its NPC to a station.
- Changed ram attacks to visibly telegraph and lock their direction before a
  committed charge, making player position a predictable control input rather
  than requiring reaction to continuous homing.
- Made cart movement deterministic between readable rail stops; cart position
  now carries the NPC, powers a safety circuit, provides traversal height,
  arms the final lock, and determines the win state.
- Added a shared live-rail interaction that kills the player but stuns the ram,
  an elevated player-strike cut-off, and a ram-only final switch whose result
  releases the last cart stop.
- Added a visible danger bay that rejects a premature cart push with NPC alarm,
  impact feedback, and a clear strategic hint, refining the early “always push
  right” heuristic without creating an unrecoverable state.
- Added state-aware rewind checkpoints, NPC reaction poses, objective feedback,
  new switch/telegraph/alarm sounds, particles, and brief impact camera shake.
- Expanded the Kinetic Clockwork experiment from one room into a continuous
  three-part rail relay built around the same persistent carriage.
- Added an opposing ram, a scrolling camera, recovery islands, and an exit
  gantry reached by using the carriage's leftward return.
- Extended the launch ram's range so a carriage reversed by the opposing ram
  can return to it and be relaunched instead of forcing a restart.
- Reduced carriage friction for the long rail, keeping objects in motion while
  preserving direct strike corrections and rail-stop rebounds.
- Added a one-room Kinetic Clockwork gray-box prototype as the project's launch
  scene while preserving the original two-level game scene.
- Made downward strikes transfer the player's horizontal momentum into the
  prototype ram and heavy rail carriage. The persistent ram can then transfer
  its current momentum into the carriage on contact.
- Added deterministic carriage friction, damped rail-stop rebounds, direct
  strike corrections, quick room resets, and temporary velocity diagnostics.
- Built a compact test room with a safe starting ledge, spike rail, movable
  carriage, charging ram, and upper-right exit to test undershoot, controlled
  pushes, overshoot, and recovery from imperfect inputs.

## 2026-09-18

### Directional dash targeting (`60af703`)

- Changed the level-two dash from automatic nearest-target selection to
  directional aiming with the keyboard, D-pad, or analog stick.
- Limited valid dash targets to visible enemies within 175 pixels and a
  35-degree cone around the player's aim.
- Added an aim-cone guide and target highlight, and revised the HUD and in-level
  instructions to teach the new controls.

### Relay Shaft and level selection (`23dc870`)

- Expanded *Clockwork Ascent* from one level to two with the Relay Shaft, a
  longer stage built around chains of relay enemies, spike gaps, crushers, and
  three checkpoints.
- Added the target dash. It homes toward a visible relay enemy, defeats it on
  contact, carries some entry momentum through the hit, and refreshes after a
  successful connection so dashes can be chained.
- Added dash-ready HUD feedback, dash effects and sounds, and relay-enemy visual
  states.
- Added a level selector to the title and completion screens. Finishing level
  one unlocks level two and saves that unlock in `user://progress.cfg`.
- Made checkpoints, goals, camera limits, respawning, and completion flow work
  independently for either level.

### Rebound and crusher corrections (`47efc06`)

- Made crushers solid moving bodies with separate lethal spike hitboxes, so
  their movement and contacts are handled by physics instead of an approximate
  distance check.
- Stopped jump-button release from shortening a rebound, downward strike, damage
  knockback, death, or respawn motion by tracking whether a normal jump is still
  eligible for a variable-height cut.
- Added focused integration coverage for rebound height and the corrected
  crusher behavior.

### Clockwork Ascent vertical slice (`9809cea`, integrated by `d6b581b`)

- Replaced the thread-swinging prototype with *Clockwork Ascent*, a side-view
  pixel-art platformer rendered at a 384 x 216 internal resolution.
- Added momentum-based running, variable jump height, coyote time, jump
  buffering, an airborne downward strike, and upward rebounds from enemies and
  gold clockwork devices.
- Built the Clockwork Tower stage with platforms, spikes, moving platforms,
  timed crushers, rebound devices, checkpoints, and a bell goal.
- Added three enemy types: patrolling walkers, hovering drones, and charging
  sentries with a telegraphed windup.
- Added three-point health, damage knockback and invulnerability, fall and hazard
  deaths, checkpoint respawns, pause/retry flow, a timer and HUD, title and win
  overlays, particles, and generated sound effects.
- Added keyboard and gamepad controls plus smoke, route, interaction, and
  screenshot checks.
- Added the game's design and implementation brief in `GAME_PLAN.md`.

### Prototype reset and branch transition (`abc3a7a`, `d6b581b`)

- Removed the Wind Effigy implementation, its generated art and audio, design
  notes, playtest materials, and recovery bundle from the main branch.
- Merged the Clockwork Ascent branch, making that vertical slice the active game.

### Wind Effigy thread playground (`30e8be7`)

- Reworked the earlier 3D experiment into *Wind Effigy*, a 30–60 second
  side-view swinging playground intended to test whether the core interaction
  was enjoyable.
- Added running, buffered/coyote-time jumping, mouse-aimed Wind Thread
  attachment, momentum-preserving release, roof checkpoints, recovery ledges,
  an optional high route, and an airborne two-anchor chain.
- Added three switchable feel profiles, retry and full-restart controls, and a
  HUD showing speed, thread tension, attempts, and elapsed time.
- Added a puppet sprite, generated audio, art studies, a design foundation,
  human playtest instructions, and automated probes for constraint stability,
  landing windows, timing, and anchor chaining.
- Preserved the preceding Momentum Lab prototype in a Git recovery bundle before
  replacing it.

## 2026-09-17 to 2026-09-19

### Momentum Lab greybox (`6a228f7`)

- Created a third-person momentum playground for redirecting speed around rigid
  tether anchors, storing and returning energy with elastic bamboo, and
  transferring motion into a resonant bell.
- Added camera-relative movement, orbit camera controls, jumping with coyote time
  and input buffering, directional dash, hold-to-attach tethering, preserved
  swing velocity on release, and respawning.
- Built multiple anchor chains, alternate routes, a low recovery floor, a goal
  bell, debug feedback, placeholder sound effects, and reference art.
- Added automated probes for the first swing, bamboo behavior, and momentum
  transfer.

> The commit's authored date is 2026-09-19 in UTC+08, which corresponds to
> 2026-09-18 in this repository's later UTC-04 working timezone.

### Project foundation (`ce11fd8`, `7456c70`, `d695b22`)

- Created the repository and an initially empty Godot 4.7 project named *Slop*.
- Added the project icon, editor and Git settings, and local Codex/Godot tooling
  configuration. The follow-up commit corrected that tooling configuration; it
  did not change gameplay.

## Maintenance rule

Every future change that affects gameplay, levels, controls, balance, content,
presentation, audio, player-visible behavior, or game-facing bug fixes must add
an entry under **Unreleased** in the same change. Replace “No game changes yet”
when adding the first entry. Keep entries factual and player-focused, and never
delete historical entries when a feature is removed; record the removal as a new
change instead. Documentation-only, test-only, and internal refactors need an
entry only when they alter or clarify player-visible behavior.
