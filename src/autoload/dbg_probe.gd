extends Node
## Dev probe (inert unless DISASTER_PROBE=1).

func _ready() -> void:
	if OS.get_environment("DISASTER_PROBE") != "1":
		return
	await get_tree().process_frame
	print("PROBE_OK buttons=", get_tree().get_nodes_in_group("obj_menu_button").size())
