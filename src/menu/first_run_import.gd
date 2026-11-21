extends CanvasLayer
## The profile autoloads wait until this first-launch choice is completed.

var message: Label
var import_button: Button
var fresh_button: Button
var folder_dialog: FileDialog


func _ready() -> void:
	layer = 200
	get_tree().root.gui_embed_subwindows = true
	var blocker = ColorRect.new()
	blocker.color = Color(0, 0, 0, 0.9)
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(blocker)
	var panel = PanelContainer.new()
	panel.position = Vector2(20, 40)
	panel.size = Vector2(440, 190)
	blocker.add_child(panel)
	var margin = MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	var heading = Label.new()
	heading.text = "Import save data from the original game?"
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size", 19)
	column.add_child(heading)
	message = Label.new()
	message.text = "Import your settings, unlocks and progress, or start with a new profile."
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 14)
	column.add_child(message)
	var buttons = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	import_button = Button.new()
	import_button.text = "Import save"
	import_button.custom_minimum_size = Vector2(150, 36)
	import_button.pressed.connect(_choose_import)
	buttons.add_child(import_button)
	fresh_button = Button.new()
	fresh_button.text = "Start fresh"
	fresh_button.custom_minimum_size = Vector2(150, 36)
	fresh_button.pressed.connect(_start_fresh)
	buttons.add_child(fresh_button)
	import_button.grab_focus()


func _choose_import() -> void:
	var folder = SaveStore.original_save_folder()
	if DirAccess.dir_exists_absolute(folder):
		_import_folder(folder)
		return
	_browse_for_folder()


func _browse_for_folder() -> void:
	if not is_instance_valid(folder_dialog):
		folder_dialog = FileDialog.new()
		folder_dialog.title = "Select the original save folder"
		folder_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
		folder_dialog.access = FileDialog.ACCESS_FILESYSTEM
		folder_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
		folder_dialog.dir_selected.connect(_import_folder)
		add_child(folder_dialog)
	folder_dialog.popup_centered(Vector2i(460, 240))


func _import_folder(folder: String) -> void:
	if not SaveStore.import_original(folder):
		message.text = (
			SaveStore.import_error + " Select a folder containing 1.bson, 2.bson and 3.bin."
		)
		# A detected folder can be incomplete; let the player choose another one.
		import_button.text = "Choose folder"
		if import_button.pressed.is_connected(_choose_import):
			import_button.pressed.disconnect(_choose_import)
			import_button.pressed.connect(_browse_for_folder)
		return
	if SaveStore.finish_first_launch("imported"):
		queue_free()
	else:
		message.text = SaveStore.import_error


func _start_fresh() -> void:
	if SaveStore.finish_first_launch("fresh"):
		queue_free()
	else:
		message.text = SaveStore.import_error
