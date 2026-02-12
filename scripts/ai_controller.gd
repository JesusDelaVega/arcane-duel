extends Node

# Difficulty: 0=easy, 1=normal, 2=hard
var difficulty: int = 1

var player = null
var decision_timer: float = 0.0
var action: String = "collect"
var target_pos = Vector2.ZERO
var defend_timer: float = 0.0

# Difficulty params (set in setup)
var reaction_min: float = 0.35
var reaction_max: float = 0.7
var move_speed_mult: float = 0.85
var dodge_chance: float = 0.35
var defend_chance: float = 0.25
var mana_aggression: float = 0.6
var projectile_dodge: bool = false
var aim_error: float = 0.0


func setup(p) -> void:
	player = p
	_apply_difficulty()


func _apply_difficulty() -> void:
	match difficulty:
		0:  # Easy
			reaction_min = 0.5
			reaction_max = 0.9
			move_speed_mult = 0.7
			dodge_chance = 0.2
			defend_chance = 0.15
			mana_aggression = 0.4
			projectile_dodge = false
			aim_error = 0.35
		1:  # Normal
			reaction_min = 0.3
			reaction_max = 0.6
			move_speed_mult = 0.85
			dodge_chance = 0.35
			defend_chance = 0.25
			mana_aggression = 0.6
			projectile_dodge = false
			aim_error = 0.15
		2:  # Hard
			reaction_min = 0.15
			reaction_max = 0.35
			move_speed_mult = 0.95
			dodge_chance = 0.5
			defend_chance = 0.3
			mana_aggression = 0.8
			projectile_dodge = true
			aim_error = 0.0


