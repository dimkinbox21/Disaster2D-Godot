extends Node2D
## Darkness overlay drawer for obj_dotdotdot_i (lives in the HUD CanvasLayer).
## The controller's _gm_draw delegates here so the overlays stay screen-fixed.

var ctrl: Node = null


func _physics_process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	if ctrl == null or not is_instance_valid(ctrl):
		return
	if ctrl.bgnew == "background_dotdotdot":
		if ctrl.fade3 > 0:
			ctrl.fade3 -= 0.025
		if ctrl.fade2 > 0:
			ctrl.fade2 -= 0.025
	elif ctrl.bgnew == "background_dotdotdot2":
		if ctrl.fade3 > 0:
			ctrl.fade3 -= 0.025
		if ctrl.fade2 < 1:
			ctrl.fade2 += 0.025
	elif ctrl.bgnew == "background_dotdotdot3":
		if ctrl.fade3 < 1:
			ctrl.fade3 += 0.025
		if ctrl.fade2 > 0:
			ctrl.fade2 -= 0.025
	if OS.get_environment("NO_DARKNESS") == "1":
		return
	var o2 = GM.sprite_texture("spr_screenoverlay2", 0)
	var o3 = GM.sprite_texture("spr_screenoverlay2", 1)
	if o2 and ctrl.fade2 > 0:
		draw_texture_rect(o2, Rect2(0, 0, 480, 270), false, Color(1, 1, 1, ctrl.fade2))
	if o3 and ctrl.fade3 > 0:
		draw_texture_rect(o3, Rect2(0, 0, 480, 270), false, Color(1, 1, 1, ctrl.fade3))
