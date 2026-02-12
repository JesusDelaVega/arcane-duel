extends CharacterBody2D

const ProjectileScene = preload("res://scenes/projectile.tscn")
const AreaEffectScene = preload("res://scenes/area_effect.tscn")

enum State { IDLE, ATTACKING, DEFENDING, DODGING, STUNNED, HIT }

@export var player_id: int = 1
@export var is_ai: bool = false
@export var player_color: Color = Color.CYAN
@export var character_type: int = 0
var is_preview: bool = false

const CHAR_NAMES = ["Mago", "Hechicero", "Chaman", "Nahual", "Brujo", "Sacerdote Sol"]
const CHAR_DESCS = [
	"Hechicero clasico con magia estelar",
	"Maestro de las artes oscuras",
	"Guardian de espiritus ancestrales",
	"Guerrero jaguar con poder animal",
	"Invocador de almas y huesos",
	"Portador del fuego sagrado",
]
const CHAR_COLORS = [
	Color(0.2, 0.8, 0.9),
	Color(0.9, 0.3, 0.6),
	Color(0.15, 0.75, 0.3),
	Color(0.95, 0.75, 0.1),
	Color(0.55, 0.15, 0.8),
	Color(1.0, 0.55, 0.1),
]

# Input prefix for per-player actions ("p1_" or "p2_")
var input_prefix: String = "p1_"

const SPEED = 200.0
const DODGE_SPEED = 400.0
const DODGE_DURATION = 0.2
const DODGE_COOLDOWN = 0.8
const ATTACK_REACH = 55.0
const ARENA = Rect2(150, 70, 980, 580)

const CD_MELEE = 0.35
const CD_FIRE = 1.0
const CD_ICE = 1.5
const CD_SPECIAL = 2.5

const MAX_MANA = 100.0
const MANA_REGEN = 3.0
const MANA_PER_HIT = 10.0
const MANA_PER_ORB = 15.0
const COST_FIRE = 20.0
const COST_ICE = 30.0
const COST_ARCANE = 50.0

var state = State.IDLE
var hp: int = 100
var max_hp: int = 100
var mana: float = 0.0
var facing = Vector2.RIGHT

var state_timer: float = 0.0
var dodge_dir = Vector2.ZERO
var dodge_cd: float = 0.0

var attack_damage: int = 0
var attack_stun: float = 0.0
var attack_hit_checked: bool = false
var attack_time: float = 0.0
var attack_duration: float = 0.0
var attack_is_melee: bool = false

var cd_fire: float = 0.0
var cd_ice: float = 0.0
var cd_special: float = 0.0

var last_ability_name: String = ""
var ability_label_timer: float = 0.0

var anim_time: float = 0.0

# Draw state (set per frame)
var _d_bc = Color.WHITE
var _d_rc = Color.WHITE
var _d_dc = Color.WHITE
var _d_lc = Color.WHITE
var _d_vy = 0.0
var _d_walk = 0.0
var _d_moving = false
var _d_facing = Vector2.RIGHT
var _d_has_facing = true
var _d_last_facing = Vector2.RIGHT

var opponent: CharacterBody2D = null
var ai_controller = null
var ai_difficulty: int = 1

signal health_changed(new_hp: int, max_hp: int)
signal mana_changed(current_mana: float, max_mana_val: float)
signal died()


func _ready() -> void:
	add_to_group("players")
	var collector = $OrbCollector
	collector.area_entered.connect(_on_orb_collected)
	if is_ai:
		ai_controller = preload("res://scripts/ai_controller.gd").new()
		ai_controller.name = "AI"
		ai_controller.difficulty = ai_difficulty
		add_child(ai_controller)
		ai_controller.setup(self)


func _physics_process(delta: float) -> void:
	anim_time += delta

	if is_preview:
		queue_redraw()
		return

	state_timer = max(0.0, state_timer - delta)
	dodge_cd = max(0.0, dodge_cd - delta)
	ability_label_timer = max(0.0, ability_label_timer - delta)
	cd_fire = max(0.0, cd_fire - delta)
	cd_ice = max(0.0, cd_ice - delta)
	cd_special = max(0.0, cd_special - delta)

	# Mana regen pasivo
	if mana < MAX_MANA:
		mana = min(mana + MANA_REGEN * delta, MAX_MANA)
		mana_changed.emit(mana, MAX_MANA)

	if state_timer <= 0.0:
		if state in [State.ATTACKING, State.HIT, State.STUNNED, State.DODGING]:
			state = State.IDLE

	if state == State.ATTACKING and attack_is_melee and not attack_hit_checked:
		attack_time += delta
		if attack_time >= attack_duration * 0.4:
			_check_melee_hit()
			attack_hit_checked = true

	match state:
		State.IDLE:
			if is_ai:
				ai_controller.update(delta)
			else:
				_handle_input()
		State.DEFENDING:
			if is_ai:
				ai_controller.update(delta)
			else:
				_handle_input()
			velocity *= 0.3
		State.DODGING:
			velocity = dodge_dir * DODGE_SPEED
		State.ATTACKING:
			velocity = velocity.move_toward(Vector2.ZERO, 600 * delta)
		State.STUNNED, State.HIT:
			velocity = velocity.move_toward(Vector2.ZERO, 400 * delta)

	move_and_slide()
	_clamp_arena()
	queue_redraw()


func _handle_input() -> void:
	var input = Vector2.ZERO
	input.x = Input.get_axis(input_prefix + "move_left", input_prefix + "move_right")
	input.y = Input.get_axis(input_prefix + "move_up", input_prefix + "move_down")

	if input.length() > 0.1:
		facing = input.normalized()
		velocity = input.normalized() * SPEED
	else:
		velocity = Vector2.ZERO

	if Input.is_action_just_pressed(input_prefix + "special") and cd_special <= 0:
		use_arcane_blast()
	elif Input.is_action_just_pressed(input_prefix + "fire") and cd_fire <= 0:
		use_fireball()
	elif Input.is_action_just_pressed(input_prefix + "ice") and cd_ice <= 0:
		use_ice_wave()
	elif Input.is_action_just_pressed(input_prefix + "attack"):
		use_melee()
	elif Input.is_action_just_pressed(input_prefix + "dodge") and dodge_cd <= 0:
		var ddir = input.normalized() if input.length() > 0.1 else facing
		do_dodge(ddir)

	if state == State.IDLE and Input.is_action_pressed(input_prefix + "defend"):
		state = State.DEFENDING
	elif state == State.DEFENDING and not Input.is_action_pressed(input_prefix + "defend"):
		state = State.IDLE


# ── HABILIDADES ──

func use_melee() -> void:
	if state != State.IDLE and state != State.DEFENDING:
		return
	state = State.ATTACKING
	state_timer = CD_MELEE + 0.15
	attack_damage = 5
	attack_stun = 0.0
	attack_duration = CD_MELEE
	attack_time = 0.0
	attack_hit_checked = false
	attack_is_melee = true
	last_ability_name = "Golpe"
	ability_label_timer = 0.6
	AudioManager.play_sfx("melee")


func use_fireball() -> void:
	if state != State.IDLE and state != State.DEFENDING:
		return
	if mana < COST_FIRE:
		return

	mana -= COST_FIRE
	mana_changed.emit(mana, MAX_MANA)

	var dmg = 18
	var spd = 320.0
	var rad = 10.0

	state = State.ATTACKING
	state_timer = 0.25
	attack_is_melee = false
	cd_fire = CD_FIRE

	var proj = ProjectileScene.instantiate()
	proj.position = global_position + facing * 24
	proj.direction = facing
	proj.speed = spd
	proj.damage = dmg
	proj.stun_time = 0.0
	proj.radius = rad
	proj.proj_color = Color(1, 0.4, 0.1)
	proj.shooter = self
	var main_scene = get_tree().current_scene
	main_scene.add_child(proj)
	if main_scene.has_method("arena_tint"):
		main_scene.arena_tint(Color(1.0, 0.5, 0.1), 0.4)

	last_ability_name = "Fuego"
	ability_label_timer = 1.0
	AudioManager.play_sfx("fire")


func use_ice_wave() -> void:
	if state != State.IDLE and state != State.DEFENDING:
		return
	if mana < COST_ICE:
		return

	mana -= COST_ICE
	mana_changed.emit(mana, MAX_MANA)

	var dmg = 12
	var stun = 0.8
	var max_rad = 100.0

	state = State.ATTACKING
	state_timer = 0.35
	attack_is_melee = false
	cd_ice = CD_ICE

	var effect = AreaEffectScene.instantiate()
	effect.position = global_position
	effect.max_radius = max_rad
	effect.damage = dmg
	effect.stun_time = stun
	effect.effect_color = Color(0.3, 0.6, 1.0)
	effect.shooter = self
	var main_scene = get_tree().current_scene
	main_scene.add_child(effect)
	if main_scene.has_method("arena_tint"):
		main_scene.arena_tint(Color(0.3, 0.6, 1.0), 0.5)

	last_ability_name = "Hielo"
	ability_label_timer = 1.0
	AudioManager.play_sfx("ice")


func use_arcane_blast() -> void:
	if state != State.IDLE and state != State.DEFENDING:
		return
	if mana < COST_ARCANE:
		return

	mana -= COST_ARCANE
	mana_changed.emit(mana, MAX_MANA)

	var dmg = 35
	var stun = 0.6
	var rad = 16.0

	state = State.ATTACKING
	state_timer = 0.5
	attack_is_melee = false
	cd_special = CD_SPECIAL

	var proj = ProjectileScene.instantiate()
	proj.position = global_position + facing * 20
	proj.direction = facing
	proj.speed = 240.0
	proj.damage = dmg
	proj.stun_time = stun
	proj.radius = rad
	proj.proj_color = Color(0.7, 0.2, 0.9)
	proj.shooter = self
	proj.lifetime = 2.5
	var main_scene = get_tree().current_scene
	main_scene.add_child(proj)
	if main_scene.has_method("arena_tint"):
		main_scene.arena_tint(Color(0.7, 0.2, 0.9), 0.6)

	last_ability_name = "ARCANO!"
	ability_label_timer = 1.2
	AudioManager.play_sfx("arcane")


# ── COMBATE ──

func _check_melee_hit() -> void:
	if not is_instance_valid(opponent):
		return
	var dist = global_position.distance_to(opponent.global_position)
	if dist > ATTACK_REACH + 20:
		return
	var dir_to = (opponent.global_position - global_position).normalized()
	if facing.dot(dir_to) < 0.2:
		return
	opponent.receive_hit(attack_damage, attack_stun, global_position)
	# Ganar mana al golpear
	mana = min(mana + MANA_PER_HIT, MAX_MANA)
	mana_changed.emit(mana, MAX_MANA)


