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
var ringFrame := 0
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
var KeyA := 90   # ord("Z")
var KeyB := 88   # ord("X")
var KeyC := 67   # ord("C")
var KeyEm1 := 65 # ord("A")
var KeyEm2 := 83 # ord("S")
var KeyEm3 := 68 # ord("D")
var KeyHide := GM.VK_LCONTROL
var KeyPList := GM.VK_TAB
var KeyIdle := 87 # ord("W")

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
