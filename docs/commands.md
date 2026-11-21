# Chat commands

| Command | Action |
| --- | --- |
| `.help`, `.info` | Command list and server description |
| `.lobby N` | Switch lobby |
| `.vk`, `.vp` | Vote kick or vote for Fart Zone practice |
| `.yes`, `.y` | Support the current vote |
| `.mute`, `.m` | Toggle local chat mute |
| `.test k` | Solo test as a hunter |
| `.test s` | Solo test as a survivor |
| `.map N` | Operator: select map 1–21; 21 is Fart Zone |
| `.kick`, `.ban`, `.op` | Operator: select a player for an action |

Use the arrow keys to select a target, the game A button to confirm and B to cancel
(Z and X by default). The server validates operator IPs against `Operators.json`.
Votes last 20 seconds and require a strict majority; they finish early when every
eligible player has voted.

## Solo test mode

`.test k/s` works only with exactly one player in the lobby. It opens regular map
voting, followed by character selection for the requested team. If another player
joins before the round starts, the test is cancelled.

Test rounds do not change achievements, currency, wins, kills, stuns or map progress.
Hunter selection chance and pending priority are preserved. The server suppresses
profile events and the client disables progress awards. Normal rounds award progress
again after the test ends.

## Practice

The server panel's Practice button and `.vp` select Fart Zone. At least two players
are required. Practice does not award achievements or currency. Losing ends that
participant's training session while leaving the application open.
