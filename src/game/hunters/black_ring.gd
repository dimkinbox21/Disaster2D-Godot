extends GMNode
var nid := 0
var used := false
var purple := false
var retry_ticks := 0
var hum: AudioStreamPlayer2D


func _ready():
	gm_name = "obj_blackring"
	sprite_name = "spr_blackring_purple" if purple else "spr_blackring"
	depth = -202
	if Net.lvlId == 8:
		image_blend = Color("404040")
	super._ready()
	image_alpha = 0
	image_speed = 0
	var stream: AudioStream = GameAudio._stream("snd_blackring_ball").duplicate()
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
	elif stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	hum = AudioStreamPlayer2D.new()
	hum.stream = stream
	hum.max_distance = 500
	hum.attenuation = 1
	add_child(hum)
	hum.play()
	update_hum()


func hum_gain(camera_origin: Vector2) -> float:
	return 1.0 - minf(position.distance_to(camera_origin + Vector2(213, 120)), 400) / 400.0


func update_hum():
	for camera in GMNode.all_of("obj_camera"):
		hum.volume_linear = hum_gain(camera.position)
		return


func _gm_step():
	update_hum()
	image_alpha = minf(1, image_alpha + 1.0 / 30)
	image_index = Globals.ringFrame
	if used and Net.state == Net.STATE_GAME:
		retry_ticks -= 1
		if retry_ticks <= 0:
			used = false
	var player: GMNode = Globals.player
	if (
		used
		or not visible
		or image_alpha < 1
		or not is_instance_valid(player)
		or Globals.character == 0
		or player.revivalTimes >= 2
		or player.hp <= 0
		or Net.gameEnds
	):
		return
	if bbox_rect().intersects(player.bbox_rect()):
		used = true
		if Net.state == Net.STATE_GAME:
			retry_ticks = 12
			Net.report_black_ring(nid)
		else:
			Net.consume_black_ring(nid)


func _gm_draw():
	draw_self()
