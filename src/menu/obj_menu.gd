extends GMNode
## Port of obj_menu — the menu controller (Create/Step/Alarm events).

const SUBMENU_NONE := 0
const SUBMENU_JOIN := 1
const SUBMENU_JOIN_MOBILE := 47
const SUBMENU_OPTIONSGENERAL := 2
const SUBMENU_OPTIONSCONTROLS := 3
const SUBMENU_OPTIONSBACK := 4
const SUBMENU_OPTIONSCONTROLSMOBILE := 5
const SUBMENU_MECH_SPIN := 6
const SUBMENU_MECH_HIT := 7
const SUBMENU_MECH_PAR := 8
const SUBMENU_MECH_REB := 9
const SUBMENU_MECH_STEAL := 10
const SUBMENU_MECH_RINGS := 11
const SUBMENU_MECH_REDRINGS := 12
const SUBMENU_MECH_DEMON := 13
const SUBMENU_MECH_SUDDEN := 14
const SUBMENU_MECH_ESCAPE := 15
const SUBMENU_MECH_DIFF := 16
const SUBMENU_ABOUT_CREDITS := 18
const SUBMENU_ABOUT_BACK := 19
const SUBMENU_CHAR_TAILS := 20
const SUBMENU_CHAR_KNUX := 21
const SUBMENU_CHAR_EGG := 22
const SUBMENU_CHAR_AMY := 23
const SUBMENU_CHAR_CREAM := 24
const SUBMENU_CHAR_SALLY := 25
const SUBMENU_CHAR_EXE := 26
const SUBMENU_CHAR_CHAOS := 27
const SUBMENU_CHAR_EXETIOR := 28
const SUBMENU_CHAR_EXELLER := 29
const SUBMENU_EXTRA_ACHIVEMENTS := 30
const SUBMENU_EXTRA_TAILS := 31
const SUBMENU_EXTRA_KNUX := 32
const SUBMENU_EXTRA_EGG := 33
const SUBMENU_EXTRA_AMY := 34
const SUBMENU_EXTRA_CREAM := 35
const SUBMENU_EXTRA_SALLY := 36
const SUBMENU_EXTRA_EXE := 37
const SUBMENU_EXTRA_CHAOS := 38
const SUBMENU_EXTRA_EXETIOR := 39
const SUBMENU_EXTRA_EXELLER := 40
const SUBMENU_EXTRA_SKINS1 := 41
const SUBMENU_EXTRA_SKINS2 := 42
const SUBMENU_EXTRA_SKINS3 := 43
const SUBMENU_EXTRA_BACK := 44
const SUBMENU_EXTRA_TAUNT := 45
const SUBMENU_EXTRA_PENIS := 46

var scheme := false
var bSelected := 0
var bCount := 5
var bSelectedColumn := 0
var bColumnCount := 0
var buttonA := false
var submenu := SUBMENU_NONE
var justEntered := true
var bind := false
var bindBtn: Variant = 0
var ignoreButtons := false
var mobSelectedButton := 0

## injected by the scene generator
var bars: GMNode = null
var layers: Dictionary = {}  # layer name -> Node
var characters_node: GMNode = null


func _ready() -> void:
	super._ready()
	call_deferred("_alarm0")
	call_deferred("_config_alarm0")


func _alarm0() -> void:
	buttonSelected(0, -1, 0, false)


## Port of obj_config Alarm_0: fills saved settings into the menu widgets
func _config_alarm0() -> void:
	var ping_b := findButton("ping")
	if ping_b:
		ping_b.state = GameConfig.showPing
	var fps_b := findButton("fps")
	if fps_b:
		fps_b.state = GameConfig.showFps
	var ip_tb := findTextbox("ip")
	if ip_tb:
		ip_tb.text = GameConfig.ip
	var ipm_tb := findTextbox("ip_mobile")
	if ipm_tb:
		ipm_tb.text = GameConfig.ip
	var nick_tb := findTextbox("nickname")
	if nick_tb:
		nick_tb.text = Globals.nickname
	var binds := {
		"left": Globals.KeyLeft,
		"right": Globals.KeyRight,
		"up": Globals.KeyUp,
		"down": Globals.KeyDown,
		"jump": Globals.KeyA,
		"special1": Globals.KeyB,
		"special2": Globals.KeyC,
		"playerlist": Globals.KeyPList,
		"emotion1": Globals.KeyEm1,
		"emotion2": Globals.KeyEm2,
		"emotion3": Globals.KeyEm3,
		"emotion4": Globals.KeyIdle,
		"hidegui": Globals.KeyHide,
	}
	for tid: String in binds:
		var panel := findTextpanel(tid)
		if panel:
			panel.text = GM.keycode_to_key(binds[tid])


func findButton(tid: String) -> GMNode:
	for b in GMNode.all_of("obj_menu_button"):
		if b.tid == tid:
			return b
	return null


func findTextbox(tid) -> GMNode:
	for b in GMNode.all_of("obj_menu_textbox"):
		if b.tid == tid:
			return b
	return null


func findTextpanel(tid: String) -> GMNode:
	for b in GMNode.all_of("obj_menu_textpanel"):
		if b.tid == tid:
			return b
	return null


func _set_layer_visible(name_: String, vis: bool) -> void:
	if layers.has(name_):
		layers[name_].visible = vis


