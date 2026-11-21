extends Node
## Port of scr_globals (global variables) — stage 1: only what the menu needs.

var init := false
var score := 0
var player: Node = null
var playerControls := true
var cameraMode := 0
var timeSeconds := 0
var timeMinutes := 0
var lives := 3
var showHud := true
var paused := false
var errorCode := -1
var muteChat := false

var ringId := 0
var ringFrame := 0.0  # obj_level Step_0 advances it by 1/10 every step — must be float or the ring sprite freezes on frame 0
## scr_globals levelDescriptions — the vote cards' map blurbs (index = lvlId)
var levelDescriptions: Array[String] = [
	"long and spacious map with no less spacious boxes to hide behind, using       \nsprings echoes all over the cave, revealing your location to exe |+25 sec.",
	"6 shards have to be collected to access the exit on the last minute, collected\nshards will lead you to the exit. avoid slugs that feed on rings, kill them  \nto obtain the ring if they devour one",
	"long stairway with three floors, you can't run on stairs and the lower you go \n- the darker it gets |+25 sec.",
	"high buildings will serve you a hideout, it's hard to break away here, but you\ncan hide almost everywhere",
	"constant gas leaks will fill the areas poisoning you and causing you to       \nhallucinate, revealing your location to exe ",
	"the city is limp but not blind, you can be watched through eye cameras or use \nthem yourself, there are the circuits that periodically activate blocking the \npassages |-25 sec.",
	"map rotates every 30 seconds, the floor becomes walls and the walls become the\nfloor, the exit is available on only one turn |-25 sec.",
	"avoid breaking speed monitors, as they will launch you right in the spikes    \nwithout letting you stop running until you meet a wall or get hurt",
	"you can see only the silhouettes, the walls are slowly shrickening, avoid     \ngetting cornered if you don't want to be squished |-50 sec. +10 sec. for each\nsurvivor instead of 25",
	"giant snowballs roll down the slopes, damaging and slowing you down.\nsometimes springs and rings cover with ice |-25 sec.",
	"escape with elevators and avoid black rings that will drain your health upon  \ngetting them, damage from them can be avoided by having 5 rings |-25 sec. +10 \nsec. for each survivor instead of 25",
	"long map filled with lava pits, some of which burst with lava pillars. break  \nthe pots to get more rings",
	"long linear map filled with water that slows you down. when the lightning     \nstrikes, don't touch the water",
	"wherever you run - you will never reach the end, there are no bounds, fun is   \ninfinite |-25 sec. +10 sec. for each survivor instead of 25",
	"hide behind palm trees and bushes, moving along the ziplines",
	"an abandoned mine illuminated only by searchlights, sometimes acid evaporates \nincreasing its area, stay away from it unless you're a fan of sulfuric acid    \nbaths |-25 sec.",
	"don't stand under stalactites, they will fall if you walk under them. every 10 \nseconds it gets dark for a while, at this time try not to run into the owner  \nof this place |+25 sec.",
	"you will be able to open the passages by activating the crystals. hold the jump  \nor up on special springs so that they throw you higher, and most importantly, \ndo not wake up |+25 sec.",
	"be careful on conveyor belts and get to ignited lanterns to banish spirit that \nhaunts the forest, before things get even darker |-25 sec",
	"you better not touch the crystals releasing the phantom energy, otherwise it \nwill be difficult for you to move and avoid traps of the ancient temple \n|+25 sec",
]
var character := -1
var exeCharacter := -1
var nickname := "player"
var configInit := false
var errorMessage := ""
var palleteFrom: Array = []
var palleteTo: Array = []
var palleteName := "defualt"

# Keys (GameMaker vk codes, save-compatible with the original 1.bson)
var KeyLeft := GM.VK_LEFT
var KeyRight := GM.VK_RIGHT
var KeyUp := GM.VK_UP
var KeyDown := GM.VK_DOWN
var KeyA := 90  # ord("Z")
var KeyB := 88  # ord("X")
var KeyC := 67  # ord("C")
var KeyEm1 := 65  # ord("A")
var KeyEm2 := 83  # ord("S")
var KeyEm3 := 68  # ord("D")
var KeyHide := GM.VK_LCONTROL
var KeyPList := GM.VK_TAB
var KeyIdle := 87  # ord("W")

# character constants (scr_exe / scr_survivors)
const CHARACTER_EXE := 0
const CHARACTER_TAILS := 1
const CHARACTER_KNUX := 2
const CHARACTER_EGGMAN := 3
const CHARACTER_AMY := 4
const CHARACTER_CREAM := 5
const CHARACTER_SALLY := 6

# palette table offsets (scr_palletes)
const PALETTE_DEMON := 20
const PALETTE_EXE := 40

# exe constants (scr_exe) — used by skins
const EXE_ORIGINAL := 0
const EXE_CHAOS := 1
const EXE_EXETIOR := 2
const EXE_EXELLER := 3
