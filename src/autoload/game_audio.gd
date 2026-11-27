extends Node
## Port of scr_music (scr_play_music / scr_stop_music) + audio_play_sound helper.

var music_id := -1
var music_gain := 1.0

var _music_player: AudioStreamPlayer
var _sound_pool: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _sound_paths: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sound_pool.append(p)


func _stream(sound_name: String) -> AudioStream:
	if _streams.has(sound_name):
		return _streams[sound_name]
	if _sound_paths.is_empty():
		for file in DirAccess.get_files_at("res://assets/sounds"):
			file = file.trim_suffix(".remap").trim_suffix(".import")
			if file.get_extension().to_lower() in ["ogg", "wav", "mp3"]:
				_sound_paths[file.to_lower()] = "res://assets/sounds/" + file
	var path := ""
	for ext in [".ogg", ".wav", ".mp3"]:
		var p: String = _sound_paths.get((sound_name + ext).to_lower(), "")
		if not p.is_empty() and ResourceLoader.exists(p):
			path = p
			break
	var s: AudioStream = load(path) if path != "" else null
	_streams[sound_name] = s
	return s


## scr_play_music(bid) — menu/music tracks loop (audio_play_sound(bid,0,true))
func play_music(sound_name: String) -> void:
	if music_id != -1:
		stop_music()
	var s := _stream(sound_name)
	if s == null:
		push_warning("missing music: " + sound_name)
		return
	if s is AudioStreamOggVorbis:
		s.loop = true
	elif s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = s.data.size() / 4
	elif s is AudioStreamMP3:
		s.loop = true  # mp3 needs an explicit loop too (Desert Town)
	_music_player.stream = s
	_music_player.volume_db = linear_to_db(1.0)
	_music_player.play()
	music_id = 1


## audio_sound_gain(track, vol, ms) port — dual-track crossfade:
## both music tracks loop simultaneously, only the gain changes (2000ms).
## Used by obj_dotdotdot_i zone phases (zone 2 touches no track at all).
var _cross_players: Dictionary = {}  # track name -> AudioStreamPlayer
var _cross_targets: Dictionary = {}  # track name -> target linear gain


func crossfade_music(track: String, gain_to: float, seconds := 2.0) -> void:
	if Net.motion.replaying:
		return
	var p: AudioStreamPlayer = _cross_players.get(track)
	if p == null:
		var st := _stream(track)
		if st == null:
			push_warning("missing music: " + track)
			return
		p = AudioStreamPlayer.new()
		p.bus = "Master"
		if st is AudioStreamOggVorbis:
			st.loop = true
		elif st is AudioStreamWAV:
			st.loop_mode = AudioStreamWAV.LOOP_FORWARD
			st.loop_end = st.data.size() / 4
		elif st is AudioStreamMP3:
			st.loop = true  # crossfaded tracks must loop too
		p.stream = st
		add_child(p)
		_cross_players[track] = p
		# first appearance: the original's Create sets gains instantly
		p.volume_db = linear_to_db(clampf(gain_to, 0.0005, 1.0))
		if gain_to > 0.001:
			p.play()
	_cross_targets[track] = gain_to
	_fade_left = maxf(_fade_left, seconds)
	_fade_dur = maxf(_fade_dur, seconds)


var _fade_left := 0.0
var _fade_dur := 1.0


func _process(delta: float) -> void:
	if _fade_left <= 0.0 or _cross_targets.is_empty():
		return
	_fade_left = maxf(0.0, _fade_left - delta)
	var k := 1.0 if _fade_dur <= 0.0 else 1.0 - _fade_left / _fade_dur
	for track in _cross_targets:
		var tgt: float = _cross_targets[track]
		var p: AudioStreamPlayer = _cross_players.get(track)
		if p == null:
			continue
		var cur := db_to_linear(p.volume_db)
		var v: float = lerpf(cur, tgt, k if _fade_left == 0.0 else 0.12)
		if _fade_left == 0.0:
			v = tgt
		p.volume_db = linear_to_db(maxf(v, 0.0005))
		if v < 0.002 and not p.playing:
			p.stop()
		elif v >= 0.002 and not p.playing and tgt > 0.0:
			p.play()
	if _fade_left == 0.0:
		for track in _cross_targets:
			var tgt2: float = _cross_targets[track]
			if tgt2 <= 0.001:
				var p2: AudioStreamPlayer = _cross_players.get(track)
				if p2:
					p2.stop()