func _button_iterate(_bid: int, _bcolumn: Variant, dir: int, anim: bool, press: bool) -> void:
	# Shared core of buttonSelected/buttonPressed with()-loops.
	var found := false
	for b in GMNode.all_of("obj_menu_button"):
		if b.submenu != submenu:
			b.image_blend = GM.C_WHITE
			continue
		if b.bcolumn != _bcolumn and b.bcolumn != -1 and _bcolumn != -1:
			b.image_blend = GM.C_WHITE
			continue
		if b.bid != _bid:
			b.image_blend = GM.C_WHITE
			continue
		if not press:
			# --- buttonSelected body ---
			if b.bcolumn == -1 and dir != 0 and bSelectedColumn == -1:
				bSelectedColumn = -1
				_bcolumn = b.bcolumn
				return
			if _bcolumn == -1 and b.bcolumn != -1 and b.bcolumn != 0:
				continue
			if found:
				continue
			bSelectedColumn = b.bcolumn
			_bcolumn = b.bcolumn
			found = true
			if b.gm_object_name() != "obj_menu_skin":
				b.image_blend = Color("910000")
			if anim:
				b.offset = 3
		else:
			# --- buttonPressed body ---
			if (
				b.gm_object_name() == "obj_menu_skin"
				or b.gm_object_name() == "obj_menu_icon"
				or b.gm_object_name() == "obj_menu_taunt"
				or b.gm_object_name() == "obj_menu_pet"
			):
				b.click()
				return
			if b.gm_object_name() == "obj_menu_togglebutton":
				b.state = not b.state
			break


func buttonSelected(_bid: int, _bcolumn: Variant, dir: int, anim: bool) -> void:
	if bind:
		return
	bSelected = _bid
	for tb in GMNode.all_of("obj_menu_textbox"):
		if tb.bid != _bid:
			continue
		if tb.submenu != submenu:
			continue
		GM.keyboard_string = tb.text
		break
	match submenu:
		SUBMENU_JOIN, SUBMENU_JOIN_MOBILE:
			if _bid == 1:
				bColumnCount = 5
			elif _bid == 2:
				if _bcolumn is int and _bcolumn >= 2:
					_bcolumn = 0
				bColumnCount = 2
	_button_iterate(_bid, _bcolumn, dir, anim, false)


