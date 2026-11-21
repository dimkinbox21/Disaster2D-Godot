extends RefCounted
var host
var r: Dictionary = {}
var active = false
var ended = false
const ROOMS = [
	"hideandseek2",
	"ravinemist",
	"dotdotdot",
	"deserttown",
	"youcantrun",
	"limpcity",
	"notperfect",
	"kindandfair",
	"act9",
	"nastyparadise",
	"pricelessfreedom",
	"volcanovalley",
	"greenhill",
	"majongforest",
	"angelisland",
	"torturecave",
	"dartower",
	"haundream",
	"weedzone",
	"marijuna"
]


func _init(profile):
	host = profile
	reset()


func reset():
	r = {
		"revivals": 0,
		"revive_window": 0,
		"demon_window": 0,
		"stuns": 0,
		"hurt": false,
		"heals": 0,
		"heal_others": [],
		"escaped": 0,
		"demon_kills": 0,
		"egg": 0,
		"evil_egg": 0,
		"amy": 0,
		"evil_amy": 0,
		"shield": 0,
		"evil_shield": 0,
		"black": 0,
		"shards": 0,
		"clone": 0,
		"wave": 0,
		"dash": 0,
		"invis": 0,
		"upper": 0,
		"upper_window": 0
	}
	ended = false


func begin():
	reset()
	active = not Net.test_round and Net.lvlId >= 0 and Net.lvlId < 20


func grant(id: int, reward: int):
	if Net.test_round or not active or Net.lvlId < 0 or Net.lvlId >= 20 or host.achivements[id]:
		return
	host.achivements[id] = true
	host.mercoins += reward
	host.show_popup()


func tally(key: String, amount := 1) -> int:
	r[key] = int(r.get(key, 0)) + amount
	return r[key]


func tick():
	for key in [
		"revive_window",
		"demon_window",
		"clone",
		"wave_window",
		"dash_window",
		"invis",
		"upper_window"
	]:
		if int(r.get(key, 0)) > 0:
			r[key] -= 1
			if r[key] == 0 and key == "wave_window":
				r.wave = 0
			if r[key] == 0 and key == "dash_window":
				r.dash = 0
			if r[key] == 0 and key == "upper_window":
				r.upper = 0
	var p = Globals.player
	if (
		not Net.test_round
		and active
		and not ended
		and is_instance_valid(p)
		and Globals.character > 0
		and p.rings >= 25
		and not host.achivements[21]
	):
		grant(21, 25)
		host.save()


func event(kind: String, value := 1, other := -1):
	if Net.test_round or not active or ended:
		return
	var before = hash([host.mercoins, host.survStuns, host.exeKills, host.achivements])
	match kind:
		"taken":
			r.hurt = true
			r.shards = 0
		"healed":
			if tally("heals", value) >= 3:
				grant(16, 100)
		"heal_other":
			if r.heal_others.is_empty() or r.heal_others.back() != other:
				r.heal_others.append(other)
			if r.heal_others.size() >= 2:
				grant(17, 100)
			if r.heal_others.size() >= 3 and Globals.character == 5:
				grant(30, 100)
		"revive":
			if r.revive_window > 0:
				grant(5, 100)
			r.revive_window = 60
			var count = tally("revivals")
			if count >= 1:
				grant(3, 25)
			if count >= 2:
				grant(4, 50)
			if count >= 3:
				grant(6, 200)
		"demon":
			r.demon_window = 300
		"escape":
			r.escaped += 1
		"black":
			r.black += 1
		"shard":
			r.shards += value
		"clone":
			r.clone = 60
		"invis":
			r.invis = 80
		"wave_start":
			r.wave = 0
			r.wave_window = 60
		"dash_start":
			r.dash = 0
			r.dash_window = 60
		"tracker":
			if Globals.character == 3:
				var evil = Globals.player != null and Globals.player.revivalTimes >= 2
				if evil and tally("evil_egg") >= 3:
					grant(27, 75)
				elif not evil and tally("egg") >= 4:
					grant(26, 100)
		"shield":
			if tally("shield") >= 2:
				grant(32, 75)
		"bonus":
			bonus(value, other)
	if before != hash([host.mercoins, host.survStuns, host.exeKills, host.achivements]):
		host.save()


