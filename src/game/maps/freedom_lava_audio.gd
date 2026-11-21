extends Node2D
var hum: AudioStreamPlayer2D


func _ready():
	var source = GameAudio._stream("snd_lava")
	if source == null:
		return
	var stream = source.duplicate()
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
	elif stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	hum = AudioStreamPlayer2D.new()
	hum.stream = stream
	hum.max_distance = 100000
	hum.attenuation = 0
	hum.volume_db = -80
	add_child(hum)
	hum.play()


func _physics_process(_delta):
	if not is_instance_valid(hum):
		return
	var center = Vector2.ZERO
	for camera in GMNode.all_of("obj_camera"):
		center = camera.render_origin + Vector2(213, 120)
		break
	hum.volume_db = linear_to_db(
		maxf(0.0005, 1 - minf(global_position.distance_to(center), 700) / 700)
	)