func buttonPressed(_bid: int, _bcolumn: Variant) -> void:
	if buttonA:
		return
	if bind:
		return
	if bSelected != _bid:
		buttonSelected(_bid, _bcolumn, 0, true)
	buttonA = true
	_button_iterate(_bid, _bcolumn, 0, false, true)
	GameAudio.play_sound("snd_menu_press")

	match submenu:
		SUBMENU_NONE:
			match _bid:
				0:
					changeSubmenu(SUBMENU_JOIN)
				1:
					changeSubmenu(SUBMENU_OPTIONSGENERAL)
					buttonSelected(4, -1, 0, false)
				2:
					changeSubmenu(SUBMENU_EXTRA_ACHIVEMENTS)
				3:
					changeSubmenu(SUBMENU_MECH_SPIN)
					buttonSelected(1, -1, 0, false)
				4:
					get_tree().quit()
		SUBMENU_JOIN, SUBMENU_JOIN_MOBILE:
			if _bid == 0:
				for tb in GMNode.all_of("obj_menu_textbox"):
					if tb.bid != _bid:
						continue
					if tb.submenu != submenu:
						continue
					Net.join(tb.text)
					break
			elif _bid == 2:
				changeSubmenu(SUBMENU_NONE)
			else:
				var server_ips := [
					"155.138.243.246",
					"216.238.117.232",
					"185.114.72.187",
					"45.95.203.244",
					"194.36.178.150"
				]
				if _bcolumn is int and _bcolumn >= 0 and _bcolumn < server_ips.size():
					Net.join(server_ips[_bcolumn])
		SUBMENU_OPTIONSGENERAL:
			if _bid == 2:
				var ping_b := findButton("ping")
				if ping_b:
					GameConfig.showPing = ping_b.state
				GameConfig.save()
			if _bid == 3:
				var fps_b := findButton("fps")
				if fps_b:
					GameConfig.showFps = fps_b.state
				GameConfig.save()
			if _bcolumn == 1:
				if _bid == 4:
					changeSubmenu(SUBMENU_OPTIONSCONTROLS)
					buttonSelected(8, -1, 0, false)
				if _bid == 5:
					changeSubmenu(SUBMENU_NONE)
		SUBMENU_OPTIONSCONTROLS:
			if _bcolumn == 2:
				if _bid == 9:
					changeSubmenu(SUBMENU_OPTIONSGENERAL)
					buttonSelected(4, -1, 0, false)
				elif _bid == 10:
					changeSubmenu(SUBMENU_NONE)
			else:
				if _bid == 10:
					return
				if _bid == 9:
					bindChanged("left", GM.VK_LEFT)
					bindChanged("right", GM.VK_RIGHT)
					bindChanged("up", GM.VK_UP)
					bindChanged("down", GM.VK_DOWN)
					bindChanged("jump", 90)
					bindChanged("special1", 88)
					bindChanged("special2", 67)
					bindChanged("emotion1", 65)
					bindChanged("emotion2", 83)
					bindChanged("emotion3", 68)
					bindChanged("emotion4", 87)
					bindChanged("hidegui", GM.VK_LCONTROL)
					bindChanged("playerlist", GM.VK_TAB)
					return
				bind = true
				if _bcolumn == 0:
					match _bid:
						0:
							bindBtn = "up"
						1:
							bindBtn = "down"
						2:
							bindBtn = "left"
						3:
							bindBtn = "right"
				elif _bcolumn == 1:
					match _bid:
						0:
							bindBtn = "jump"
						1:
							bindBtn = "special1"
						2:
							bindBtn = "special2"
						3:
							bindBtn = "hidegui"
				else:
					match _bid:
						4:
							bindBtn = "playerlist"
						5:
							bindBtn = "emotion1"
						6:
							bindBtn = "emotion2"
						7:
							bindBtn = "emotion3"
						8:
							bindBtn = "emotion4"
				var panel := findTextpanel(bindBtn)
				if panel:
					panel.text = "press..."
		SUBMENU_OPTIONSCONTROLSMOBILE:
			if _bid == 1:
				GameConfig.dpadX = 68
				GameConfig.dpadY = 187
				GameConfig.jScale = 1
				GameConfig.jOpacity = 0.6
				GameConfig.bAX = 378
				GameConfig.bAY = 221
				GameConfig.bAScale = 1
				GameConfig.bAOpacity = 0.6
				GameConfig.bBX = 416
				GameConfig.bBY = 171
				GameConfig.bBScale = 1
				GameConfig.bBOpacity = 0.6
				GameConfig.bCX = 452
				GameConfig.bCY = 221
				GameConfig.bCScale = 1
				GameConfig.bCOpacity = 0.6
				GameConfig.bDX = 466
				GameConfig.bDY = 48
				GameConfig.bDScale = 1
				GameConfig.bDOpacity = 0.6
				GameConfig.bEX = 466
				GameConfig.bEY = 80
				GameConfig.bEScale = 1
				GameConfig.bEOpacity = 0.6
				GameConfig.bFX = 466
				GameConfig.bFY = 112
				GameConfig.bFScale = 1
				GameConfig.bFOpacity = 0.6
				GameConfig.bWX = 466
				GameConfig.bWY = 144
				GameConfig.bWScale = 1
				GameConfig.bWOpacity = 0.6
				GameConfig.bGX = 23
				GameConfig.bGY = 51
				GameConfig.bGScale = 1
				GameConfig.bGOpacity = 0.6
				GameConfig.save()
			elif _bid == 2:
				changeSubmenu(SUBMENU_OPTIONSGENERAL)
		SUBMENU_OPTIONSBACK:
			if _bid == 1:
				changeSubmenu(SUBMENU_OPTIONSGENERAL)
				buttonSelected(4, -1, 0, false)
			elif _bid == 2:
				changeSubmenu(SUBMENU_OPTIONSCONTROLS)
				buttonSelected(8, -1, 0, false)
			else:
				changeSubmenu(SUBMENU_NONE)
		SUBMENU_ABOUT_CREDITS:
			if _bid == 1:
				changeSubmenu(SUBMENU_NONE)
			elif _bid == 2:
				changeSubmenu(SUBMENU_CHAR_TAILS)
				buttonSelected(1, 0, -1, false)
			elif _bid == 3:
				changeSubmenu(SUBMENU_MECH_SPIN)
				buttonSelected(1, 0, -1, false)
		SUBMENU_ABOUT_BACK:
			if _bid == 0:
				changeSubmenu(SUBMENU_NONE)
			if _bid == 1:
				changeSubmenu(SUBMENU_ABOUT_CREDITS)
			elif _bid == 2:
				changeSubmenu(SUBMENU_CHAR_TAILS)
				buttonSelected(1, 0, -1, false)
			elif _bid == 3:
				changeSubmenu(SUBMENU_MECH_SPIN)
				buttonSelected(1, 0, -1, false)
		SUBMENU_MECH_SPIN, SUBMENU_MECH_STEAL, SUBMENU_MECH_HIT, SUBMENU_MECH_PAR, SUBMENU_MECH_RINGS, SUBMENU_MECH_REB, SUBMENU_MECH_REDRINGS, SUBMENU_MECH_DEMON, SUBMENU_MECH_SUDDEN, SUBMENU_MECH_ESCAPE, SUBMENU_MECH_DIFF:
			if _bid == 2:
				changeSubmenu(SUBMENU_CHAR_TAILS)
				buttonSelected(1, 0, -1, false)
			elif _bid == 3:
				changeSubmenu(SUBMENU_ABOUT_CREDITS)
			elif _bid == 4:
				changeSubmenu(SUBMENU_NONE)
			if _bcolumn != 1:
				return
			if _bid == 1:
				if submenu + 1 > SUBMENU_MECH_DIFF:
					changeSubmenu(SUBMENU_MECH_SPIN)
					return
				changeSubmenu(submenu + 1)
			else:
				if submenu - 1 < SUBMENU_MECH_SPIN:
					changeSubmenu(SUBMENU_MECH_DIFF)
					return
				changeSubmenu(submenu - 1)
			for g in GMNode.all_of("obj_menu_gif"):
				g.image_index = 0
		SUBMENU_CHAR_TAILS, SUBMENU_CHAR_KNUX, SUBMENU_CHAR_EGG, SUBMENU_CHAR_AMY, SUBMENU_CHAR_SALLY, SUBMENU_CHAR_CREAM, SUBMENU_CHAR_EXE, SUBMENU_CHAR_CHAOS, SUBMENU_CHAR_EXETIOR, SUBMENU_CHAR_EXELLER:
			if _bid == 2:
				changeSubmenu(SUBMENU_MECH_SPIN)
				buttonSelected(1, 0, -1, false)
			elif _bid == 3:
				changeSubmenu(SUBMENU_ABOUT_CREDITS)
			elif _bid == 4:
				changeSubmenu(SUBMENU_NONE)
			if _bcolumn != 1:
				return
			if _bid == 1:
				if submenu + 1 > SUBMENU_CHAR_EXELLER:
					changeSubmenu(SUBMENU_CHAR_TAILS)
					return
				changeSubmenu(submenu + 1)
			else:
				if submenu - 1 < SUBMENU_CHAR_TAILS:
					changeSubmenu(SUBMENU_CHAR_EXELLER)
					return
				changeSubmenu(submenu - 1)
		SUBMENU_EXTRA_ACHIVEMENTS:
			match _bid:
				1:
					changeSubmenu(SUBMENU_EXTRA_TAILS)
					buttonSelected(3, -1, 0, false)
				2:
					changeSubmenu(SUBMENU_EXTRA_SKINS1)
					buttonSelected(3, -1, 0, false)
				3:
					changeSubmenu(SUBMENU_EXTRA_PENIS)
					buttonSelected(2, -1, 0, false)
				4:
					changeSubmenu(SUBMENU_EXTRA_TAUNT)
					buttonSelected(2, -1, 0, false)
				5:
					changeSubmenu(SUBMENU_NONE)
		SUBMENU_EXTRA_BACK:
			match _bid:
				0:
					changeSubmenu(SUBMENU_NONE)
				1:
					changeSubmenu(SUBMENU_EXTRA_TAILS)
					buttonSelected(3, -1, 0, false)
				2:
					changeSubmenu(SUBMENU_EXTRA_SKINS1)
					buttonSelected(3, -1, 0, false)
				3:
					changeSubmenu(SUBMENU_EXTRA_PENIS)
					buttonSelected(2, -1, 0, false)
				4:
					changeSubmenu(SUBMENU_EXTRA_TAUNT)
					buttonSelected(2, -1, 0, false)
				5:
					changeSubmenu(SUBMENU_EXTRA_ACHIVEMENTS)
					buttonSelected(1, 0, -1, false)
			return
		SUBMENU_EXTRA_TAILS, SUBMENU_EXTRA_KNUX, SUBMENU_EXTRA_EGG, SUBMENU_EXTRA_AMY, SUBMENU_EXTRA_CREAM, SUBMENU_EXTRA_SALLY, SUBMENU_EXTRA_EXE, SUBMENU_EXTRA_CHAOS, SUBMENU_EXTRA_EXETIOR, SUBMENU_EXTRA_EXELLER:
			if _bcolumn == 5:
				match _bid:
					0:
						changeSubmenu(SUBMENU_EXTRA_ACHIVEMENTS)
						buttonSelected(0, -1, 0, false)
					1:
						changeSubmenu(SUBMENU_EXTRA_SKINS1)
						buttonSelected(3, -1, 0, false)
					2:
						changeSubmenu(SUBMENU_EXTRA_PENIS)
						buttonSelected(2, -1, 0, false)
					3:
						changeSubmenu(SUBMENU_EXTRA_TAUNT)
						buttonSelected(2, -1, 0, false)
					4:
						changeSubmenu(SUBMENU_NONE)
			if _bcolumn != 4:
				return
			if _bid == 1:
				if submenu + 1 > SUBMENU_EXTRA_EXELLER:
					changeSubmenu(SUBMENU_EXTRA_TAILS)
					buttonSelected(0, -1, 0, false)
					return
				changeSubmenu(submenu + 1)
			else:
				if submenu - 1 < SUBMENU_EXTRA_TAILS:
					changeSubmenu(SUBMENU_EXTRA_EXELLER)
					return
				changeSubmenu(submenu - 1)
		SUBMENU_EXTRA_SKINS1:
			if _bcolumn == 5:
				match _bid:
					0:
						changeSubmenu(SUBMENU_EXTRA_ACHIVEMENTS)
						buttonSelected(1, 0, -1, false)
						return
					1:
						changeSubmenu(SUBMENU_EXTRA_TAILS)
						buttonSelected(3, -1, 0, false)
					2:
						changeSubmenu(SUBMENU_EXTRA_PENIS)
						buttonSelected(2, -1, 0, false)
					3:
						changeSubmenu(SUBMENU_EXTRA_TAUNT)
						buttonSelected(2, -1, 0, false)
					4:
						changeSubmenu(SUBMENU_NONE)
			if _bcolumn != 4:
				return
			if _bid == 4:
				changeSubmenu(SUBMENU_EXTRA_SKINS2)
			else:
				changeSubmenu(SUBMENU_EXTRA_SKINS3)
		SUBMENU_EXTRA_SKINS2:
			if _bcolumn == 5:
				match _bid:
					0:
						changeSubmenu(SUBMENU_EXTRA_ACHIVEMENTS)
						buttonSelected(1, 0, -1, false)
						return
					1:
						changeSubmenu(SUBMENU_EXTRA_TAILS)
						buttonSelected(3, -1, 0, false)
					2:
						changeSubmenu(SUBMENU_EXTRA_PENIS)
						buttonSelected(2, -1, 0, false)
					3:
						changeSubmenu(SUBMENU_EXTRA_TAUNT)
						buttonSelected(2, -1, 0, false)
					4:
						changeSubmenu(SUBMENU_NONE)
			if _bcolumn != 4:
				return
			if _bid == 4:
				changeSubmenu(SUBMENU_EXTRA_SKINS1)
			else:
				changeSubmenu(SUBMENU_EXTRA_SKINS3)
		SUBMENU_EXTRA_SKINS3:
			if _bcolumn == 5:
				match _bid:
					0:
						changeSubmenu(SUBMENU_EXTRA_ACHIVEMENTS)
						buttonSelected(1, 0, -1, false)
						return
					1:
						changeSubmenu(SUBMENU_EXTRA_TAILS)
						buttonSelected(3, -1, 0, false)
					2:
						changeSubmenu(SUBMENU_EXTRA_PENIS)
						buttonSelected(2, -1, 0, false)
					3:
						changeSubmenu(SUBMENU_EXTRA_TAUNT)
						buttonSelected(2, -1, 0, false)
					4:
						changeSubmenu(SUBMENU_NONE)
			if _bcolumn != 4:
				return
			if _bid == 4:
				changeSubmenu(SUBMENU_EXTRA_SKINS1)
			else:
				changeSubmenu(SUBMENU_EXTRA_SKINS2)
		SUBMENU_EXTRA_PENIS:
			if _bcolumn != 5:
				return
			match _bid:
				0:
					changeSubmenu(SUBMENU_EXTRA_ACHIVEMENTS)
					buttonSelected(1, 0, -1, false)
				1:
					changeSubmenu(SUBMENU_EXTRA_TAILS)
					buttonSelected(3, -1, 0, false)
				2:
					changeSubmenu(SUBMENU_EXTRA_SKINS1)
					buttonSelected(3, -1, 0, false)
					return
				3:
					changeSubmenu(SUBMENU_EXTRA_TAUNT)
					buttonSelected(2, -1, 0, false)
				4:
					changeSubmenu(SUBMENU_NONE)
			return
		SUBMENU_EXTRA_TAUNT:
			if _bcolumn != 5:
				return
			match _bid:
				3:
					changeSubmenu(SUBMENU_EXTRA_ACHIVEMENTS)
					buttonSelected(1, 0, -1, false)
				4:
					changeSubmenu(SUBMENU_EXTRA_TAILS)
					buttonSelected(3, -1, 0, false)
				5:
					changeSubmenu(SUBMENU_EXTRA_SKINS1)
					buttonSelected(3, -1, 0, false)
					return
				6:
					changeSubmenu(SUBMENU_EXTRA_PENIS)
					buttonSelected(2, -1, 0, false)
				7:
					changeSubmenu(SUBMENU_NONE)


