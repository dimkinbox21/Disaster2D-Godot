extends GMNode
## Port of obj_menu_mobilebutton / obj_menu_mobilebutton2.

var bid := 0
var scale_v := 1.0
var dragTime := 0
var tapTimer := 0
var tapCount := 0

func _ready() -> void:
	super._ready()
	z_index = clampi(9999, -4096, 4096)
	image_alpha = 0.5

func _prop() -> Array:
	match bid:
		1: return [GameConfig.bAX, GameConfig.bAY, GameConfig.bAScale, GameConfig.bAOpacity]
		2: return [GameConfig.bBX, GameConfig.bBY, GameConfig.bBScale, GameConfig.bBOpacity]
		3: return [GameConfig.bCX, GameConfig.bCY, GameConfig.bCScale, GameConfig.bCOpacity]
		4: return [GameConfig.bDX, GameConfig.bDY, GameConfig.bDScale, GameConfig.bDOpacity]
		5: return [GameConfig.bEX, GameConfig.bEY, GameConfig.bEScale, GameConfig.bEOpacity]
		6: return [GameConfig.bFX, GameConfig.bFY, GameConfig.bFScale, GameConfig.bFOpacity]
		7: return [GameConfig.bGX, GameConfig.bGY, GameConfig.bGScale, GameConfig.bGOpacity]
		8: return [GameConfig.bWX, GameConfig.bWY, GameConfig.bWScale, GameConfig.bWOpacity]
	return [0, 0, 1, 0.5]

func _gm_draw() -> void:
	var menu: GMNode = null
	for m in GMNode.all_of("obj_menu"):
		menu = m
		break
	if menu and not menu.layers.get("OptionsControlsMobile", self).visible:
		return
	var p := _prop()
	position = Vector2(p[0], p[1])
	scale_v = p[2]
	image_alpha = p[3]
	image_xscale = scale_v
	image_yscale = scale_v
	draw_self()
