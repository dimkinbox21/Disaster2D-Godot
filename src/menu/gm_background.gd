extends GMNode
## Port of GMRBackgroundLayer — tiled scrolling background, optional heat haze
## filter (layer effect on the original "Background" layer).

var htiled := false
var vtiled := false
var stretch := false
var hspeed := 0.0
var vspeed := 0.0
var layer_colour := Color.WHITE
var use_heathaze := false

var _scroll := Vector2.ZERO
## parallax: layer origin = camera_topleft * factor (port of obj_parallax)
var parallax_x := 1.0
var parallax_y := 1.0
var parallax_yoff := 0.0

func _ready() -> void:
	gm_name = "gm_background"  # findable by controllers (obj_dotdotdot_i BG lookup)
	super._ready()
	if use_heathaze:
		var mat := ShaderMaterial.new()
		mat.shader = load("res://src/menu/heat_haze.gdshader")
		# Without a low render priority, materialized items get drawn in front
		# of the rest of the canvas regardless of z_index.
		mat.render_priority = -100.0
		mat.set_shader_parameter("noise_tex", _make_noise())
		set_material(mat)

func _make_noise() -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.seed = 12345
	n.frequency = 0.012
	n.fractal_octaves = 3
	var t := NoiseTexture2D.new()
	t.noise = n
	t.width = 256
	t.height = 256
	t.seamless = true
	return t

var _last_a := -1.0

func _gm_step() -> void:
	_scroll.x += hspeed
	_scroll.y += vspeed
	if parallax_x != 1.0 or parallax_y != 1.0 or parallax_yoff != 0.0:
		var cam: GMNode = null
		for c in GMNode.all_of("obj_camera"):
			cam = c
			break
		if cam:
			position.x = cam.position.x * parallax_x
			position.y = (cam.position.y + parallax_yoff) * parallax_y
	# layer_colour.a is driven externally (layer_background_alpha) — the base
	# conditional redraw doesn't track it, so check here
	if layer_colour.a != _last_a:
		_last_a = layer_colour.a
		queue_redraw()
	# scrolling layers (fog hspeed, drifting clouds) move their pattern phase
	if hspeed != 0.0 or vspeed != 0.0:
		queue_redraw()

func _gm_draw() -> void:
	var tex := GM.sprite_texture(sprite_name, int(image_index))
	if tex == null:
		return
	var m := GM.sprite_meta(sprite_name)
	var w := float(m["w"])
	var h := float(m["h"])
	# layer_colour.a carries layer_background_alpha (obj_deserttown_i fog fade)
	var tint := Color(layer_colour, layer_colour.a)
	if not htiled and not vtiled:
		draw_texture(tex, Vector2.ZERO, tint)
		return
	# GM layers tile across the whole room; the parallax node shift only moves
	# the pattern — cover the CAMERA VIEW in local coords, not 480px from origin.
	# FLOOR (not ceil): the tile starting LEFT/ABOVE the view still covers it.
	var vl := 0.0
	var vt := 0.0
	for c in GMNode.all_of("obj_camera"):
		vl = c.position.x - position.x
		vt = c.position.y - position.y
		break
	var ox := fposmod(_scroll.x, w)
	var oy := fposmod(_scroll.y, h)
	var x0 := ox + floorf((vl - ox) / w) * w
	var y := (oy if not vtiled else oy + floorf((vt - oy) / h) * h)
	while y < vt + 270.0:
		var x := x0
		while x < vl + 480.0:
			draw_texture(tex, Vector2(x, y), tint)
			x += w
		if not vtiled:
			break
		y += h
