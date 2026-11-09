extends Node2D
## Port of obj_parallax — shifts background layers by camera * factor.
## parallax = [["LayerName", xfactor, yfactor, yoffset?], ...] — names resolved
## against the parent scene's background nodes (cached — find_child is a full
## recursive tree walk, too hot to run every frame).

var parallax: Array = []  # set by the map controller

var _cache: Dictionary = {}
var _cache_root: Node = null

func _physics_process(_d: float) -> void:
	var cam: GMNode = null
	for c in GMNode.all_of("obj_camera"):
		cam = c
		break
	if cam == null:
		return
	var root := get_tree().current_scene
	if root == null:
		return
	if root != _cache_root:
		_cache_root = root
		_cache.clear()
	for entry in parallax:
		var lay_name: String = entry[0]
		var lay: Node2D = _cache.get(lay_name)
		if lay == null or not is_instance_valid(lay):
			lay = root.find_child(lay_name, true, false) as Node2D
			_cache[lay_name] = lay
			if lay == null:
				continue
		var xspd: float = entry[1]
		var yspd: float = entry[2]
		var yoff: float = entry[3] if entry.size() > 3 else 0.0
		lay.position.x = cam.position.x * xspd
		lay.position.y = (cam.position.y + yoff) * yspd
