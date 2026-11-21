extends GMNode
## Original mobile layout editor: hold 20 ticks to drag, double-tap to resize.
@export_storage var bid := 0
var scale_v := 1.0
var dragTime := 0
var tapTimer := 0
var tapCount := 0


func _ready():
	super._ready()
	z_index = 4096
	image_alpha = .5
	add_to_group("menu_mobile_editor")


func _menu():
	for menu in GMNode.all_of("obj_menu"):
		return menu
	return null


func _prop() -> Array:
	return [GameConfig.dpadX, GameConfig.dpadY, GameConfig.jScale, GameConfig.jOpacity]


func _sync_layout():
	var values = _prop()
	position = Vector2(values[0], values[1])
	scale_v = values[2]
	image_alpha = values[3]
	image_xscale = scale_v
	image_yscale = scale_v


func _gm_step():
	var menu = _menu()
	if menu == null or menu.submenu != menu.SUBMENU_OPTIONSCONTROLSMOBILE:
		return
	_sync_layout()
	if GM.mouse_released(2) and position_meeting(GM.mouse_x, GM.mouse_y):
		menu.mobSelectedButton = bid
		for slider in GMNode.all_of("obj_menu_slider"):
			slider.value = image_alpha
		tapCount += 1
		if tapCount >= 2:
			scale_v += .5
			if scale_v > 1.5:
				scale_v = .5
			GameConfig.buttonSetProp(bid, scale_v, image_alpha)
			tapCount = 0
		tapTimer = 10
	if tapTimer > 0:
		tapTimer -= 1
	else:
		tapCount = 0
	if GM.mouse_down(2):
		if dragTime < 20 and position_meeting(GM.mouse_x, GM.mouse_y):
			dragTime += 1
	else:
		dragTime = 0
	if dragTime >= 20:
		GameConfig.buttonSetPos(bid, GM.mouse_x, GM.mouse_y)
		for control in get_tree().get_nodes_in_group("menu_mobile_editor"):
			if control != self:
				control.dragTime = 0
	_sync_layout()
	queue_redraw()


func _gm_draw():
	var menu = _menu()
	if menu == null or menu.submenu != menu.SUBMENU_OPTIONSCONTROLSMOBILE:
		return
	draw_self()
