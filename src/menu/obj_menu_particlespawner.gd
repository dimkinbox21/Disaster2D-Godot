extends GMNode
## Port of obj_menu_particlespawner — spawns 20 floating particles.

func _ready() -> void:
	super._ready()
	var room_w := 480.0
	var room_h := 270.0
	for i in 20:
		var p := GMNode.new()
		p.set_script(load("res://src/menu/obj_menu_particle.gd"))
		p.position = Vector2(randf() * room_w, randf() * room_h)
		p.sprite_name = "spr_menu_particle"
		p.z_index = clampi(-1999, -4096, 4096)
		add_child(p)
