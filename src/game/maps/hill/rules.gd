extends "res://src/game/maps/shared/rules.gd"
## Hill: presentation and network effects.
var tick := 0
var particles: Array = []
var in_water := false
var electro := false


func _ready():
	process_physics_priority = 60
	z_index = 200
	# Original obj_ghz_water Draw draws only electricity; its green mask is hidden.
	for water in GMNode.all_of("obj_ghz_water"):
		water.gm_visible = false
	var audio := AudioStreamPlayer.new()
	audio.stream = GameAudio._stream("snd_rain").duplicate()
	audio.stream.set("loop", true)
	audio.add_to_group("game_positional_sound")
	add_child(audio)
	audio.play()


func effect(sprite: String, at: Vector2, motion := Vector2.ZERO):
	var debris := sprite.ends_with("_part")
	var fx = (
		load("res://src/game/maps/debris.gd" if debris else "res://src/game/obj_quickfx.gd").new()
	)
	fx.sprite_name = sprite
	fx.position = at
	fx.motion = motion
	if debris:
		fx.image_index = randi_range(0, GM.sprite_count(sprite) - 1)
		fx.image_speed = 0
	else:
		fx.fade = false
	map.add_child(fx)


func thunder(state: int):
	electro = state == 0
	if electro:
		flash = 1
		GameAudio.play_sound("snd_thunder")


func _physics_process(_dt):
	tick += 1
	flash = maxf(0, flash - 0.016)
	var p: GMNode = Globals.player
	if not is_instance_valid(p) or Net.gameEnds:
		return
	var touching := false
	for water in GMNode.all_of("obj_ghz_water"):
		var area: Rect2 = water.bbox_rect()
		if area.intersects(Rect2(p.position + Vector2(-6, 17), Vector2(12, 3))):
			touching = true
			p.apply_slow(30, 0.6)
			if in_water != touching:
				GameAudio.play_sound_at("snd_watersplash", p.position)
				effect("spr_watersplash", Vector2(p.position.x, area.position.y))
	if in_water and not touching:
		GameAudio.play_sound_at("snd_watersplash", p.position)
		effect("spr_watersplash", p.position)
	in_water = touching
	for wave in GMNode.all_of("obj_ghz_wave"):
		wave.position.y = wave._start.y + sin(Time.get_ticks_msec() / 250.0) * 2
		wave.queue_redraw()
	weather(p)


func weather(p):
	var camera := Vector2.ZERO
	for c in GMNode.all_of("obj_camera"):
		camera = c.render_origin
	var inside := false
	for zone in GMNode.all_of("obj_nap_trigger"):
		if zone.bbox_rect().intersects(p.bbox_rect()):
			inside = true
	if not inside:
		for i in 10 if map.lvl_id == 12 else 5:
			particles.append(
				{
					"at":
					(
						camera + Vector2(randf_range(-120, 560), -1)
						if i % 5 < 3
						else camera + Vector2(481, randf_range(-120, 350))
					),
					"speed": randf_range(-1, 0) if map.lvl_id == 12 else randf_range(-1, 1),
					"life": 90 if map.lvl_id == 12 else 120
				}
			)
	for i in range(particles.size() - 1, -1, -1):
		var a: Dictionary = particles[i]
		a.at += Vector2(-3 - a.speed, (5 if map.lvl_id == 12 else 2) + a.speed)
		a.life -= 1
		if a.life <= 0:
			particles.remove_at(i)
	queue_redraw()


func _draw():
	var texture := GM.sprite_texture("spr_ghz_rain" if map.lvl_id == 12 else "spr_nap_snow", 0)
	for item in particles:
		if texture != null:
			draw_texture(texture, item.at.floor())
	if electro:
		for water in GMNode.all_of("obj_ghz_water"):
			var area: Rect2 = water.bbox_rect()
			for xx in range(int(area.position.x), int(area.end.x) + 97, 97):
				draw_texture(
					GM.sprite_texture("spr_ghz_electroshock", int(Time.get_ticks_msec() / 45.0)),
					Vector2(xx, area.position.y)
				)
