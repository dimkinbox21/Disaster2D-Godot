extends "res://src/game/maps/shared/rules.gd"
## Torture Cave: presentation and network effects.
var acid_group := -1
var acid_on := false


func _ready() -> void:
	process_physics_priority = 60
	z_index = -250
	var stream: AudioStream = GameAudio._stream("snd_waterdrops").duplicate()
	stream.set("loop", true)
	var ambient := AudioStreamPlayer.new()
	ambient.stream = stream
	ambient.add_to_group("game_positional_sound")
	add_child(ambient)
	ambient.play()


func acid_packet(group: int, on: bool) -> void:
	if group not in range(7):
		return
	acid_group = group
	acid_on = on
	for cloud in GMNode.all_of("obj_abadon_cloud"):
		if int(cloud.properties.get("nid", 0)) != group:
			continue
		cloud.properties.damage = on
		if on:
			cloud.image_index = 0
			cloud._anim_accum = 0
			cloud.visible = true
			cloud.gm_visible = true
	if on:
		for emitter in GMNode.all_of("obj_soundemitter"):
			if int(emitter.properties.get("stype", emitter.stype)) == group:
				GameAudio.play_sound_at("snd_acid", emitter.position)


func _physics_process(_dt: float) -> void:
	frame += 1
	flash = maxf(0, flash - 0.1)
	var p: GMNode = Globals.player
	if not is_instance_valid(p):
		return
	if Net.gameEnds:
		return


func _draw() -> void:
	return


func _process(_dt: float) -> void:
	return
