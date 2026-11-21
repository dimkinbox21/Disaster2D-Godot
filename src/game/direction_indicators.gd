extends RefCounted
## Original obj_exe_indicator Step_2 / Draw_64, obj_demon_indicator and
## obj_surv_indicator. Commands use GUI coordinates and GameMaker angles.


static func survivor_target(p: GMNode, prefer_red: bool) -> GMNode:
	var nearest: GMNode = null
	var distance := INF
	for puppet in GMNode.all_of("obj_player_puppet"):
		if (
			puppet.isInactive
			or puppet.pcharacter <= 0
			or puppet.hp <= 0
			or puppet.revivalTimes >= 2
		):
			continue
		# Original visible hunters prioritize the first red-ring carrier;
		# invisibility always selects the nearest living human instead.
		if prefer_red and puppet.hasRedRing:
			return puppet
		var d: float = p.position.distance_squared_to(puppet.position)
		if d < distance:
			distance = d
			nearest = puppet
	return nearest


static func primary_hunter() -> GMNode:
	for puppet in GMNode.all_of("obj_player_puppet"):
		if puppet.pcharacter == 0 and not puppet.isInactive:
			return puppet
	return null


static func command(sprite: String, p: GMNode, target: GMNode, at: Vector2) -> Dictionary:
	return {
		"sprite": sprite,
		"at": at,
		"angle": -rad_to_deg((target.position - p.position).angle()),
		"target": target.master_id
	}


static func commands(p: GMNode, camera: Vector2) -> Array:
	var result := []
	if not is_instance_valid(p):
		return result
	var at: Vector2 = (p.position - camera).ceil()
	if (
		Net.lvlId == 1
		and Globals.character > 0
		and p.hp > 0
		and not p.isDead
		and p.revivalTimes < 2
	):
		var scene := p.get_tree().current_scene
		if (
			scene != null
			and scene.get("rules") != null
			and scene.rules.get("shard_count") != null
			and scene.rules.shard_count >= 6
		):
			for exit in GMNode.all_of("obj_bigring"):
				result.append(
					{
						"sprite": "spr_sindicator2",
						"at": at,
						"angle": -rad_to_deg((exit.position - p.position).angle()),
						"target": -1
					}
				)
				break
	if Globals.character == 0:
		var target := survivor_target(p, p.invisTimer <= 0)
		var slime: bool = (
			Globals.exeCharacter == Globals.EXE_CHAOS
			and p.hunter != null
			and p.hunter.slimeTimer > 0
		)
		var revealing: bool = (
			Globals.exeCharacter in [Globals.EXE_EXETIOR, Globals.EXE_EXELLER]
			and p.hunter != null
			and p.hunter.indicatorTimer > 0
		)
		if target != null and (p.invisTimer > 0 or slime or revealing or target.hasRedRing):
			result.append(command("spr_indicator", p, target, at))
		if Globals.exeCharacter == Globals.EXE_EXELLER:
			for clone in GMNode.all_of("obj_exeller_clone"):
				if clone.owner_id != Net.nid:
					continue
				result.append(
					{
						"sprite": "spr_exeller_clonearrow",
						"frame": clone.slot,
						"at":
						Vector2(
							floorf(clone.position.x - camera.x),
							floorf(
								(
									clone.position.y
									- camera.y
									- 35
									- sin(Time.get_ticks_msec() / 200.0)
								)
							)
						),
						"angle": 0,
						"target": clone.nid
					}
				)
				var nearby: GMNode = clone.nearest_survivor()
				if nearby != null:
					var marker: Vector2 = (
						(
							p.position.ceil()
							+ (nearby.position - p.position).normalized() * 32
							- camera
						)
						. ceil()
					)
					result.append(
						{
							"sprite":
							(
								"spr_exeller_clonetracker"
								if clone.slot == 0
								else "spr_exeller_clonetracker2"
							),
							"at": marker,
							"angle": 0,
							"target": nearby.master_id
						}
					)
	elif p.revivalTimes >= 2:
		var target := primary_hunter()
		if target != null:
			var offset := (
				20 if Globals.character in [1, 5] else (36 if Globals.character == 3 else 25)
			)
			result.append(command("spr_indicator2", p, target, at - Vector2(0, offset + 9)))
	if not p.isDead:
		for tracker in GMNode.all_of("obj_tracker_indicator"):
			if tracker.remaining <= 0:
				continue
			for target in GMNode.all_of("obj_player_puppet"):
				if target.master_id == tracker.target_id:
					result.append(command("spr_sindicator", p, target, at))
					break
	return result