func buttonListed(_bid: int, _bcolumn: Variant, dir: bool) -> bool:
	match submenu:
		SUBMENU_OPTIONSGENERAL:
			if _bid == 1:
				if dir:
					GameConfig.screenMode += 1
					if GameConfig.screenMode > 3:
						GameConfig.screenMode = 0
				else:
					GameConfig.screenMode -= 1
					if GameConfig.screenMode < 0:
						GameConfig.screenMode = 3
				GameConfig.apply_res()
				GameConfig.save()
				return true
			else:
				if _bid != 4:
					return false
				if _bcolumn is int and _bcolumn > -1:
					return false
				if dir:
					changeSubmenu(SUBMENU_OPTIONSCONTROLS)
					buttonSelected(10, -1, -1, true)
				else:
					changeSubmenu(SUBMENU_OPTIONSBACK)
					buttonSelected(0, -1, 0, true)
				return true
		SUBMENU_OPTIONSCONTROLS:
			if _bid != 10:
				return false
			if dir:
				changeSubmenu(SUBMENU_OPTIONSBACK)
				buttonSelected(0, -1, 0, true)
			else:
				changeSubmenu(SUBMENU_OPTIONSGENERAL)
				buttonSelected(4, -1, 0, true)
			return true
		SUBMENU_OPTIONSBACK:
			if dir:
				changeSubmenu(SUBMENU_OPTIONSGENERAL)
				buttonSelected(4, -1, 0, true)
			else:
				changeSubmenu(SUBMENU_OPTIONSCONTROLS)
				buttonSelected(10, -1, -1, true)
			return true
		SUBMENU_MECH_SPIN, SUBMENU_MECH_STEAL, SUBMENU_MECH_HIT, SUBMENU_MECH_PAR, SUBMENU_MECH_RINGS, SUBMENU_MECH_REB, SUBMENU_MECH_REDRINGS, SUBMENU_MECH_DEMON, SUBMENU_MECH_SUDDEN, SUBMENU_MECH_ESCAPE, SUBMENU_MECH_DIFF:
			if _bid == 0:
				if dir:
					if submenu + 1 > SUBMENU_MECH_DIFF:
						changeSubmenu(SUBMENU_MECH_SPIN)
						return false
					changeSubmenu(submenu + 1)
				else:
					if submenu - 1 < SUBMENU_MECH_SPIN:
						changeSubmenu(SUBMENU_MECH_DIFF)
						return false
					changeSubmenu(submenu - 1)
				for g in GMNode.all_of("obj_menu_gif"):
					g.image_index = 0
			else:
				if dir:
					changeSubmenu(SUBMENU_CHAR_TAILS)
					buttonSelected(1, 0, -1, true)
				else:
					changeSubmenu(SUBMENU_ABOUT_BACK)
			return false
		SUBMENU_CHAR_TAILS, SUBMENU_CHAR_KNUX, SUBMENU_CHAR_EGG, SUBMENU_CHAR_AMY, SUBMENU_CHAR_SALLY, SUBMENU_CHAR_CREAM, SUBMENU_CHAR_EXE, SUBMENU_CHAR_CHAOS, SUBMENU_CHAR_EXETIOR, SUBMENU_CHAR_EXELLER:
			if _bid == 0:
				if dir:
					if submenu + 1 > SUBMENU_CHAR_EXELLER:
						changeSubmenu(SUBMENU_CHAR_TAILS)
						return false
					changeSubmenu(submenu + 1)
				else:
					if submenu - 1 < SUBMENU_CHAR_TAILS:
						changeSubmenu(SUBMENU_CHAR_EXELLER)
						return false
					changeSubmenu(submenu - 1)
				for g in GMNode.all_of("obj_menu_gif"):
					g.image_index = 0
			else:
				if dir:
					changeSubmenu(SUBMENU_ABOUT_CREDITS)
				else:
					changeSubmenu(SUBMENU_MECH_SPIN)
					buttonSelected(1, 0, -1, false)
			return false
		SUBMENU_ABOUT_CREDITS:
			if dir:
				changeSubmenu(SUBMENU_ABOUT_BACK)
			else:
				changeSubmenu(SUBMENU_CHAR_TAILS)
				buttonSelected(1, 0, 0, true)
			return false
		SUBMENU_ABOUT_BACK:
			if dir:
				changeSubmenu(SUBMENU_MECH_SPIN)
				buttonSelected(1, 0, 0, true)
			else:
				changeSubmenu(SUBMENU_ABOUT_CREDITS)
			return false
		SUBMENU_EXTRA_ACHIVEMENTS:
			if dir:
				changeSubmenu(SUBMENU_EXTRA_TAILS)
				buttonSelected(3, -1, 0, true)
			else:
				changeSubmenu(SUBMENU_EXTRA_BACK)
			return true
		SUBMENU_EXTRA_BACK:
			if dir:
				changeSubmenu(SUBMENU_EXTRA_ACHIVEMENTS)
				buttonSelected(0, -1, 0, true)
			else:
				changeSubmenu(SUBMENU_EXTRA_TAUNT)
				buttonSelected(2, -1, 0, true)
			return true
		SUBMENU_EXTRA_TAILS, SUBMENU_EXTRA_KNUX, SUBMENU_EXTRA_EGG, SUBMENU_EXTRA_AMY, SUBMENU_EXTRA_CREAM, SUBMENU_EXTRA_SALLY, SUBMENU_EXTRA_EXE, SUBMENU_EXTRA_CHAOS, SUBMENU_EXTRA_EXETIOR, SUBMENU_EXTRA_EXELLER:
			if _bid == 0 and (_bcolumn is int and _bcolumn <= -1):
				if dir:
					if submenu + 1 > SUBMENU_EXTRA_EXELLER:
						changeSubmenu(SUBMENU_EXTRA_TAILS)
						buttonSelected(0, -1, 0, true)
						return false
					changeSubmenu(submenu + 1)
				else:
					if submenu - 1 < SUBMENU_EXTRA_TAILS:
						changeSubmenu(SUBMENU_EXTRA_EXELLER)
						return false
					changeSubmenu(submenu - 1)
			elif _bid == 3:
				if dir:
					changeSubmenu(SUBMENU_EXTRA_SKINS1)
					buttonSelected(3, -1, 0, true)
				else:
					changeSubmenu(SUBMENU_EXTRA_ACHIVEMENTS)
					buttonSelected(0, -1, 0, true)
			return false
		SUBMENU_EXTRA_SKINS1:
			if _bid == 3:
				if dir:
					changeSubmenu(SUBMENU_EXTRA_PENIS)
					buttonSelected(2, -1, 0, true)
				else:
					changeSubmenu(SUBMENU_EXTRA_TAILS)
					buttonSelected(3, -1, 0, true)
				return true
			elif _bid == 0:
				if dir:
					changeSubmenu(SUBMENU_EXTRA_SKINS2)
					buttonSelected(0, -1, 0, true)
				else:
					changeSubmenu(SUBMENU_EXTRA_SKINS3)
					buttonSelected(0, -1, 0, true)
			return false
		SUBMENU_EXTRA_SKINS2:
			if _bid == 3:
				if dir:
					changeSubmenu(SUBMENU_EXTRA_PENIS)
					buttonSelected(2, -1, 0, true)
				else:
					changeSubmenu(SUBMENU_EXTRA_TAILS)
					buttonSelected(3, -1, 0, true)
			elif _bid == 0:
				if dir:
					changeSubmenu(SUBMENU_EXTRA_SKINS3)
					buttonSelected(0, -1, 0, true)
				else:
					changeSubmenu(SUBMENU_EXTRA_SKINS1)
					buttonSelected(0, -1, 0, true)
				return true
			return false
		SUBMENU_EXTRA_SKINS3:
			if _bid == 2:
				if dir:
					changeSubmenu(SUBMENU_EXTRA_PENIS)
					buttonSelected(2, -1, 0, true)
					return true
				else:
					changeSubmenu(SUBMENU_EXTRA_TAILS)
					buttonSelected(3, -1, 0, true)
			elif _bid == 0:
				if dir:
					changeSubmenu(SUBMENU_EXTRA_SKINS1)
					buttonSelected(0, -1, 0, true)
				else:
					changeSubmenu(SUBMENU_EXTRA_SKINS2)
					buttonSelected(0, -1, 0, true)
			return false
		SUBMENU_EXTRA_PENIS:
			if _bid == 2:
				if dir:
					changeSubmenu(SUBMENU_EXTRA_TAUNT)
					buttonSelected(2, -1, 0, true)
					return true
				else:
					changeSubmenu(SUBMENU_EXTRA_SKINS1)
					buttonSelected(3, -1, 0, true)
			return false
		SUBMENU_EXTRA_TAUNT:
			if _bid == 2:
				if dir:
					changeSubmenu(SUBMENU_EXTRA_BACK)
					return true
				else:
					changeSubmenu(SUBMENU_EXTRA_PENIS)
					buttonSelected(2, -1, 0, true)
			return false
	return false


