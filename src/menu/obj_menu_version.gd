extends GMNode
## Port of obj_menu_version.

var version := ""

func _ready() -> void:
	super._ready()
	version = "v mod&%d" % GM.BUILD_VER

func _gm_draw() -> void:
	GM.scr_text_spr(self, position.x, position.y, version)
