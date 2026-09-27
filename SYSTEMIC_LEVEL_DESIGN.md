# System Link redesign audit and implementation

## Pre-redesign audit

The active Kinetic Clockwork prototype began on a safe island. The player
downward-struck a continuously homing ram, transferred horizontal momentum to
it, let it transfer momentum into a freely coasting carriage, met a second ram,
then used the carriage's return from the far rail stop to reach an upper exit.
The persistent physical state was promising, but progress mostly rewarded
fast strikes, moving catches, and platforming execution. There was no NPC,
world-state objective, shared hazard behavior, or reason not to move the
carriage right immediately.

Reusable systems were the buffered/coyote-time controller, variable jump,
downward strike and rebound, telegraphed sentry states, kinetic ram/cart
contact, moving-body passenger support, collision layers, spikes, crushers,
quick reset, camera, procedural particles, and generated sound. Direct player
momentum transfer and the second ram were redundant with the new indirect
control goal. The strongest unrealized interactions were cart-as-weight,
ram-versus-hazard, cart-as-platform, and NPC position as progression state.

## Implementation phases

- **System core:** a ram now uses idle, windup/direction lock, committed
  charge, collision, stun/recovery, and idle states. The cart snaps between
  five deterministic stops and visibly carries the NPC.
- **Shared interactions:** the live rail affects player and ram; a generic
  systemic switch accepts player strike or ram impact according to its public
  property; the cart accepts any sufficient ram momentum from either side.
- **Level rebuild:** one continuous rail contains five accumulating beats
  rather than separate tutorial rooms.
- **Strategic-depth pass:** danger bay and final lock reject the dominant
  always-push-right strategy with clear visible feedback and recoverable state.
- **Feedback:** locked-direction cue, impact particles, brief camera shake,
  cart dust, NPC moods, hazard colors, state labels, alarms, switch sounds, and
  success burst.
- **Reset:** stable cart stops become quick rewind points. State-dependent
  hazards, switches, ram, player, cart, and passenger restore together.

## Five beats

1. **Threat becomes tool:** the first spike trench is crossed comfortably by
   downward-striking the pursuing ram and using its rebound height.
2. **Tool affects world:** on the far side, baiting a committed charge into the
   passenger cart advances it exactly one stop.
3. **First composition:** the cart reaches a brass pressure stop, cuts the live
   rail, and becomes the staging platform beneath an elevated safety cut-off.
   The live rail otherwise stuns the ram and kills the player.
4. **Heuristic break:** another immediate right push meets a visibly red danger
   bay. The passenger alarms, the cart refuses the unsafe move, and the ram is
   briefly stunned. The player must use the staged cart and ram rebound to
   reach and strike CUT-OFF first.
5. **Payoff:** after the safe bay, cart position arms a ram-only lock behind
   the cart. The player lures the ram left into it; the bumper activates and
   returns the ram on the useful side for one final rightward charge. No new
   rule appears in this sequence.

## Interaction coverage

| Pair | Meaningful state change | Feeds another rule |
| --- | --- | --- |
| Player × ram | Contact kills; downward strike rebounds and redirects | Rebound reaches balcony; position aims next charge |
| Ram × cart | Sufficient committed momentum advances one stop | New cart stop powers circuits, platforms, or progression |
| Cart × NPC | NPC rides, braces, alarms, points, and arrives | NPC arrival enables completion |
| Cart × environment | Brass stop cuts live rail; safe-bay stop arms lock | Ram can traverse rail; ram-only lock becomes usable |
| Ram × environment | Live rail stuns; ram switch activates and rebounds | Stunned ram is safer lift; activated lock releases final cart stop |
| Player × cart | Cart roof carries and rebounds the player but cannot be directly steered | Staged roof makes upper interaction accessible |
| Player × environment | Live rail kills; downward strike activates cut-off | Danger bay becomes a valid future cart state |

## Heuristic progression

The early heuristic is **ram equals danger**. The trench refines it to **ram is
also lift**. The first impact teaches **stand beyond the cart to push it right**.
The danger bay then refines that incomplete rule to **move the cart only when
the resulting ram, cart, hazard, and passenger positions remain useful**. The
final lock asks the player to plan several interactions ahead: send the ram
away, change the environment, recover the ram to the useful side, push the
cart, then meet the NPC.

## Intended route

1. Stand right of the ram, wait for the direction-lock cue, jump, and
   downward-strike it to cross the entrance trench.
2. Continue right so committed ram charges hit the cart from its left, moving
   it to transfer dock and then the brass pressure stop.
3. Do not push again. Use the cart roof and a ram rebound to reach the upper
   balcony; jump and downward-strike CUT-OFF.
4. Push the cart into the now-safe bay. This arms RAM LOCK.
5. Move left and bait the ram back into RAM LOCK. The bumper activates and
   returns the ram on the useful left side of the cart.
6. Move right of the cart and bait one final committed rightward charge.
7. Follow the delivered passenger to the lit station door.

The system permits recovery variations: a player can use an electric stun as a
safer bounce window before the cart cuts power, can reverse the ram with a
moving strike, and can approach the final lock with either a natural charge or
a redirected one. The cart itself remains stop-based so these variations do
not become physics chaos.