func changeSubmenu(_menu: int) -> void:
	submenu = _menu
	for lname in [
		"Main",
		"Main2",
		"Main3",
		"JoinGame",
		"JoinGameMobile",
		"OptionsGeneral",
		"OptionsControls",
		"OptionsControlsMobile",
		"OptionsBack",
		"AboutSpin",
		"AboutHit",
		"AboutPar",
		"AboutReb",
		"AboutSteal",
		"AboutRings",
		"AboutRedRings",
		"AboutDemon",
		"AboutSudden",
		"AboutEscape",
		"AboutDiff",
		"AboutCredits",
		"AboutCreditsText",
		"AboutBack",
		"AboutTails",
		"AboutKnux",
		"AboutEgg",
		"AboutAmy",
		"AboutCream",
		"AboutSally",
		"AboutExe",
		"AboutChaos",
		"AboutExetior",
		"AboutExeller",
		"AboutCharacter",
		"ExtraAchivements",
		"ExtraAchivementsList",
		"Achivements",
		"ExtraTails",
		"ExtraKnux",
		"ExtraEgg",
		"ExtraAmy",
		"ExtraCream",
		"ExtraSally",
		"ExtraExe",
		"ExtraChaos",
		"ExtraExetior",
		"ExtraExeller",
		"ExtraBack",
		"ExtraSkins1",
		"ExtraSkins2",
		"ExtraSkins3",
		"ExtraMoney",
		"ExtraPenis",
		"ExtraTaunts"
	]:
		_set_layer_visible(lname, false)

	match submenu:
		SUBMENU_NONE:
			_bars_set(0)
			bCount = 5
			bColumnCount = 0
			scheme = false
			_set_layer_visible("Main", true)
			_set_layer_visible("Main2", true)
			_set_layer_visible("Main3", true)
		SUBMENU_JOIN:
			_bars_set(1)
			bCount = 3
			bColumnCount = 5
			scheme = true
			_set_layer_visible("JoinGame", true)
		SUBMENU_JOIN_MOBILE:
			_bars_set(1)
			bCount = 3
			bColumnCount = 5
			scheme = true
			_set_layer_visible("JoinGameMobile", true)
		SUBMENU_OPTIONSGENERAL:
			_bars_set(2)
			bCount = 5
			bColumnCount = 0
			scheme = true
			_set_layer_visible("OptionsGeneral", true)
		SUBMENU_OPTIONSCONTROLS:
			_bars_set(2)
			bCount = 11
			bColumnCount = 2
			scheme = true
			_set_layer_visible("OptionsControls", true)
		SUBMENU_OPTIONSCONTROLSMOBILE:
			_bars_set(3)
			bCount = 3
			bColumnCount = 0
			scheme = false
			_set_layer_visible("OptionsControlsMobile", true)
		SUBMENU_OPTIONSBACK:
			_bars_set(2)
			bCount = 1
			bColumnCount = 0
			scheme = true
			_set_layer_visible("OptionsBack", true)
		SUBMENU_MECH_SPIN:
			_mech_submenu("AboutSpin")
		SUBMENU_MECH_HIT:
			_mech_submenu("AboutHit")
		SUBMENU_MECH_PAR:
			_mech_submenu("AboutPar")
		SUBMENU_MECH_REB:
			_mech_submenu("AboutReb")
		SUBMENU_MECH_STEAL:
			_mech_submenu("AboutSteal")
		SUBMENU_MECH_RINGS:
			_mech_submenu("AboutRings")
		SUBMENU_MECH_REDRINGS:
			_mech_submenu("AboutRedRings")
		SUBMENU_MECH_DEMON:
			_mech_submenu("AboutDemon")
		SUBMENU_MECH_SUDDEN:
			_mech_submenu("AboutSudden")
		SUBMENU_MECH_ESCAPE:
			_mech_submenu("AboutEscape")
		SUBMENU_MECH_DIFF:
			_mech_submenu("AboutDiff")
		SUBMENU_CHAR_TAILS:
			_char_submenu("AboutTails", "spr_menu_tails")
		SUBMENU_CHAR_KNUX:
			_char_submenu("AboutKnux", "spr_menu_knux")
		SUBMENU_CHAR_EGG:
			_char_submenu("AboutEgg", "spr_menu_egg")
		SUBMENU_CHAR_AMY:
			_char_submenu("AboutAmy", "spr_menu_amy")
		SUBMENU_CHAR_CREAM:
			_char_submenu("AboutCream", "spr_menu_cream")
		SUBMENU_CHAR_SALLY:
			_char_submenu("AboutSally", "spr_menu_sally")
		SUBMENU_CHAR_EXE:
			_char_submenu("AboutExe", "spr_menu_exe")
		SUBMENU_CHAR_CHAOS:
			_char_submenu("AboutChaos", "spr_menu_chaos")
		SUBMENU_CHAR_EXETIOR:
			_char_submenu("AboutExetior", "spr_menu_exetior")
		SUBMENU_CHAR_EXELLER:
			_char_submenu("AboutExeller", "spr_menu_exeller")
		SUBMENU_ABOUT_CREDITS:
			_bars_set(5)
			bCount = 1
			bColumnCount = 0
			scheme = true
			_set_layer_visible("AboutCredits", true)
			_set_layer_visible("AboutCreditsText", true)
			for c in GMNode.all_of("obj_menu_credits"):
				c.position.y = 196
			GM.keyboard_string = ""
		SUBMENU_ABOUT_BACK:
			_bars_set(0)
			bCount = 1
			bColumnCount = 0
			scheme = true
			_set_layer_visible("AboutBack", true)
			for c in GMNode.all_of("obj_menu_credits"):
				c.position.y = 196
		SUBMENU_EXTRA_ACHIVEMENTS:
			_bars_set(7)
			bCount = 1
			bColumnCount = 0
			scheme = true
			_set_layer_visible("Achivements", true)
			_set_layer_visible("ExtraMoney", true)
			_set_layer_visible("ExtraAchivements", true)
			_set_layer_visible("ExtraAchivementsList", true)
		SUBMENU_EXTRA_TAILS:
			_extra_char_submenu("ExtraTails")
		SUBMENU_EXTRA_KNUX:
			_extra_char_submenu("ExtraKnux")
		SUBMENU_EXTRA_EGG:
			_extra_char_submenu("ExtraEgg")
		SUBMENU_EXTRA_AMY:
			_extra_char_submenu("ExtraAmy")
		SUBMENU_EXTRA_CREAM:
			_extra_char_submenu("ExtraCream")
		SUBMENU_EXTRA_SALLY:
			_extra_char_submenu("ExtraSally")
		SUBMENU_EXTRA_EXE:
			_extra_char_submenu("ExtraExe")
		SUBMENU_EXTRA_CHAOS:
			_extra_char_submenu("ExtraChaos")
		SUBMENU_EXTRA_EXETIOR:
			_extra_char_submenu("ExtraExetior")
		SUBMENU_EXTRA_EXELLER:
			_extra_char_submenu("ExtraExeller")
		SUBMENU_EXTRA_SKINS1:
			_bars_set(6)
			bCount = 4
			bColumnCount = 5
			scheme = true
			_set_layer_visible("Achivements", true)
			_set_layer_visible("ExtraMoney", true)
			_set_layer_visible("ExtraSkins1", true)
		SUBMENU_EXTRA_SKINS2:
			_bars_set(6)
			bCount = 4
			bColumnCount = 5
			scheme = true
			_set_layer_visible("Achivements", true)
			_set_layer_visible("ExtraMoney", true)
			_set_layer_visible("ExtraSkins2", true)
		SUBMENU_EXTRA_SKINS3:
			_bars_set(6)
			bCount = 3
			bColumnCount = 5
			scheme = true
			_set_layer_visible("Achivements", true)
			_set_layer_visible("ExtraMoney", true)
			_set_layer_visible("ExtraSkins3", true)
		SUBMENU_EXTRA_BACK:
			_bars_set(6)
			bCount = 1
			bColumnCount = 0
			scheme = true
			_set_layer_visible("Achivements", true)
			_set_layer_visible("ExtraMoney", true)
			_set_layer_visible("ExtraBack", true)
		SUBMENU_EXTRA_PENIS:
			_bars_set(7)
			bCount = 3
			bColumnCount = 4
			scheme = true
			_set_layer_visible("Achivements", true)
			_set_layer_visible("ExtraMoney", true)
			_set_layer_visible("ExtraPenis", true)
		SUBMENU_EXTRA_TAUNT:
			_bars_set(7)
			bCount = 3
			bColumnCount = 4
			scheme = true
			_set_layer_visible("Achivements", true)
			_set_layer_visible("ExtraMoney", true)
			_set_layer_visible("ExtraTaunts", true)

	buttonSelected(0, -1, 0, false)


