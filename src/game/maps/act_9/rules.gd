extends "res://src/game/maps/shared/rules.gd"
## Act 9: presentation and network effects.


func _ready() -> void:
	process_physics_priority = 60
	z_index = -250



func wall_packet(id: int, xx: int, yy: int) -> void:
	for wall in GMNode.all_of("obj_act9_wall"):
		if wall.nid != id:
			continue
		wall.move_wall(
			(
				Vector2(-2240, yy - 768)
				if id == 0
				else (Vector2(xx - 2240, yy) if id == 1 else Vector2(3072 - xx, yy))
			)
		)


func relocate(p: GMNode, at: Vector2) -> void:
	p.position = at
	p.xspd = 0
	p.gspd = 0
	p.yspd = 0
	p.isHurt = false
	p.hurttime = 0
	p.isSliding = false
	p.isStuck = false
	p.isGliding = false
	p.isZipline = false
	p.isGrounded = false
	p.isLookingDown = false
	p.isLookingUp = false


func resolve_walls(p: GMNode) -> bool:
	var left := -64.0
	var right := 3072.0
	var ceiling := 0.0
	for wall in GMNode.all_of("obj_act9_wall"):
		var rect: Rect2 = wall.bbox_rect()
		match wall.nid:
			0:
				ceiling = rect.end.y
			1:
				left = rect.end.x
			2:
				right = rect.position.x
	var crushed := p.position.y <= ceiling + 8 or right - left < 16
	if p.position.x - 8 <= left:
		p.position.x = ceilf(left) + 8
		crushed = (
			crushed
			or p.position.x + 8 >= right
			or GMFloor.point_meeting_floor(p.position.x + 8, p.position.y - 4)
		)
	if p.position.x + 8 >= right:
		p.position.x = ceilf(right) - 8
		crushed = (
			crushed
			or p.position.x - 8 <= left
			or GMFloor.point_meeting_floor(p.position.x - 8, p.position.y - 4)
		)
	if p.position.y <= ceiling + 16:
		p.position.y = ceiling + 16
	if crushed:
		if not p.isDead and Globals.character != 0 and p.revivalTimes < 2:
			p.player_instakill()
		relocate(p, Vector2(1535, 943))
	return crushed


func _physics_process(_dt: float) -> void:
	frame += 1
	flash = maxf(0, flash - 0.1)
	var p: GMNode = Globals.player
	if not is_instance_valid(p):
		return
	if Net.gameEnds:
		return
	resolve_walls(p)


func _draw() -> void:
	return


func _process(_dt: float) -> void:
	return
