extends GMNode
## Port of obj_ring — collectible ring.

var nid := 0
var iid := 0
var used := false

func _ready() -> void:
	# obj_ring.yy spriteId — the map_controller never sets sprite_name, and
	# nothing calls default_sprite_name(), so the rings were invisible
	sprite_name = "spr_ring"
	super._ready()
	image_alpha = 0.0
	depth = 2

func _gm_step() -> void:
	if image_alpha < 1:
		image_alpha += 1.0 / 30.0
	image_index = Globals.ringFrame
	if used:
		return
	var player: GMNode = null
	for p in GMNode.all_of("obj_player"):
		player = p
		break
	if player == null:
		return
	# the original: place_meeting(x, y, global.player) — the ring's point against the
	# PLAYER's mask, not the player's origin point (the ring sits 16px below the
	# spawner, so a point-vs-point test misses by the sprite offset)
	if visible and image_alpha >= 1 and player.bbox_rect().has_point(Vector2(position.x, position.y)):
		if Globals.character == Globals.CHARACTER_EXE:
			# exe breaks rings when attacking
			if player.isAttacking:
				ring_break()
			return
		if player.hp <= 0:
			return
		# solo practice: local collect (obj_net's SERVER_RING_COLLECTED type 0 → +1)
		player.ring_collected(1)
		visible = false
		used = true
		queue_free()

func ring_break() -> void:
	GameAudio.play_sound("snd_exe_ringshutter")
	for i in 4:
		var part := GMNode.new()
		part.set_script(load("res://src/game/obj_ringpart.gd"))
		part.position = position + Vector2([12, 0, 4, 0][i], [4, 12, 4, -4][i])
		part.xspd = ([1, -1, -1, 1][i]) + player_xspd()
		part.yspd = [-3, 1, -3, 1][i] + randf() * 1.0
		part.sprite_name = ["spr_ringpart", "spr_ringpart2", "spr_ringpart3", "spr_ringpart"][i]
		get_parent().add_child(part)
	queue_free()

func player_xspd() -> float:
	for p in GMNode.all_of("obj_player"):
		return p.xspd
	return 0.0
