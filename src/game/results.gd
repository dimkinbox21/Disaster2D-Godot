extends GMNode
## Exact 480x270 layout from room_results, obj_results and obj_results_icon.
var preview: GMNode
var row_count := -1
var fade := 1.0
var ticks := 0
var music_started := false
var gray_material: ShaderMaterial


func _ready() -> void:
	super._ready()
	preview = preload("res://src/net/obj_lobby_prolet.gd").new()
	preview.depth = 300
	preview.set_zone(clampi(Net.lvlId, 0, 20))
	gray_material = ShaderMaterial.new()
	gray_material.shader = preload("res://src/game/results_gray.gdshader")
	add_child(preview)
	Net.send_server_tcp(Net.cpacket_tcp(Net.PacketType.CLIENT_RESULTS_REQUEST))


func _gm_step() -> void:
	ticks += 1
	if Net.results_rows.size() != row_count:
		row_count = Net.results_rows.size()
		fade = 1.0
	fade = maxf(0.0, fade - 0.02)
	if row_count > 0:
		var result: int = Net.results_rows[0].result
		preview.material = gray_material if result == 0 else null
		if not music_started:
			music_started = true
			GameAudio.play_music(
				["mus_exewin", "mus_survwin", "mus_timeover"][clampi(result, 0, 2)]
			)
	queue_redraw()


func _gm_draw() -> void:
	if Net.results_rows.is_empty():
		draw_rect(Rect2(0, 0, 480, 270), Color.BLACK)
		return
	var first: Dictionary = Net.results_rows[0]
	draw_sprite("spr_results_bar", first.result, 0, 0)
	draw_sprite("spr_counter", 10, 233, 5)
	_counter(int(first.time) / 60, 224, 5)
	_counter(int(first.time) % 60, 244, 5, 2)
	for i in Net.results_rows.size():
		_draw_row(Net.results_rows[i], i)
	if fade > 0:
		draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, fade))


func _counter(value: int, x: float, y: float, zeros := 0) -> void:
	var text := str(value).pad_zeros(zeros)
	for i in text.length():
		draw_sprite("spr_counter", int(text[i]), x + i * 11, y)


func _text(value: String, x: float, y: float, color: Color) -> void:
	GM.scr_text_spr(self, x, y, value, color)


func _time(seconds: int) -> String:
	return "%d:%02d" % [seconds / 60, seconds % 60]


## Health, damage and healing already use whole sections on both peers.
func _sections(hp: int) -> String:
	return str(hp)


func _draw_row(row: Dictionary, index: int) -> void:
	var x := 3.0
	var y := 33.0 + index * 30
	var color := Color.GRAY if row.quit else Color.WHITE
	var sprite := "spr_playerhealth"
	var frame: float = row.character
	var ox := 0.0
	var oy := 26.0
	var format := 0
	match int(row.type):
		0:
			sprite = [
				"spr_lobby_exeicon",
				"spr_lobby_exeicon2",
				"spr_lobby_exeicon3",
				"spr_lobby_exeicon4"
			][clampi(row.character, 0, 3)]
			frame = ticks * 0.15
			ox = 13
			oy = 13
		1:
			sprite = "spr_playerhealth_demon"
		2:
			frame = 6 + row.character * 7
		3:
			sprite = "spr_lobby_icon"
			frame += 2
			ox = 12
			oy = 13
		4:
			sprite = "spr_playerescaped"
	if row.type <= 1:
		_text(str(row.kills), x + 47, y + 17, color)
		_text(_sections(row.damage), x + 83, y + 17, color)
		_text(str(row.rings), x + 116, y + 17, color)
		_text(str(row.stun_time) + " sec.", x + 152, y + 17, color)
		format = 2
		if row.type == 1:
			_text(_time(row.survival), x + 203, y + 17, color)
			format = 1
	else:
		_text(_time(row.survival), x + 47, y + 17, color)
		_text(_time(row.danger), x + 92, y + 17, color)
		_text(str(row.rings), x + 132, y + 17, color)
		_text(_sections(row.healed), x + 168, y + 17, color)
		_text(_sections(row.taken), x + 197, y + 17, color)
		_text(str(row.stuns), x + 226, y + 17, color)
	draw_sprite(sprite, frame, x + ox, y + oy, 1, 1, 0, color)
	_text(row.name, x + 34, y + 3, color)
	draw_sprite("spr_results_icons", format, x, y, 1, 1, 0, color)