func _bars_set(index: int) -> void:
	if bars:
		bars.sprite_name = "spr_menu_bars"
		bars.image_index = index


func _mech_submenu(layer_name: String) -> void:
	_bars_set(4)
	bCount = 2
	bColumnCount = 0
	scheme = true
	_set_layer_visible(layer_name, true)


func _char_submenu(layer_name: String, char_sprite: String) -> void:
	_mech_submenu(layer_name)
	_set_layer_visible("AboutCharacter", true)
	for c in GMNode.all_of("obj_menu_character"):
		c.sprite_name = char_sprite


func _extra_char_submenu(layer_name: String) -> void:
	_bars_set(6)
	bCount = 4
	bColumnCount = 4
	scheme = true
	_set_layer_visible("Achivements", true)
	_set_layer_visible("ExtraMoney", true)
	_set_layer_visible(layer_name, true)


func textChanged(_bid: int, _text: String) -> void:
	if submenu == SUBMENU_JOIN or submenu == SUBMENU_JOIN_MOBILE:
		GameConfig.ip = _text.strip_edges()
		GameConfig.save()
	if submenu == SUBMENU_OPTIONSGENERAL:
		Globals.nickname = GameConfig.validate_nickname(_text)
		GameConfig.save()


func bindChanged(_bid: String, key: int) -> void:
	var panel := findTextpanel(_bid)
	if panel:
		panel.text = GM.keycode_to_key(key)
	match _bid:
		"up":
			Globals.KeyUp = key
		"down":
			Globals.KeyDown = key
		"left":
			Globals.KeyLeft = key
		"right":
			Globals.KeyRight = key
		"jump":
			Globals.KeyA = key
		"special1":
			Globals.KeyB = key
		"special2":
			Globals.KeyC = key
		"hidegui":
			Globals.KeyHide = key
		"playerlist":
			Globals.KeyPList = key
		"emotion1":
			Globals.KeyEm1 = key
		"emotion2":
			Globals.KeyEm2 = key
		"emotion3":
			Globals.KeyEm3 = key
		"emotion4":
			Globals.KeyIdle = key
	GameConfig.save()