func receive_hit(damage: int, stun: float, from: Vector2) -> void:
	if state == State.DODGING:
		AudioManager.play_sfx("dodge")
		return
	if state == State.DEFENDING:
		damage = int(damage * 0.15)
		stun = 0.0
		AudioManager.play_sfx("defend")

	hp = max(0, hp - damage)
	health_changed.emit(hp, max_hp)
	AudioManager.play_sfx("hit")

	if stun > 0:
		state = State.STUNNED
		state_timer = stun
	else:
		state = State.HIT
		state_timer = 0.15

	velocity = (global_position - from).normalized() * 180

	var main = get_tree().current_scene
	if main.has_method("spawn_damage_number"):
		main.spawn_damage_number(global_position, damage, stun > 0.3)
	if main.has_method("spawn_hit_particles"):
		var hit_color = Color(1, 0.3, 0.2) if damage >= 15 else Color(1, 0.8, 0.3)
		var count = clampi(damage / 3, 4, 14)
		main.spawn_hit_particles(global_position, hit_color, count)
	if main.has_method("screen_shake"):
		var intensity = clamp(float(damage) * 0.4, 2.0, 12.0)
		main.screen_shake(intensity)
	# Hitstop en golpes fuertes
	if main.has_method("hitstop") and damage >= 15:
		var freeze_time = 0.05 + clamp(float(damage) * 0.001, 0.0, 0.04)
		main.hitstop(freeze_time)
	# Screen flash en golpes fuertes
	if main.has_method("screen_flash") and damage >= 15:
		if damage >= 30:
			main.screen_flash(Color(1, 0.9, 0.7), 0.15, 0.5)
		elif damage >= 20:
			main.screen_flash(Color(1, 1, 1), 0.12, 0.4)
		else:
			main.screen_flash(Color(1, 1, 1), 0.08, 0.25)

	if hp <= 0:
		AudioManager.play_sfx("death")
		if main.has_method("death_explosion"):
			main.death_explosion(global_position, player_color)
		died.emit()


func do_dodge(dir: Vector2) -> void:
	if state != State.IDLE and state != State.DEFENDING:
		return
	dodge_dir = dir.normalized()
	state = State.DODGING
	state_timer = DODGE_DURATION
	dodge_cd = DODGE_COOLDOWN
	AudioManager.play_sfx("dodge")


func collect_orb(color: String) -> void:
	if mana < MAX_MANA:
		mana = min(mana + MANA_PER_ORB, MAX_MANA)
		mana_changed.emit(mana, MAX_MANA)
		AudioManager.play_sfx("orb")
		var main = get_tree().current_scene
		if main.has_method("spawn_hit_particles"):
			main.spawn_hit_particles(global_position, Color(0.9, 0.75, 0.2), 5)


func _on_orb_collected(area: Area2D) -> void:
	if area.has_method("pickup"):
		area.pickup(self)


func _clamp_arena() -> void:
	position.x = clamp(position.x, ARENA.position.x + 20, ARENA.end.x - 20)
	position.y = clamp(position.y, ARENA.position.y + 20, ARENA.end.y - 20)


# ══════════════════════════════════════════════════════
# VISUAL - Sistema de dibujo con 6 personajes
# ══════════════════════════════════════════════════════

func _draw() -> void:
	_d_moving = velocity.length() > 10
	_d_walk = sin(anim_time * 12.0)
	_d_vy = sin(anim_time * 2.0) + sin(anim_time * 3.0) * 0.3
	var f_len_sq = facing.length_squared()
	if facing.is_finite() and f_len_sq >= 0.0001:
		_d_last_facing = facing.normalized()
	_d_facing = _d_last_facing
	_d_has_facing = _d_last_facing.length_squared() >= 0.0001

	_d_bc = player_color
	_d_rc = player_color.darkened(0.15)
	_d_dc = player_color.darkened(0.4)
	_d_lc = player_color.lightened(0.3)

	if state == State.STUNNED:
		_d_bc = Color(1, 1, 0.3)
		_d_rc = Color(0.9, 0.9, 0.2)
		_d_dc = Color(0.7, 0.7, 0.0)
		_d_lc = Color(1, 1, 0.6)
	elif state == State.HIT:
		_d_bc = Color.WHITE
		_d_rc = Color(0.92, 0.92, 0.92)
		_d_dc = Color(0.8, 0.8, 0.8)
		_d_lc = Color.WHITE
	elif state == State.DODGING:
		_d_bc = Color(player_color, 0.4)
		_d_rc = Color(player_color.darkened(0.15), 0.4)
		_d_dc = Color(player_color.darkened(0.4), 0.4)
		_d_lc = Color(player_color.lightened(0.3), 0.4)

	var hp_r = float(hp) / float(max(1, max_hp))
	if hp_r <= 0.25 and state != State.HIT:
		var d = abs(sin(anim_time * 5.0)) * 0.3
		_d_bc = _d_bc.lerp(Color(1, 0.2, 0.1), d)
		_d_rc = _d_rc.lerp(Color(0.6, 0.1, 0.05), d * 0.5)

	# Sombra
	draw_circle(Vector2(2, 18), 11, Color(0, 0, 0, 0.18))

	# Aura de mana
	if mana > 5.0 and not is_preview:
		var mana_r = mana / MAX_MANA
		var ac = player_color.lightened(0.2)
		var p = sin(anim_time * 3.5) * 0.04 + 0.06 + mana_r * 0.1
		var ar = 16.0 + mana_r * 10.0
		draw_circle(Vector2(0, _d_vy), ar + 4, Color(ac.r, ac.g, ac.b, p * 0.3))
		draw_circle(Vector2(0, _d_vy), ar, Color(ac.r, ac.g, ac.b, p))
		# Particulas de mana girando
		if mana_r > 0.3:
			var num_p = int(mana_r * 4.0)
			for i in num_p:
				var ma = anim_time * 2.0 + float(i) * TAU / float(num_p)
				var mr = ar + 2.0
				var mp = Vector2(cos(ma), sin(ma)) * mr + Vector2(0, _d_vy)
				draw_circle(mp, 1.5, Color(ac.r, ac.g, ac.b, p * 1.5))

	# Personaje
	match character_type:
		0: _draw_char_mago()
		1: _draw_char_hechicero()
		2: _draw_char_chaman()
		3: _draw_char_nahual()
		4: _draw_char_brujo()
		5: _draw_char_sacerdote()
		_: _draw_char_mago()

	if not is_preview:
		_draw_state_effects()
		_draw_hud_elements()


# ── HELPERS COMPARTIDOS ──

func _draw_std_cape(col: Color) -> void:
	if not _d_has_facing:
		return
	var cd = -_d_facing
	var sw = sin(anim_time * 2.5) * 4.0
	var ms = sin(anim_time * 8.0) * 3.0 if _d_moving else 0.0
	var cp = Vector2(-cd.y, cd.x)
	var mid = cd * 14 + cp * (sw + ms) * 0.5
	var tip = cd * 22 + cp * (sw + ms)
	var c1 = Vector2(-5, -2 + _d_vy)
	var c2 = Vector2(5, -2 + _d_vy)
	var c3 = mid + cp * 6 + Vector2(0, 4 + _d_vy)
	var c4 = tip + Vector2(0, 10 + _d_vy)
	var c5 = mid - cp * 6 + Vector2(0, 4 + _d_vy)
	var pts = PackedVector2Array([c1, c2, c3, c4, c5])
	var tri = Geometry2D.triangulate_polygon(pts)
	if _is_valid_poly(pts) and tri.size() >= 3:
		draw_polygon(pts,
			PackedColorArray([col, col, col, col.darkened(0.2), col]))
	# Borde brillante de la capa
	draw_polyline(PackedVector2Array([c1, c5, c4, c3, c2]),
		col.lightened(0.15), 1.0)
	# Pliegue central
	var fold = (c1 + c2) * 0.5
	draw_line(fold, c4, Color(col.r, col.g, col.b, 0.3), 1.0)


func _is_valid_poly(pts: PackedVector2Array) -> bool:
	if pts.size() < 3:
		return false
	var area = 0.0
	for i in pts.size():
		var p = pts[i]
		if not p.is_finite():
			return false
		var q = pts[(i + 1) % pts.size()]
		area += p.x * q.y - q.x * p.y
	return abs(area) > 0.01



func _draw_std_feet() -> void:
	var fa = _d_walk * 3.0 if _d_moving else 0.0
	var fd = _d_facing
	# Pierna izquierda
	var fl = Vector2(-5, 14 + _d_vy + fa)
	draw_circle(fl, 3.5, _d_dc)
	draw_circle(fl + fd * 2, 2.0, _d_dc.darkened(0.15))
	draw_arc(fl, 3.5, 0, TAU, 10, _d_dc.darkened(0.2), 1.0)
	# Pierna derecha
	var fr = Vector2(5, 14 + _d_vy - fa)
	draw_circle(fr, 3.5, _d_dc)
	draw_circle(fr + fd * 2, 2.0, _d_dc.darkened(0.15))
	draw_arc(fr, 3.5, 0, TAU, 10, _d_dc.darkened(0.2), 1.0)
	# Polvo al caminar
	if _d_moving:
		var dust_a = abs(sin(anim_time * 6.0))
		if dust_a > 0.8:
			var dust_p = Vector2(0, 17 + _d_vy) - fd * 4
			draw_circle(dust_p, 2.0, Color(0.5, 0.45, 0.35, 0.15))
			draw_circle(dust_p + Vector2(-2, -1), 1.5, Color(0.5, 0.45, 0.35, 0.1))


func _draw_std_body() -> void:
	var v = _d_vy
	# Tunica base
	draw_polygon(PackedVector2Array([
		Vector2(-6, -3 + v), Vector2(6, -3 + v),
		Vector2(12, 12 + v), Vector2(-12, 12 + v)
	]), PackedColorArray([_d_rc, _d_rc, _d_rc.darkened(0.05), _d_rc.darkened(0.05)]))
	# Bordes
	draw_polyline(PackedVector2Array([
		Vector2(-6, -3 + v), Vector2(-12, 12 + v),
		Vector2(12, 12 + v), Vector2(6, -3 + v)
	]), _d_dc, 1.5)
	# Pliegues de tela
	draw_line(Vector2(-3, 4 + v), Vector2(-5, 12 + v), Color(_d_dc.r, _d_dc.g, _d_dc.b, 0.35), 1.0)
	draw_line(Vector2(3, 4 + v), Vector2(5, 12 + v), Color(_d_dc.r, _d_dc.g, _d_dc.b, 0.35), 1.0)
	draw_line(Vector2(0, 5 + v), Vector2(0, 12 + v), Color(_d_dc.r, _d_dc.g, _d_dc.b, 0.2), 1.0)
	# Cinturon con hebilla
	draw_line(Vector2(-8, 3 + v), Vector2(8, 3 + v), _d_dc, 2.0)
	draw_rect(Rect2(Vector2(-2, 1.5 + v), Vector2(4, 3)), _d_lc)
	# Borde inferior de tunica
	draw_line(Vector2(-12, 12 + v), Vector2(12, 12 + v), _d_dc.lightened(0.1), 1.5)


