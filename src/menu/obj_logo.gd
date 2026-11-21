extends GMNode
## Port of obj_logo — "EXE EMPIRE PRESENTS" splash before the menu.

var start := false
var ind := 0
var _alarm := -1


func _ready() -> void:
	super._ready()
	if Globals.init:
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return
	Globals.init = true
	image_speed = 0.0


func _gm_step() -> void:
	if SaveStore.startup_pending:
		return
	# Draw_77 (begin draw) start logic — runs once on the first frame
	if not start:
		start = true
		var f := GMNode.new()
		f.set_script(load("res://src/menu/obj_blackfadeout.gd"))
		f.position = Vector2.ZERO
		f.depth = -900
		get_parent().add_child(f)
		GameAudio.play_sound("mus_logo")
		_alarm = 60 * 2
	if _alarm > 0:
		_alarm -= 1
		if _alarm == 0:
			_alarm0()
	# skip: any key or mouse press (Keyboard_1 / Step_0)
	if GM.key_pressed(GM.VK_ANYKEY) or GM.mouse_pressed(2):
		ind = GM.sprite_count(sprite_name)
		_alarm = 1
		GameAudio.stop_all()


func _alarm0() -> void:
	ind += 1
	image_index = ind
	var w := GMNode.new()
	w.set_script(load("res://src/menu/obj_lobby_white.gd"))
	w.position = Vector2.ZERO
	w.depth = 0
	get_parent().add_child(w)
	if ind > GM.sprite_count(sprite_name) - 1:
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return
	if ind == 1:
		_alarm = int(60 * 2.4)
	if ind == 2:
		_alarm = int(60 * 2.5)