func sliderChanged(_value: float) -> void:
	if submenu != SUBMENU_OPTIONSCONTROLSMOBILE:
		return
	for control in get_tree().get_nodes_in_group("menu_mobile_editor"):
		if control.bid == mobSelectedButton:
			GameConfig.buttonSetProp(mobSelectedButton, control.scale_v, _value)
			control._sync_layout()


func _gm_step() -> void:
	buttonA = false

	# menu (headless 2-client testing without mouse clicks); once per process —
	# a menu reload after net_reset must not re-join
	if bind:
		if GM.key_pressed(GM.VK_ANYKEY):
			bindChanged(bindBtn, GM.keyboard_lastkey)
			bind = false
		return

	if scheme:
		if kp(Globals.KeyUp):
			bSelected -= 1
			if bSelected < 0:
				bSelectedColumn = -1
				bSelected = bCount - 1
			buttonSelected(bSelected, bSelectedColumn, 0, true)
			GameAudio.play_sound("snd_menu_select")
		if kp(Globals.KeyDown):
			bSelected += 1
			if bSelected >= bCount:
				bSelected = 0
			buttonSelected(bSelected, bSelectedColumn, 0, true)
			GameAudio.play_sound("snd_menu_select")
		if kp(Globals.KeyLeft):
			bSelectedColumn -= 1
			if bSelectedColumn < 0:
				if not buttonListed(bSelected, bSelectedColumn, false):
					bSelectedColumn = bColumnCount - 1
			buttonSelected(bSelected, bSelectedColumn, -1, true)
			GameAudio.play_sound("snd_menu_select")
		if kp(Globals.KeyRight):
			var listed := false
			bSelectedColumn += 1
			if bSelectedColumn >= bColumnCount:
				if not buttonListed(bSelected, bSelectedColumn, true):
					bSelectedColumn = 0
				else:
					listed = true
			buttonSelected(bSelected, bSelectedColumn, 1, true)
			GameAudio.play_sound("snd_menu_select")
			if bSelectedColumn == -1 and not listed:
				buttonListed(bSelected, bSelectedColumn, true)
	else:
		if kp(Globals.KeyLeft):
			bSelected -= 1
			if bSelected < 0:
				bSelected = bCount - 1
			buttonSelected(bSelected, bSelectedColumn, 0, true)
			GameAudio.play_sound("snd_menu_select")
		if kp(Globals.KeyRight):
			bSelected += 1
			if bSelected >= bCount:
				bSelected = 0
			buttonSelected(bSelected, bSelectedColumn, 0, true)
			GameAudio.play_sound("snd_menu_select")

	if not ignoreButtons:
		if kp(Globals.KeyA):
			buttonPressed(bSelected, bSelectedColumn)
		if kp(Globals.KeyB):
			changeSubmenu(SUBMENU_NONE)

	if kp(GM.VK_ESCAPE):
		changeSubmenu(SUBMENU_NONE)
	if kp(GM.VK_ENTER):
		buttonPressed(bSelected, bSelectedColumn)

	# port of obj_menu Draw_76: resets at the end of every frame
	ignoreButtons = false
