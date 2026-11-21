extends RefCounted
## Shared hooks used by the actor; each hunter owns its ability state.
var p: GMNode


func allows_look() -> bool:
	return true


func ball_contact_allowed() -> bool:
	return true


func taunt_key(slot: int) -> String:
	return "texe1" if slot == 1 else "texe0"


func emotion_sound(slot: int):
	if slot == 3:
		GameAudio.play_emotion3(0, Globals.exeCharacter)


func tick():
	pass


func draw_effect():
	pass


func wall_collision(_floor: GMFloor, _side: int):
	pass