func bonus(kind: int, power: int):
	if Net.test_round or not active or ended:
		return
	match kind:
		0:
			host.mercoins += 2
			host.exeKills += 1
			for row in [[3, 12, 25], [10, 13, 50], [50, 14, 250], [100, 15, 500]]:
				if host.exeKills >= row[0]:
					grant(row[1], row[2])
			if r.clone > 0:
				grant(37, 100)
			if r.invis > 0:
				grant(34, 100)
		1, 2:
			host.mercoins += 1
			host.survStuns += 1
			if kind == 1 or power <= 1:
				if tally("stuns") >= 5:
					grant(9, 100)
			if kind == 2:
				# The port sends damage tiers 1..6, original bonus used stun ticks 6..60.
				if power == 1:
					grant(22, 75)
				if power >= 6:
					grant(23, 100)
		3:
			if tally("evil_amy") >= 5:
				grant(29, 100)
		4:
			if r.demon_window > 0:
				grant(8, 125)
			if tally("demon_kills") >= 2 and Globals.character == 5:
				grant(31, 75)
			grant(7, 25)
		5:
			if tally("shield") >= 2:
				grant(33, 100)
		7:
			if tally("wave") >= 2:
				grant(36, 100)
			r.wave_window = 60
		8, 9:
			if tally("upper") >= 2:
				grant(25 if kind == 8 else 24, 100 if kind == 8 else 75)
			r.upper_window = 60
		10:
			if tally("dash") >= 2:
				grant(35, 100)
			r.dash_window = 60
		11:
			r.amy += 1


func finish(outcome: int, eligible: bool):
	if Net.test_round or not active or ended:
		return
	ended = true
	if not eligible or Net.lvlId not in range(20):
		return
	var p = Globals.player
	var ch = Globals.character
	var escaped = bool(Net.players.get(Net.nid, {}).get("hasEscaped", false))
	var win = (
		(ch == 0 and outcome != Net.PacketType.SERVER_GAME_SURVIVOR_WIN)
		or (
			ch > 0
			and outcome == Net.PacketType.SERVER_GAME_SURVIVOR_WIN
			and (escaped or (is_instance_valid(p) and p.hp > 0 and p.revivalTimes < 2))
		)
	)
	if not win:
		return
	if ch == 0:
		host.exeWins += 1
		host.set(["exe", "chaos", "exetior", "exeller"][clampi(Globals.exeCharacter, 0, 3)], true)
		host.mercoins += maxi(0, Net.players.size() - 1) * 2
		if host.exe and host.chaos and host.exetior and host.exeller:
			grant(19, 100)
	else:
		host.survWins += 1
		host.set(["", "tails", "knux", "eggman", "amy", "cream", "sally"][ch], true)
		if host.tails and host.knux and host.eggman and host.amy and host.cream and host.sally:
			grant(18, 100)
		if not r.hurt:
			grant(11, 50)
		if int(r.get("escape_hp", 5)) <= 1 and int(r.get("escape_ticks", 9999)) <= 300:
			grant(10, 100)
		if Net.lvlId == 10 and r.black == 0:
			grant(47, 25)
		if r.shards >= 6:
			grant(48, 25)
		if ch == 4 and r.amy == 0:
			grant(28, 75)
		if r.escaped >= 5:
			grant(20, 50)
		for row in [
			[0, 1, 38], [14, 1, 38], [4, 2, 39], [2, 3, 40], [6, 4, 41], [7, 5, 42], [8, 6, 43]
		]:
			if Net.lvlId == row[0] and ch == row[1]:
				grant(row[2], 25)
		var killer = 0
		for data in Net.players.values():
			if int(data.get("character", -1)) == 0:
				killer = int(data.get("exeCharacter", 0))
				break
		for row in [[15, 1, 1, 44], [9, 5, 2, 45], [5, 6, 3, 46]]:
			if Net.lvlId == row[0] and ch == row[1] and killer == row[2]:
				grant(row[3], 25)
	var room = "room_" + ROOMS[Net.lvlId]
	if not host.maps.has(room):
		host.maps.append(room)
	if (
		host.maps.size()
		>= (20 if ch == 0 and outcome == Net.PacketType.SERVER_GAME_EXE_WINS else 18)
	):
		grant(49, 100)
	for row in [[10, 0, 50], [50, 1, 250], [100, 2, 500]]:
		if host.exeWins + host.survWins >= row[0]:
			grant(row[1], row[2])
	host.save()
