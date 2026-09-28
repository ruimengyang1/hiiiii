# Prototype characteristics and strategic-depth alignment

This document maps *System Link* to the game-characteristics framework in the
course slides, **Characteristics of Games and (Skill) Depth**.

## Stochasticity, observability, and time granularity

| Characteristic | Design choice | Player-facing implementation |
| --- | --- | --- |
| Stochasticity | Deterministic gameplay | A locked ram charge, identical collision, cart stop, hazard, or switch input always produces the same result. Randomness is limited to cosmetic particles and camera shake. |
| Observability | Near-perfect information | The HUD reports cart stop, ram state/direction, rail power, bay safety, and gate state. Long charge arrows, named stops, visible wiring, red/green machinery, NPC reactions, and cause/effect announcements expose state changes. |
| Time granularity | Real-time with protected thinking space | The ram uses notice, telegraph, committed charge, and recovery states. It waits outside its notice range, major cart transitions stun it for a one-second planning window, and nearby rewinds make experimentation inexpensive. |

The game remains real-time because positioning during a locked charge is part
of the interaction. It avoids making reflex speed the source of depth: once a
player understands the intended state transition, the execution window is
broad and deterministic.

## Length of playtime

- A **round-like interaction** is one bait, charge, collision, and recovery
  cycle, normally lasting several seconds.
- A **session** is one complete rescue attempt, expected to take a few minutes.
- The prototype's **full game** is the five-beat rescue from briefing through
  delivery. Stable cart stops prevent a failed late interaction from requiring
  a complete replay.

## Systems

The prototype intentionally uses a small interaction vocabulary in all four
system categories from the slides.

| System category | Example |
| --- | --- |
| Conditional | If the player enters the notice range, the ram telegraphs and locks the player's side. If the cart reaches POWER, the live rail switches off. |
| Combination | Player position + ram agent creates a chosen charge; ram momentum + cart produces a new cart stop; cart position + ram rebound creates upper access. |
| Feedback loop | Idle -> notice -> telegraph -> committed charge -> collision/stun -> recovery -> idle. Each result changes the next useful player position. |
| Resources | Ram side/state, cart stop, safe space, powered rail, bay safety, and route availability are spatial resources. Using the ram or moving the cart changes which resource is available next. |

## Player structure

This is a single-player game with non-trivial autonomous agents. The engineer
is an objective and state communicator rather than a second controllable
character. The ram is simultaneously enemy, tool, and environmental force.
This preserves a focused solo prototype while still exploring relationships
between player, NPC, enemy, object, and environment.

## Heuristics

The broadly useful heuristic is:

> Before causing an interaction, predict which side and state every important
> object will occupy afterward.

It applies at the beginning, middle, and end; lies between reflex and exhaustive
search; and compresses ram side, cart stop, hazard state, and future access into
one actionable question.

The learning sequence refines rather than discards heuristics:

1. Avoid the ram.
2. Attack from above: the ram is also lift.
3. Stand beyond a target: player position aims the locked charge.
4. Ram impacts advance the heavy cart.
5. Do not take every available push: positions are future resources.
6. Predict the collision result and preserve the useful side for the next step.

Early guidance teaches vocabulary and cause/effect. Later prompts state the
goal and relevant properties but ask the player to compose the solution, so
clarity does not collapse the puzzle into a command list.

## Depth versus entropy

System Link seeks structure rather than either extreme in the slides' depth
curve. Discrete stops and deterministic rules keep entropy low enough for
heuristics to work. Depth comes from composing the same rules across changing
spatial states, not from randomness, hidden information, or additional
mechanics. The danger bay challenges the shallow “always push right” rule; the
final lock asks the player to predict a rebound and one later cart impact.

The completion screen reports **Plan Quality** without penalizing elapsed time.
Unsafe pushes, contact hits, deaths, and rewinds reduce the rating. A player who
stops to reason can therefore outperform a faster player who brute-forces the
state space, directly supporting the assignment criterion: the more you think
about the game, the better you should do.

## Dexterity versus strategy

Dexterity is present only as the physical language used to manipulate the
system. Coyote time, jump buffering, broad rebound windows, direction locking,
discrete cart movement, planning stuns, and checkpoint rewinds lower execution
cost. Strategic skill determines when to move the cart, where to leave the ram,
which state must be changed first, and whether an action preserves future
options.

## Scope control

The pass adds no inventory, crafting, dialogue tree, new enemy roster, or
additional level. It reuses one player, one ram, one cart/NPC, one shared
hazard, and two property-based switches. This follows the slides' warning not
to overbuild mechanics or scope while still exhibiting strategic depth.
