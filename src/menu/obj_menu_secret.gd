extends GMNode
## Port of obj_menu_secret (pet unlock codes typed on the credits screen).
## Codes are stored Atbash-encrypted exactly as in the original.

var codes := [
	"kzgfh", "gszmlh", "svsirws", "hgliv", "kfhwvi", "zmpov", "slnhgvi",
	"glmthdvo", "wzmzo", "kvirwlm", "hloultl", "kraz", "ksromfh", "gfnzir",
	"hlmrzmt1", "hlmrzmt2", "hlmrzmt3", "eztrmvggv", "nvigslmt",
	"TUTANHAMONUS DELEGATION EL EGIPET", "lastround", "jojomart",
]

func _gm_step() -> void:
	var menu: GMNode = null
	for m in GMNode.all_of("obj_menu"):
		menu = m
		break
	if menu == null or menu.submenu != menu.SUBMENU_ABOUT_CREDITS:
		return
	for i in codes.size():
		var petCode := i + 7
		if GM.keyboard_string.ends_with(codes[i]) and Unlockables.pet != petCode:
			Unlockables.pet = petCode
			Unlockables.save()
			GameAudio.play_sound("snd_ring")
