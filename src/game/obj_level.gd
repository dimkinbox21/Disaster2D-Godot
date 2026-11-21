extends GMNode
## Port of obj_level — the round state holder.
## The original has no Draw event on the object itself; all of its drawing is
## the GUI event Draw_64 (screen space), ported in obj_level_hud.gd inside a
## CanvasLayer. The object only runs Step_0 (ring animation frame) and owns the
## round timer, the fades and the title card.

const ROUND_TICKS := 60 * 300  # solo: a 5-minute round, in 1/60 s ticks

var ending_sprite := ""
var ending_fade := 0.0
var ending_age := 0
var sudden_started := false
var sudden_age := -1
var sudden_fade := 0.0
var timeFrame := 0  # original: ++ on every SERVER_GAME_TIME_SYNC
var clockAngle := 0.0
var bloodFade := 0.0  # attack overlay (spr_attackgui)
var hideFade := 0.0  # hiding overlay (spr_hidegui)
var state := 0  # 0 = running, 1 = big ring spawned
var showSurvivors := false
var survivorTimer := 0
## title card (spr_titlecard1/2 slide-in, one frame per level)
var titleCard := 0.0
var cardX := 480.0
var cardY := -270.0
## the countdown in 1/60 s — the original reads it from the server's
## SERVER_GAME_TIME_SYNC packet (u16); solo replays the same shape 5:00 → 0:00
var _ticks := ROUND_TICKS
var _elapsed := 0  # physics frames since the round start


func _ready() -> void:
	gm_name = "obj_level"  # spawned by map_controller — must be findable
	super._ready()
	Globals.ringFrame = 0.0
	_ticks = (
		Net.round_ticks if Net.state == Net.STATE_GAME and Net.round_ticks >= 0 else ROUND_TICKS
	)
	_set_clock(_ticks)
	# HUD lives in a CanvasLayer so the camera never moves it (GM's Draw GUI)
	var cl := CanvasLayer.new()
	cl.layer = 10
	add_child(cl)
	var drawer := preload("res://src/game/obj_level_hud.gd").new()
	drawer.level = self
	cl.add_child(drawer)
	# the world-space counter copy that renders UNDER the red-ring frenzy fog
	# (obj_counters_under.gd draws only while redRingTimer > 0)
	var under := Node2D.new()
	under.set_script(load("res://src/game/obj_counters_under.gd"))
	add_child(under)


## SERVER_GAME_TIME_SYNC — the server-driven round clock (the solo emulation
## in _step_timer stands down while Net.state == STATE_GAME)
func net_time(timer: int) -> void:
	if not sudden_started and _ticks > 7260 and timer <= 7260:
		sudden_started = true
		sudden_age = 0
		GameAudio.play_sound("snd_suddendeath")
	_ticks = timer
	timeFrame += 1
	_set_clock(timer)
	if Globals.timeMinutes == 0 and Globals.timeSeconds <= 10:
		GameAudio.play_sound("snd_clock")


func _set_clock(ticks: int) -> void:
	var seconds := maxi(0, ceili(ticks / 60.0))
	Globals.timeMinutes = seconds / 60
	Globals.timeSeconds = seconds % 60


func _gm_step() -> void:
	# Step_0: global.ringFrame += 1/10, wrap at 4 (the ring sprite animation)
	Globals.ringFrame += 1.0 / 10.0
	if Globals.ringFrame > 4.0:
		Globals.ringFrame = 0.0
	if sudden_age >= 0:
		sudden_age += 1
		sudden_fade = (
			minf(0.5, sudden_fade + 0.01) if sudden_age <= 240 else maxf(0.0, sudden_fade - 0.02)
		)
	_step_timer()
	_step_fades()
	if ending_sprite != "":
		ending_age += 1
		ending_fade = minf(0.5, ending_fade + 0.01)


func _step_timer() -> void:
	if Net.state == Net.STATE_GAME:
		return  # netplay: the SERVER_GAME_TIME_SYNC packet drives _ticks
	if _ticks > 0:
		_ticks -= 1
	# the original increments the clock hand + the display once per second
	# (once per tick packet), not once per frame — the hand is a 45°/s sweep
	_elapsed += 1
	if _elapsed % 60 != 0:
		return
	timeFrame += 1
	_set_clock(_ticks)
	# last ten seconds: one clock tick per second
	if Globals.timeMinutes == 0 and Globals.timeSeconds <= 10:
		GameAudio.play_sound("snd_clock")


func _step_fades() -> void:
	var player: GMNode = _player()
	if player and player.isHiding:
		if hideFade < 1.0:
			hideFade += 0.02
	elif hideFade > 0.0:
		hideFade -= 0.02
	if bloodFade > 0.0:
		bloodFade -= 0.02
	# title card: slide in (cardX 480→0, cardY -270→0), hold, slide back out
	if titleCard < 8.0:
		if cardX > 0.0:
			cardX -= 12.0
		if cardY < 0.0:
			cardY += 12.0
	if titleCard > 18.0:
		if cardX < 480.0:
			cardX += 12.0
		if cardY > -270.0:
			cardY -= 12.0
	if titleCard < 30.0:
		titleCard += 0.12


## obj_level.bloodFade = 0.4 — set when a survivor's attack connects
func flash_blood() -> void:
	bloodFade = 0.4


func _player() -> GMNode:
	for p in GMNode.all_of("obj_player"):
		return p
	return null


func _gm_draw() -> void:
	pass  # everything is drawn screen-fixed by obj_level_hud.gd
