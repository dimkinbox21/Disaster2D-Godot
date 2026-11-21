extends "res://src/menu/mobile_control_editor.gd"


func _prop() -> Array:
	match bid:
		1:
			return [GameConfig.bAX, GameConfig.bAY, GameConfig.bAScale, GameConfig.bAOpacity]
		2:
			return [GameConfig.bBX, GameConfig.bBY, GameConfig.bBScale, GameConfig.bBOpacity]
		3:
			return [GameConfig.bCX, GameConfig.bCY, GameConfig.bCScale, GameConfig.bCOpacity]
		4:
			return [GameConfig.bDX, GameConfig.bDY, GameConfig.bDScale, GameConfig.bDOpacity]
		5:
			return [GameConfig.bEX, GameConfig.bEY, GameConfig.bEScale, GameConfig.bEOpacity]
		6:
			return [GameConfig.bFX, GameConfig.bFY, GameConfig.bFScale, GameConfig.bFOpacity]
		7:
			return [GameConfig.bGX, GameConfig.bGY, GameConfig.bGScale, GameConfig.bGOpacity]
		8:
			return [GameConfig.bWX, GameConfig.bWY, GameConfig.bWScale, GameConfig.bWOpacity]
	return [0, 0, 1, 0.5]