func _draw_std_head() -> void:
	var hy = -11.0 + _d_vy
	draw_line(Vector2(0, -4 + _d_vy), Vector2(0, hy + 7.5), _d_bc.darkened(0.1), 4.0)
	draw_circle(Vector2(0, hy), 7.5, _d_bc)
	draw_arc(Vector2(0, hy), 7.5, 0, TAU, 24, _d_dc, 1.5)


func _draw_std_eyes(iris_c: Color) -> void:
	var hy = -11.0 + _d_vy
	var ed = _d_facing
	var ep = Vector2(-ed.y, ed.x)
	var eb = Vector2(0, hy) + ed * 3.5
	var e1 = eb + ep * 2.8
	var e2 = eb - ep * 2.8
	draw_circle(e1, 2.2, Color.WHITE)
	draw_circle(e2, 2.2, Color.WHITE)
	draw_circle(e1 + ed * 0.5, 1.4, iris_c)
	draw_circle(e2 + ed * 0.5, 1.4, iris_c)
	draw_circle(e1 + ed * 0.7, 0.7, Color(0.05, 0.05, 0.1))
	draw_circle(e2 + ed * 0.7, 0.7, Color(0.05, 0.05, 0.1))
	draw_circle(e1 + ed * 0.2 + ep * 0.5, 0.5, Color(1, 1, 1, 0.8))
	draw_circle(e2 + ed * 0.2 + ep * 0.5, 0.5, Color(1, 1, 1, 0.8))
	# Cejas
	var b1 = e1 - ed * 0.5 + Vector2(0, -2.5)
	var b2 = e2 - ed * 0.5 + Vector2(0, -2.5)
	var bc2 = Color(0.25, 0.2, 0.15)
	if state == State.ATTACKING:
		draw_line(b1 - ep * 2, b1 + ep + Vector2(0, -1.5), bc2, 1.5)
		draw_line(b2 + ep * 2, b2 - ep + Vector2(0, -1.5), bc2, 1.5)
	elif state == State.STUNNED:
		draw_line(b1 - ep * 2 + Vector2(0, -1), b1 + ep + Vector2(0, 1), bc2, 1.5)
		draw_line(b2 + ep * 2 + Vector2(0, -1), b2 - ep + Vector2(0, 1), bc2, 1.5)
	else:
		draw_line(b1 - ep * 1.5, b1 + ep * 1.5 + Vector2(0, -0.5), bc2, 1.2)
		draw_line(b2 + ep * 1.5, b2 - ep * 1.5 + Vector2(0, -0.5), bc2, 1.2)


func _draw_std_mouth() -> void:
	var hy = -11.0 + _d_vy
	var ed = _d_facing
	var mp = Vector2(0, hy) + ed * 5.0 + Vector2(0, 2.5)
	var hr = float(hp) / float(max(1, max_hp))
	if state == State.STUNNED:
		draw_circle(mp, 2.0, Color(0.15, 0.1, 0.1))
	elif state == State.ATTACKING:
		draw_arc(mp, 2.5, 0.2, PI - 0.2, 8, Color(0.15, 0.1, 0.1), 2.0)
	elif state == State.HIT:
		draw_arc(mp, 1.5, PI + 0.3, TAU - 0.3, 6, Color(0.2, 0.15, 0.1), 1.5)
	elif hr <= 0.25:
		draw_arc(mp, 1.5, PI + 0.3, TAU - 0.3, 6, Color(0.25, 0.2, 0.15), 1.0)
	else:
		draw_arc(mp, 1.2, 0.3, PI - 0.3, 6, Color(0.25, 0.2, 0.15), 1.0)


func _draw_std_attack() -> void:
	if state == State.ATTACKING:
		if attack_is_melee:
			var prog = attack_time / max(attack_duration, 0.01)
			var sw = lerp(-1.2, 1.4, clamp(prog * 2.5, 0.0, 1.0))
			var wd = _d_facing.rotated(sw).normalized()
			var a_s = wd * 6 + Vector2(0, _d_vy)
			var a_e = wd * 30 + Vector2(0, _d_vy)
			if prog > 0.1 and prog < 0.75:
				for t in 3:
					var td = _d_facing.rotated(sw - 0.3 * (t + 1)).normalized()
					draw_line(td * 10 + Vector2(0, _d_vy), td * 28 + Vector2(0, _d_vy), Color(1, 1, 1, 0.12 - float(t) * 0.03), 2.0)
			draw_line(a_s, a_e, Color(0.45, 0.3, 0.15), 3.0)
			draw_line(a_s, a_e, Color(0.6, 0.4, 0.2), 1.5)
			var ig = 1.0 if prog > 0.3 and prog < 0.6 else 0.4
			draw_circle(a_e, 4, Color(1, 1, 0.7, ig * 0.6))
			draw_circle(a_e, 2, Color(1, 1, 1, ig))
		else:
			var cd2 = _d_facing
			var sb = cd2 * 4 + Vector2(0, _d_vy)
			var st = cd2 * 26 + Vector2(0, _d_vy - 4)
			draw_line(sb, st, Color(0.45, 0.3, 0.15), 2.5)
			var cp = sin(anim_time * 12.0) * 0.2 + 0.8
			draw_circle(st, 8, Color(1, 0.8, 0.3, cp * 0.25))
			draw_circle(st, 5, Color(1, 0.9, 0.5, cp * 0.5))
			draw_circle(st, 3, Color(1, 1, 1, cp))
			for i in 4:
				var sa = anim_time * 6.0 + float(i) * TAU / 4.0
				var sp = st + Vector2(cos(sa), sin(sa)) * 6.0
				draw_circle(sp, 1.5, Color(1, 0.9, 0.4, 0.7))
			draw_circle(sb + cd2 * 2 + Vector2(0, 1), 3, _d_bc.lightened(0.15))
	else:
		var ss = Vector2(-_d_facing.y, _d_facing.x)
		draw_circle(-ss * 5 + _d_facing * 6 + Vector2(0, 2 + _d_vy), 2.5, _d_bc.lightened(0.15))


func _draw_state_effects() -> void:
	# Circulo runico al lanzar magia
	if state == State.ATTACKING and not attack_is_melee:
		var cast_prog = state_timer / 0.5
		var cast_a = cast_prog * 0.6 + 0.4
		var rc = player_color.lightened(0.3)
		draw_arc(Vector2(0, _d_vy + 14), 16, 0, TAU, 24, Color(rc.r, rc.g, rc.b, cast_a * 0.3), 1.5)
		draw_arc(Vector2(0, _d_vy + 14), 12, anim_time * 3.0, anim_time * 3.0 + TAU * 0.7, 16, Color(rc.r, rc.g, rc.b, cast_a * 0.5), 1.0)
		# Runas girando
		for i in 4:
			var ra = anim_time * 4.0 + float(i) * TAU / 4.0
			var rp = Vector2(cos(ra), sin(ra) * 0.5) * 14 + Vector2(0, _d_vy + 14)
			draw_circle(rp, 1.5, Color(rc.r, rc.g, rc.b, cast_a * 0.6))

	if state == State.DEFENDING:
		var sd = _d_facing
		var sc = sd * 20
		var sa = sd.angle()
		var sp = sin(anim_time * 6.0) * 0.15 + 0.85
		var perp = Vector2(-sd.y, sd.x)
		# Glow exterior
		draw_arc(sc, 20, sa - 1.4, sa + 1.4, 24, Color(0.2, 0.4, 0.9, sp * 0.15), 10.0)
		# Barrera hexagonal - lineas cruzadas
		for i in 5:
			var la = sa - 1.2 + float(i) * 0.6
			var lp1 = sc + Vector2(cos(la), sin(la)) * 6
			var lp2 = sc + Vector2(cos(la), sin(la)) * 18
			draw_line(lp1, lp2, Color(0.4, 0.7, 1.0, sp * 0.5), 1.5)
		# Anillos de escudo con pattern
		draw_arc(sc, 18, sa - 1.3, sa + 1.3, 28, Color(0.3, 0.5, 0.95, sp * 0.4), 4.0)
		draw_arc(sc, 14, sa - 1.2, sa + 1.2, 24, Color(0.4, 0.65, 1.0, sp * 0.7), 2.5)
		draw_arc(sc, 10, sa - 1.0, sa + 1.0, 20, Color(0.6, 0.85, 1.0, sp), 1.5)
		# Hexagonos pequenos en el escudo
		for i in 3:
			var hex_a = sa - 0.7 + float(i) * 0.7
			var hex_p = sc + Vector2(cos(hex_a), sin(hex_a)) * 14
			var hex_r = 3.5
			var hex_pts = PackedVector2Array()
			for j in 7:
				var ha = float(j) * TAU / 6.0 + anim_time * 0.5
				hex_pts.append(hex_p + Vector2(cos(ha), sin(ha)) * hex_r)
			draw_polyline(hex_pts, Color(0.5, 0.8, 1.0, sp * 0.6), 1.0)
		# Runas girando en el borde
		for i in 5:
			var rune_a = sa - 1.0 + float(i) * 0.5
			var rune_p = sc + Vector2(cos(rune_a), sin(rune_a)) * 17
			var rg = sin(anim_time * 4.0 + float(i) * 1.5) * 0.3 + 0.5
			draw_circle(rune_p, 2.0, Color(0.6, 0.85, 1.0, rg))
			draw_circle(rune_p, 1.0, Color(0.9, 0.95, 1.0, rg * 1.3))
		# Particulas de energia fluyendo por el escudo
		for i in 3:
			var pa = anim_time * 3.0 + float(i) * 2.1
			var pt = fmod(pa, 1.0)
			var pp_a = sa - 1.2 + pt * 2.4
			var pp = sc + Vector2(cos(pp_a), sin(pp_a)) * 15
			draw_circle(pp, 1.5, Color(0.8, 0.9, 1.0, (1.0 - pt) * sp * 0.8))

	if state == State.DODGING:
		var back = -dodge_dir.normalized()
		# Afterimage siluetas con forma de cuerpo
		for g in 4:
			var ghost_d = float(g + 1) * 10.0
			var ga = 0.25 - float(g) * 0.055
			var gp = back * ghost_d
			var gc = Color(_d_bc.r, _d_bc.g, _d_bc.b, ga)
			var gc_dim = Color(_d_bc.r, _d_bc.g, _d_bc.b, ga * 0.4)
			# Glow exterior
			draw_circle(gp + Vector2(0, _d_vy), 12, gc_dim)
			# Cabeza
			draw_circle(gp + Vector2(0, -11 + _d_vy), 6, gc)
			# Cuerpo
			draw_rect(Rect2(gp + Vector2(-5, -4 + _d_vy), Vector2(10, 16)), gc)
			# Pies
			draw_circle(gp + Vector2(-4, 14 + _d_vy), 2.5, gc)
			draw_circle(gp + Vector2(4, 14 + _d_vy), 2.5, gc)
		# Lineas de velocidad
		var perp = Vector2(-back.y, back.x)
		for i in 8:
			var loff = perp * float(i - 4) * 4.0
			var la = 0.25 - float(i % 3) * 0.06
			draw_line(back * 8 + loff, back * (22 + float(i) * 5) + loff,
				Color(1, 1, 1, la), 1.5)
		# Particulas de energia
		for i in 5:
			var pa = anim_time * 10.0 + float(i) * 1.5
			var pp = back * (10 + sin(pa) * 5) + perp * cos(pa) * 10
			draw_circle(pp, 1.5, Color(player_color.r, player_color.g, player_color.b, 0.4))

	if state == State.STUNNED:
		var hy = -11.0 + _d_vy
		for i in 4:
			var a = anim_time * 3.5 + float(i) * TAU / 4.0
			var sp = Vector2(cos(a), sin(a)) * 15 + Vector2(0, hy - 8)
			draw_circle(sp, 2.5, Color(1, 1, 0.3, 0.9))
			draw_circle(sp, 1.2, Color(1, 1, 0.8))
			# Puntas de estrella
			for j in 4:
				var ja = anim_time * 5.0 + float(j) * TAU / 4.0
				draw_line(sp, sp + Vector2(cos(ja), sin(ja)) * 3, Color(1, 1, 0.5, 0.5), 1.0)

	var hr = float(hp) / float(max(1, max_hp))
	if hr <= 0.3 and hr > 0 and state != State.HIT:
		var hy = -11.0 + _d_vy
		var sy = sin(anim_time * 2.0) * 3.0
		# Gota de sudor con forma
		draw_circle(Vector2(7, hy - 2 + sy), 1.5, Color(0.5, 0.7, 1, 0.5))
		draw_polygon(PackedVector2Array([
			Vector2(7, hy - 4 + sy), Vector2(8, hy - 2 + sy),
			Vector2(7, hy - 0.5 + sy), Vector2(6, hy - 2 + sy)
		]), PackedColorArray([
			Color(0.5, 0.7, 1, 0.2), Color(0.5, 0.7, 1, 0.5),
			Color(0.5, 0.7, 1, 0.5), Color(0.5, 0.7, 1, 0.2)
		]))