func update(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(player.opponent):
		return

	decision_timer -= delta
	defend_timer -= delta

	# Hard: check for projectiles constantly
	if projectile_dodge and player.dodge_cd <= 0:
		if _dodge_incoming_projectile():
			return

	if decision_timer <= 0:
		_decide()
		decision_timer = randf_range(reaction_min, reaction_max)

	_execute()


func _dodge_incoming_projectile() -> bool:
	for node in player.get_tree().get_nodes_in_group("projectiles"):
		if not is_instance_valid(node):
			continue
		if not node.has_method("get") or node.get("shooter") == player:
			continue
		var dist = player.global_position.distance_to(node.global_position)
		if dist > 150:
			continue
		# Check if projectile is heading toward us
		var to_us = (player.global_position - node.global_position).normalized()
		var proj_dir = node.get("direction")
		if proj_dir == null:
			continue
		if to_us.dot(proj_dir) > 0.4:
			# Dodge perpendicular to projectile
			var perp = proj_dir.rotated(PI / 2.0)
			if randf() > 0.5:
				perp = -perp
			player.do_dodge(perp)
			action = "collect"
			decision_timer = 0.3
			return true
	return false


func _decide() -> void:
	if action == "defend_wait" and defend_timer > 0:
		return

	var opp = player.opponent
	var dist = player.global_position.distance_to(opp.global_position)
	var pm = player.mana

	# React to opponent attacking nearby
	if opp.state == opp.State.ATTACKING and dist < 80:
		var r = randf()
		if r < dodge_chance:
			action = "dodge"
		elif r < dodge_chance + defend_chance:
			action = "defend"
		else:
			action = "retreat"
		return

	# Hard: defend against close opponent with high mana
	if difficulty >= 2 and dist < 50 and opp.mana >= 30:
		if randf() < 0.4:
			action = "defend"
			return

	# Arcane blast: enough mana and in range
	if pm >= player.COST_ARCANE and player.cd_special <= 0 and dist < 280:
		var chance = 0.4 if difficulty == 0 else (0.6 if difficulty == 1 else 0.8)
		if randf() < chance:
			action = "arcane_blast"
			return

	# Fireball: enough mana and at range
	if pm >= player.COST_FIRE and player.cd_fire <= 0 and dist > 80 and dist < 420:
		if randf() < mana_aggression:
			action = "fireball"
			return

	# Ice wave: enough mana and close
	if pm >= player.COST_ICE and player.cd_ice <= 0 and dist < 140:
		if randf() < mana_aggression:
			action = "ice_wave"
			return

	# Melee: close
	if dist < 55:
		action = "melee"
		return

	# Hard: strategic positioning
	if difficulty >= 2 and pm >= player.COST_FIRE:
		var ideal_dist = 120.0 if pm >= player.COST_ICE else 250.0
		if abs(dist - ideal_dist) > 50:
			action = "position"
			return

	# Collect orbs or approach
	if pm < player.COST_FIRE:
		action = "collect"
	elif dist > 140:
		action = "approach"
	else:
		action = "collect"


func _execute() -> void:
	if action != "defend" and action != "defend_wait":
		if player.state == player.State.DEFENDING:
			player.state = player.State.IDLE

	match action:
		"collect":
			_go_collect()
		"approach":
			_move_toward(player.opponent.global_position)
		"position":
			_do_position()
		"melee":
			var dir = _aim_at_opponent()
			player.facing = dir
			player.use_melee()
			action = "retreat"
			decision_timer = 0.3
		"fireball":
			var dir = _aim_at_opponent()
			player.facing = dir
			player.use_fireball()
			action = "collect" if difficulty < 2 else "retreat"
			decision_timer = 0.5
		"ice_wave":
			player.use_ice_wave()
			action = "retreat"
			decision_timer = 0.4
		"arcane_blast":
			var dir = _aim_at_opponent()
			player.facing = dir
			player.use_arcane_blast()
			action = "retreat"
			decision_timer = 0.6
		"dodge":
			var away = (player.global_position - player.opponent.global_position).normalized()
			var ddir = away.rotated(randf_range(-0.5, 0.5))
			player.do_dodge(ddir)
			action = "collect"
		"defend":
			player.state = player.State.DEFENDING
			defend_timer = randf_range(0.3, 0.8)
			action = "defend_wait"
		"defend_wait":
			player.velocity = Vector2.ZERO
			if defend_timer <= 0:
				player.state = player.State.IDLE
				action = "collect"
		"retreat":
			var away = (player.global_position - player.opponent.global_position).normalized()
			_move_toward(player.global_position + away * 100)
		_:
			player.velocity = Vector2.ZERO


func _aim_at_opponent() -> Vector2:
	var dir = (player.opponent.global_position - player.global_position).normalized()
	if aim_error > 0:
		dir = dir.rotated(randf_range(-aim_error, aim_error))
	return dir


func _do_position() -> void:
	var opp = player.opponent
	var dist = player.global_position.distance_to(opp.global_position)
	var ideal = 120.0 if player.mana >= player.COST_ICE else 250.0
	var dir_to_opp = (opp.global_position - player.global_position).normalized()
	if dist > ideal + 30:
		_move_toward(player.global_position + dir_to_opp * 50)
	elif dist < ideal - 30:
		_move_toward(player.global_position - dir_to_opp * 50)
	else:
		# Strafe
		var strafe = dir_to_opp.rotated(PI / 2.0 * (1 if randf() > 0.5 else -1))
		_move_toward(player.global_position + strafe * 40)


func _go_collect() -> void:
	var orb_nodes = player.get_tree().get_nodes_in_group("orbs")
	if orb_nodes.is_empty():
		if player.global_position.distance_to(target_pos) < 20 or target_pos == Vector2.ZERO:
			target_pos = Vector2(randf_range(200, 1080), randf_range(120, 600))
		_move_toward(target_pos)
		return

	var best = null
	var best_score = -99999.0
	for orb in orb_nodes:
		if not is_instance_valid(orb):
			continue
		var d = player.global_position.distance_to(orb.global_position)
		var score = -d
		if difficulty >= 2:
			# Avoid orbs near opponent
			var opp_dist = player.opponent.global_position.distance_to(orb.global_position)
			if opp_dist < 60:
				score -= 80
		if score > best_score:
			best_score = score
			best = orb

	if best:
		_move_toward(best.global_position)
	else:
		player.velocity = Vector2.ZERO


func _move_toward(target: Vector2) -> void:
	var dir = target - player.global_position
	if dir.length() < 5:
		player.velocity = Vector2.ZERO
		return
	dir = dir.normalized()
	player.facing = dir
	player.velocity = dir * player.SPEED * move_speed_mult
