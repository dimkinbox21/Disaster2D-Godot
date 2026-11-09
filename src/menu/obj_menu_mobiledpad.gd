extends GMNode
## Port of obj_menu_mobiledpad — mobile touch controls editor (visual parity on
## the OptionsControlsMobile screen; drag tuning is desktop-mouse compatible).

var scale_v := 1.0
var dragTime := 0
var tapTimer := 0
var tapCount := 0

func _ready() -> void:
	super._ready()
	z_index = clampi(9999, -4096, 4096)
	image_alpha = 0.5

func _gm_draw() -> void:
	var menu: GMNode = null
	for m in GMNode.all_of("obj_menu"):
		menu = m
		break
	if menu and not menu.layers.get("OptionsControlsMobile", self).visible:
		return
	position = Vector2(GameConfig.dpadX, GameConfig.dpadY)
	scale_v = GameConfig.jScale
	image_alpha = GameConfig.jOpacity
	image_xscale = scale_v
	image_yscale = scale_v
	draw_self()