func _draw_hud_elements() -> void:
	var hr = float(hp) / float(max(1, max_hp))
	var bw = 36.0
	var bh = 5.0
	var bp = Vector2(-bw / 2.0, -40.0)
	draw_rect(Rect2(bp, Vector2(bw, bh)), Color(0.1, 0.1, 0.1))
	var hc = Color(0.2, 0.8, 0.3) if hr > 0.5 else (Color(0.9, 0.75, 0.1) if hr > 0.25 else Color(0.9, 0.15, 0.1))
	draw_rect(Rect2(bp, Vector2(bw * hr, bh)), hc)
	draw_rect(Rect2(bp, Vector2(bw, bh)), Color(0.3, 0.3, 0.35), false, 1.0)

	if ability_label_timer > 0:
		var font = ThemeDB.fallback_font
		if font:
			var alpha = min(1.0, ability_label_timer * 2)
			var fu = (1.0 - ability_label_timer) * 8.0
			draw_string(font, Vector2(-40, -48 - fu), last_ability_name,
				HORIZONTAL_ALIGNMENT_CENTER, 80, 13, Color(1, 1, 1, alpha))

	# Barra de mana (mas grande y clara)
	var mw = 36.0
	var mh = 4.0
	var mpos = Vector2(-mw / 2.0, -34.0)
	# Fondo con glow
	draw_rect(Rect2(mpos - Vector2(1, 1), Vector2(mw + 2, mh + 2)), Color(0.1, 0.1, 0.25, 0.4))
	draw_rect(Rect2(mpos, Vector2(mw, mh)), Color(0.04, 0.04, 0.12))
	var mr = mana / MAX_MANA
	# Color que cambia segun nivel de mana
	var mc = Color(0.15, 0.3, 0.6).lerp(Color(0.4, 0.5, 1.0), mr)
	draw_rect(Rect2(mpos, Vector2(mw * mr, mh)), mc)
	# Brillo en la barra cuando esta llena
	if mr > 0.9:
		var mg = sin(anim_time * 4.0) * 0.15 + 0.2
		draw_rect(Rect2(mpos, Vector2(mw * mr, mh)), Color(0.6, 0.7, 1.0, mg))
	# Borde
	draw_rect(Rect2(mpos, Vector2(mw, mh)), Color(0.25, 0.3, 0.5), false, 1.0)
	# Marcas de costo (lineas en 20%, 30%, 50% = fire, ice, arcane)
	var fire_x = mpos.x + mw * (COST_FIRE / MAX_MANA)
	var ice_x = mpos.x + mw * (COST_ICE / MAX_MANA)
	var arc_x = mpos.x + mw * (COST_ARCANE / MAX_MANA)
	draw_line(Vector2(fire_x, mpos.y), Vector2(fire_x, mpos.y + mh), Color(1, 0.5, 0.2, 0.35), 1.0)
	draw_line(Vector2(ice_x, mpos.y), Vector2(ice_x, mpos.y + mh), Color(0.3, 0.6, 1, 0.35), 1.0)
	draw_line(Vector2(arc_x, mpos.y), Vector2(arc_x, mpos.y + mh), Color(0.7, 0.3, 0.9, 0.35), 1.0)
	# Numero de mana
	var font = ThemeDB.fallback_font
	if font and mana >= 1.0:
		var mana_str = str(int(mana))
		var mana_col = Color(0.5, 0.6, 0.9, 0.8) if mr < 0.5 else Color(0.7, 0.8, 1.0, 0.9)
		var mana_size = font.get_string_size(mana_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9)
		var mana_pos = Vector2(-mana_size.x * 0.5, -36.0)
		draw_string(font, mana_pos, mana_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, mana_col)


# ══════════════════════════════════════════════════════
# PERSONAJE 0: MAGO - Sombrero puntiagudo, vara estelar
# ══════════════════════════════════════════════════════

func _draw_char_mago() -> void:
	_draw_std_cape(_d_dc.darkened(0.15))
	_draw_std_feet()
	# Vara idle
	if state != State.ATTACKING:
		var ss = Vector2(-_d_facing.y, _d_facing.x)
		var sd = _d_facing.rotated(0.4).normalized()
		var sb = ss * 7 + Vector2(0, _d_vy)
		var st = sb + sd * 28 + Vector2(0, -8)
		draw_line(sb, st, Color(0.45, 0.3, 0.15), 2.5)
		var sg = sin(anim_time * 4.0) * 0.2 + 0.8
		draw_circle(st, 3, Color(1, 1, 0.5, sg))
		for i in 4:
			var ra = anim_time * 1.5 + float(i) * TAU / 4.0
			draw_line(st + Vector2(cos(ra), sin(ra)) * 3, st + Vector2(cos(ra), sin(ra)) * 6, Color(1, 1, 0.6, sg * 0.4), 1.0)
	_draw_std_body()
	# Estrella emblema
	draw_circle(Vector2(0, 7 + _d_vy), 2.5, _d_lc)
	draw_line(Vector2(0, 4 + _d_vy), Vector2(0, 10 + _d_vy), _d_lc, 1.0)
	draw_line(Vector2(-3, 7 + _d_vy), Vector2(3, 7 + _d_vy), _d_lc, 1.0)
	# Hombreras redondas
	draw_circle(Vector2(-8, -2 + _d_vy), 4, _d_rc.lightened(0.1))
	draw_arc(Vector2(-8, -2 + _d_vy), 4, 0, TAU, 12, _d_dc, 1.0)
	draw_circle(Vector2(8, -2 + _d_vy), 4, _d_rc.lightened(0.1))
	draw_arc(Vector2(8, -2 + _d_vy), 4, 0, TAU, 12, _d_dc, 1.0)
	_draw_std_head()
	_draw_std_eyes(Color(0.2, 0.5, 0.9))
	_draw_std_mouth()
	# Sombrero puntiagudo
	var hb = -11.0 + _d_vy - 5.5
	draw_polygon(PackedVector2Array([
		Vector2(3, hb - 18), Vector2(-11, hb + 2), Vector2(11, hb + 2)
	]), PackedColorArray([_d_rc.lightened(0.2), _d_dc, _d_dc]))
	draw_line(Vector2(-11, hb + 2), Vector2(11, hb + 2), _d_dc, 3.0)
	var sg2 = sin(anim_time * 3.0) * 0.3 + 0.7
	draw_circle(Vector2(3, hb - 18), 2.5, Color(1, 1, 0.5, sg2))
	# Chispas estelares orbitando
	for i in 3:
		var sa = anim_time * 2.0 + float(i) * TAU / 3.0
		var sr = 20.0 + sin(anim_time * 3.0 + float(i)) * 3.0
		var sp = Vector2(cos(sa), sin(sa)) * sr + Vector2(0, _d_vy)
		var sparkle = sin(anim_time * 8.0 + float(i) * 2.0) * 0.3 + 0.7
		draw_circle(sp, 1.5, Color(0.8, 0.9, 1, sparkle * 0.4))
		draw_circle(sp, 0.8, Color(1, 1, 1, sparkle * 0.6))
	_draw_std_attack()


# ══════════════════════════════════════════════════════
# PERSONAJE 1: HECHICERO - Capucha con cuernos, cristal
# ══════════════════════════════════════════════════════

