# Maps

Numeric IDs are used by the protocol and save files. Keep IDs stable when renaming modules.

| ID | Map | Module directory |
| --- | --- | --- |
| 0 | Hide and Seek Act 2 | `hide_and_seek_act_2` |
| 1 | Ravine Mist | `ravine_mist` |
| 2 | ... | `dot_dot_dot` |
| 3 | Desert Town | `desert_town` |
| 4 | You Can't Run | `you_cant_run` |
| 5 | Limp City | `limp_city` |
| 6 | Not Perfect | `not_perfect` |
| 7 | Kind and Fair | `kind_and_fair` |
| 8 | Act 9 | `act_9` |
| 9 | Nasty Paradise | `nasty_paradise` |
| 10 | Priceless Freedom | `priceless_freedom` |
| 11 | Volcano Valley | `volcano_valley` |
| 12 | Hill | `hill` |
| 13 | Majin Forest | `majin_forest` |
| 14 | Hide and Seek | `hide_and_seek` |
| 15 | Torture Cave | `torture_cave` |
| 16 | Dark Tower | `dark_tower` |
| 17 | Haunting Dream | `haunting_dream` |
| 18 | Mystic Wood | `mystic_wood` |
| 19 | Echidna Ruins | `echidna_ruins` |
| 20 | Fart Zone | `fart_zone` |

Client modules live in `src/game/maps/`; server modules live in `src/maps/`.
Fart Zone (20) is a practice map and is excluded from the regular map pool.
Server geometry, entities and spawn data live in `assets/maps/<map>/world.json`.
Client scenes are listed in `assets/maps/catalog.json`.