## scr_stop_music()
func stop_music() -> void:
	for player in _cross_players.values():
		player.stop()
		player.queue_free()
	_cross_players.clear()
	_cross_targets.clear()
	_fade_left = 0.0
	_music_player.stop()
	music_id = -1


## audio_stop_all() — stops music and every one-shot sound
func stop_all() -> void:
	stop_music()
	for player in get_tree().get_nodes_in_group("game_positional_sound"):
		player.stop()
		player.queue_free()
	for p in _sound_pool:
		p.stop()


## audio_stop_sound(snd) — stops pool players currently playing this stream
func stop_sound(sound_name: String) -> void:
	if Net.motion.replaying:
		return
	var s := _stream(sound_name)
	if s == null:
		return
	for p in _sound_pool:
		if p.playing and p.stream == s:
			p.stop()


## audio_play_sound(snd, priority, loop)
func play_sound(sound_name: String, _priority := 0, _loop := false, gain := 1.0) -> void:
	if Net.motion.replaying:
		return
	var s := _stream(sound_name)
	if s == null:
		push_warning("missing sound: " + sound_name)
		return
	for p in _sound_pool:
		if not p.playing:
			p.stream = s
			p.volume_db = linear_to_db(clampf(gain, 0.0005, 1.0))
			p.play()
			return
	# Preserve playing voices when several players emit effects at once.
	if _sound_pool.size() >= 128:
		return
	var player := AudioStreamPlayer.new()
	add_child(player)
	_sound_pool.append(player)
	player.stream = s
	player.volume_db = linear_to_db(clampf(gain, 0.0005, 1.0))
	player.play()


## scr_move_basic EMOTION3: survivors animate silently; only the primary
## hunter plays its own voice. A demonized survivor retains survivor emotions.
func play_emotion3(character: int, exe_character: int) -> void:
	if Net.motion.replaying:
		return
	if character != Globals.CHARACTER_EXE:
		return
	match exe_character:
		Globals.EXE_ORIGINAL:
			play_sound("snd_exe_laugh")
		Globals.EXE_CHAOS:
			play_sound(["snd_chaos_taunt", "snd_chaos_taunt2"].pick_random())
		Globals.EXE_EXETIOR:
			play_sound("snd_exetior_laugh")
		Globals.EXE_EXELLER:
			play_sound("snd_exeller_laugh")


## scr_exe_stunsound: voice reaction in addition to the shared impact sound.
func play_exe_stun(exe_character: int) -> void:
	match exe_character:
		Globals.EXE_ORIGINAL:
			play_sound("snd_exe_stun2")
		Globals.EXE_CHAOS:
			play_sound("snd_chaos_stun")
		Globals.EXE_EXETIOR:
			play_sound("snd_exetior_stun")
		Globals.EXE_EXELLER:
			play_sound("snd_exeller_stun")


## Original audio_play_sound_at: attach a short-lived positional player to the
## world canvas so Godot's camera/listener supplies position and attenuation.
func play_sound_at(
	sound_name: String, at: Vector2, radius := 700.0, attenuate := true, mirror := true
) -> void:
	if Net.motion.replaying:
		return
	if mirror and Net.lvlId == 13:
		if at.x < 512:
			play_sound_at(sound_name, at + Vector2(3136, 0), radius, attenuate, false)
		elif at.x >= 3136:
			play_sound_at(sound_name, at - Vector2(3136, 0), radius, attenuate, false)
	var stream := _stream(sound_name)
	if stream == null or get_tree().current_scene == null:
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.position = at
	# Keep the cave reverb audible
	# beyond the 600px echo trigger. Normal puppet sounds fade over 700px.
	player.max_distance = radius if attenuate else 100000.0
	player.attenuation = 1.0 if attenuate else 0.0
	player.add_to_group("game_positional_sound")
	get_tree().current_scene.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