func _draw_char_hechicero() -> void:
	_draw_std_cape(_d_dc.darkened(0.2))
	_draw_std_feet()
	# Vara cristal idle
	if state != State.ATTACKING:
		var ss = Vector2(-_d_facing.y, _d_facing.x)
		var sd = _d_facing.rotated(0.4).normalized()
		var sb = ss * 7 + Vector2(0, _d_vy)
		var st = sb + sd * 28 + Vector2(0, -8)
		draw_line(sb, st, Color(0.35, 0.25, 0.4), 2.5)
		var gp = sin(anim_time * 3.0) * 0.15 + 0.85
		draw_circle(st, 3, Color(0.8, 0.2, 1.0, gp))
		draw_polygon(PackedVector2Array([
			st + Vector2(0, -4), st + Vector2(3, 0), st + Vector2(0, 4), st + Vector2(-3, 0)
		]), PackedColorArray([Color(0.9, 0.4, 1, gp), Color(0.6, 0.1, 0.8, gp), Color(0.9, 0.4, 1, gp), Color(0.6, 0.1, 0.8, gp)]))
	_draw_std_body()
	# Gema emblema
	draw_polygon(PackedVector2Array([
		Vector2(0, 4.5 + _d_vy), Vector2(2.5, 7 + _d_vy), Vector2(0, 9.5 + _d_vy), Vector2(-2.5, 7 + _d_vy)
	]), PackedColorArray([_d_lc, _d_lc, _d_lc, _d_lc]))
	# Hombreras puntiagudas
	draw_polygon(PackedVector2Array([
		Vector2(-5, -4 + _d_vy), Vector2(-12, -3 + _d_vy), Vector2(-7, 1 + _d_vy)
	]), PackedColorArray([_d_rc.lightened(0.1), _d_dc, _d_rc]))
	draw_polygon(PackedVector2Array([
		Vector2(5, -4 + _d_vy), Vector2(12, -3 + _d_vy), Vector2(7, 1 + _d_vy)
	]), PackedColorArray([_d_rc.lightened(0.1), _d_dc, _d_rc]))
	_draw_std_head()
	_draw_std_eyes(Color(0.8, 0.2, 0.4))
	_draw_std_mouth()
	# Capucha con cuernos
	var hb = -11.0 + _d_vy - 5.5
	draw_polygon(PackedVector2Array([
		Vector2(0, hb - 10), Vector2(-10, hb), Vector2(-8, hb + 5), Vector2(8, hb + 5), Vector2(10, hb)
	]), PackedColorArray([_d_rc.lightened(0.1), _d_dc, _d_dc, _d_dc, _d_dc]))
	draw_line(Vector2(-7, hb - 1), Vector2(-12, hb - 13), _d_dc, 2.5)
	draw_line(Vector2(7, hb - 1), Vector2(12, hb - 13), _d_dc, 2.5)
	var hg = sin(anim_time * 2.5) * 0.3 + 0.7
	draw_circle(Vector2(-12, hb - 13), 2, Color(1, 0.3, 0.5, hg))
	draw_circle(Vector2(12, hb - 13), 2, Color(1, 0.3, 0.5, hg))
	# Niebla oscura a los pies
	for i in 5:
		var ma = anim_time * 1.5 + float(i) * 1.3
		var mx = sin(ma) * 12.0
		var my = cos(ma * 0.7) * 4.0
		draw_circle(Vector2(mx, 14 + my + _d_vy), 3.0 + sin(anim_time + float(i)) * 1.0, Color(0.3, 0.1, 0.4, 0.08))
	_draw_std_attack()


# ══════════════════════════════════════════════════════
# PERSONAJE 2: CHAMAN - Penacho de plumas, pintura tribal
# ══════════════════════════════════════════════════════

func _draw_char_chaman() -> void:
	# Capa de plumas colgantes
	var cd = -_d_facing
	var cp = Vector2(-cd.y, cd.x)
	var sw = sin(anim_time * 3.0) * 3.0
	for i in 5:
		var off = float(i - 2) * 4.0
		var base = cp * off + Vector2(0, -1 + _d_vy)
		var tip = cd * (16 + float(i % 2) * 4) + cp * (off + sw) + Vector2(0, 8 + _d_vy)
		var fc = [Color(0.8, 0.2, 0.1), Color(0.1, 0.6, 0.2), Color(0.9, 0.7, 0.1), Color(0.1, 0.6, 0.2), Color(0.8, 0.2, 0.1)]
		draw_line(base, tip, fc[i].darkened(0.3), 3.0)
		draw_line(base, tip, fc[i], 1.5)

	# Pies descalzos/sandalias
	var fa = _d_walk * 3.0 if _d_moving else 0.0
	draw_circle(Vector2(-5, 14 + _d_vy + fa), 3, Color(0.55, 0.35, 0.2))
	draw_circle(Vector2(5, 14 + _d_vy - fa), 3, Color(0.55, 0.35, 0.2))

	# Vara con sonaja
	if state != State.ATTACKING:
		var ss = Vector2(-_d_facing.y, _d_facing.x)
		var sd = _d_facing.rotated(0.4).normalized()
		var sb = ss * 7 + Vector2(0, _d_vy)
		var st = sb + sd * 26 + Vector2(0, -6)
		draw_line(sb, st, Color(0.5, 0.35, 0.15), 2.5)
		# Sonaja (circulitos que se mueven)
		var rattle = sin(anim_time * 6.0) * 2.0
		draw_circle(st + Vector2(rattle, 0), 3, Color(0.8, 0.5, 0.1))
		draw_circle(st + Vector2(-rattle, -2), 2, Color(0.6, 0.3, 0.05))
		# Plumita colgando
		draw_line(st, st + Vector2(sin(anim_time * 2.0) * 2, 6), Color(0.8, 0.2, 0.1), 1.5)

	# Cuerpo - Huipil (poncho mas ancho)
	var v = _d_vy
	draw_polygon(PackedVector2Array([
		Vector2(-8, -4 + v), Vector2(8, -4 + v),
		Vector2(14, 12 + v), Vector2(-14, 12 + v)
	]), PackedColorArray([_d_rc, _d_rc, _d_rc, _d_rc]))
	draw_polyline(PackedVector2Array([
		Vector2(-8, -4 + v), Vector2(-14, 12 + v), Vector2(14, 12 + v), Vector2(8, -4 + v)
	]), _d_dc, 1.5)
	# Patron zigzag
	for i in 5:
		var zx = -8.0 + float(i) * 4.0
		var zy = 6.0 + v
		draw_line(Vector2(zx, zy), Vector2(zx + 2, zy - 3), Color(0.9, 0.6, 0.1, 0.6), 1.5)
		draw_line(Vector2(zx + 2, zy - 3), Vector2(zx + 4, zy), Color(0.9, 0.6, 0.1, 0.6), 1.5)
	# Espiral emblema
	draw_arc(Vector2(0, 7 + v), 3, 0, TAU * 0.75, 12, _d_lc, 1.5)
	draw_arc(Vector2(0, 7 + v), 1.5, PI, PI + TAU * 0.75, 8, _d_lc, 1.5)

	# Hombreras de plumas
	draw_polygon(PackedVector2Array([
		Vector2(-7, -3 + v), Vector2(-14, -5 + v), Vector2(-10, 0 + v)
	]), PackedColorArray([Color(0.1, 0.6, 0.2), Color(0.8, 0.5, 0.1), Color(0.1, 0.6, 0.2)]))
	draw_polygon(PackedVector2Array([
		Vector2(7, -3 + v), Vector2(14, -5 + v), Vector2(10, 0 + v)
	]), PackedColorArray([Color(0.1, 0.6, 0.2), Color(0.8, 0.5, 0.1), Color(0.1, 0.6, 0.2)]))

	_draw_std_head()
	_draw_std_eyes(Color(0.3, 0.6, 0.2))
	# Pintura facial - lineas en mejillas
	var hy = -11.0 + _d_vy
	var ed = _d_facing
	var ep = Vector2(-ed.y, ed.x)
	var cheek1 = Vector2(0, hy) + ed * 3.0 + ep * 5.0
	var cheek2 = Vector2(0, hy) + ed * 3.0 - ep * 5.0
	for j in 3:
		draw_line(cheek1 + Vector2(0, float(j) * 2 - 2), cheek1 + ep * 3 + Vector2(0, float(j) * 2 - 2), Color(0.9, 0.3, 0.1, 0.7), 1.0)
		draw_line(cheek2 + Vector2(0, float(j) * 2 - 2), cheek2 - ep * 3 + Vector2(0, float(j) * 2 - 2), Color(0.9, 0.3, 0.1, 0.7), 1.0)
	# Punto en frente
	draw_circle(Vector2(0, hy) + ed * 1.0 + Vector2(0, -3), 1.5, Color(0.1, 0.7, 0.3))
	_draw_std_mouth()

	# Penacho de plumas (abanico)
	var hat_y = hy - 6.0
	var feather_colors = [Color(0.9, 0.15, 0.1), Color(0.1, 0.7, 0.2), Color(0.9, 0.7, 0.1), Color(0.1, 0.5, 0.8), Color(0.9, 0.15, 0.1)]
	for i in 5:
		var angle = -0.6 + float(i) * 0.3
		var fdir = Vector2(sin(angle), -cos(angle))
		var flen = 16.0 + float(i % 2) * 4.0
		var fbase = Vector2(0, hat_y)
		var ftip = fbase + fdir * flen
		draw_line(fbase, ftip, feather_colors[i].darkened(0.3), 3.0)
		draw_line(fbase, ftip, feather_colors[i], 2.0)
		draw_circle(ftip, 1.5, feather_colors[i].lightened(0.3))
	# Banda base del penacho
	draw_line(Vector2(-8, hat_y + 1), Vector2(8, hat_y + 1), Color(0.6, 0.4, 0.1), 2.5)
	draw_line(Vector2(-7, hat_y + 3), Vector2(7, hat_y + 3), Color(0.4, 0.25, 0.05), 1.5)

	# Espiritus ancestrales flotando
	for i in 2:
		var sa = anim_time * 1.5 + float(i) * PI
		var sx = sin(sa) * 18.0
		var sy = cos(sa * 0.8) * 10.0 + _d_vy
		var sa2 = sin(anim_time * 3.0 + float(i)) * 0.3 + 0.4
		draw_circle(Vector2(sx, sy), 3, Color(0.3, 0.9, 0.4, sa2 * 0.15))
		draw_circle(Vector2(sx, sy), 1.5, Color(0.5, 1, 0.6, sa2 * 0.3))

	_draw_std_attack()


# ══════════════════════════════════════════════════════
# PERSONAJE 3: NAHUAL - Mascara de jaguar, garras
# ══════════════════════════════════════════════════════

