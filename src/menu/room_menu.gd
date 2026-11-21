extends Node2D
## Root of the generated menu scene (port of room_menu).
## Room creation code: randomize(); scr_play_music(mus_menu);

var layers: Dictionary = {}  # GM layer name -> Node


func _ready() -> void:
	_collect_layers(self)
	GameAudio.play_music("mus_menu")
	for m in get_tree().get_nodes_in_group("obj_menu"):
		m.layers = layers
		if layers.has("Bars"):
			m.bars = layers["Bars"]


func _collect_layers(node: Node) -> void:
	for c in node.get_children():
		if not layers.has(c.name):
			layers[c.name] = c
		_collect_layers(c)