func _draw_char_nahual() -> void:
	# Capa de piel de jaguar (manchas)
	var cape_col = Color(0.75, 0.55, 0.15)
	if _d_has_facing:
		var cd = -_d_facing
		var cp = Vector2(-cd.y, cd.x)
		var sw = sin(anim_time * 2.0) * 3.0
		# Capa como triangulos individuales para evitar poligono degenerado
		var p0 = Vector2(-6, -2 + _d_vy)
		var p1 = Vector2(6, -2 + _d_vy)
		var p2 = cd * 12 + cp * (sw + 5) + Vector2(0, 5 + _d_vy)
		var p3 = cd * 18 + cp * sw + Vector2(0, 10 + _d_vy)
		var p4 = cd * 12 + cp * (sw - 5) + Vector2(0, 5 + _d_vy)
		var cc0 = cape_col
		var cc1 = cape_col.darkened(0.2)
		var cc2 = cape_col.darkened(0.3)
		draw_polygon(PackedVector2Array([p0, p1, p2]), PackedColorArray([cc0, cc0, cc1]))
		draw_polygon(PackedVector2Array([p0, p2, p3]), PackedColorArray([cc0, cc1, cc2]))
		draw_polygon(PackedVector2Array([p0, p3, p4]), PackedColorArray([cc0, cc2, cc1]))
		# Manchas en la capa
		for i in 3:
			var sp = cd * (8 + float(i) * 4) + cp * (sw * 0.5 + float(i - 1) * 3) + Vector2(0, 6 + _d_vy)
			draw_circle(sp, 2, Color(0.3, 0.2, 0.05, 0.6))

	# Pies con garras
	var fa = _d_walk * 3.0 if _d_moving else 0.0
	var fd = _d_facing
	draw_circle(Vector2(-5, 14 + _d_vy + fa), 3.5, Color(0.6, 0.4, 0.1))
	draw_line(Vector2(-5, 14 + _d_vy + fa), Vector2(-5, 14 + _d_vy + fa) + fd * 4, Color(0.2, 0.2, 0.2), 1.5)
	draw_circle(Vector2(5, 14 + _d_vy - fa), 3.5, Color(0.6, 0.4, 0.1))
	draw_line(Vector2(5, 14 + _d_vy - fa), Vector2(5, 14 + _d_vy - fa) + fd * 4, Color(0.2, 0.2, 0.2), 1.5)

	# Macuahuitl (obsidiana) idle
	if state != State.ATTACKING:
		var ss = Vector2(-_d_facing.y, _d_facing.x)
		var sd = _d_facing.rotated(0.35).normalized()
		var sb = ss * 7 + Vector2(0, _d_vy)
		var st = sb + sd * 26 + Vector2(0, -6)
		draw_line(sb, st, Color(0.4, 0.3, 0.1), 3.5)
		# Filos de obsidiana
		var blade_p = Vector2(-sd.y, sd.x)
		for i in 3:
			var bp = sb + sd * (10 + float(i) * 6)
			draw_polygon(PackedVector2Array([
				bp + blade_p * 3, bp + sd * 2, bp - blade_p * 3
			]), PackedColorArray([Color(0.15, 0.15, 0.2), Color(0.3, 0.3, 0.35), Color(0.15, 0.15, 0.2)]))

	# Cuerpo guerrero (mas cuadrado)
	var v = _d_vy
	draw_polygon(PackedVector2Array([
		Vector2(-7, -4 + v), Vector2(7, -4 + v),
		Vector2(10, 12 + v), Vector2(-10, 12 + v)
	]), PackedColorArray([_d_rc, _d_rc, _d_rc, _d_rc]))
	draw_polyline(PackedVector2Array([
		Vector2(-7, -4 + v), Vector2(-10, 12 + v), Vector2(10, 12 + v), Vector2(7, -4 + v)
	]), _d_dc, 1.5)
	# Manchas de jaguar en el cuerpo
	draw_circle(Vector2(-3, 5 + v), 2, _d_dc.darkened(0.15))
	draw_circle(Vector2(4, 8 + v), 1.5, _d_dc.darkened(0.15))
	draw_circle(Vector2(1, 2 + v), 1.5, _d_dc.darkened(0.15))
	# Cinturon con colmillo
	draw_line(Vector2(-8, 3 + v), Vector2(8, 3 + v), _d_dc, 2.0)
	draw_polygon(PackedVector2Array([
		Vector2(-1, 3 + v), Vector2(1, 3 + v), Vector2(0, 7 + v)
	]), PackedColorArray([Color(0.9, 0.85, 0.7), Color(0.9, 0.85, 0.7), Color(0.7, 0.65, 0.5)]))

	# Hombreras de garra
	draw_polygon(PackedVector2Array([
		Vector2(-6, -3 + v), Vector2(-13, -5 + v), Vector2(-9, 0 + v)
	]), PackedColorArray([Color(0.7, 0.5, 0.1), Color(0.5, 0.35, 0.05), Color(0.7, 0.5, 0.1)]))
	draw_polygon(PackedVector2Array([
		Vector2(6, -3 + v), Vector2(13, -5 + v), Vector2(9, 0 + v)
	]), PackedColorArray([Color(0.7, 0.5, 0.1), Color(0.5, 0.35, 0.05), Color(0.7, 0.5, 0.1)]))

	_draw_std_head()

	# Ojos feroces (amarillos, rasgados)
	var hy = -11.0 + _d_vy
	var ed = _d_facing
	var ep = Vector2(-ed.y, ed.x)
	var eb = Vector2(0, hy) + ed * 3.5
	var e1 = eb + ep * 2.8
	var e2 = eb - ep * 2.8
	draw_circle(e1, 2.2, Color(1, 0.9, 0.3))
	draw_circle(e2, 2.2, Color(1, 0.9, 0.3))
	# Pupilas rasgadas
	draw_line(e1 + ed * 0.3 + Vector2(0, -1.5), e1 + ed * 0.3 + Vector2(0, 1.5), Color(0.05, 0.05, 0.05), 1.5)
	draw_line(e2 + ed * 0.3 + Vector2(0, -1.5), e2 + ed * 0.3 + Vector2(0, 1.5), Color(0.05, 0.05, 0.05), 1.5)
	# Cejas agresivas siempre
	draw_line(e1 - ep * 2 + Vector2(0, -3), e1 + ep + Vector2(0, -1.5), Color(0.3, 0.2, 0.05), 2.0)
	draw_line(e2 + ep * 2 + Vector2(0, -3), e2 - ep + Vector2(0, -1.5), Color(0.3, 0.2, 0.05), 2.0)

	# Pintura facial jaguar
	var cheek = Vector2(0, hy) + ed * 4.0
	draw_line(cheek + ep * 4, cheek + ep * 7, Color(0.1, 0.1, 0.1, 0.6), 2.0)
	draw_line(cheek - ep * 4, cheek - ep * 7, Color(0.1, 0.1, 0.1, 0.6), 2.0)
	# Colmillos
	var mp = Vector2(0, hy) + ed * 5.5 + Vector2(0, 2)
	draw_line(mp + ep * 1.5, mp + ep * 1.5 + Vector2(0, 3), Color(0.95, 0.9, 0.8), 1.5)
	draw_line(mp - ep * 1.5, mp - ep * 1.5 + Vector2(0, 3), Color(0.95, 0.9, 0.8), 1.5)

	# Capucha jaguar (orejas puntiagudas)
	var hb = hy - 5.5
	draw_polygon(PackedVector2Array([
		Vector2(0, hb - 6), Vector2(-10, hb + 2), Vector2(-8, hb + 5), Vector2(8, hb + 5), Vector2(10, hb + 2)
	]), PackedColorArray([Color(0.75, 0.55, 0.15), _d_dc, _d_dc, _d_dc, _d_dc]))
	# Orejas
	draw_polygon(PackedVector2Array([
		Vector2(-8, hb), Vector2(-12, hb - 10), Vector2(-4, hb - 2)
	]), PackedColorArray([Color(0.75, 0.55, 0.15), Color(0.6, 0.4, 0.1), Color(0.75, 0.55, 0.15)]))
	draw_polygon(PackedVector2Array([
		Vector2(8, hb), Vector2(12, hb - 10), Vector2(4, hb - 2)
	]), PackedColorArray([Color(0.75, 0.55, 0.15), Color(0.6, 0.4, 0.1), Color(0.75, 0.55, 0.15)]))
	# Manchas en la capucha
	draw_circle(Vector2(-4, hb - 2), 1.5, Color(0.3, 0.2, 0.05, 0.5))
	draw_circle(Vector2(4, hb - 2), 1.5, Color(0.3, 0.2, 0.05, 0.5))

	# Sombra de jaguar detras
	var jaguar_a = sin(anim_time * 1.0) * 0.05 + 0.08
	var jd = _d_facing
	draw_circle(-jd * 12 + Vector2(0, _d_vy), 10, Color(0.4, 0.3, 0.05, jaguar_a))
	draw_circle(-jd * 12 + Vector2(0, _d_vy - 5), 5, Color(0.4, 0.3, 0.05, jaguar_a))
	# Ojos del espiritu jaguar
	var je = sin(anim_time * 2.0) * 0.15 + 0.15
	var jep = Vector2(-jd.y, jd.x)
	draw_circle(-jd * 12 + jep * 3 + Vector2(0, _d_vy - 6), 1, Color(1, 0.8, 0.1, je))
	draw_circle(-jd * 12 - jep * 3 + Vector2(0, _d_vy - 6), 1, Color(1, 0.8, 0.1, je))

	_draw_std_attack()


# ══════════════════════════════════════════════════════
# PERSONAJE 4: BRUJO - Mascara de calavera, huesos
# ══════════════════════════════════════════════════════

func _draw_char_brujo() -> void:
	# Capa rasgada/fantasmal
	var cd = -_d_facing
	var cp = Vector2(-cd.y, cd.x)
	for i in 4:
		var off = float(i - 2) * 5.0
		var sw = sin(anim_time * 2.0 + float(i)) * 3.0
		var base = cp * off + Vector2(0, -1 + _d_vy)
		var tip = cd * (14 + float(i % 2) * 6) + cp * (off + sw) + Vector2(0, 10 + _d_vy)
		draw_line(base, tip, Color(0.3, 0.15, 0.4, 0.5 - float(i) * 0.08), 3.0)

	# Pies esqueléticos
	var fa = _d_walk * 3.0 if _d_moving else 0.0
	draw_circle(Vector2(-5, 14 + _d_vy + fa), 2.5, Color(0.8, 0.75, 0.65))
	draw_circle(Vector2(5, 14 + _d_vy - fa), 2.5, Color(0.8, 0.75, 0.65))

	# Vara de hueso idle
	if state != State.ATTACKING:
		var ss = Vector2(-_d_facing.y, _d_facing.x)
		var sd = _d_facing.rotated(0.4).normalized()
		var sb = ss * 7 + Vector2(0, _d_vy)
		var st = sb + sd * 28 + Vector2(0, -8)
		draw_line(sb, st, Color(0.8, 0.75, 0.65), 2.5)
		# Calavera en la punta
		draw_circle(st, 4, Color(0.85, 0.8, 0.7))
		draw_circle(st + Vector2(-1.5, -1), 1, Color(0.1, 0.1, 0.1))
		draw_circle(st + Vector2(1.5, -1), 1, Color(0.1, 0.1, 0.1))
		# Brillo espectral
		var gp = sin(anim_time * 3.0) * 0.2 + 0.5
		draw_circle(st, 6, Color(0.4, 0.8, 0.3, gp * 0.3))

	# Cuerpo rasgado
	var v = _d_vy
	draw_polygon(PackedVector2Array([
		Vector2(-6, -3 + v), Vector2(6, -3 + v),
		Vector2(11, 12 + v), Vector2(-11, 12 + v)
	]), PackedColorArray([_d_rc, _d_rc, _d_rc.darkened(0.1), _d_rc.darkened(0.1)]))
	# Costillas
	for i in 3:
		var ry = 4.0 + float(i) * 3.0 + v
		draw_line(Vector2(-5, ry), Vector2(5, ry), Color(0.8, 0.75, 0.65, 0.4), 1.5)
	# Cinturon de huesos
	draw_line(Vector2(-8, 2 + v), Vector2(8, 2 + v), Color(0.8, 0.75, 0.65), 2.0)

	# Hombreras de hueso
	draw_circle(Vector2(-8, -2 + v), 3.5, Color(0.8, 0.75, 0.65))
	draw_circle(Vector2(-8, -2 + v), 1.5, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(8, -2 + v), 3.5, Color(0.8, 0.75, 0.65))
	draw_circle(Vector2(8, -2 + v), 1.5, Color(0.1, 0.1, 0.1))

	# Cabeza calavera (sin helper estandar)
	var hy = -11.0 + _d_vy
	draw_line(Vector2(0, -4 + _d_vy), Vector2(0, hy + 7.5), _d_bc.darkened(0.1), 4.0)
	draw_circle(Vector2(0, hy), 7.5, Color(0.85, 0.8, 0.7))
	draw_arc(Vector2(0, hy), 7.5, 0, TAU, 24, Color(0.5, 0.45, 0.35), 1.5)

	# Ojos huecos brillantes
	var ed = _d_facing
	var ep = Vector2(-ed.y, ed.x)
	var eb = Vector2(0, hy) + ed * 2.5
	var e1 = eb + ep * 2.5
	var e2 = eb - ep * 2.5
	draw_circle(e1, 2.5, Color(0.05, 0.05, 0.05))
	draw_circle(e2, 2.5, Color(0.05, 0.05, 0.05))
	var eg = sin(anim_time * 3.0) * 0.2 + 0.7
	draw_circle(e1, 1.2, Color(0.4, 0.9, 0.3, eg))
	draw_circle(e2, 1.2, Color(0.4, 0.9, 0.3, eg))
	# Nariz (triangulo invertido)
	var nose = Vector2(0, hy) + ed * 4.5
	draw_polygon(PackedVector2Array([
		nose + Vector2(-1, -1), nose + Vector2(1, -1), nose + Vector2(0, 1.5)
	]), PackedColorArray([Color(0.15, 0.15, 0.1), Color(0.15, 0.15, 0.1), Color(0.15, 0.15, 0.1)]))
	# Boca cosida
	var mp = Vector2(0, hy) + ed * 5.0 + Vector2(0, 3)
	draw_line(mp + ep * 3, mp - ep * 3, Color(0.2, 0.2, 0.15), 1.0)
	for i in 4:
		var sx = -2.5 + float(i) * 1.7
		draw_line(mp + ep * sx + Vector2(0, -1.5), mp + ep * sx + Vector2(0, 1.5), Color(0.2, 0.2, 0.15), 1.0)

	# Capucha rasgada
	var hb = hy - 5.0
	draw_polygon(PackedVector2Array([
		Vector2(0, hb - 10), Vector2(-10, hb + 1), Vector2(-7, hb + 5), Vector2(7, hb + 5), Vector2(10, hb + 1)
	]), PackedColorArray([_d_rc.darkened(0.2), _d_dc, _d_dc, _d_dc, _d_dc]))
	# Rasgaduras
	draw_line(Vector2(-6, hb + 5), Vector2(-8, hb + 9), _d_dc.darkened(0.2), 1.5)
	draw_line(Vector2(3, hb + 5), Vector2(5, hb + 8), _d_dc.darkened(0.2), 1.5)

	# Particulas espectrales
	for i in 2:
		var pa = anim_time * 2.0 + float(i) * 3.0
		var pp = Vector2(sin(pa) * 12, cos(pa * 0.7) * 8 + _d_vy)
		draw_circle(pp, 2, Color(0.4, 0.9, 0.3, 0.15))

	# Almas flotando alrededor
	for i in 3:
		var sa = anim_time * 1.2 + float(i) * TAU / 3.0
		var sr = 16.0 + sin(anim_time * 2.0 + float(i)) * 4.0
		var sx = cos(sa) * sr
		var sy = sin(sa) * sr * 0.6 + _d_vy
		var ghost_a = sin(anim_time * 3.0 + float(i) * 2.0) * 0.1 + 0.12
		draw_circle(Vector2(sx, sy), 2.5, Color(0.3, 0.9, 0.2, ghost_a))
		# Estela del alma
		var prev_sa = sa - 0.3
		var psx = cos(prev_sa) * sr
		var psy = sin(prev_sa) * sr * 0.6 + _d_vy
		draw_line(Vector2(sx, sy), Vector2(psx, psy), Color(0.3, 0.9, 0.2, ghost_a * 0.5), 1.5)

	_draw_std_attack()


# ══════════════════════════════════════════════════════
# PERSONAJE 5: SACERDOTE SOL - Corona solar, vara dorada
# ══════════════════════════════════════════════════════

func _draw_char_sacerdote() -> void:
	# Capa dorada ornamental
	var cd = -_d_facing
	var cp = Vector2(-cd.y, cd.x)
	var sw = sin(anim_time * 2.5) * 3.0
	var cape_col = Color(0.8, 0.5, 0.05)
	var cape_pts = PackedVector2Array([
		Vector2(-6, -2 + _d_vy), Vector2(6, -2 + _d_vy),
		cd * 13 + cp * (sw + 6) + Vector2(0, 4 + _d_vy),
		cd * 20 + cp * sw + Vector2(0, 9 + _d_vy),
		cd * 13 + cp * (sw - 6) + Vector2(0, 4 + _d_vy),
	])
	if Geometry2D.triangulate_polygon(cape_pts).size() > 0:
		draw_polygon(cape_pts, PackedColorArray([cape_col, cape_col, cape_col.darkened(0.1), cape_col.darkened(0.3), cape_col.darkened(0.1)]))
	# Borde dorado
	draw_polyline(PackedVector2Array([
		cd * 13 + cp * (sw - 6) + Vector2(0, 4 + _d_vy),
		cd * 20 + cp * sw + Vector2(0, 9 + _d_vy),
		cd * 13 + cp * (sw + 6) + Vector2(0, 4 + _d_vy),
	]), Color(1, 0.85, 0.3, 0.6), 1.5)

	# Sandalias doradas
	var fa = _d_walk * 3.0 if _d_moving else 0.0
	draw_circle(Vector2(-5, 14 + _d_vy + fa), 3.5, Color(0.7, 0.5, 0.1))
	draw_circle(Vector2(5, 14 + _d_vy - fa), 3.5, Color(0.7, 0.5, 0.1))

	# Vara con disco solar idle
	if state != State.ATTACKING:
		var ss = Vector2(-_d_facing.y, _d_facing.x)
		var sd = _d_facing.rotated(0.4).normalized()
		var sb = ss * 7 + Vector2(0, _d_vy)
		var st = sb + sd * 28 + Vector2(0, -8)
		draw_line(sb, st, Color(0.7, 0.55, 0.1), 3.0)
		draw_line(sb, st, Color(0.9, 0.7, 0.2), 1.5)
		# Disco solar
		var sg = sin(anim_time * 3.0) * 0.15 + 0.85
		draw_circle(st, 5, Color(1, 0.7, 0.1, sg * 0.4))
		draw_circle(st, 3.5, Color(1, 0.85, 0.2, sg))
		# Rayos del disco
		for i in 6:
			var ra = anim_time * 1.0 + float(i) * TAU / 6.0
			draw_line(st + Vector2(cos(ra), sin(ra)) * 4, st + Vector2(cos(ra), sin(ra)) * 8, Color(1, 0.8, 0.2, sg * 0.5), 1.5)

	# Cuerpo ornamental
	var v = _d_vy
	draw_polygon(PackedVector2Array([
		Vector2(-6, -3 + v), Vector2(6, -3 + v),
		Vector2(12, 12 + v), Vector2(-12, 12 + v)
	]), PackedColorArray([_d_rc, _d_rc, _d_rc, _d_rc]))
	draw_polyline(PackedVector2Array([
		Vector2(-6, -3 + v), Vector2(-12, 12 + v), Vector2(12, 12 + v), Vector2(6, -3 + v)
	]), Color(1, 0.8, 0.2, 0.5), 1.5)
	# Patron solar en tunica
	draw_circle(Vector2(0, 6 + v), 3.5, Color(1, 0.7, 0.1, 0.5))
	draw_arc(Vector2(0, 6 + v), 3.5, 0, TAU, 12, _d_lc, 1.0)
	for i in 6:
		var ra = float(i) * TAU / 6.0
		draw_line(Vector2(0, 6 + v) + Vector2(cos(ra), sin(ra)) * 3.5, Vector2(0, 6 + v) + Vector2(cos(ra), sin(ra)) * 5.5, _d_lc, 1.0)
	# Cinturon dorado
	draw_line(Vector2(-8, 2 + v), Vector2(8, 2 + v), Color(0.9, 0.7, 0.15), 2.5)

	# Hombreras con rayos solares
	for side in [-1, 1]:
		var sx = float(side) * 9
		draw_circle(Vector2(sx, -2 + v), 4, Color(0.9, 0.6, 0.1))
		for i in 4:
			var ra = float(i) * TAU / 4.0 + anim_time * 0.5
			draw_line(Vector2(sx, -2 + v) + Vector2(cos(ra), sin(ra)) * 3,
				Vector2(sx, -2 + v) + Vector2(cos(ra), sin(ra)) * 6,
				Color(1, 0.8, 0.2, 0.4), 1.0)

	_draw_std_head()
	# Ojos dorados
	_draw_std_eyes(Color(0.9, 0.65, 0.1))
	# Marcas doradas faciales
	var hy = -11.0 + _d_vy
	var ed = _d_facing
	draw_line(Vector2(0, hy - 3) + ed * 1, Vector2(0, hy - 6) + ed * 1, Color(1, 0.8, 0.2, 0.6), 1.5)
	var ep = Vector2(-ed.y, ed.x)
	draw_line(Vector2(0, hy + 1) + ed * 4 + ep * 3, Vector2(0, hy + 1) + ed * 4 + ep * 6, Color(1, 0.8, 0.2, 0.5), 1.0)
	draw_line(Vector2(0, hy + 1) + ed * 4 - ep * 3, Vector2(0, hy + 1) + ed * 4 - ep * 6, Color(1, 0.8, 0.2, 0.5), 1.0)
	_draw_std_mouth()

	# Corona solar
	var hb = hy - 6.0
	# Disco base
	draw_circle(Vector2(0, hb - 4), 7, Color(0.9, 0.6, 0.1))
	draw_circle(Vector2(0, hb - 4), 5, Color(1, 0.8, 0.2))
	# Rayos de la corona
	var ray_glow = sin(anim_time * 2.0) * 0.2 + 0.8
	for i in 8:
		var ra = float(i) * TAU / 8.0
		var rlen = 10.0 if i % 2 == 0 else 7.0
		draw_line(Vector2(0, hb - 4) + Vector2(cos(ra), sin(ra)) * 6,
			Vector2(0, hb - 4) + Vector2(cos(ra), sin(ra)) * rlen,
			Color(1, 0.85, 0.2, ray_glow), 2.0)
	# Centro
	draw_circle(Vector2(0, hb - 4), 2.5, Color(1, 0.95, 0.5))

	# Rayos de luz divina cayendo
	for i in 3:
		var la = anim_time * 0.8 + float(i) * 1.0
		var lx = sin(la) * 10.0
		var light_a = sin(anim_time * 2.0 + float(i)) * 0.06 + 0.08
		draw_line(Vector2(lx, -35), Vector2(lx + sin(la) * 2, 15 + _d_vy), Color(1, 0.9, 0.4, light_a), 2.0)

	_draw_std_attack()


# ══════════════════════════════════════════════════════
# PERSONAJE 6: ATLANTE - Guerrero de piedra tolteca
# ══════════════════════════════════════════════════════

func _draw_char_atlante() -> void:
	# Base de piedra / pies columna (pesados, rectangulares)
	var fa = _d_walk * 2.0 if _d_moving else 0.0
	var stone = Color(0.55, 0.58, 0.55)
	var stone_d = Color(0.4, 0.43, 0.4)
	draw_polygon(PackedVector2Array([
		Vector2(-6, 12 + _d_vy + fa), Vector2(-2, 12 + _d_vy + fa),
		Vector2(-2, 16 + _d_vy + fa), Vector2(-7, 16 + _d_vy + fa)
	]), PackedColorArray([stone, stone, stone_d, stone_d]))
	draw_polygon(PackedVector2Array([
		Vector2(2, 12 + _d_vy - fa), Vector2(6, 12 + _d_vy - fa),
		Vector2(7, 16 + _d_vy - fa), Vector2(2, 16 + _d_vy - fa)
	]), PackedColorArray([stone, stone, stone_d, stone_d]))

	# Atlatl (lanzadardos) idle
	if state != State.ATTACKING:
		var ss = Vector2(-_d_facing.y, _d_facing.x)
		var sd = _d_facing.rotated(0.3).normalized()
		var sb = ss * 7 + Vector2(0, _d_vy)
		var st = sb + sd * 28 + Vector2(0, -8)
		# Vara del atlatl
		draw_line(sb, st, Color(0.5, 0.4, 0.25), 3.0)
		# Gancho del atlatl
		var hook_d = sd.rotated(-0.5).normalized()
		draw_line(st, st + hook_d * 6, Color(0.45, 0.35, 0.2), 2.5)
		# Dardo
		var dart_end = st + sd * 14
		draw_line(st + sd * 2, dart_end, Color(0.6, 0.55, 0.45), 2.0)
		# Punta de obsidiana
		var dp = Vector2(-sd.y, sd.x)
		draw_polygon(PackedVector2Array([
			dart_end, dart_end + sd * 4 + dp * 1.5, dart_end + sd * 4 - dp * 1.5
		]), PackedColorArray([Color(0.15, 0.15, 0.2), Color(0.25, 0.25, 0.3), Color(0.15, 0.15, 0.2)]))

	# Cuerpo columnar (rectangular, rigido como pilar)
	var v = _d_vy
	draw_polygon(PackedVector2Array([
		Vector2(-8, -5 + v), Vector2(8, -5 + v),
		Vector2(9, 12 + v), Vector2(-9, 12 + v)
	]), PackedColorArray([_d_rc, _d_rc, _d_rc, _d_rc]))
	# Bordes de piedra
	draw_polyline(PackedVector2Array([
		Vector2(-8, -5 + v), Vector2(-9, 12 + v), Vector2(9, 12 + v), Vector2(8, -5 + v)
	]), _d_dc, 1.5)
	# Grietas en el cuerpo
	draw_line(Vector2(-4, -2 + v), Vector2(-6, 4 + v), Color(0.3, 0.32, 0.3, 0.4), 1.0)
	draw_line(Vector2(3, 1 + v), Vector2(5, 7 + v), Color(0.3, 0.32, 0.3, 0.4), 1.0)
	draw_line(Vector2(-2, 6 + v), Vector2(2, 9 + v), Color(0.3, 0.32, 0.3, 0.4), 1.0)

	# Pectoral de mariposa estilizada (simbolo tolteca)
	var bx = 0.0
	var by = 2.0 + v
	# Alas de mariposa
	draw_polygon(PackedVector2Array([
		Vector2(bx, by), Vector2(bx - 5, by - 3), Vector2(bx - 6, by + 1), Vector2(bx - 3, by + 3)
	]), PackedColorArray([Color(0.2, 0.7, 0.65), Color(0.15, 0.55, 0.5), Color(0.1, 0.45, 0.4), Color(0.2, 0.7, 0.65)]))
	draw_polygon(PackedVector2Array([
		Vector2(bx, by), Vector2(bx + 5, by - 3), Vector2(bx + 6, by + 1), Vector2(bx + 3, by + 3)
	]), PackedColorArray([Color(0.2, 0.7, 0.65), Color(0.15, 0.55, 0.5), Color(0.1, 0.45, 0.4), Color(0.2, 0.7, 0.65)]))
	# Centro turquesa
	draw_circle(Vector2(bx, by), 1.5, Color(0.3, 0.85, 0.8))

	# Cinturon con disco
	draw_line(Vector2(-8, -1 + v), Vector2(8, -1 + v), stone_d, 2.0)
	draw_circle(Vector2(0, -1 + v), 2, Color(0.25, 0.65, 0.6))

	# Hombreras cuadradas de piedra
	draw_polygon(PackedVector2Array([
		Vector2(-8, -4 + v), Vector2(-14, -6 + v), Vector2(-13, -1 + v), Vector2(-8, 0 + v)
	]), PackedColorArray([stone, stone_d, stone_d, stone]))
	draw_polygon(PackedVector2Array([
		Vector2(8, -4 + v), Vector2(14, -6 + v), Vector2(13, -1 + v), Vector2(8, 0 + v)
	]), PackedColorArray([stone, stone_d, stone_d, stone]))
	# Turquesa en hombreras
	draw_circle(Vector2(-11, -3 + v), 1.5, Color(0.2, 0.65, 0.6, 0.7))
	draw_circle(Vector2(11, -3 + v), 1.5, Color(0.2, 0.65, 0.6, 0.7))

	_draw_std_head()

	# Ojos de piedra (turquesa brillante, sin pupilas)
	var hy = -11.0 + _d_vy
	var ed = _d_facing
	var ep = Vector2(-ed.y, ed.x)
	var eb = Vector2(0, hy) + ed * 3.5
	var e1 = eb + ep * 2.8
	var e2 = eb - ep * 2.8
	var eye_glow = sin(anim_time * 2.5) * 0.15 + 0.85
	draw_circle(e1, 2.2, Color(0.2, 0.75, 0.7, eye_glow))
	draw_circle(e2, 2.2, Color(0.2, 0.75, 0.7, eye_glow))
	# Brillo interno
	draw_circle(e1, 1.0, Color(0.5, 0.95, 0.9, eye_glow * 0.7))
	draw_circle(e2, 1.0, Color(0.5, 0.95, 0.9, eye_glow * 0.7))
	# Cejas rectas (estoicas)
	draw_line(e1 - ep * 2.5 + Vector2(0, -2.5), e1 + ep * 1.5 + Vector2(0, -2.5), stone_d, 1.8)
	draw_line(e2 + ep * 2.5 + Vector2(0, -2.5), e2 - ep * 1.5 + Vector2(0, -2.5), stone_d, 1.8)

	# Boca recta (expresion estoica)
	var mp = Vector2(0, hy) + ed * 5.0 + Vector2(0, 2.5)
	draw_line(mp + ep * 2.5, mp - ep * 2.5, Color(0.3, 0.32, 0.3), 1.5)

	# Tocado columnar con plumas
	var hb = hy - 5.5
	# Base del tocado (rectangular, tipo pilar)
	draw_polygon(PackedVector2Array([
		Vector2(-8, hb + 3), Vector2(8, hb + 3),
		Vector2(9, hb - 6), Vector2(-9, hb - 6)
	]), PackedColorArray([stone, stone, stone_d, stone_d]))
	# Banda turquesa en el tocado
	draw_line(Vector2(-9, hb - 2), Vector2(9, hb - 2), Color(0.2, 0.7, 0.65), 2.0)
	# Plumas superiores
	for i in 5:
		var fx = -6.0 + float(i) * 3.0
		var fh = 8.0 + sin(anim_time * 1.5 + float(i) * 0.8) * 1.5
		var feather_col = Color(0.15, 0.55, 0.5) if i % 2 == 0 else Color(0.8, 0.2, 0.15)
		draw_line(Vector2(fx, hb - 6), Vector2(fx + sin(anim_time * 1.0 + float(i)) * 1.0, hb - 6 - fh), feather_col, 2.0)
	# Disco frontal del tocado
	draw_circle(Vector2(0, hb - 1), 2.5, Color(0.25, 0.7, 0.65))

	# Efecto de piedra - particulas de polvo/gravilla
	for i in 2:
		var pa = anim_time * 1.5 + float(i) * 2.5
		var pp = Vector2(sin(pa) * 10, cos(pa * 0.6) * 6 + _d_vy + 8)
		var dust_a = sin(anim_time * 2.0 + float(i)) * 0.08 + 0.1
		draw_circle(pp, 1.5, Color(0.5, 0.52, 0.48, dust_a))

	# Aura turquesa tenue
	var aura_a = sin(anim_time * 1.8) * 0.04 + 0.06
	draw_circle(Vector2(0, _d_vy), 14, Color(0.2, 0.7, 0.65, aura_a))

	_draw_std_attack()
