extends Node2D

const PlayerScene = preload("res://scenes/player.tscn")
const OrbScene = preload("res://scenes/orb.tscn")
const HitParticlesScene = preload("res://scenes/hit_particles.tscn")
const DamageNumberScene = preload("res://scenes/damage_number.tscn")
const AreaEffectScene = preload("res://scenes/area_effect.tscn")
const PortraitScene = preload("res://scenes/portrait_drawer.tscn")
const LogoTexture = preload("res://nahual_logo.png")
const InicioTexture = preload("res://inicio_game.png")
const TemploTexture = preload("res://templo.png")

const ARENA = Rect2(150, 70, 980, 580)
const ORB_SPAWN_TIME = 2.5
const GAME_TIME = 90.0
const MAX_ORBS_IN_ARENA = 8

var player1: CharacterBody2D
var player2: CharacterBody2D
var game_mode: int = 0  # 0=not selected, 1=vs AI, 2=local 2P
var ai_difficulty: int = 1  # 0=easy, 1=normal, 2=hard
var game_timer: float = GAME_TIME
var game_over: bool = false
var waiting_to_start: bool = true
var orb_timer: float = 1.0

# Rounds
const ROUNDS_TO_WIN = 2  # default para vs, story usa 1
var p1_wins: int = 0
var p2_wins: int = 0
var current_round: int = 1
var round_transition: bool = false
var round_transition_timer: float = 0.0

# HUD
var hud: CanvasLayer
var timer_label: Label
var p1_hp_bar: ProgressBar
var p2_hp_bar: ProgressBar
var p1_mana_bar: ProgressBar
var p2_mana_bar: ProgressBar
var game_over_panel: Panel
var game_over_label: Label
var instructions_panel: Panel
var mode_select_panel: Panel
var round_label: Label
var p1_wins_label: Label
var p2_wins_label: Label
var round_banner: Label

# Portrait HUD
var p1_portrait_panel: Panel
var p2_portrait_panel: Panel
var p1_name_label: Label
var p2_name_label: Label
var p1_hp_text: Label
var p2_hp_text: Label
var p1_portrait_icon: Panel
var p2_portrait_icon: Panel
var p1_portrait_initial: Label
var p2_portrait_initial: Label
var p1_hud_portrait: Node2D
var p2_hud_portrait: Node2D

# Ability HUD
var p1_ability_fire: Label
var p1_ability_ice: Label
var p1_ability_special: Label

# Character Select
var char_select_active: bool = false
var char_select_panel: Panel
var p1_char_idx: int = 0
var p2_char_idx: int = 1
var p1_confirmed: bool = false
var p2_confirmed: bool = false
var preview_p1: CharacterBody2D
var preview_p2: CharacterBody2D
var p1_char_name_label: Label
var p1_char_desc_label: Label
var p2_char_name_label: Label
var p2_char_desc_label: Label
var p1_status_label: Label
var p2_status_label: Label
var char_select_cards: Array = []
var portrait_p1: Node2D
var portrait_p2: Node2D
var char_select_phase = 0  # 0=navegar, 1=confirmando (pose), 2=listo
var confirm_anim_timer = 0.0

# Story Mode
var story_player_char = 0
var story_opponents = []
var story_current_stage = 0
var story_completed = []
var story_select_active = false
var story_select_panel: Panel
var story_cursor = 0
var boss_intro_active = false

# Cursor indicators (char select)
var p1_cursor_indicator: Label
var p2_cursor_indicator: Label

# AI search animation (char select)
var ai_search_active = false
var ai_search_timer = 0.0
var ai_search_target = 0
var ai_search_speed = 0.08
var ai_search_elapsed = 0.0

# Title screen
var title_active = true
var title_panel: Panel
var title_blink_time = 0.0

# Menu cursor
var menu_cursor = 0  # 0=VS IA, 1=2P Local, 2=Campana

# Settings
var settings_active = false
var settings_panel: Panel
var settings_cursor = 0
var settings_rebinding = false
var settings_rebind_action = ""
var settings_items = []
var music_vol = 0.8
var sfx_vol = 0.8
var brightness_val = 1.0
var brightness_overlay: ColorRect
var key_bindings = []

# Menu visual state
var menu_particles = []
var menu_time = 0.0
var menu_magic_angle = 0.0
var arena_time = 0.0

# Pause menu
var pause_active = false
var pause_panel: Panel
var pause_cursor = 0

# Arena ambient particles
var arena_particles = []
const ARENA_PARTICLE_COUNT = 30

const MENU_PARTICLE_COUNT = 50


func _ready() -> void:
	_init_key_bindings()
	_load_settings()
	_setup_inputs()
	_create_hud()
	_create_brightness_overlay()
	_apply_settings()
	_init_menu_particles()
	_create_title_screen()


# ── Input Setup ──

func _setup_inputs() -> void:
	# P1: usar key_bindings (puede tener teclas personalizadas de settings)
	for kb in key_bindings:
		_add_key(kb.action, kb.key)
	_add_key("ui_confirm", KEY_ENTER)
	# P1 Gamepad
	_add_joy_button("p1_attack", JOY_BUTTON_A)
	_add_joy_button("p1_fire", JOY_BUTTON_LEFT_SHOULDER)
	_add_joy_button("p1_ice", JOY_BUTTON_RIGHT_SHOULDER)
	_add_joy_button("p1_special", JOY_BUTTON_Y)
	_add_joy_button("p1_defend", JOY_BUTTON_B)
	_add_joy_button("p1_dodge", JOY_BUTTON_X)
	_add_joy_motion("p1_move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_motion("p1_move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_motion("p1_move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_motion("p1_move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_button("p1_move_up", JOY_BUTTON_DPAD_UP)
	_add_joy_button("p1_move_down", JOY_BUTTON_DPAD_DOWN)
	_add_joy_button("p1_move_left", JOY_BUTTON_DPAD_LEFT)
	_add_joy_button("p1_move_right", JOY_BUTTON_DPAD_RIGHT)
	# P2: registrar acciones con teclas por defecto
	for kb in key_bindings:
		if kb.action.begins_with("p2_"):
			_add_key(kb.action, kb.key)
	# UI
	_add_key("ui_tab", KEY_TAB)
	_add_key("ui_escape", KEY_ESCAPE)
	_add_key("ui_1", KEY_1)
	_add_key("ui_2", KEY_2)
	_add_key("ui_3", KEY_3)
	_add_key("ui_4", KEY_4)
	_add_key("ui_5", KEY_5)


func _add_key(action_name: String, key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var ev = InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action_name, ev)


func _add_joy_button(action_name: String, button: JoyButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var ev = InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action_name, ev)


func _add_joy_motion(action_name: String, axis: JoyAxis, value: float) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var ev = InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action_name, ev)


# ── Menu Particles ──

func _init_menu_particles():
	menu_particles.clear()
	for i in MENU_PARTICLE_COUNT:
		menu_particles.append(_new_menu_particle(true))


func _new_menu_particle(randomize_life: bool) -> Dictionary:
	var colors = [
		Color(0.95, 0.72, 0.15, 0.55), Color(1.0, 0.8, 0.25, 0.45),
		Color(0.8, 0.5, 0.12, 0.4), Color(0.7, 0.35, 0.95, 0.35),
		Color(1.0, 0.9, 0.35, 0.4)
	]
	var ml = randf_range(4.0, 8.0)
	return {
		"pos": Vector2(randf_range(0, 1280), randf_range(0, 720)),
		"vel": Vector2(randf_range(-12, 12), randf_range(-25, -8)),
		"color": colors[randi() % colors.size()],
		"life": ml * randf() if randomize_life else ml,
		"max_life": ml,
		"size": randf_range(1.5, 5.0)
	}


func _update_menu_particles(delta):
	for p in menu_particles:
		p.pos += p.vel * delta
		p.pos.x += sin(menu_time * 0.8 + p.pos.y * 0.01) * 8.0 * delta
		p.life -= delta
		if p.life <= 0 or p.pos.y < -30:
			var np = _new_menu_particle(false)
			p.pos = Vector2(randf_range(0, 1280), 740)
			p.vel = np.vel
			p.color = np.color
			p.life = np.max_life
			p.max_life = np.max_life
			p.size = np.size


# ── Arena Particles ──

func _init_arena_particles():
	arena_particles.clear()
	for i in ARENA_PARTICLE_COUNT:
		arena_particles.append(_new_arena_particle(true))


func _new_arena_particle(randomize_life: bool) -> Dictionary:
	var colors = [
		Color(0.3, 0.4, 0.8, 0.3), Color(0.5, 0.3, 0.7, 0.25),
		Color(0.2, 0.6, 0.8, 0.2), Color(0.7, 0.5, 0.2, 0.15),
		Color(0.4, 0.2, 0.6, 0.2)
	]
	var ml = randf_range(3.0, 7.0)
	var px = randf_range(ARENA.position.x + 20, ARENA.end.x - 20)
	var py = randf_range(ARENA.position.y + 20, ARENA.end.y - 20)
	return {
		"pos": Vector2(px, py),
		"vel": Vector2(randf_range(-6, 6), randf_range(-10, -3)),
		"color": colors[randi() % colors.size()],
		"life": ml * randf() if randomize_life else ml,
		"max_life": ml,
		"size": randf_range(1.0, 3.0),
		"phase": randf() * TAU
	}


func _update_arena_particles(delta):
	for p in arena_particles:
		p.pos += p.vel * delta
		p.pos.x += sin(arena_time * 0.5 + p.phase) * 6.0 * delta
		p.life -= delta
		if p.life <= 0 or p.pos.y < ARENA.position.y - 10 or p.pos.x < ARENA.position.x or p.pos.x > ARENA.end.x:
			var np = _new_arena_particle(false)
			p.pos = Vector2(
				randf_range(ARENA.position.x + 20, ARENA.end.x - 20),
				randf_range(ARENA.end.y - 60, ARENA.end.y - 10)
			)
			p.vel = np.vel
			p.color = np.color
			p.life = np.max_life
			p.max_life = np.max_life
			p.size = np.size
			p.phase = np.phase


# ── Title Screen ──

func _create_title_screen() -> void:
	title_active = true
	title_panel = Panel.new()
	title_panel.position = Vector2(0, 0)
	title_panel.size = Vector2(1280, 720)
	var ts = StyleBoxFlat.new()
	ts.bg_color = Color(0, 0, 0, 0)
	title_panel.add_theme_stylebox_override("panel", ts)
	title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(title_panel)

	# Vignette overlay - tono oscuro con toque azulado para equilibrar el dorado
	var vignette = ColorRect.new()
	vignette.position = Vector2.ZERO
	vignette.size = Vector2(1280, 720)
	vignette.color = Color(0.0, 0.02, 0.06, 0.35)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_panel.add_child(vignette)

	# Logo centrado (compacto)
	var logo_w = 260.0
	var logo_h = logo_w * (float(LogoTexture.get_height()) / float(LogoTexture.get_width()))
	var logo_rect = TextureRect.new()
	logo_rect.name = "TitleLogo"
	logo_rect.texture = LogoTexture
	logo_rect.position = Vector2(640.0 - logo_w / 2.0, 160)
	logo_rect.size = Vector2(logo_w, logo_h)
	logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_panel.add_child(logo_rect)

	# Subtitle
	var sub = Label.new()
	sub.text = "DUELO ARCANO"
	sub.position = Vector2(0, 160 + logo_h + 6)
	sub.size = Vector2(1280, 34)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75, 0.85))
	title_panel.add_child(sub)

	# Decorative line
	var deco = ColorRect.new()
	deco.position = Vector2(470, 160 + logo_h + 42)
	deco.size = Vector2(340, 2)
	deco.color = Color(0.75, 0.7, 0.55, 0.4)
	title_panel.add_child(deco)

	# Version / flavor text
	var flavor = Label.new()
	flavor.text = "Invoca el poder de los antiguos nahuales"
	flavor.position = Vector2(0, 160 + logo_h + 50)
	flavor.size = Vector2(1280, 26)
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.add_theme_font_size_override("font_size", 13)
	flavor.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45, 0.7))
	title_panel.add_child(flavor)

	# "PRESIONA ENTER" - animated
	var enter_label = Label.new()
	enter_label.name = "EnterPrompt"
	enter_label.text = ">>> PRESIONA ENTER <<<"
	enter_label.position = Vector2(0, 540)
	enter_label.size = Vector2(1280, 40)
	enter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enter_label.add_theme_font_size_override("font_size", 22)
	enter_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.8))
	title_panel.add_child(enter_label)

	# Bottom credits
	var credits = Label.new()
	credits.text = "Nahual: Duelo Arcano"
	credits.position = Vector2(0, 680)
	credits.size = Vector2(1280, 20)
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits.add_theme_font_size_override("font_size", 11)
	credits.add_theme_color_override("font_color", Color(0.4, 0.35, 0.3, 0.5))
	title_panel.add_child(credits)


func _dismiss_title() -> void:
	title_active = false
	AudioManager.play_sfx("confirm_power")
	var tw = create_tween()
	tw.tween_property(title_panel, "modulate", Color(1, 1, 1, 0), 0.5)
	tw.tween_callback(func():
		title_panel.queue_free()
		title_panel = null
		_create_mode_select()
		# Fade in mode select
		mode_select_panel.modulate = Color(1, 1, 1, 0)
		var tw2 = create_tween()
		tw2.tween_property(mode_select_panel, "modulate", Color(1, 1, 1, 1), 0.4)
	)


# ── Mode Select ──

func _create_mode_select() -> void:
	mode_select_panel = Panel.new()
	mode_select_panel.position = Vector2(140, 80)
	mode_select_panel.size = Vector2(1000, 560)
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.02, 0.02, 0.05, 0.6)
	ps.border_color = Color(0.6, 0.5, 0.35, 0.35)
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(12)
	ps.shadow_color = Color(0, 0, 0, 0.5)
	ps.shadow_size = 25
	mode_select_panel.add_theme_stylebox_override("panel", ps)
	hud.add_child(mode_select_panel)

	# Logo inside panel (compacto)
	var logo_w = 140.0
	var logo_h = logo_w * (float(LogoTexture.get_height()) / float(LogoTexture.get_width()))
	var logo_rect = TextureRect.new()
	logo_rect.name = "MenuLogo"
	logo_rect.texture = LogoTexture
	logo_rect.position = Vector2((1000 - logo_w) / 2.0, 12)
	logo_rect.size = Vector2(logo_w, logo_h)
	logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mode_select_panel.add_child(logo_rect)

	# Separator
	_add_menu_separator(mode_select_panel, 12 + logo_h + 6)

	# Mode label
	var mode_label = Label.new()
	mode_label.text = "SELECCIONA MODO DE JUEGO"
	mode_label.position = Vector2(0, 12 + logo_h + 12)
	mode_label.size = Vector2(1000, 22)
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_label.add_theme_font_size_override("font_size", 14)
	mode_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65))
	mode_select_panel.add_child(mode_label)

	# 3 mode cards - horizontal layout
	var card_w = 280
	var card_h = 200
	var gap_x = 20
	var total_w = card_w * 3 + gap_x * 2
	var sx = int((1000 - total_w) / 2)

	var cards_y = 12 + int(logo_h) + 40
	var opt1 = _create_mode_card_v2(
		Vector2(sx, cards_y), Vector2(card_w, card_h),
		"VS MAQUINA", "1 Jugador",
		"Pelea contra la\nInteligencia Arcana",
		Color(0.2, 0.85, 1.0), Color(0.03, 0.05, 0.12, 0.78)
	)
	opt1.name = "ModeCard0"
	mode_select_panel.add_child(opt1)

	var opt2 = _create_mode_card_v2(
		Vector2(sx + card_w + gap_x, cards_y), Vector2(card_w, card_h),
		"2 JUGADORES", "Local",
		"Pelea contra un\namigo en tu pantalla",
		Color(0.2, 1.0, 0.5), Color(0.03, 0.08, 0.04, 0.78)
	)
	opt2.name = "ModeCard1"
	mode_select_panel.add_child(opt2)

	var opt3 = _create_mode_card_v2(
		Vector2(sx + (card_w + gap_x) * 2, cards_y), Vector2(card_w, card_h),
		"CAMPANA", "Camino del Nahual",
		"Derrota a los 5\nmaestros arcanos",
		Color(1.0, 0.8, 0.2), Color(0.07, 0.04, 0.02, 0.78)
	)
	opt3.name = "ModeCard2"
	mode_select_panel.add_child(opt3)

	# Separator
	_add_menu_separator(mode_select_panel, cards_y + card_h + 14)

	# Difficulty selector
	var diff_label = Label.new()
	diff_label.text = "DIFICULTAD IA"
	diff_label.position = Vector2(0, cards_y + card_h + 26)
	diff_label.size = Vector2(1000, 22)
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_label.add_theme_font_size_override("font_size", 14)
	diff_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6))
	mode_select_panel.add_child(diff_label)

	var arrow_l = Label.new()
	arrow_l.name = "DiffArrowL"
	arrow_l.text = "<"
	var diff_y = cards_y + card_h + 50
	arrow_l.position = Vector2(350, diff_y)
	arrow_l.add_theme_font_size_override("font_size", 22)
	arrow_l.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6))
	mode_select_panel.add_child(arrow_l)

	var diff_data = [
		["FACIL", Color(0.3, 0.9, 0.3)],
		["NORMAL", Color(1.0, 0.8, 0.2)],
		["DIFICIL", Color(1.0, 0.3, 0.2)],
	]
	var diff_display = Label.new()
	diff_display.name = "DiffDisplay"
	diff_display.text = diff_data[ai_difficulty][0]
	diff_display.position = Vector2(0, diff_y - 2)
	diff_display.size = Vector2(1000, 28)
	diff_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_display.add_theme_font_size_override("font_size", 20)
	diff_display.add_theme_color_override("font_color", diff_data[ai_difficulty][1])
	mode_select_panel.add_child(diff_display)

	var arrow_r = Label.new()
	arrow_r.name = "DiffArrowR"
	arrow_r.text = ">"
	arrow_r.position = Vector2(620, diff_y)
	arrow_r.add_theme_font_size_override("font_size", 22)
	arrow_r.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6))
	mode_select_panel.add_child(arrow_r)

	# Bottom hint
	var bottom = Label.new()
	bottom.text = "Izq/Der: Modo  |  ENTER: Seleccionar  |  Arriba/Abajo: Dificultad"
	bottom.name = "BottomHint"
	bottom.position = Vector2(0, diff_y + 36)
	bottom.size = Vector2(1000, 24)
	bottom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_theme_font_size_override("font_size", 14)
	bottom.add_theme_color_override("font_color", Color(0.45, 0.85, 0.45))
	mode_select_panel.add_child(bottom)
	var tw = create_tween().set_loops()
	tw.tween_property(bottom, "modulate", Color(1, 1, 1, 0.3), 0.9).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(bottom, "modulate", Color(1, 1, 1, 1.0), 0.9).set_ease(Tween.EASE_IN_OUT)

	var config_hint = Label.new()
	config_hint.text = "[TAB] CONFIGURACION"
	config_hint.position = Vector2(790, diff_y + 72)
	config_hint.add_theme_font_size_override("font_size", 11)
	config_hint.add_theme_color_override("font_color", Color(0.5, 0.45, 0.35))
	mode_select_panel.add_child(config_hint)

	# Initial menu highlight
	_update_menu_highlight()


func _create_mode_card_v2(pos: Vector2, card_size: Vector2, title_text: String, subtitle: String, desc: String, accent: Color, bg: Color) -> Panel:
	var card = Panel.new()
	card.position = pos
	card.size = card_size
	card.clip_contents = true
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = Color(accent.r, accent.g, accent.b, 0.5)
	s.set_border_width_all(2)
	s.set_corner_radius_all(10)
	s.shadow_color = Color(accent.r * 0.3, accent.g * 0.3, accent.b * 0.3, 0.25)
	s.shadow_size = 8
	card.add_theme_stylebox_override("panel", s)

	# Top accent bar
	var top_bar = ColorRect.new()
	top_bar.position = Vector2(0, 0)
	top_bar.size = Vector2(card_size.x, 4)
	top_bar.color = accent
	card.add_child(top_bar)

	# Icon/symbol (large letter)
	var icon_lbl = Label.new()
	icon_lbl.name = "Icon"
	icon_lbl.text = title_text.substr(0, 1)
	icon_lbl.position = Vector2(0, 20)
	icon_lbl.size = Vector2(card_size.x, 60)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 48)
	icon_lbl.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.25))
	card.add_child(icon_lbl)

	# Title centered
	var t = Label.new()
	t.text = title_text
	t.position = Vector2(0, 80)
	t.size = Vector2(card_size.x, 28)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 18)
	t.add_theme_color_override("font_color", accent)
	card.add_child(t)

	# Subtitle
	var st = Label.new()
	st.text = subtitle
	st.position = Vector2(0, 104)
	st.size = Vector2(card_size.x, 22)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.add_theme_font_size_override("font_size", 13)
	st.add_theme_color_override("font_color", Color(accent.r * 0.7, accent.g * 0.7, accent.b * 0.7, 0.8))
	card.add_child(st)

	# Separator line
	var sep = ColorRect.new()
	sep.position = Vector2(40, 130)
	sep.size = Vector2(card_size.x - 80, 1)
	sep.color = Color(accent.r, accent.g, accent.b, 0.3)
	card.add_child(sep)

	# Description (multiline)
	var d = Label.new()
	d.text = desc
	d.position = Vector2(12, 140)
	d.size = Vector2(card_size.x - 24, 50)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.add_theme_font_size_override("font_size", 12)
	d.add_theme_color_override("font_color", Color(0.6, 0.62, 0.7))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD
	card.add_child(d)

	# Selection arrow (bottom)
	var arrow = Label.new()
	arrow.name = "Arrow"
	arrow.text = "^"
	arrow.position = Vector2(0, card_size.y - 24)
	arrow.size = Vector2(card_size.x, 20)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 14)
	arrow.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	arrow.visible = false
	card.add_child(arrow)

	return card


func _add_menu_separator(parent: Control, y: float):
	var sep = ColorRect.new()
	sep.position = Vector2(60, y)
	sep.size = Vector2(parent.size.x - 120, 1)
	sep.color = Color(0.7, 0.6, 0.4, 0.35)
	parent.add_child(sep)


# ── Players ──

func _spawn_players() -> void:
	player1 = PlayerScene.instantiate()
	player1.player_id = 1
	player1.is_ai = false
	player1.input_prefix = "p1_"
	player1.character_type = p1_char_idx
	player1.player_color = player1.CHAR_COLORS[p1_char_idx]
	player1.position = Vector2(250, 360)
	player1.facing = Vector2.RIGHT
	add_child(player1)

	player2 = PlayerScene.instantiate()
	player2.player_id = 2
	player2.is_ai = (game_mode == 1 or game_mode == 3)
	player2.ai_difficulty = ai_difficulty
	player2.input_prefix = "p2_"
	player2.character_type = p2_char_idx
	player2.player_color = player2.CHAR_COLORS[p2_char_idx]
	player2.position = Vector2(1030, 360)
	player2.facing = Vector2.LEFT
	add_child(player2)

	player1.opponent = player2
	player2.opponent = player1


func _connect_signals() -> void:
	player1.health_changed.connect(_on_p1_hp)
	player2.health_changed.connect(_on_p2_hp)
	player1.mana_changed.connect(_on_p1_mana)
	player2.mana_changed.connect(_on_p2_mana)
	player1.died.connect(func(): _end_round(2))
	player2.died.connect(func(): _end_round(1))


# ── Game Loop ──

func _process(delta: float) -> void:
	# Mode selection screen
	if game_mode == 0:
		menu_time += delta
		menu_magic_angle += delta * 0.3
		_update_menu_particles(delta)
		queue_redraw()
		# Title screen phase
		if title_active:
			title_blink_time += delta
			if is_instance_valid(title_panel):
				var prompt = title_panel.get_node_or_null("EnterPrompt")
				if prompt:
					var alpha = 0.4 + 0.6 * abs(sin(title_blink_time * 2.0))
					prompt.modulate = Color(1, 1, 1, alpha)
			if Input.is_action_just_pressed("ui_confirm") or Input.is_action_just_pressed("ui_accept"):
				_dismiss_title()
			return
		if settings_active:
			_process_settings(delta)
			return
		# Left/Right navigation for mode cards (horizontal)
		if Input.is_action_just_pressed("p1_move_right"):
			menu_cursor = (menu_cursor + 1) % 3
			_update_menu_highlight()
			AudioManager.play_sfx("select")
		elif Input.is_action_just_pressed("p1_move_left"):
			menu_cursor = (menu_cursor + 2) % 3
			_update_menu_highlight()
			AudioManager.play_sfx("select")
		# Up/Down for difficulty
		if Input.is_action_just_pressed("p1_move_up"):
			_set_difficulty(mini(ai_difficulty + 1, 2))
		elif Input.is_action_just_pressed("p1_move_down"):
			_set_difficulty(maxi(ai_difficulty - 1, 0))
		if Input.is_action_just_pressed("ui_tab"):
			_open_settings()
		elif Input.is_action_just_pressed("ui_confirm") or Input.is_action_just_pressed("ui_accept"):
			if menu_cursor == 0:
				_start_game(1)  # VS IA
			elif menu_cursor == 1:
				_start_game(2)  # 2 Jugadores Local
			else:
				_start_game(3)  # Campana
		return

	if char_select_active:
		queue_redraw()
		if Input.is_action_just_pressed("ui_escape") and char_select_phase == 0:
			_cancel_char_select()
			return
		_process_char_select()
		return

	if defeat_panel_active:
		if Input.is_action_just_pressed("ui_confirm"):
			_confirm_defeat_sign()
		return

	if story_select_active:
		queue_redraw()
		if Input.is_action_just_pressed("ui_escape"):
			_cancel_story_select()
			return
		_process_story_select()
		return

	if boss_intro_active:
		if Input.is_action_just_pressed("ui_confirm"):
			_skip_boss_intro()
		return

	if waiting_to_start:
		if Input.is_action_just_pressed("ui_confirm"):
			waiting_to_start = false
			_fade_instructions(false)
			if is_instance_valid(footer_label):
				footer_label.text = ">>> Presiona TAB para cerrar <<<"
			AudioManager.set_battle_mode(true)
			_start_round_intro()
		return

	if round_transition:
		round_transition_timer -= delta
		if round_transition_timer <= 0:
			_next_round()
			round_transition = false
		return

	if round_intro_active:
		return

	if pause_active:
		_process_pause()
		return

	if Input.is_action_just_pressed("ui_escape"):
		_toggle_pause()
		return

	if game_over:
		if Input.is_action_just_pressed("ui_confirm"):
			if game_mode == 3:
				# Story mode: checar si hay victory panel o resultado de match
				var vp = hud.get_node_or_null("VictoryPanel")
				if vp:
					get_tree().reload_current_scene()
				else:
					_story_match_result()
			else:
				get_tree().reload_current_scene()
		return

	if Input.is_action_just_pressed("ui_tab"):
		if not is_instance_valid(instructions_panel):
			_create_instructions_panel()
			footer_label.text = ">>> Presiona TAB para cerrar <<<"
			_pause_players(true)
		elif instructions_panel.visible:
			_fade_instructions(false)
			_pause_players(false)
		else:
			instructions_panel.visible = true
			_fade_instructions(true)
			_pause_players(true)

	if is_instance_valid(instructions_panel) and instructions_panel.visible and instructions_panel.modulate.a > 0.5:
		return

	game_timer -= delta
	var mins = int(game_timer) / 60
	var secs = int(game_timer) % 60
	timer_label.text = "%d:%02d" % [mins, secs]
	# Timer urgency effects
	if game_timer <= 15.0:
		var pulse = abs(sin(arena_time * 4.0))
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.15).lerp(Color(1.0, 0.6, 0.3), pulse))
		timer_label.add_theme_font_size_override("font_size", 24 + int(pulse * 4))
	elif game_timer <= 30.0:
		var pulse = abs(sin(arena_time * 2.0)) * 0.3
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.25).lerp(Color(1.0, 0.9, 0.6), pulse))
	else:
		timer_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))

	if game_timer <= 0:
		if not is_instance_valid(player1) or not is_instance_valid(player2):
			return
		if player1.hp > player2.hp:
			_end_round(1)
		elif player2.hp > player1.hp:
			_end_round(2)
		else:
			_end_round(0)  # Draw
		return

	orb_timer -= delta
	if orb_timer <= 0:
		_spawn_orb()
		orb_timer = ORB_SPAWN_TIME

	_update_ability_hud()
	_update_arena_particles(delta)
	_apply_shake(delta)
	_update_hitstop(delta)
	_update_flash(delta)
	if arena_tint_timer > 0:
		arena_tint_timer -= delta
	queue_redraw()


func _set_difficulty(level: int) -> void:
	if level == ai_difficulty:
		return
	ai_difficulty = level
	var names = ["FACIL", "NORMAL", "DIFICIL"]
	var colors = [Color(0.3, 0.9, 0.3), Color(1.0, 0.8, 0.2), Color(1.0, 0.3, 0.2)]
	var display = mode_select_panel.get_node_or_null("DiffDisplay")
	if display:
		display.text = names[level]
		display.add_theme_color_override("font_color", colors[level])
	AudioManager.play_sfx("select")


func _update_menu_highlight() -> void:
	if not is_instance_valid(mode_select_panel):
		return
	var accents = [Color(0.2, 0.85, 1.0), Color(0.2, 1.0, 0.5), Color(1.0, 0.8, 0.2)]
	var bgs = [Color(0.03, 0.05, 0.12, 0.78), Color(0.03, 0.08, 0.04, 0.78), Color(0.07, 0.04, 0.02, 0.78)]
	for i in 3:
		var card = mode_select_panel.get_node_or_null("ModeCard" + str(i))
		if not card:
			continue
		var selected = (i == menu_cursor)
		var accent = accents[i]
		var s = StyleBoxFlat.new()
		if selected:
			s.bg_color = Color(accent.r * 0.12, accent.g * 0.12, accent.b * 0.12, 0.88)
			s.border_color = accent
			s.set_border_width_all(2)
			s.shadow_color = Color(accent.r * 0.3, accent.g * 0.3, accent.b * 0.3, 0.35)
			s.shadow_size = 10
		else:
			s.bg_color = bgs[i]
			s.border_color = Color(accent.r, accent.g, accent.b, 0.2)
			s.set_border_width_all(1)
			s.shadow_size = 0
		s.set_corner_radius_all(10)
		card.add_theme_stylebox_override("panel", s)
		# Scale effect for selected card
		if selected:
			card.scale = Vector2(1.04, 1.04)
			card.pivot_offset = card.size / 2.0
		else:
			card.scale = Vector2(1.0, 1.0)
		var arrow = card.get_node_or_null("Arrow")
		if arrow:
			arrow.visible = selected


func _start_game(mode: int) -> void:
	game_mode = mode
	AudioManager.play_sfx("select")
	# Scale out + fade
	var tw = create_tween()
	mode_select_panel.pivot_offset = mode_select_panel.size / 2.0
	tw.tween_property(mode_select_panel, "modulate", Color(1, 1, 1, 0), 0.35)
	tw.parallel().tween_property(mode_select_panel, "scale", Vector2(0.92, 0.92), 0.35).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		mode_select_panel.visible = false
		mode_select_panel.scale = Vector2(1, 1)
		menu_cursor = 0
		if mode == 3 and _load_story_progress():
			_start_story_select()
		else:
			_start_char_select()
	)


func _rounds_to_win() -> int:
	return 1 if game_mode == 3 else ROUNDS_TO_WIN


var last_orb_side = 0  # 0=left, 1=right - alterna para spawn parejo

func _spawn_orb() -> void:
	var current = get_tree().get_nodes_in_group("orbs").size()
	if current >= MAX_ORBS_IN_ARENA:
		return
	var orb = OrbScene.instantiate()
	orb.orb_color = "mana"
	# Alternar entre lado izquierdo y derecho
	var cx = ARENA.get_center().x
	if last_orb_side == 0:
		orb.position = Vector2(
			randf_range(ARENA.position.x + 40, cx - 20),
			randf_range(ARENA.position.y + 40, ARENA.end.y - 40)
		)
	else:
		orb.position = Vector2(
			randf_range(cx + 20, ARENA.end.x - 40),
			randf_range(ARENA.position.y + 40, ARENA.end.y - 40)
		)
	last_orb_side = 1 - last_orb_side
	add_child(orb)


func _end_round(winner: int) -> void:
	_pause_players(true)

	if winner == 1:
		p1_wins += 1
	elif winner == 2:
		p2_wins += 1

	_update_wins_display()

	var p2_name = "IA" if game_mode == 1 else "J2"

	# Check if match is over
	var rtw = _rounds_to_win()
	if p1_wins >= rtw:
		game_over = true
		game_over_label.text = "Jugador 1 Gana!"
		var sl = game_over_panel.get_node("ScoreLabel")
		if sl:
			sl.text = "J1 %d - %d %s" % [p1_wins, p2_wins, p2_name]
		game_over_panel.visible = true
		game_over_panel.modulate = Color(1, 1, 1, 0)
		var tw = create_tween()
		tw.tween_property(game_over_panel, "modulate", Color(1, 1, 1, 1), 0.5)
		screen_shake(8.0)
		AudioManager.play_sfx("win")
		return
	elif p2_wins >= rtw:
		game_over = true
		game_over_label.text = p2_name + " Gana!"
		var sl = game_over_panel.get_node("ScoreLabel")
		if sl:
			sl.text = "J1 %d - %d %s" % [p1_wins, p2_wins, p2_name]
		game_over_panel.visible = true
		game_over_panel.modulate = Color(1, 1, 1, 0)
		var tw = create_tween()
		tw.tween_property(game_over_panel, "modulate", Color(1, 1, 1, 1), 0.5)
		screen_shake(8.0)
		AudioManager.play_sfx("win")
		return

	# Show round result banner
	var round_text = ""
	if winner == 1:
		round_text = "Jugador 1 gana la ronda!"
	elif winner == 2:
		round_text = p2_name + " gana la ronda!"
	else:
		round_text = "Ronda empatada!"

	var banner_bg = hud.get_node("BannerBG")
	round_banner.text = round_text
	banner_bg.visible = true
	banner_bg.modulate = Color(1, 1, 1, 0)
	var tw = create_tween()
	tw.tween_property(banner_bg, "modulate", Color(1, 1, 1, 1), 0.3)
	AudioManager.play_sfx("win")

	round_transition = true
	round_transition_timer = 2.5
	current_round += 1


func _next_round() -> void:
	# Fade-out banner
	var banner_bg = hud.get_node("BannerBG")
	if banner_bg:
		var tw = create_tween()
		tw.tween_property(banner_bg, "modulate", Color(1, 1, 1, 0), 0.4)
		tw.tween_callback(func(): banner_bg.visible = false)

	# Clear orbs
	for orb in get_tree().get_nodes_in_group("orbs"):
		orb.queue_free()
	for proj in get_tree().get_nodes_in_group("projectiles"):
		proj.queue_free()

	# Reset players
	player1.hp = player1.max_hp
	player1.mana = 0.0
	player1.state = player1.State.IDLE
	player1.state_timer = 0.0
	player1.cd_fire = 0.0
	player1.cd_ice = 0.0
	player1.cd_special = 0.0
	player1.position = Vector2(250, 360)
	player1.facing = Vector2.RIGHT
	player1.velocity = Vector2.ZERO
	player1.health_changed.emit(player1.hp, player1.max_hp)
	player1.mana_changed.emit(player1.mana, player1.MAX_MANA)

	player2.hp = player2.max_hp
	player2.mana = 0.0
	player2.state = player2.State.IDLE
	player2.state_timer = 0.0
	player2.cd_fire = 0.0
	player2.cd_ice = 0.0
	player2.cd_special = 0.0
	player2.position = Vector2(1030, 360)
	player2.facing = Vector2.LEFT
	player2.velocity = Vector2.ZERO
	player2.health_changed.emit(player2.hp, player2.max_hp)
	player2.mana_changed.emit(player2.mana, player2.MAX_MANA)

	# Reset timer
	game_timer = GAME_TIME
	orb_timer = 1.0

	# Update round label
	round_label.text = "Ronda %d" % current_round

	# Reset HP text
	p1_hp_text.text = "100"
	p2_hp_text.text = "100"

	_start_round_intro()


# ── Round Intro ──

var round_intro_active = false


func _start_round_intro() -> void:
	round_intro_active = true
	_pause_players(true)

	# Phase 1: "RONDA X"
	round_intro_label.text = "RONDA %d" % current_round
	round_intro_label.visible = true
	round_intro_label.modulate = Color(1, 1, 1, 0)
	round_intro_label.scale = Vector2(2.5, 2.5)
	round_intro_label.pivot_offset = Vector2(640, 50)

	var tw = create_tween()
	tw.tween_property(round_intro_label, "modulate", Color(1, 1, 1, 1), 0.3).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(round_intro_label, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(0.6)
	tw.tween_property(round_intro_label, "modulate", Color(1, 1, 1, 0), 0.2)
	tw.tween_callback(func():
		round_intro_label.visible = false
		# Phase 2: "LUCHA!"
		fight_intro_label.text = "LUCHA!"
		fight_intro_label.visible = true
		fight_intro_label.modulate = Color(1, 1, 1, 0)
		fight_intro_label.scale = Vector2(0.3, 0.3)
		fight_intro_label.pivot_offset = Vector2(640, 60)
		var tw2 = create_tween()
		tw2.tween_property(fight_intro_label, "modulate", Color(1, 1, 1, 1), 0.1)
		tw2.parallel().tween_property(fight_intro_label, "scale", Vector2(1.2, 1.2), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw2.tween_property(fight_intro_label, "scale", Vector2(1.0, 1.0), 0.1)
		tw2.tween_interval(0.3)
		tw2.tween_property(fight_intro_label, "modulate", Color(1, 1, 1, 0), 0.2)
		tw2.tween_callback(func():
			fight_intro_label.visible = false
			round_intro_active = false
			if not game_over and not round_transition:
				_pause_players(false)
		)
	)


# ── Screen Shake ──

var shake_amount = 0.0
var shake_decay = 8.0
var base_position = Vector2.ZERO


func screen_shake(intensity: float) -> void:
	shake_amount = max(shake_amount, intensity)


func _apply_shake(delta: float) -> void:
	if shake_amount > 0.1:
		position = base_position + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amount
		shake_amount = lerp(shake_amount, 0.0, shake_decay * delta)
	else:
		shake_amount = 0.0
		position = base_position


# ── Hitstop ──

var hitstop_timer = 0.0
var hitstop_active = false


func hitstop(duration: float) -> void:
	hitstop_timer = duration
	hitstop_active = true
	_pause_players(true)


func _update_hitstop(delta: float) -> void:
	if hitstop_active:
		hitstop_timer -= delta
		if hitstop_timer <= 0:
			hitstop_active = false
			if not game_over and not round_transition and not waiting_to_start:
				_pause_players(false)


# ── Screen Flash ──

var flash_overlay: ColorRect
var flash_timer = 0.0
var flash_duration = 0.0
var flash_color = Color.WHITE


func screen_flash(color: Color = Color.WHITE, duration: float = 0.12, intensity: float = 0.6) -> void:
	flash_color = Color(color.r, color.g, color.b, intensity)
	flash_timer = duration
	flash_duration = duration
	if flash_overlay:
		flash_overlay.color = flash_color


func _update_flash(delta: float) -> void:
	if flash_timer > 0:
		flash_timer -= delta
		var t = max(flash_timer / flash_duration, 0.0)
		# Ease-out cuadratico: desvanece rapido al inicio, suave al final
		t = t * t
		flash_overlay.color = Color(flash_color.r, flash_color.g, flash_color.b, flash_color.a * t)
		if flash_timer <= 0:
			flash_overlay.color = Color(1, 1, 1, 0)


# ── Arena Tint ──

var arena_tint_color = Color(0, 0, 0, 0)
var arena_tint_timer = 0.0
var arena_tint_duration = 0.0


func arena_tint(color: Color, duration: float = 0.5) -> void:
	arena_tint_color = color
	arena_tint_timer = duration
	arena_tint_duration = duration


# ── Death Explosion ──

func death_explosion(pos: Vector2, color: Color) -> void:
	screen_flash(Color(1, 0.95, 0.85), 0.15, 0.35)
	screen_shake(15.0)
	hitstop(0.12)
	spawn_hit_particles(pos, color, 20)
	spawn_hit_particles(pos, color.lightened(0.3), 16)
	spawn_hit_particles(pos, Color.WHITE, 8)
	# Anillo expansivo visual
	var ring = AreaEffectScene.instantiate()
	ring.position = pos
	ring.max_radius = 150.0
	ring.expand_speed = 400.0
	ring.damage = 0
	ring.stun_time = 0.0
	ring.effect_color = color
	ring.shooter = null
	if player1 and player2:
		ring.hit_targets = [player1, player2]
	add_child(ring)


func spawn_hit_particles(pos: Vector2, color: Color, count: int = 8) -> void:
	var p = HitParticlesScene.instantiate()
	add_child(p)
	p.spawn(pos, color, count)


func spawn_damage_number(pos: Vector2, amount: int, is_stun: bool = false) -> void:
	var dn = DamageNumberScene.instantiate()
	add_child(dn)
	dn.setup(pos, amount, is_stun)
	# "CRITICO!" para golpes grandes
	if amount >= 25 and not is_stun:
		var crit = DamageNumberScene.instantiate()
		add_child(crit)
		crit.setup(pos + Vector2(0, -20), 0, false)
		crit.text = "CRITICO!"
		crit.color = Color(1, 0.85, 0.2)
		crit.rise_speed = 35.0


# ── Arena Drawing ──

func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.08, 0.05, 0.07))

	if game_mode == 0:
		_draw_menu_background()
		if settings_active:
			_draw_settings_bg()
		return

	if char_select_active:
		_draw_char_select_bg()
		return

	if story_select_active:
		_draw_story_select_bg()
		return

	_draw_arena()


func _draw_menu_background():
	# Subtle vertical gradient (dark top, slightly lighter bottom)
	for gy in range(0, 18):
		var ga = float(gy) / 18.0 * 0.04
		draw_rect(Rect2(0, float(gy) * 40, 1280, 40), Color(0.06, 0.04, 0.12, ga))

	# Vignette - dark edges
	for i in 10:
		var va = 0.07 * (1.0 - float(i) / 10.0)
		draw_rect(Rect2(i * 18, i * 10, 1280 - i * 36, 720 - i * 20), Color(0, 0, 0, va))

	# Golden ember particles (brighter)
	for p in menu_particles:
		var alpha = clampf(p.life / p.max_life, 0.0, 1.0)
		var c = Color(p.color.r, p.color.g, p.color.b, p.color.a * alpha)
		draw_circle(p.pos, p.size, c)
		draw_circle(p.pos, p.size * 3.0, Color(c.r, c.g, c.b, c.a * 0.15))

	# Golden arcane seal - triple ring (more visible)
	var center = Vector2(640, 360)
	var mc_alpha = 0.14 + sin(menu_time * 0.5) * 0.05
	_draw_magic_circle(center, 290, Color(0.8, 0.58, 0.15, mc_alpha))
	_draw_magic_circle(center, 205, Color(0.9, 0.68, 0.2, mc_alpha * 0.7))
	_draw_magic_circle(center, 125, Color(1.0, 0.78, 0.25, mc_alpha * 0.5))

	# Serpent borders (Quetzalcoatl) - thicker
	_draw_serpent_border(Vector2(80, 28), Vector2(1200, 28), 0.12)
	_draw_serpent_border(Vector2(80, 692), Vector2(1200, 692), 0.12)

	# Corner ornaments - bigger
	_draw_corner_ornament(Vector2(65, 45), 1.0, 1.0)
	_draw_corner_ornament(Vector2(1215, 45), -1.0, 1.0)
	_draw_corner_ornament(Vector2(65, 675), 1.0, -1.0)
	_draw_corner_ornament(Vector2(1215, 675), -1.0, -1.0)

	# Vertical golden lines on sides (thicker)
	var side_a = 0.1 + sin(menu_time * 0.7) * 0.04
	var side_col = Color(0.75, 0.55, 0.14, side_a)
	draw_line(Vector2(78, 60), Vector2(78, 660), side_col, 2.0)
	draw_line(Vector2(1202, 60), Vector2(1202, 660), side_col, 2.0)


func _draw_serpent_border(from: Vector2, to: Vector2, alpha: float):
	var col = Color(0.8, 0.58, 0.15, alpha)
	var wave_a = 0.08 + sin(menu_time * 0.4) * 0.03
	var col2 = Color(0.9, 0.68, 0.22, wave_a)
	draw_line(from, to, col, 2.0)
	var steps = 30
	var prev = from
	for i in range(1, steps + 1):
		var t = float(i) / float(steps)
		var px = lerp(from.x, to.x, t)
		var wave = sin(t * TAU * 3.0 + menu_time * 1.5) * 5.0
		var pt = Vector2(px, from.y + wave)
		draw_line(prev, pt, col2, 1.0)
		prev = pt
	for i in range(0, 12):
		var t = float(i) / 11.0
		var px = lerp(from.x + 30, to.x - 30, t)
		draw_rect(Rect2(px - 2, from.y - 2, 4, 4), Color(0.85, 0.65, 0.2, alpha * 1.5))


func _draw_corner_ornament(pos: Vector2, dir_x: float, dir_y: float):
	var alpha = 0.16 + sin(menu_time * 0.6) * 0.05
	var col = Color(0.85, 0.62, 0.16, alpha)
	var col_bright = Color(1.0, 0.8, 0.25, alpha * 1.4)
	var step_size = 10.0
	for i in 4:
		var fi = float(i)
		var x1 = pos.x + fi * step_size * dir_x
		var x2 = x1
		var y2 = pos.y + fi * step_size * dir_y
		var x3 = pos.x + (fi + 1) * step_size * dir_x
		draw_line(Vector2(x1, pos.y), Vector2(x2, y2), col, 1.5)
		draw_line(Vector2(x2, y2), Vector2(x3, y2), col, 1.5)
	var jewel = pos + Vector2(dir_x * 16, dir_y * 16)
	draw_circle(jewel, 3.5, col_bright)
	draw_arc(jewel, 6, 0, TAU, 12, col, 1.0)
	for j in 12:
		var a = float(j) * TAU / 12.0 + menu_time * 0.3
		var r = 10.0 + float(j) * 0.8
		draw_circle(jewel + Vector2(cos(a), sin(a)) * r, 0.8, Color(0.75, 0.55, 0.15, alpha * 0.5))


func _draw_magic_circle(center: Vector2, radius: float, color: Color):
	draw_arc(center, radius, menu_magic_angle, menu_magic_angle + TAU, 48, color, 1.5)
	draw_arc(center, radius * 0.65, -menu_magic_angle * 0.7, -menu_magic_angle * 0.7 + TAU, 36, Color(color.r, color.g, color.b, color.a * 0.6), 1.0)
	# Rune dots with diamond markers (Aztec sun style)
	for j in 8:
		var a = menu_magic_angle + j * TAU / 8.0
		var pt = center + Vector2(cos(a), sin(a)) * radius * 0.83
		draw_circle(pt, 3.0, Color(color.r, color.g, color.b, color.a * 1.5))
		var d = 2.0
		draw_line(pt + Vector2(0, -d), pt + Vector2(d, 0), Color(color.r, color.g, color.b, color.a * 0.8), 1.0)
		draw_line(pt + Vector2(d, 0), pt + Vector2(0, d), Color(color.r, color.g, color.b, color.a * 0.8), 1.0)
		draw_line(pt + Vector2(0, d), pt + Vector2(-d, 0), Color(color.r, color.g, color.b, color.a * 0.8), 1.0)
		draw_line(pt + Vector2(-d, 0), pt + Vector2(0, -d), Color(color.r, color.g, color.b, color.a * 0.8), 1.0)
	# Cross lines
	for j in 4:
		var a = menu_magic_angle * 0.5 + j * TAU / 4.0
		var p1 = center + Vector2(cos(a), sin(a)) * radius * 0.3
		var p2 = center + Vector2(cos(a), sin(a)) * radius * 0.95
		draw_line(p1, p2, Color(color.r, color.g, color.b, color.a * 0.4), 1.0)
	# Sun ray triangles between points
	for j in 8:
		var a = menu_magic_angle + (float(j) + 0.5) * TAU / 8.0
		var tip = center + Vector2(cos(a), sin(a)) * radius * 0.72
		var base_l = center + Vector2(cos(a - 0.08), sin(a - 0.08)) * radius * 0.6
		var base_r = center + Vector2(cos(a + 0.08), sin(a + 0.08)) * radius * 0.6
		draw_line(base_l, tip, Color(color.r, color.g, color.b, color.a * 0.3), 1.0)
		draw_line(base_r, tip, Color(color.r, color.g, color.b, color.a * 0.3), 1.0)


func _draw_char_select_bg():
	menu_time += get_process_delta_time() * 0.5
	menu_magic_angle += get_process_delta_time() * 0.15

	# Vignette
	for i in 6:
		var va = 0.08 * (1.0 - float(i) / 6.0)
		draw_rect(Rect2(i * 25, i * 15, 1280 - i * 50, 720 - i * 30), Color(0, 0, 0, va))

	# Circulo magico tenue detras de cada portrait
	var char_colors = [
		Color(0.2, 0.8, 0.9), Color(0.9, 0.3, 0.6), Color(0.15, 0.75, 0.3),
		Color(0.95, 0.75, 0.1), Color(0.55, 0.15, 0.8), Color(1.0, 0.55, 0.1),
	]
	var p1c = char_colors[p1_char_idx]
	var glow_a = 0.06 + sin(menu_time * 2.0) * 0.02
	if game_mode == 3:
		# Centrado para story
		_draw_magic_circle(Vector2(640, 340), 160, Color(p1c.r, p1c.g, p1c.b, glow_a))
	else:
		_draw_magic_circle(Vector2(320, 340), 140, Color(p1c.r, p1c.g, p1c.b, glow_a))
		var p2c = char_colors[p2_char_idx]
		_draw_magic_circle(Vector2(960, 340), 140, Color(p2c.r, p2c.g, p2c.b, glow_a))

	# Serpent borders
	_draw_serpent_border(Vector2(80, 595), Vector2(1200, 595), 0.06)

	# Ornamentos de esquina
	_draw_corner_ornament(Vector2(60, 30), 1.0, 1.0)
	_draw_corner_ornament(Vector2(1220, 30), -1.0, 1.0)
	_draw_corner_ornament(Vector2(60, 690), 1.0, -1.0)
	_draw_corner_ornament(Vector2(1220, 690), -1.0, -1.0)


func _draw_story_select_bg():
	menu_time += get_process_delta_time() * 0.5
	menu_magic_angle += get_process_delta_time() * 0.15

	# Subtle gradient
	for gy in range(0, 14):
		var ga = float(gy) / 14.0 * 0.03
		draw_rect(Rect2(0, float(gy) * 52, 1280, 52), Color(0.05, 0.03, 0.1, ga))

	# Vignette
	for i in 8:
		var va = 0.08 * (1.0 - float(i) / 8.0)
		draw_rect(Rect2(i * 22, i * 13, 1280 - i * 44, 720 - i * 26), Color(0, 0, 0, va))

	# Circulo central con sello dorado (more visible)
	var center = Vector2(640, 340)
	var mc_a = 0.12 + sin(menu_time * 1.5) * 0.04
	_draw_magic_circle(center, 260, Color(0.8, 0.58, 0.15, mc_a))
	_draw_magic_circle(center, 175, Color(0.9, 0.68, 0.22, mc_a * 0.6))

	# Lineas conectando stages (camino de piedra)
	var stage_positions = _get_stage_positions()
	var path_col = Color(0.55, 0.42, 0.15, 0.2)
	for i in range(stage_positions.size() - 1):
		draw_line(stage_positions[i], stage_positions[i + 1], path_col, 3.5)
		# Puntos en el camino
		var steps = 6
		for j in steps:
			var t = float(j + 1) / float(steps + 1)
			var pt = stage_positions[i].lerp(stage_positions[i + 1], t)
			draw_circle(pt, 2.5, Color(0.55, 0.42, 0.15, 0.14))

	# Glow en stage activo (bigger for bigger cards)
	if story_cursor < stage_positions.size():
		var active_pos = stage_positions[story_cursor]
		var char_colors = [
			Color(0.2, 0.8, 0.9), Color(0.9, 0.3, 0.6), Color(0.15, 0.75, 0.3),
			Color(0.95, 0.75, 0.1), Color(0.55, 0.15, 0.8), Color(1.0, 0.55, 0.1),
		]
		var boss_idx = story_opponents[story_cursor]
		var bc = char_colors[boss_idx] if story_completed[story_cursor] else Color(0.6, 0.55, 0.4)
		var pulse = sin(menu_time * 4.0) * 0.07 + 0.14
		draw_circle(active_pos, 90, Color(bc.r, bc.g, bc.b, pulse * 0.5))
		draw_circle(active_pos, 65, Color(bc.r, bc.g, bc.b, pulse))

	# Serpent borders
	_draw_serpent_border(Vector2(60, 25), Vector2(1220, 25), 0.1)
	_draw_serpent_border(Vector2(60, 695), Vector2(1220, 695), 0.1)

	# Esquinas
	_draw_corner_ornament(Vector2(50, 42), 1.0, 1.0)
	_draw_corner_ornament(Vector2(1230, 42), -1.0, 1.0)
	_draw_corner_ornament(Vector2(50, 678), 1.0, -1.0)
	_draw_corner_ornament(Vector2(1230, 678), -1.0, -1.0)


func _get_stage_difficulty(stage_idx: int) -> int:
	# Progressive: 0=easy, 1=normal, 2=hard based on stage position
	if stage_idx <= 1:
		return 0  # Facil
	elif stage_idx <= 3:
		return 1  # Normal
	else:
		return 2  # Dificil


func _get_stage_positions() -> Array:
	return [
		Vector2(220, 250),   # Stage 1
		Vector2(440, 210),   # Stage 2
		Vector2(660, 250),   # Stage 3
		Vector2(880, 210),   # Stage 4
		Vector2(340, 440),   # Stage 5
		Vector2(640, 440),   # Stage 6
	]


func _draw_arena():
	arena_time += get_process_delta_time()

	# Arena floor base
	draw_rect(ARENA, Color(0.05, 0.05, 0.09))

	# Gradiente superior suave
	for gy in range(0, 40):
		var ga = float(40 - gy) / 40.0 * 0.04
		draw_line(Vector2(ARENA.position.x, ARENA.position.y + float(gy)),
			Vector2(ARENA.end.x, ARENA.position.y + float(gy)), Color(0.12, 0.12, 0.22, ga), 1.0)

	# Player zone tints (degradado suave desde los lados)
	var half_w = ARENA.size.x / 2.0
	for zx in range(0, 6):
		var za = 0.04 * (1.0 - float(zx) / 6.0)
		var zw = half_w / 6.0
		draw_rect(Rect2(Vector2(ARENA.position.x + zw * float(zx), ARENA.position.y),
			Vector2(zw, ARENA.size.y)), Color(0.04, 0.15, 0.2, za))
		draw_rect(Rect2(Vector2(ARENA.end.x - zw * float(zx + 1), ARENA.position.y),
			Vector2(zw, ARENA.size.y)), Color(0.2, 0.04, 0.12, za))

	# Floor tile pattern (hexagonal feel)
	var gs = 45
	for x in range(int(ARENA.position.x) + 10, int(ARENA.end.x), gs):
		for y in range(int(ARENA.position.y) + 10, int(ARENA.end.y), gs):
			var off_x = (gs / 2) if (int(y / gs) % 2 == 1) else 0
			var px = float(x + off_x)
			if px >= ARENA.position.x and px <= ARENA.end.x:
				var dp = sin(arena_time * 0.5 + px * 0.008 + float(y) * 0.008) * 0.05
				draw_circle(Vector2(px, float(y)), 1.0, Color(0.12, 0.12, 0.22, 0.18 + dp))
				# Conectar con lineas sutiles
				if px + float(gs) <= ARENA.end.x:
					draw_line(Vector2(px, float(y)), Vector2(px + float(gs), float(y)),
						Color(0.1, 0.1, 0.18, 0.06 + dp * 0.3), 0.5)

	# Edge rune border con pulso onda
	for bx in range(int(ARENA.position.x) + 20, int(ARENA.end.x), 40):
		var ea = 0.12 + sin(arena_time * 1.2 + float(bx) * 0.04) * 0.08
		var ec = Color(0.2, 0.25, 0.55, ea)
		draw_circle(Vector2(float(bx), ARENA.position.y + 4), 2.0, ec)
		draw_circle(Vector2(float(bx), ARENA.end.y - 4), 2.0, ec)
		# Lineas entre puntos
		if bx + 40 < int(ARENA.end.x):
			draw_line(Vector2(float(bx), ARENA.position.y + 4), Vector2(float(bx + 40), ARENA.position.y + 4),
				Color(0.15, 0.18, 0.4, ea * 0.4), 0.5)
			draw_line(Vector2(float(bx), ARENA.end.y - 4), Vector2(float(bx + 40), ARENA.end.y - 4),
				Color(0.15, 0.18, 0.4, ea * 0.4), 0.5)
	for by in range(int(ARENA.position.y) + 20, int(ARENA.end.y), 40):
		var ea = 0.12 + sin(arena_time * 1.2 + float(by) * 0.04) * 0.08
		draw_circle(Vector2(ARENA.position.x + 4, float(by)), 2.0, Color(0.2, 0.25, 0.55, ea))
		draw_circle(Vector2(ARENA.end.x - 4, float(by)), 2.0, Color(0.2, 0.25, 0.55, ea))

	# Spawn position magic circles
	_draw_spawn_rune(Vector2(280, 360), Color(0.15, 0.55, 0.65))
	_draw_spawn_rune(Vector2(1000, 360), Color(0.65, 0.2, 0.4))

	# Energy veins - multiples lineas con particulas viajeras
	var cc = ARENA.get_center()
	var corners = [ARENA.position, Vector2(ARENA.end.x, ARENA.position.y), ARENA.end, Vector2(ARENA.position.x, ARENA.end.y)]
	for i in corners.size():
		var va = 0.05 + sin(arena_time * 0.6 + float(i) * 1.3) * 0.025
		draw_line(corners[i], cc, Color(0.18, 0.18, 0.38, va), 1.0)
		# 2 particulas viajeras por vena
		for j in 2:
			var travel = fmod(arena_time * 0.25 + float(i) * 0.25 + float(j) * 0.5, 1.0)
			var ep = corners[i].lerp(cc, travel)
			draw_circle(ep, 3.0, Color(0.35, 0.35, 0.65, va * 2.5))
			draw_circle(ep, 1.5, Color(0.55, 0.55, 0.85, va * 3.5))

	# Center divider - energia pulsante
	var cx = ARENA.get_center().x
	var div_p = 0.25 + sin(arena_time * 1.3) * 0.1
	draw_line(Vector2(cx, ARENA.position.y + 8), Vector2(cx, ARENA.end.y - 8),
		Color(0.18, 0.18, 0.32, div_p * 0.5), 1.0)
	for dy in range(int(ARENA.position.y) + 15, int(ARENA.end.y) - 15, 25):
		var seg_a = 0.12 + sin(arena_time * 2.0 + float(dy) * 0.06) * 0.1
		draw_line(Vector2(cx, float(dy)), Vector2(cx, float(dy + 12)),
			Color(0.3, 0.3, 0.6, seg_a), 2.5)

	# Center magic circle (gran circulo arcano multi-anillo)
	var pulse = 0.16 + sin(arena_time * 1.0) * 0.06
	# Outer ring
	draw_arc(cc, 70, arena_time * 0.25, arena_time * 0.25 + TAU, 52, Color(0.22, 0.25, 0.5, pulse), 2.0)
	# Mid ring counter-rotate
	draw_arc(cc, 50, -arena_time * 0.4, -arena_time * 0.4 + TAU, 40, Color(0.28, 0.25, 0.48, pulse * 0.7), 1.5)
	# Inner ring
	draw_arc(cc, 28, arena_time * 0.7, arena_time * 0.7 + TAU, 28, Color(0.32, 0.28, 0.55, pulse * 0.5), 1.0)
	# Rune points en anillo exterior
	for j in 8:
		var ra = arena_time * 0.25 + float(j) * TAU / 8.0
		var rp = cc + Vector2(cos(ra), sin(ra)) * 60
		var rpa = pulse + sin(arena_time * 1.8 + float(j)) * 0.07
		draw_circle(rp, 3.0, Color(0.38, 0.38, 0.65, rpa))
		draw_circle(rp, 1.5, Color(0.55, 0.55, 0.85, rpa * 1.2))
	# Cross lines
	for j in 6:
		var la = arena_time * 0.12 + float(j) * TAU / 6.0
		var lp1 = cc + Vector2(cos(la), sin(la)) * 22
		var lp2 = cc + Vector2(cos(la), sin(la)) * 66
		draw_line(lp1, lp2, Color(0.25, 0.25, 0.5, pulse * 0.4), 1.0)
	# Centro glow sutil
	draw_circle(cc, 15, Color(0.3, 0.3, 0.6, pulse * 0.15))

	# Arena border (multi-layer glow mejorado)
	for i in 5:
		var expand = float(i) * 2.0
		var ba = 0.5 - float(i) * 0.1
		var border_rect = Rect2(ARENA.position - Vector2(expand, expand), ARENA.size + Vector2(expand * 2, expand * 2))
		draw_rect(border_rect, Color(0.22, 0.28, 0.55, ba), false, 2.0 - float(i) * 0.35)

	# Corner torch flames
	for i in corners.size():
		_draw_torch(corners[i], i)

	# Ambient particles (wisps)
	for p in arena_particles:
		var alpha = clampf(p.life / p.max_life, 0.0, 1.0)
		var col = Color(p.color.r, p.color.g, p.color.b, p.color.a * alpha)
		var wobble = sin(arena_time * 2.0 + p.phase) * 2.0
		var draw_pos = p.pos + Vector2(wobble, 0)
		draw_circle(draw_pos, p.size * 2.5, Color(col.r, col.g, col.b, col.a * 0.1))
		draw_circle(draw_pos, p.size, col)

	# Vignette oscuro en bordes de arena
	for vi in 12:
		var va = 0.03 * (1.0 - float(vi) / 12.0)
		draw_rect(Rect2(ARENA.position.x + float(vi), ARENA.position.y + float(vi),
			ARENA.size.x - float(vi) * 2, ARENA.size.y - float(vi) * 2),
			Color(0, 0, 0, va))

	# Dynamic spell tint
	if arena_tint_timer > 0 and arena_tint_duration > 0:
		var tint_alpha = (arena_tint_timer / arena_tint_duration) * 0.12
		draw_rect(ARENA, Color(arena_tint_color.r, arena_tint_color.g, arena_tint_color.b, tint_alpha))

	# Bottom atmospheric haze
	for hy in range(int(ARENA.end.y) - 40, int(ARENA.end.y)):
		var haze_a = float(hy - (int(ARENA.end.y) - 40)) / 40.0 * 0.06
		var haze_shift = sin(arena_time * 0.3 + float(hy) * 0.1) * 0.01
		draw_line(Vector2(ARENA.position.x, float(hy)), Vector2(ARENA.end.x, float(hy)),
			Color(0.12 + haze_shift, 0.1, 0.22, haze_a), 1.0)

	# Battle vignette (bordes oscuros cinematicos)
	for vi in 12:
		var va = 0.07 * (1.0 - float(vi) / 12.0)
		draw_rect(Rect2(0, float(vi) * 5, 1280, 5), Color(0, 0, 0, va))
		draw_rect(Rect2(0, 720 - float(vi + 1) * 5, 1280, 5), Color(0, 0, 0, va))
		draw_rect(Rect2(float(vi) * 8, 0, 8, 720), Color(0, 0, 0, va * 0.5))
		draw_rect(Rect2(1280 - float(vi + 1) * 8, 0, 8, 720), Color(0, 0, 0, va * 0.5))


func _draw_torch(pos: Vector2, idx: int):
	var flame_time = arena_time * 3.0 + float(idx) * 1.7
	var flicker = sin(flame_time) * 0.15 + sin(flame_time * 2.3) * 0.1
	var intensity = 0.5 + flicker
	# Glow
	draw_circle(pos, 22, Color(0.8, 0.4, 0.1, intensity * 0.06))
	draw_circle(pos, 12, Color(0.9, 0.5, 0.15, intensity * 0.12))
	# Flames
	var sway = sin(flame_time * 0.8) * 2.0
	var fw = 4.0 + sin(flame_time * 2.0) * 1.0
	draw_circle(pos + Vector2(sway * 0.3, -2), fw + 1, Color(0.9, 0.4, 0.05, intensity * 0.3))
	draw_circle(pos + Vector2(sway * 0.5, -3), fw, Color(1.0, 0.7, 0.15, intensity * 0.5))
	draw_circle(pos + Vector2(sway * 0.2, -1), fw * 0.5, Color(1.0, 0.9, 0.5, intensity * 0.7))
	# Sparks
	for j in 2:
		var spark_a = flame_time * 2.0 + float(j) * 3.0
		var spark_y = -fmod(spark_a, 1.0) * 8.0
		var spark_x = sin(spark_a * 1.5) * 3.0 + sway
		draw_circle(pos + Vector2(spark_x, spark_y - 4), 1.0,
			Color(1, 0.8, 0.3, max(0.0, 0.6 - fmod(spark_a, 1.0))))
	# Rune ring around torch
	var rp = 0.35 + sin(arena_time * 0.8 + float(idx) * 1.5) * 0.15
	draw_arc(pos, 14, arena_time * 0.5 + float(idx), arena_time * 0.5 + float(idx) + TAU, 16, Color(0.25, 0.3, 0.5, rp * 0.35), 1.0)


func _draw_spawn_rune(center: Vector2, color: Color):
	var sa = 0.12 + sin(arena_time * 0.9) * 0.04
	draw_arc(center, 40, arena_time * 0.2, arena_time * 0.2 + TAU, 28, Color(color.r, color.g, color.b, sa), 1.5)
	draw_arc(center, 22, -arena_time * 0.35, -arena_time * 0.35 + TAU, 20, Color(color.r, color.g, color.b, sa * 0.6), 1.0)
	for j in 6:
		var a = arena_time * 0.2 + j * TAU / 6.0
		var rp = center + Vector2(cos(a), sin(a)) * 32
		draw_circle(rp, 2, Color(color.r, color.g, color.b, sa * 1.3))


# ── Pause / Resume ──

func _pause_players(paused: bool) -> void:
	if player1:
		player1.set_physics_process(!paused)
		player1.set_process(!paused)
	if player2:
		player2.set_physics_process(!paused)
		player2.set_process(!paused)


# ── Instructions Panel ──

var footer_label: Label


func _create_instructions_panel() -> void:
	instructions_panel = Panel.new()
	instructions_panel.position = Vector2(190, 30)
	instructions_panel.size = Vector2(900, 660)
	instructions_panel.modulate = Color(1, 1, 1, 0)
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.1, 0.07, 0.09, 0.97)
	ps.border_color = Color(0.76, 0.58, 0.3, 0.8)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(6)
	ps.shadow_color = Color(0.55, 0.41, 0.08, 0.4)
	ps.shadow_size = 16
	instructions_panel.add_theme_stylebox_override("panel", ps)
	hud.add_child(instructions_panel)

	# ── Titulo ──
	var title = Label.new()
	title.text = "NAHUAL: DUELO ARCANO"
	title.position = Vector2(0, 12)
	title.size = Vector2(900, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.91, 0.72, 0.29))
	instructions_panel.add_child(title)

	_add_separator(48)

	# ── Objetivo ──
	instructions_panel.add_child(_section_label("OBJETIVO", Vector2(40, 56)))

	var obj = Label.new()
	var obj_text = "Derrota a tu oponente antes de que acabe el tiempo (90s). Recoge orbes para\ndesbloquear habilidades mas poderosas. Si el tiempo se acaba, gana quien tenga mas vida."
	obj.text = obj_text
	obj.position = Vector2(40, 80)
	obj.size = Vector2(820, 36)
	obj.add_theme_font_size_override("font_size", 13)
	obj.add_theme_color_override("font_color", Color(0.72, 0.72, 0.78))
	instructions_panel.add_child(obj)

	_add_separator(118)

	# ── Controles ──
	instructions_panel.add_child(_section_label("CONTROLES", Vector2(40, 126)))

	var controls = [
		[["FLECHAS"], "Mover"],
		[["E"], "Golpe melee"],
		[["1"], "Fuego"],
		[["2"], "Hielo"],
		[["3"], "Arcano"],
		[["Q"], "Defender"],
		[["W"], "Esquivar"],
		[["TAB"], "Abrir / cerrar instrucciones"],
	]
	if game_mode == 2:
		controls.append_array([
			[["I", "J", "K", "L"], "Mover (P2)"],
			[["SPACE"], "Golpe melee (P2)"],
			[["7", "8", "9"], "Magia (P2)"],
			[["O"], "Defender (P2)"],
			[["P"], "Esquivar (P2)"],
		])
	var cy = 152
	for c in controls:
		var kx = 55
		for k in c[0]:
			var keycap = _create_keycap(k, Vector2(kx, cy))
			instructions_panel.add_child(keycap)
			kx += keycap.size.x + 4
		var desc_lbl = Label.new()
		desc_lbl.text = c[1]
		desc_lbl.position = Vector2(210, cy + 2)
		desc_lbl.size = Vector2(650, 20)
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color(0.68, 0.68, 0.73))
		instructions_panel.add_child(desc_lbl)
		cy += 26

	_add_separator(cy + 4)

	# ── Habilidades ──
	instructions_panel.add_child(_section_label("HABILIDADES", Vector2(40, cy + 12)))
	cy += 38

	var abilities = [
		["1", "FUEGO", "20 mana - Proyectil de fuego", "18 dmg", Color(1, 0.5, 0.2)],
		["2", "HIELO", "30 mana - Onda de area + stun", "12 dmg + 0.8s stun", Color(0.3, 0.6, 1)],
		["3", "ARCANO", "50 mana - Proyectil poderoso", "35 dmg + 0.6s stun", Color(0.7, 0.3, 0.9)],
	]
	for ab in abilities:
		var keycap = _create_keycap(ab[0], Vector2(55, cy), ab[4])
		instructions_panel.add_child(keycap)

		var name_lbl = Label.new()
		name_lbl.text = ab[1]
		name_lbl.position = Vector2(100, cy)
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.add_theme_color_override("font_color", ab[4])
		instructions_panel.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = ab[2]
		desc_lbl.position = Vector2(100, cy + 19)
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		instructions_panel.add_child(desc_lbl)

		var dmg_lbl = Label.new()
		dmg_lbl.text = ab[3]
		dmg_lbl.position = Vector2(100, cy + 34)
		dmg_lbl.add_theme_font_size_override("font_size", 12)
		dmg_lbl.add_theme_color_override("font_color", Color(0.75, 0.65, 0.45))
		instructions_panel.add_child(dmg_lbl)

		cy += 52

	_add_separator(cy + 2)

	# ── Mana ──
	instructions_panel.add_child(_section_label("MANA", Vector2(40, cy + 10)))
	cy += 34

	var mana_orb = ColorRect.new()
	mana_orb.position = Vector2(55, cy + 2)
	mana_orb.custom_minimum_size = Vector2(12, 12)
	mana_orb.size = Vector2(12, 12)
	mana_orb.color = Color(0.95, 0.8, 0.2)
	instructions_panel.add_child(mana_orb)
	var mana_desc = Label.new()
	mana_desc.text = "Orbes dorados  -  Recogelos para ganar +15 mana"
	mana_desc.position = Vector2(75, cy)
	mana_desc.add_theme_font_size_override("font_size", 13)
	mana_desc.add_theme_color_override("font_color", Color(0.72, 0.72, 0.78))
	instructions_panel.add_child(mana_desc)
	cy += 20

	var mana_extra = Label.new()
	mana_extra.text = "Mana se recarga sola (+3/s) y al golpear (+10). Gasta mana para usar habilidades."
	mana_extra.position = Vector2(55, cy)
	mana_extra.add_theme_font_size_override("font_size", 12)
	mana_extra.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
	instructions_panel.add_child(mana_extra)
	cy += 22

	_add_separator(cy + 2)

	# ── Tips ──
	instructions_panel.add_child(_section_label("TIPS DE COMBATE", Vector2(40, cy + 8)))
	cy += 34

	var tips = [
		"Junta orbes antes de atacar para maximizar dano.",
		"Defiende cuando el enemigo se acerque, luego contraataca.",
		"Esquivar no cuesta nada, usalo para evadir proyectiles.",
		"Arcano es el ataque mas fuerte pero necesita ambos tipos de orbes.",
	]
	for tip in tips:
		var bullet = Label.new()
		bullet.text = tip
		bullet.position = Vector2(55, cy)
		bullet.size = Vector2(800, 18)
		bullet.add_theme_font_size_override("font_size", 12)
		bullet.add_theme_color_override("font_color", Color(0.6, 0.65, 0.55))
		instructions_panel.add_child(bullet)
		cy += 17

	# ── Footer pulsante ──
	footer_label = Label.new()
	footer_label.text = ">>> Presiona ENTER para comenzar <<<"
	footer_label.position = Vector2(0, 622)
	footer_label.size = Vector2(900, 30)
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_label.add_theme_font_size_override("font_size", 16)
	footer_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.4))
	instructions_panel.add_child(footer_label)

	# Fade in
	_fade_instructions(true)
	# Pulso del footer
	_start_footer_pulse()


func _fade_instructions(show: bool) -> void:
	if not is_instance_valid(instructions_panel):
		return
	var tw = create_tween()
	if show:
		instructions_panel.modulate = Color(1, 1, 1, 0)
		tw.tween_property(instructions_panel, "modulate", Color(1, 1, 1, 1), 0.4).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_property(instructions_panel, "modulate", Color(1, 1, 1, 0), 0.25).set_ease(Tween.EASE_IN)
		tw.tween_callback(func(): instructions_panel.visible = false)


func _start_footer_pulse() -> void:
	var tw = create_tween().set_loops()
	tw.tween_property(footer_label, "modulate", Color(1, 1, 1, 0.3), 0.8).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(footer_label, "modulate", Color(1, 1, 1, 1.0), 0.8).set_ease(Tween.EASE_IN_OUT)


func _create_keycap(text: String, pos: Vector2, tint: Color = Color(0.3, 0.8, 0.9)) -> Panel:
	var w = max(34, text.length() * 12 + 18)
	var cap = Panel.new()
	cap.position = pos
	cap.size = Vector2(w, 28)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.16)
	style.border_color = Color(tint.r * 0.65, tint.g * 0.65, tint.b * 0.65, 0.75)
	style.set_border_width_all(1)
	style.border_width_bottom = 3
	style.set_corner_radius_all(5)
	cap.add_theme_stylebox_override("panel", style)

	var lbl = Label.new()
	lbl.text = text
	lbl.position = Vector2(0, 2)
	lbl.size = Vector2(w, 24)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", tint)
	cap.add_child(lbl)
	return cap


func _add_separator(y: float) -> void:
	var sep = ColorRect.new()
	sep.position = Vector2(40, y)
	sep.size = Vector2(820, 1)
	sep.color = Color(0.25, 0.28, 0.4, 0.5)
	instructions_panel.add_child(sep)


func _section_label(text: String, pos: Vector2) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	return lbl


# ── HUD ──

var round_intro_label: Label
var fight_intro_label: Label


func _create_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)

	# Flash overlay (encima de todo)
	flash_overlay = ColorRect.new()
	flash_overlay.position = Vector2.ZERO
	flash_overlay.size = Vector2(1280, 720)
	flash_overlay.color = Color(1, 1, 1, 0)
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(flash_overlay)

	# Fondo con imagen para pantallas de menu (cubre toda la pantalla)
	var menu_bg = TextureRect.new()
	menu_bg.name = "MenuBG"
	menu_bg.texture = InicioTexture
	menu_bg.position = Vector2.ZERO
	menu_bg.size = Vector2(1280, 720)
	menu_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_bg.stretch_mode = TextureRect.STRETCH_SCALE
	menu_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(menu_bg)
	# Overlay oscuro para legibilidad (sutil para que se vea la imagen)
	var menu_bg_overlay = ColorRect.new()
	menu_bg_overlay.position = Vector2.ZERO
	menu_bg_overlay.size = Vector2(1280, 720)
	menu_bg_overlay.color = Color(0.0, 0.0, 0.02, 0.25)
	menu_bg_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_bg.add_child(menu_bg_overlay)

	# Round intro labels
	round_intro_label = Label.new()
	round_intro_label.position = Vector2(0, 280)
	round_intro_label.size = Vector2(1280, 100)
	round_intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_intro_label.add_theme_font_size_override("font_size", 60)
	round_intro_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3))
	round_intro_label.visible = false
	round_intro_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(round_intro_label)

	fight_intro_label = Label.new()
	fight_intro_label.position = Vector2(0, 290)
	fight_intro_label.size = Vector2(1280, 120)
	fight_intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fight_intro_label.add_theme_font_size_override("font_size", 80)
	fight_intro_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	fight_intro_label.visible = false
	fight_intro_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(fight_intro_label)

	# ── Timer (center top) ──
	var timer_bg = Panel.new()
	timer_bg.position = Vector2(565, 2)
	timer_bg.size = Vector2(150, 62)
	var tbs = StyleBoxFlat.new()
	tbs.bg_color = Color(0.03, 0.03, 0.08, 0.8)
	tbs.border_color = Color(0.45, 0.45, 0.65, 0.5)
	tbs.set_border_width_all(1)
	tbs.set_corner_radius_all(8)
	tbs.corner_radius_top_left = 0
	tbs.corner_radius_top_right = 0
	timer_bg.add_theme_stylebox_override("panel", tbs)
	timer_bg.name = "TimerBG"
	timer_bg.visible = false
	hud.add_child(timer_bg)

	timer_label = Label.new()
	timer_label.position = Vector2(0, 4)
	timer_label.size = Vector2(150, 28)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 26)
	timer_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	timer_label.text = "1:30"
	timer_bg.add_child(timer_label)

	round_label = Label.new()
	round_label.text = "Ronda 1"
	round_label.position = Vector2(0, 30)
	round_label.size = Vector2(150, 16)
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_label.add_theme_font_size_override("font_size", 11)
	round_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	timer_bg.add_child(round_label)

	p1_wins_label = Label.new()
	p1_wins_label.text = "J1: --"
	p1_wins_label.position = Vector2(5, 46)
	p1_wins_label.size = Vector2(70, 14)
	p1_wins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1_wins_label.add_theme_font_size_override("font_size", 10)
	p1_wins_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.9, 0.7))
	timer_bg.add_child(p1_wins_label)

	p2_wins_label = Label.new()
	p2_wins_label.text = "J2: --"
	p2_wins_label.position = Vector2(75, 46)
	p2_wins_label.size = Vector2(70, 14)
	p2_wins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_wins_label.add_theme_font_size_override("font_size", 10)
	p2_wins_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.6, 0.7))
	timer_bg.add_child(p2_wins_label)

	# Round transition banner
	var banner_bg = Panel.new()
	banner_bg.name = "BannerBG"
	banner_bg.position = Vector2(340, 310)
	banner_bg.size = Vector2(600, 70)
	banner_bg.visible = false
	var bbs = StyleBoxFlat.new()
	bbs.bg_color = Color(0.03, 0.03, 0.08, 0.85)
	bbs.border_color = Color(0.4, 0.45, 0.7, 0.6)
	bbs.set_border_width_all(1)
	bbs.set_corner_radius_all(10)
	banner_bg.add_theme_stylebox_override("panel", bbs)
	hud.add_child(banner_bg)

	round_banner = Label.new()
	round_banner.position = Vector2(0, 15)
	round_banner.size = Vector2(600, 40)
	round_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_banner.add_theme_font_size_override("font_size", 30)
	round_banner.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
	banner_bg.add_child(round_banner)

	# ── P1 Portrait Panel (left) ──
	p1_portrait_panel = _create_portrait_panel(Vector2(6, 4), Color(0.2, 0.8, 0.9), true)
	hud.add_child(p1_portrait_panel)

	p1_portrait_icon = _create_portrait_icon(Vector2(6, 6), Color(0.2, 0.8, 0.9))
	p1_portrait_panel.add_child(p1_portrait_icon)
	p1_portrait_initial = p1_portrait_icon.get_child(0)

	p1_name_label = Label.new()
	p1_name_label.text = "JUGADOR 1"
	p1_name_label.position = Vector2(52, 4)
	p1_name_label.size = Vector2(210, 22)
	p1_name_label.add_theme_font_size_override("font_size", 16)
	p1_name_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.9))
	p1_portrait_panel.add_child(p1_name_label)

	p1_hp_bar = _create_hp_bar(Vector2(52, 26), Color(0.2, 0.8, 0.9))
	p1_portrait_panel.add_child(p1_hp_bar)

	p1_hp_text = Label.new()
	p1_hp_text.text = "100"
	p1_hp_text.position = Vector2(248, 24)
	p1_hp_text.size = Vector2(44, 20)
	p1_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	p1_hp_text.add_theme_font_size_override("font_size", 14)
	p1_hp_text.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	p1_portrait_panel.add_child(p1_hp_text)

	p1_mana_bar = _create_mana_bar(Vector2(52, 50), Color(0.3, 0.5, 1.0))
	p1_portrait_panel.add_child(p1_mana_bar)

	# ── P2 Portrait Panel (right) ──
	p2_portrait_panel = _create_portrait_panel(Vector2(974, 4), Color(0.9, 0.3, 0.6), false)
	hud.add_child(p2_portrait_panel)

	p2_portrait_icon = _create_portrait_icon(Vector2(242, 6), Color(0.9, 0.3, 0.6))
	p2_portrait_panel.add_child(p2_portrait_icon)
	p2_portrait_initial = p2_portrait_icon.get_child(0)

	p2_name_label = Label.new()
	p2_name_label.text = "IA"
	p2_name_label.position = Vector2(36, 4)
	p2_name_label.size = Vector2(200, 22)
	p2_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	p2_name_label.add_theme_font_size_override("font_size", 16)
	p2_name_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.6))
	p2_portrait_panel.add_child(p2_name_label)

	p2_hp_bar = _create_hp_bar(Vector2(16, 26), Color(0.9, 0.3, 0.6))
	p2_portrait_panel.add_child(p2_hp_bar)

	p2_hp_text = Label.new()
	p2_hp_text.text = "100"
	p2_hp_text.position = Vector2(212, 24)
	p2_hp_text.size = Vector2(44, 20)
	p2_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	p2_hp_text.add_theme_font_size_override("font_size", 14)
	p2_hp_text.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	p2_portrait_panel.add_child(p2_hp_text)

	p2_mana_bar = _create_mana_bar(Vector2(16, 50), Color(0.3, 0.5, 1.0))
	p2_portrait_panel.add_child(p2_mana_bar)

	# Ocultar paneles hasta que inicie el combate
	p1_portrait_panel.visible = false
	p2_portrait_panel.visible = false

	# Ability bar with background
	var ability_bg = Panel.new()
	ability_bg.position = Vector2(270, 648)
	ability_bg.size = Vector2(740, 46)
	var abs_style = StyleBoxFlat.new()
	abs_style.bg_color = Color(0.03, 0.03, 0.08, 0.78)
	abs_style.set_corner_radius_all(8)
	ability_bg.add_theme_stylebox_override("panel", abs_style)
	ability_bg.name = "AbilityBar"
	ability_bg.visible = false
	hud.add_child(ability_bg)

	p1_ability_fire = _create_ability_slot(ability_bg, Vector2(10, 4), "[1] FUEGO", Color(1, 0.5, 0.2))
	p1_ability_ice = _create_ability_slot(ability_bg, Vector2(255, 4), "[2] HIELO", Color(0.3, 0.6, 1))
	p1_ability_special = _create_ability_slot(ability_bg, Vector2(500, 4), "[3] ARCANO", Color(0.7, 0.3, 0.9))

	# Controls hint
	var hint = Label.new()
	hint.text = "E: Golpe | 1/2/3: Magia | Q: Defender | W: Esquivar | TAB: Info"
	hint.position = Vector2(360, 694)
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.7))
	hint.name = "ControlsHint"
	hint.visible = false
	hud.add_child(hint)

	# Game Over - Epic panel
	game_over_panel = Panel.new()
	game_over_panel.position = Vector2(340, 185)
	game_over_panel.size = Vector2(600, 340)
	game_over_panel.visible = false
	var gps = StyleBoxFlat.new()
	gps.bg_color = Color(0.1, 0.07, 0.09, 0.96)
	gps.border_color = Color(0.76, 0.58, 0.3, 0.9)
	gps.set_border_width_all(3)
	gps.set_corner_radius_all(6)
	gps.shadow_color = Color(0.4, 0.25, 0.05, 0.35)
	gps.shadow_size = 18
	game_over_panel.add_theme_stylebox_override("panel", gps)
	hud.add_child(game_over_panel)

	# Small logo in game over
	var go_logo = TextureRect.new()
	go_logo.texture = LogoTexture
	var go_logo_w = 160.0
	var go_logo_h = go_logo_w * (float(LogoTexture.get_height()) / float(LogoTexture.get_width()))
	go_logo.position = Vector2((600 - go_logo_w) / 2, 10)
	go_logo.size = Vector2(go_logo_w, go_logo_h)
	go_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	go_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	game_over_panel.add_child(go_logo)

	var go_title = Label.new()
	go_title.text = "PARTIDA TERMINADA"
	go_title.position = Vector2(0, 75)
	go_title.size = Vector2(600, 30)
	go_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_title.add_theme_font_size_override("font_size", 16)
	go_title.add_theme_color_override("font_color", Color(0.76, 0.58, 0.3))
	game_over_panel.add_child(go_title)

	game_over_label = Label.new()
	game_over_label.position = Vector2(0, 120)
	game_over_label.size = Vector2(600, 60)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.add_theme_font_size_override("font_size", 36)
	game_over_label.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	game_over_panel.add_child(game_over_label)

	# Separator in game over
	var go_sep = ColorRect.new()
	go_sep.position = Vector2(80, 200)
	go_sep.size = Vector2(440, 1)
	go_sep.color = Color(0.76, 0.58, 0.3, 0.3)
	game_over_panel.add_child(go_sep)

	var restart_hint = Label.new()
	restart_hint.text = "Presiona ENTER para volver al menu"
	restart_hint.position = Vector2(0, 225)
	restart_hint.size = Vector2(600, 30)
	restart_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart_hint.add_theme_font_size_override("font_size", 16)
	restart_hint.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
	game_over_panel.add_child(restart_hint)
	# Pulse
	var rtw = create_tween().set_loops()
	rtw.tween_property(restart_hint, "modulate", Color(1, 1, 1, 0.4), 0.9)
	rtw.tween_property(restart_hint, "modulate", Color(1, 1, 1, 1.0), 0.9)

	var score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.position = Vector2(0, 265)
	score_label.size = Vector2(600, 20)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 13)
	score_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	game_over_panel.add_child(score_label)

	# Pause panel
	_create_pause_panel()

	# Mover overlays al frente del HUD
	hud.move_child(round_intro_label, -1)
	hud.move_child(fight_intro_label, -1)
	hud.move_child(flash_overlay, -1)


func _create_pause_panel() -> void:
	pause_panel = Panel.new()
	pause_panel.position = Vector2(440, 220)
	pause_panel.size = Vector2(400, 280)
	pause_panel.visible = false
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.02, 0.02, 0.06, 0.95)
	ps.border_color = Color(0.85, 0.65, 0.2, 0.8)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(12)
	pause_panel.add_theme_stylebox_override("panel", ps)
	hud.add_child(pause_panel)

	var title = Label.new()
	title.text = "PAUSA"
	title.position = Vector2(0, 30)
	title.size = Vector2(400, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	pause_panel.add_child(title)

	var opt_reanudar = Label.new()
	opt_reanudar.name = "OptReanudar"
	opt_reanudar.text = "Reanudar"
	opt_reanudar.position = Vector2(0, 110)
	opt_reanudar.size = Vector2(400, 36)
	opt_reanudar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opt_reanudar.add_theme_font_size_override("font_size", 24)
	pause_panel.add_child(opt_reanudar)

	var opt_menu = Label.new()
	opt_menu.name = "OptMenu"
	opt_menu.text = "Menu Principal"
	opt_menu.position = Vector2(0, 160)
	opt_menu.size = Vector2(400, 36)
	opt_menu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opt_menu.add_theme_font_size_override("font_size", 24)
	pause_panel.add_child(opt_menu)

	var hint = Label.new()
	hint.text = "Flechas: Navegar | ENTER: Confirmar | ESC: Reanudar"
	hint.position = Vector2(0, 235)
	hint.size = Vector2(400, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	pause_panel.add_child(hint)


func _toggle_pause() -> void:
	pause_active = not pause_active
	pause_panel.visible = pause_active
	if pause_active:
		pause_cursor = 0
		_update_pause_highlight()
		if is_instance_valid(player1):
			player1.set_process(false)
			player1.set_physics_process(false)
		if is_instance_valid(player2):
			player2.set_process(false)
			player2.set_physics_process(false)
	else:
		if is_instance_valid(player1):
			player1.set_process(true)
			player1.set_physics_process(true)
		if is_instance_valid(player2):
			player2.set_process(true)
			player2.set_physics_process(true)


func _update_pause_highlight() -> void:
	var opt_r = pause_panel.get_node("OptReanudar")
	var opt_m = pause_panel.get_node("OptMenu")
	if pause_cursor == 0:
		opt_r.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		opt_m.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	else:
		opt_r.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		opt_m.add_theme_color_override("font_color", Color(1, 0.85, 0.3))


func _process_pause() -> void:
	if Input.is_action_just_pressed("p1_move_up") or Input.is_action_just_pressed("p1_move_down"):
		pause_cursor = 1 - pause_cursor
		_update_pause_highlight()
		AudioManager.play_sfx("select")
	elif Input.is_action_just_pressed("ui_escape"):
		_toggle_pause()
	elif Input.is_action_just_pressed("ui_confirm"):
		if pause_cursor == 0:
			_toggle_pause()
		else:
			pause_active = false
			pause_panel.visible = false
			get_tree().reload_current_scene()


func _create_ability_slot(parent: Panel, pos: Vector2, text: String, accent: Color) -> Label:
	# Fondo individual por habilidad
	var bg = Panel.new()
	bg.position = pos
	bg.size = Vector2(228, 38)
	var s = StyleBoxFlat.new()
	s.bg_color = Color(accent.r * 0.1, accent.g * 0.1, accent.b * 0.1, 0.6)
	s.border_color = Color(accent.r * 0.3, accent.g * 0.3, accent.b * 0.3, 0.4)
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	bg.add_theme_stylebox_override("panel", s)
	parent.add_child(bg)
	# Label
	var lbl = Label.new()
	lbl.text = text
	lbl.position = Vector2(0, 2)
	lbl.size = Vector2(228, 34)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.add_theme_color_override("font_color", accent.darkened(0.5))
	bg.add_child(lbl)
	return lbl


func _create_hp_bar(pos: Vector2, accent: Color = Color.WHITE) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.position = pos
	bar.size = Vector2(190, 20)
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.15, 0.7, 0.3)
	fill.set_corner_radius_all(4)
	fill.shadow_color = Color(0.1, 0.5, 0.2, 0.3)
	fill.shadow_size = 2
	bar.add_theme_stylebox_override("fill", fill)
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.12)
	bg.set_corner_radius_all(4)
	bg.border_color = Color(accent.r * 0.4, accent.g * 0.4, accent.b * 0.4, 0.5)
	bg.set_border_width_all(1)
	bar.add_theme_stylebox_override("background", bg)
	return bar


func _update_wins_display() -> void:
	var rtw = _rounds_to_win()
	var p1_dots = ""
	var p2_dots = ""
	for i in rtw:
		p1_dots += "O " if i < p1_wins else "- "
		p2_dots += "O " if i < p2_wins else "- "
	p1_wins_label.text = "J1: " + p1_dots.strip_edges()
	var p2_prefix = "IA" if game_mode == 1 else "J2"
	p2_wins_label.text = p2_prefix + ": " + p2_dots.strip_edges()


func _update_ability_hud() -> void:
	if not is_instance_valid(player1):
		return
	var pm = player1.mana
	_update_slot(p1_ability_fire, "[1] FUEGO", pm, player1.COST_FIRE, player1.cd_fire, Color(1, 0.5, 0.2))
	_update_slot(p1_ability_ice, "[2] HIELO", pm, player1.COST_ICE, player1.cd_ice, Color(0.3, 0.6, 1))
	_update_slot(p1_ability_special, "[3] ARCANO", pm, player1.COST_ARCANE, player1.cd_special, Color(0.7, 0.3, 0.9))


func _update_slot(lbl: Label, name: String, mana: float, cost: float, cd: float, color: Color) -> void:
	var bg = lbl.get_parent() as Panel
	var style = bg.get_theme_stylebox("panel") as StyleBoxFlat
	if cd > 0:
		# En cooldown - gris con timer
		lbl.text = "%s  %.1fs" % [name, cd]
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		style.bg_color = Color(0.05, 0.05, 0.08, 0.6)
		style.border_color = Color(0.15, 0.15, 0.2, 0.4)
	elif mana >= cost:
		# LISTA - brilla con color fuerte
		lbl.text = "%s  LISTA" % name
		var pulse = abs(sin(Time.get_ticks_msec() * 0.005)) * 0.3
		lbl.add_theme_color_override("font_color", color.lightened(0.2 + pulse))
		style.bg_color = Color(color.r * 0.15, color.g * 0.15, color.b * 0.15, 0.85 + pulse * 0.15)
		style.border_color = Color(color.r * 0.8, color.g * 0.8, color.b * 0.8, 0.7 + pulse)
		style.set_border_width_all(2 + int(pulse * 2))
	else:
		# Sin mana suficiente - apagada con cuanto falta
		var need = int(cost - mana)
		lbl.text = "%s  -%d" % [name, need]
		lbl.add_theme_color_override("font_color", color.darkened(0.6))
		style.bg_color = Color(color.r * 0.05, color.g * 0.05, color.b * 0.05, 0.5)
		style.border_color = Color(color.r * 0.15, color.g * 0.15, color.b * 0.15, 0.3)
		style.set_border_width_all(1)


func _update_hp_bar(bar: ProgressBar, new_hp: int) -> void:
	bar.value = new_hp
	var style = bar.get_theme_stylebox("fill") as StyleBoxFlat
	var ratio = float(new_hp) / 100.0
	if ratio > 0.5:
		style.bg_color = Color(0.15, 0.7, 0.3)
		style.shadow_color = Color(0.1, 0.5, 0.2, 0.3)
	elif ratio > 0.25:
		style.bg_color = Color(0.85, 0.7, 0.1)
		style.shadow_color = Color(0.6, 0.5, 0.05, 0.3)
	else:
		style.bg_color = Color(0.85, 0.2, 0.1)
		style.shadow_color = Color(0.6, 0.1, 0.05, 0.3)


func _create_mana_bar(pos: Vector2, accent: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.position = pos
	bar.size = Vector2(190, 10)
	bar.max_value = 100
	bar.value = 0
	bar.show_percentage = false
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.2, 0.4, 0.95)
	fill.set_corner_radius_all(3)
	fill.shadow_color = Color(0.15, 0.3, 0.7, 0.3)
	fill.shadow_size = 2
	bar.add_theme_stylebox_override("fill", fill)
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.06, 0.12)
	bg.set_corner_radius_all(3)
	bg.border_color = Color(accent.r * 0.3, accent.g * 0.3, accent.b * 0.3, 0.4)
	bg.set_border_width_all(1)
	bar.add_theme_stylebox_override("background", bg)
	return bar


func _create_portrait_panel(pos: Vector2, accent: Color, is_left: bool) -> Panel:
	var panel = Panel.new()
	panel.position = pos
	panel.size = Vector2(300, 66)
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.03, 0.03, 0.08, 0.85)
	ps.border_color = Color(accent.r * 0.5, accent.g * 0.5, accent.b * 0.5, 0.6)
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(8)
	ps.corner_radius_top_left = 0 if is_left else 8
	ps.corner_radius_top_right = 8 if is_left else 0
	# Accent side border
	if is_left:
		ps.border_width_left = 3
		ps.border_color = accent.darkened(0.2)
	else:
		ps.border_width_right = 3
		ps.border_color = accent.darkened(0.2)
	ps.shadow_color = Color(accent.r * 0.15, accent.g * 0.15, accent.b * 0.15, 0.3)
	ps.shadow_size = 6
	panel.add_theme_stylebox_override("panel", ps)
	return panel


func _create_portrait_icon(pos: Vector2, accent: Color) -> Panel:
	var icon = Panel.new()
	icon.position = pos
	icon.size = Vector2(40, 40)
	var is2 = StyleBoxFlat.new()
	is2.bg_color = Color(accent.r * 0.2, accent.g * 0.2, accent.b * 0.2, 0.9)
	is2.border_color = accent.darkened(0.1)
	is2.set_border_width_all(2)
	is2.set_corner_radius_all(20)
	icon.add_theme_stylebox_override("panel", is2)
	# Initial letter
	var lbl = Label.new()
	lbl.text = "?"
	lbl.position = Vector2(0, 5)
	lbl.size = Vector2(40, 30)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", accent)
	icon.add_child(lbl)
	return icon


func _setup_mini_portrait(icon_panel: Panel, char_idx: int, color: Color, is_p1: bool) -> void:
	# Limpiar retrato anterior si existe
	if is_p1 and is_instance_valid(p1_hud_portrait):
		p1_hud_portrait.get_parent().get_parent().queue_free()
	elif not is_p1 and is_instance_valid(p2_hud_portrait):
		p2_hud_portrait.get_parent().get_parent().queue_free()

	# Ocultar letra inicial
	var lbl = icon_panel.get_child(0) as Label
	lbl.visible = false

	# SubViewportContainer dentro del icono
	var svc = SubViewportContainer.new()
	svc.position = Vector2(0, 0)
	svc.size = Vector2(40, 40)
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sv = SubViewport.new()
	sv.size = Vector2i(160, 160)
	sv.transparent_bg = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(sv)

	var portrait = PortraitScene.instantiate()
	portrait.character_type = char_idx
	portrait.char_color = color
	portrait.is_selected = false
	# Zoom a la cara para que el retrato se identifique bien en el HUD
	portrait.position = Vector2(80, 136)
	portrait.scale = Vector2(1.5, 1.5)
	sv.add_child(portrait)

	icon_panel.add_child(svc)

	if is_p1:
		p1_hud_portrait = portrait
	else:
		p2_hud_portrait = portrait


func _setup_player_hud() -> void:
	if not is_instance_valid(player1) or not is_instance_valid(player2):
		return

	var p1_color = player1.CHAR_COLORS[p1_char_idx]
	var p2_color = player2.CHAR_COLORS[p2_char_idx]
	var p1_cname = player1.CHAR_NAMES[p1_char_idx]
	var p2_cname = player2.CHAR_NAMES[p2_char_idx]

	# Mostrar paneles de retrato
	p1_portrait_panel.visible = true
	p2_portrait_panel.visible = true

	# Update P1 portrait
	p1_name_label.text = p1_cname.to_upper()
	p1_name_label.add_theme_color_override("font_color", p1_color)
	p1_portrait_initial.text = p1_cname[0]
	p1_portrait_initial.add_theme_color_override("font_color", p1_color)
	var p1_icon_style = p1_portrait_icon.get_theme_stylebox("panel") as StyleBoxFlat
	p1_icon_style.border_color = p1_color.darkened(0.1)
	p1_icon_style.bg_color = Color(p1_color.r * 0.2, p1_color.g * 0.2, p1_color.b * 0.2, 0.9)
	var p1_panel_style = p1_portrait_panel.get_theme_stylebox("panel") as StyleBoxFlat
	p1_panel_style.border_color = p1_color.darkened(0.2)
	p1_panel_style.shadow_color = Color(p1_color.r * 0.15, p1_color.g * 0.15, p1_color.b * 0.15, 0.3)

	# Update P1 HP bar accent
	var p1_bg = p1_hp_bar.get_theme_stylebox("background") as StyleBoxFlat
	p1_bg.border_color = Color(p1_color.r * 0.4, p1_color.g * 0.4, p1_color.b * 0.4, 0.5)

	# Mini retrato P1
	_setup_mini_portrait(p1_portrait_icon, p1_char_idx, p1_color, true)

	# Update P2 portrait
	var p2_prefix = "IA" if game_mode == 1 else "J2"
	p2_name_label.text = p2_cname.to_upper()
	p2_name_label.add_theme_color_override("font_color", p2_color)
	p2_portrait_initial.text = p2_cname[0]
	p2_portrait_initial.add_theme_color_override("font_color", p2_color)
	var p2_icon_style = p2_portrait_icon.get_theme_stylebox("panel") as StyleBoxFlat
	p2_icon_style.border_color = p2_color.darkened(0.1)
	p2_icon_style.bg_color = Color(p2_color.r * 0.2, p2_color.g * 0.2, p2_color.b * 0.2, 0.9)
	var p2_panel_style = p2_portrait_panel.get_theme_stylebox("panel") as StyleBoxFlat
	p2_panel_style.border_color = p2_color.darkened(0.2)
	p2_panel_style.shadow_color = Color(p2_color.r * 0.15, p2_color.g * 0.15, p2_color.b * 0.15, 0.3)

	# Update P2 HP bar accent
	var p2_bg = p2_hp_bar.get_theme_stylebox("background") as StyleBoxFlat
	p2_bg.border_color = Color(p2_color.r * 0.4, p2_color.g * 0.4, p2_color.b * 0.4, 0.5)

	# Mini retrato P2
	_setup_mini_portrait(p2_portrait_icon, p2_char_idx, p2_color, false)


func _on_p1_hp(new_hp: int, _max: int) -> void:
	_update_hp_bar(p1_hp_bar, new_hp)
	p1_hp_text.text = str(new_hp)

func _on_p2_hp(new_hp: int, _max: int) -> void:
	_update_hp_bar(p2_hp_bar, new_hp)
	p2_hp_text.text = str(new_hp)

func _on_p1_mana(current: float, max_val: float) -> void:
	p1_mana_bar.value = current

func _on_p2_mana(current: float, max_val: float) -> void:
	p2_mana_bar.value = current


# ══════════════════════════════════════════════════════
# CHARACTER SELECT
# ══════════════════════════════════════════════════════

func _hide_collision_shapes(node: Node) -> void:
	for child in node.get_children():
		if child is CollisionShape2D:
			child.visible = false
		if child is Area2D:
			for sub in child.get_children():
				if sub is CollisionShape2D:
					sub.visible = false


func _start_char_select() -> void:
	char_select_active = true
	char_select_phase = 0
	confirm_anim_timer = 0.0
	p1_confirmed = false
	p2_confirmed = false
	ai_search_active = false
	p1_char_idx = 0
	p2_char_idx = 1
	# Ocultar fondo opaco y logo para que se vean los previews y efectos
	var mbg = hud.get_node_or_null("MenuBG")
	if mbg: mbg.visible = false
	var ml = hud.get_node_or_null("MenuLogo")
	if ml: ml.visible = false

	# Preview P1 (grande, estilo gameplay escalado)
	preview_p1 = PlayerScene.instantiate()
	preview_p1.player_id = 1
	preview_p1.is_ai = false
	preview_p1.input_prefix = "preview1_"
	preview_p1.character_type = p1_char_idx
	preview_p1.player_color = preview_p1.CHAR_COLORS[p1_char_idx]
	preview_p1.position = Vector2(640, 320) if game_mode == 3 else Vector2(330, 320)
	preview_p1.facing = Vector2.RIGHT
	preview_p1.scale = Vector2(6.0, 6.0)
	preview_p1.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview_p1.is_preview = true
	add_child(preview_p1)
	_hide_collision_shapes(preview_p1)

	# Preview P2 (solo si no es story)
	if game_mode != 3:
		preview_p2 = PlayerScene.instantiate()
		preview_p2.player_id = 2
		preview_p2.is_ai = false
		preview_p2.input_prefix = "preview2_"
		preview_p2.character_type = p2_char_idx
		preview_p2.player_color = preview_p2.CHAR_COLORS[p2_char_idx]
		preview_p2.position = Vector2(950, 320)
		preview_p2.facing = Vector2.LEFT
		preview_p2.scale = Vector2(6.0, 6.0)
		preview_p2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		preview_p2.is_preview = true
		add_child(preview_p2)
		_hide_collision_shapes(preview_p2)

	_create_char_select_panel()


func _create_char_select_panel() -> void:
	char_select_panel = Panel.new()
	char_select_panel.position = Vector2(0, 0)
	char_select_panel.size = Vector2(1280, 720)
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0, 0, 0, 0)
	char_select_panel.add_theme_stylebox_override("panel", ps)
	hud.add_child(char_select_panel)

	# Titulo
	var title = Label.new()
	title.text = "ELIGE TU GUERRERO" if game_mode == 3 else "ELIGE TU PERSONAJE"
	title.position = Vector2(0, 18)
	title.size = Vector2(1280, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	char_select_panel.add_child(title)

	# VS label en el centro (solo si no es story)
	if game_mode != 3:
		var vs = Label.new()
		vs.text = "VS"
		vs.position = Vector2(590, 280)
		vs.size = Vector2(100, 50)
		vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vs.add_theme_font_size_override("font_size", 40)
		vs.add_theme_color_override("font_color", Color(0.85, 0.65, 0.2, 0.6))
		char_select_panel.add_child(vs)

	# P1 header
	var p1h = Label.new()
	p1h.text = "JUGADOR 1"
	if game_mode == 3:
		p1h.position = Vector2(490, 75)
		p1h.size = Vector2(300, 30)
	else:
		p1h.position = Vector2(220, 75)
		p1h.size = Vector2(200, 30)
	p1h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1h.add_theme_font_size_override("font_size", 18)
	p1h.add_theme_color_override("font_color", Color(0.2, 0.8, 0.9))
	char_select_panel.add_child(p1h)

	# P2 header (no en story)
	if game_mode != 3:
		var p2h = Label.new()
		p2h.text = "IA" if game_mode == 1 else "JUGADOR 2"
		p2h.position = Vector2(860, 75)
		p2h.size = Vector2(200, 30)
		p2h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p2h.add_theme_font_size_override("font_size", 18)
		p2h.add_theme_color_override("font_color", Color(0.9, 0.3, 0.6))
		char_select_panel.add_child(p2h)

	# P1 character name (grande)
	p1_char_name_label = Label.new()
	if game_mode == 3:
		p1_char_name_label.position = Vector2(440, 510)
		p1_char_name_label.size = Vector2(400, 40)
	else:
		p1_char_name_label.position = Vector2(200, 510)
		p1_char_name_label.size = Vector2(240, 40)
	p1_char_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1_char_name_label.add_theme_font_size_override("font_size", 26)
	char_select_panel.add_child(p1_char_name_label)

	# P1 character desc
	p1_char_desc_label = Label.new()
	if game_mode == 3:
		p1_char_desc_label.position = Vector2(440, 545)
		p1_char_desc_label.size = Vector2(400, 24)
	else:
		p1_char_desc_label.position = Vector2(170, 545)
		p1_char_desc_label.size = Vector2(300, 24)
	p1_char_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1_char_desc_label.add_theme_font_size_override("font_size", 13)
	p1_char_desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	char_select_panel.add_child(p1_char_desc_label)

	# P2 labels (no en story)
	if game_mode != 3:
		p2_char_name_label = Label.new()
		p2_char_name_label.position = Vector2(840, 510)
		p2_char_name_label.size = Vector2(240, 40)
		p2_char_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p2_char_name_label.add_theme_font_size_override("font_size", 26)
		char_select_panel.add_child(p2_char_name_label)

		p2_char_desc_label = Label.new()
		p2_char_desc_label.position = Vector2(810, 545)
		p2_char_desc_label.size = Vector2(300, 24)
		p2_char_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p2_char_desc_label.add_theme_font_size_override("font_size", 13)
		p2_char_desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		char_select_panel.add_child(p2_char_desc_label)
	else:
		p2_char_name_label = null
		p2_char_desc_label = null

	# Status labels
	p1_status_label = Label.new()
	if game_mode == 3:
		p1_status_label.position = Vector2(490, 572)
		p1_status_label.size = Vector2(300, 24)
	else:
		p1_status_label.position = Vector2(220, 572)
		p1_status_label.size = Vector2(200, 24)
	p1_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1_status_label.add_theme_font_size_override("font_size", 15)
	char_select_panel.add_child(p1_status_label)

	if game_mode != 3:
		p2_status_label = Label.new()
		p2_status_label.position = Vector2(860, 572)
		p2_status_label.size = Vector2(200, 24)
		p2_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p2_status_label.add_theme_font_size_override("font_size", 15)
		char_select_panel.add_child(p2_status_label)
	else:
		p2_status_label = null

	# Character cards at bottom
	var card_names = ["Mago", "Hechicero", "Chaman", "Nahual", "Brujo", "Sacerdote"]
	var card_colors = [
		Color(0.2, 0.8, 0.9), Color(0.9, 0.3, 0.6), Color(0.15, 0.75, 0.3),
		Color(0.95, 0.75, 0.1), Color(0.55, 0.15, 0.8), Color(1.0, 0.55, 0.1),
	]
	char_select_cards.clear()
	var total_w = 6 * 110 + 5 * 10
	var start_x = (1280 - total_w) / 2.0
	for i in 6:
		var card = Panel.new()
		card.position = Vector2(start_x + float(i) * 120, 600)
		card.size = Vector2(110, 95)
		var cs = StyleBoxFlat.new()
		cs.bg_color = Color(card_colors[i].r * 0.2, card_colors[i].g * 0.2, card_colors[i].b * 0.2, 0.9)
		cs.border_color = card_colors[i].darkened(0.3)
		cs.set_border_width_all(2)
		cs.set_corner_radius_all(6)
		card.add_theme_stylebox_override("panel", cs)
		char_select_panel.add_child(card)

		# Color circle
		var cr = ColorRect.new()
		cr.position = Vector2(43, 10)
		cr.custom_minimum_size = Vector2(24, 24)
		cr.size = Vector2(24, 24)
		cr.color = card_colors[i]
		card.add_child(cr)

		# Name
		var nl = Label.new()
		nl.text = card_names[i]
		nl.position = Vector2(0, 45)
		nl.size = Vector2(110, 26)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.add_theme_font_size_override("font_size", 15)
		nl.add_theme_color_override("font_color", card_colors[i])
		card.add_child(nl)

		char_select_cards.append(card)

	# Controls hint
	var hint = Label.new()
	hint.position = Vector2(0, 693)
	hint.size = Vector2(1280, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	if game_mode == 3:
		hint.text = "Flechas: Cambiar personaje  |  ENTER: Confirmar  |  ESC: Volver"
	elif game_mode == 2:
		hint.text = "P1: Flechas + ENTER  |  P2: J/L + SPACE  |  ESC: Volver"
	elif game_mode == 1:
		hint.text = "Flechas: Cambiar personaje  |  ENTER: Confirmar  |  IA elige automaticamente"
	else:
		hint.text = "Flechas: elegir  |  ENTER: confirmar  |  ESC: volver"
	char_select_panel.add_child(hint)

	# Cursor indicators (Smash-style)
	p1_cursor_indicator = Label.new()
	p1_cursor_indicator.text = "\u25bc"
	p1_cursor_indicator.position = Vector2(0, 575)
	p1_cursor_indicator.size = Vector2(30, 24)
	p1_cursor_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1_cursor_indicator.add_theme_font_size_override("font_size", 20)
	p1_cursor_indicator.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
	char_select_panel.add_child(p1_cursor_indicator)

	if game_mode != 3:
		p2_cursor_indicator = Label.new()
		p2_cursor_indicator.text = "\u25bc"
		p2_cursor_indicator.position = Vector2(0, 575)
		p2_cursor_indicator.size = Vector2(30, 24)
		p2_cursor_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p2_cursor_indicator.add_theme_font_size_override("font_size", 20)
		p2_cursor_indicator.add_theme_color_override("font_color", Color(0.9, 0.3, 0.6))
		char_select_panel.add_child(p2_cursor_indicator)
	else:
		p2_cursor_indicator = null

	_update_char_select_display()

	# Si es vs IA, iniciar animacion de busqueda
	if game_mode == 1:
		ai_search_target = randi() % 6
		while ai_search_target == p1_char_idx:
			ai_search_target = randi() % 6
		ai_search_active = true
		ai_search_timer = 0.0
		ai_search_elapsed = 0.0
		ai_search_speed = 0.08


func _process_char_select() -> void:
	match char_select_phase:
		0: _process_char_browse()
		1: _process_char_confirm()
		2: pass  # Esperando tween de salida


func _process_char_browse() -> void:
	# AI search animation
	if ai_search_active:
		_process_ai_search(get_process_delta_time())
	# P1 navigation
	if Input.is_action_just_pressed("p1_move_right"):
		p1_char_idx = (p1_char_idx + 1) % 6
		_update_preview_p1()
		_update_char_select_display()
		AudioManager.play_sfx("select")
	elif Input.is_action_just_pressed("p1_move_left"):
		p1_char_idx = (p1_char_idx + 5) % 6
		_update_preview_p1()
		_update_char_select_display()
		AudioManager.play_sfx("select")
	elif Input.is_action_just_pressed("ui_confirm"):
		_trigger_char_confirm()

	# P2 navigation (solo en modo 2P)
	if game_mode == 2 and not p2_confirmed:
		if Input.is_action_just_pressed("p2_move_right"):
			p2_char_idx = (p2_char_idx + 1) % 6
			_update_preview_p2()
			_update_char_select_display()
			AudioManager.play_sfx("select")
		elif Input.is_action_just_pressed("p2_move_left"):
			p2_char_idx = (p2_char_idx + 5) % 6
			_update_preview_p2()
			_update_char_select_display()
			AudioManager.play_sfx("select")
		elif Input.is_action_just_pressed("p2_attack"):
			_trigger_p2_confirm()


func _trigger_char_confirm() -> void:
	p1_confirmed = true

	# En modo IA o story, auto-confirmar P2
	if game_mode == 1:
		if ai_search_active:
			ai_search_active = false
			p2_char_idx = ai_search_target
			_update_preview_p2()
		if p2_char_idx == p1_char_idx:
			p2_char_idx = (p1_char_idx + 1) % 6
			_update_preview_p2()
		p2_confirmed = true
	elif game_mode == 3:
		p2_confirmed = true

	# En 2P, esperar a que P2 tambien confirme antes de avanzar
	if game_mode == 2 and not p2_confirmed:
		_update_char_select_display()
		AudioManager.play_sfx("confirm_power")
		return

	_start_confirm_animation()


func _trigger_p2_confirm() -> void:
	p2_confirmed = true
	# Si P1 ya confirmo, iniciar animacion
	if p1_confirmed:
		_start_confirm_animation()
	else:
		_update_char_select_display()
		AudioManager.play_sfx("confirm_power")


func _process_ai_search(delta) -> void:
	ai_search_elapsed += delta
	ai_search_timer += delta
	if ai_search_timer >= ai_search_speed:
		ai_search_timer = 0.0
		var new_idx = randi() % 6
		while new_idx == p2_char_idx:
			new_idx = randi() % 6
		p2_char_idx = new_idx
		_update_preview_p2()
		_update_char_select_display()
		AudioManager.play_sfx("select")
		ai_search_speed = minf(ai_search_speed + 0.025, 0.3)
	if ai_search_elapsed >= 1.5:
		ai_search_active = false
		p2_char_idx = ai_search_target
		p2_confirmed = true
		_update_preview_p2()
		_update_char_select_display()
		AudioManager.play_sfx("confirm_power")


func _start_confirm_animation() -> void:
	char_select_phase = 1
	confirm_anim_timer = 0.0

	# Escalar preview P1 como pose de poder
	if is_instance_valid(preview_p1):
		var tw_s = create_tween()
		tw_s.tween_property(preview_p1, "scale", Vector2(7.0, 7.0), 0.3).set_ease(Tween.EASE_OUT)
		tw_s.tween_property(preview_p1, "scale", Vector2(6.5, 6.5), 0.4).set_ease(Tween.EASE_IN_OUT)

	_update_char_select_display()

	# Efectos visuales de confirmacion
	screen_shake(6.0)
	screen_flash(Color(1, 0.9, 0.5), 0.15, 0.4)
	AudioManager.play_sfx("confirm_power")

	# Nombre escala con tween
	if is_instance_valid(p1_char_name_label):
		var tw = create_tween()
		p1_char_name_label.pivot_offset = p1_char_name_label.size / 2.0
		tw.tween_property(p1_char_name_label, "scale", Vector2(1.3, 1.3), 0.2).set_ease(Tween.EASE_OUT)
		tw.tween_property(p1_char_name_label, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_IN_OUT)


func _process_char_confirm() -> void:
	confirm_anim_timer += get_process_delta_time()
	if confirm_anim_timer >= 1.2:
		char_select_phase = 2
		if game_mode == 3:
			_finish_char_select_story()
		else:
			_finish_char_select()


func _update_preview_p1() -> void:
	if is_instance_valid(preview_p1):
		preview_p1.character_type = p1_char_idx
		preview_p1.player_color = preview_p1.CHAR_COLORS[p1_char_idx]
		preview_p1.facing = Vector2.RIGHT
		preview_p1.queue_redraw()


func _update_preview_p2() -> void:
	if is_instance_valid(preview_p2):
		preview_p2.character_type = p2_char_idx
		preview_p2.player_color = preview_p2.CHAR_COLORS[p2_char_idx]
		preview_p2.facing = Vector2.LEFT
		preview_p2.queue_redraw()


func _update_char_select_display() -> void:
	var names = ["Mago", "Hechicero", "Chaman", "Nahual", "Brujo", "Sacerdote Sol"]
	var descs = [
		"Hechicero clasico con magia estelar",
		"Maestro de las artes oscuras",
		"Guardian de espiritus ancestrales",
		"Guerrero jaguar con poder animal",
		"Invocador de almas y huesos",
		"Portador del fuego sagrado",
	]
	var colors = [
		Color(0.2, 0.8, 0.9), Color(0.9, 0.3, 0.6), Color(0.15, 0.75, 0.3),
		Color(0.95, 0.75, 0.1), Color(0.55, 0.15, 0.8), Color(1.0, 0.55, 0.1),
	]

	if is_instance_valid(p1_char_name_label):
		p1_char_name_label.text = names[p1_char_idx]
		p1_char_name_label.add_theme_color_override("font_color", colors[p1_char_idx])
	if is_instance_valid(p1_char_desc_label):
		p1_char_desc_label.text = descs[p1_char_idx]

	if is_instance_valid(p2_char_name_label):
		p2_char_name_label.text = names[p2_char_idx]
		p2_char_name_label.add_theme_color_override("font_color", colors[p2_char_idx])
	if is_instance_valid(p2_char_desc_label):
		p2_char_desc_label.text = descs[p2_char_idx]

	if is_instance_valid(p1_status_label):
		if p1_confirmed:
			p1_status_label.text = "LISTO!"
			p1_status_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		else:
			p1_status_label.text = "< Flechas >  ENTER"
			p1_status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))

	if is_instance_valid(p2_status_label):
		if p2_confirmed:
			p2_status_label.text = "LISTO!"
			p2_status_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		elif game_mode == 1:
			if ai_search_active:
				p2_status_label.text = "Buscando..."
				p2_status_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2))
			else:
				p2_status_label.text = "(IA)"
				p2_status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		else:
			p2_status_label.text = "< J/L > SPACE"
			p2_status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))

	# Highlight cards
	for i in char_select_cards.size():
		var card = char_select_cards[i] as Panel
		var style = card.get_theme_stylebox("panel") as StyleBoxFlat
		if i == p1_char_idx and not p1_confirmed:
			style.border_color = Color(0.2, 0.9, 1.0)
			style.set_border_width_all(4)
		elif i == p2_char_idx and not p2_confirmed and game_mode != 3:
			style.border_color = Color(0.9, 0.3, 0.6)
			style.set_border_width_all(4)
		elif i == p1_char_idx and p1_confirmed:
			style.border_color = Color(0.3, 0.9, 0.3)
			style.set_border_width_all(4)
		elif i == p2_char_idx and p2_confirmed and game_mode != 3:
			style.border_color = Color(0.3, 0.9, 0.3)
			style.set_border_width_all(4)
		else:
			style.border_color = colors[i].darkened(0.5)
			style.set_border_width_all(2)

	# Position cursor indicators
	if is_instance_valid(p1_cursor_indicator) and char_select_cards.size() > p1_char_idx:
		var p1_card = char_select_cards[p1_char_idx]
		p1_cursor_indicator.position = Vector2(p1_card.position.x + p1_card.size.x / 2.0 - 15, p1_card.position.y - 26)
	if is_instance_valid(p2_cursor_indicator) and game_mode != 3 and char_select_cards.size() > p2_char_idx:
		var p2_card = char_select_cards[p2_char_idx]
		p2_cursor_indicator.position = Vector2(p2_card.position.x + p2_card.size.x / 2.0 - 15, p2_card.position.y - 26)


func _cancel_char_select() -> void:
	char_select_active = false
	ai_search_active = false
	if is_instance_valid(preview_p1):
		preview_p1.queue_free()
	if is_instance_valid(preview_p2):
		preview_p2.queue_free()
	if is_instance_valid(char_select_panel):
		char_select_panel.queue_free()
	game_mode = 0
	mode_select_panel.visible = true
	mode_select_panel.modulate = Color(1, 1, 1, 1)
	# Restaurar fondo opaco y logo para menu
	var mbg = hud.get_node_or_null("MenuBG")
	if mbg: mbg.visible = true
	var ml = hud.get_node_or_null("MenuLogo")
	if ml: ml.visible = true


func _finish_char_select() -> void:
	char_select_active = false

	# Remove previews
	if is_instance_valid(preview_p1):
		preview_p1.queue_free()
	if is_instance_valid(preview_p2):
		preview_p2.queue_free()

	# Fade out char select panel
	var tw = create_tween()
	tw.tween_property(char_select_panel, "modulate", Color(1, 1, 1, 0), 0.4)
	tw.tween_callback(func():
		char_select_panel.visible = false
		char_select_panel.queue_free()
		_spawn_players()
		_connect_signals()
		_setup_player_hud()
		_init_arena_particles()
		waiting_to_start = false
		var ab = hud.get_node_or_null("AbilityBar")
		if ab: ab.visible = true
		var ch = hud.get_node_or_null("ControlsHint")
		if ch: ch.visible = true
		var tb = hud.get_node_or_null("TimerBG")
		if tb: tb.visible = true
		var mbg = hud.get_node_or_null("MenuBG")
		if mbg: mbg.visible = false
		AudioManager.set_battle_mode(true)
		_start_round_intro()
	)


func _finish_char_select_story() -> void:
	char_select_active = false
	story_player_char = p1_char_idx

	# Remove previews
	if is_instance_valid(preview_p1):
		preview_p1.queue_free()
	if is_instance_valid(preview_p2):
		preview_p2.queue_free()

	# Generar oponentes (los 5 personajes que no elegiste)
	story_opponents = []
	story_completed = []
	for i in 6:
		if i != story_player_char:
			story_opponents.append(i)
	story_opponents.shuffle()
	for i in story_opponents.size():
		story_completed.append(false)
	story_current_stage = 0
	story_cursor = 0
	_save_story_progress()

	# Fade out char select
	var tw = create_tween()
	tw.tween_property(char_select_panel, "modulate", Color(1, 1, 1, 0), 0.4)
	tw.tween_callback(func():
		char_select_panel.queue_free()
		_start_story_select()
	)


# ══════════════════════════════════════════════════════
# STORY MODE - Stage Select
# ══════════════════════════════════════════════════════

func _start_story_select() -> void:
	story_select_active = true
	# Ocultar fondo opaco y logo
	var mbg = hud.get_node_or_null("MenuBG")
	if mbg: mbg.visible = false
	var ml = hud.get_node_or_null("MenuLogo")
	if ml: ml.visible = false
	# Auto-cursor al primer stage no completado
	for i in story_completed.size():
		if not story_completed[i]:
			story_cursor = i
			break

	var char_names = ["Mago", "Hechicero", "Chaman", "Nahual", "Brujo", "Sacerdote Sol"]
	var char_colors = [
		Color(0.2, 0.8, 0.9), Color(0.9, 0.3, 0.6), Color(0.15, 0.75, 0.3),
		Color(0.95, 0.75, 0.1), Color(0.55, 0.15, 0.8), Color(1.0, 0.55, 0.1),
	]

	story_select_panel = Panel.new()
	story_select_panel.position = Vector2(0, 0)
	story_select_panel.size = Vector2(1280, 720)
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0, 0, 0, 0)
	story_select_panel.add_theme_stylebox_override("panel", ps)
	hud.add_child(story_select_panel)

	# Fondo de templo
	var temple_bg = TextureRect.new()
	temple_bg.texture = TemploTexture
	temple_bg.position = Vector2.ZERO
	temple_bg.size = Vector2(1280, 720)
	temple_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	temple_bg.stretch_mode = TextureRect.STRETCH_SCALE
	temple_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	story_select_panel.add_child(temple_bg)
	# Overlay oscuro para legibilidad
	var temple_overlay = ColorRect.new()
	temple_overlay.position = Vector2.ZERO
	temple_overlay.size = Vector2(1280, 720)
	temple_overlay.color = Color(0.02, 0.01, 0.04, 0.55)
	temple_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	story_select_panel.add_child(temple_overlay)

	# Titulo
	var title = Label.new()
	title.text = "TEMPLOS DEL PODER"
	title.position = Vector2(0, 30)
	title.size = Vector2(1280, 55)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	story_select_panel.add_child(title)

	# Subtitulo
	var sub = Label.new()
	sub.text = "Guerrero: " + char_names[story_player_char]
	sub.position = Vector2(0, 82)
	sub.size = Vector2(1280, 28)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", char_colors[story_player_char])
	story_select_panel.add_child(sub)

	# Progreso
	var completed_count = 0
	for s in story_completed:
		if s:
			completed_count += 1
	var prog = Label.new()
	prog.text = "Victorias: %d / %d" % [completed_count, story_opponents.size()]
	prog.position = Vector2(0, 110)
	prog.size = Vector2(1280, 22)
	prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prog.add_theme_font_size_override("font_size", 14)
	prog.add_theme_color_override("font_color", Color(0.65, 0.6, 0.45))
	story_select_panel.add_child(prog)

	# Temple names per character
	var temple_names = [
		"Templo Estelar",
		"Templo de Sombras",
		"Templo Ancestral",
		"Templo del Jaguar",
		"Templo de Huesos",
		"Templo del Sol",
	]
	var diff_names = ["Facil", "Normal", "Dificil"]

	# Stage cards - bigger 160x160
	var positions = _get_stage_positions()
	for i in story_opponents.size():
		var boss_idx = story_opponents[i]
		var pos = positions[i]
		var is_revealed = story_completed[i]
		var bc = char_colors[boss_idx] if is_revealed else Color(0.45, 0.42, 0.38)

		# Card panel
		var card = Panel.new()
		card.name = "StageCard" + str(i)
		card.position = pos - Vector2(85, 80)
		card.size = Vector2(170, 160)
		var cs = StyleBoxFlat.new()
		if story_completed[i]:
			cs.bg_color = Color(0.08, 0.14, 0.06, 0.92)
			cs.border_color = Color(0.45, 0.85, 0.25)
		elif i == story_cursor:
			cs.bg_color = Color(bc.r * 0.18, bc.g * 0.18, bc.b * 0.18, 0.95)
			cs.border_color = bc
		else:
			cs.bg_color = Color(0.07, 0.07, 0.1, 0.85)
			cs.border_color = Color(0.3, 0.3, 0.38)
		cs.set_border_width_all(3 if i != story_cursor else 4)
		cs.set_corner_radius_all(10)
		cs.shadow_color = Color(bc.r * 0.2, bc.g * 0.2, bc.b * 0.2, 0.25) if i == story_cursor else Color(0, 0, 0, 0.1)
		cs.shadow_size = 10 if i == story_cursor else 4
		card.add_theme_stylebox_override("panel", cs)
		story_select_panel.add_child(card)

		# Temple name at top
		var temple_lbl = Label.new()
		temple_lbl.text = temple_names[boss_idx]
		temple_lbl.position = Vector2(0, 6)
		temple_lbl.size = Vector2(170, 18)
		temple_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		temple_lbl.add_theme_font_size_override("font_size", 11)
		temple_lbl.add_theme_color_override("font_color", Color(bc.r, bc.g, bc.b, 0.65))
		card.add_child(temple_lbl)

		# Boss initial/symbol (large letter)
		var symbol = Label.new()
		symbol.text = char_names[boss_idx].substr(0, 1) if is_revealed else "?"
		symbol.position = Vector2(0, 22)
		symbol.size = Vector2(170, 48)
		symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		symbol.add_theme_font_size_override("font_size", 38)
		var sym_col = bc if not story_completed[i] else bc.darkened(0.3)
		symbol.add_theme_color_override("font_color", sym_col)
		card.add_child(symbol)

		# Boss name
		var nl = Label.new()
		nl.text = char_names[boss_idx] if is_revealed else "???"
		nl.position = Vector2(0, 74)
		nl.size = Vector2(170, 24)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.add_theme_font_size_override("font_size", 15)
		nl.add_theme_color_override("font_color", bc if not story_completed[i] else bc.darkened(0.3))
		card.add_child(nl)

		# Stage difficulty label
		var stage_diff = _get_stage_difficulty(i)
		var diff_col = [Color(0.3, 0.9, 0.3), Color(1.0, 0.8, 0.2), Color(1.0, 0.3, 0.2)][stage_diff]
		var diff_lbl = Label.new()
		diff_lbl.text = "Dif: " + diff_names[stage_diff]
		diff_lbl.position = Vector2(0, 98)
		diff_lbl.size = Vector2(170, 18)
		diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		diff_lbl.add_theme_font_size_override("font_size", 11)
		diff_lbl.add_theme_color_override("font_color", diff_col)
		card.add_child(diff_lbl)

		# Difficulty bar (visual)
		var bar_x = 40.0
		var bar_w = 90.0
		var bar_bg = ColorRect.new()
		bar_bg.position = Vector2(bar_x, 118)
		bar_bg.size = Vector2(bar_w, 6)
		bar_bg.color = Color(0.15, 0.15, 0.2, 0.6)
		card.add_child(bar_bg)
		var bar_fill = ColorRect.new()
		bar_fill.position = Vector2(bar_x, 118)
		var fill_pct = float(stage_diff + 1) / 3.0
		bar_fill.size = Vector2(bar_w * fill_pct, 6)
		bar_fill.color = diff_col
		card.add_child(bar_fill)

		# Completado check
		if story_completed[i]:
			var check = Label.new()
			check.text = "VICTORIA"
			check.position = Vector2(0, 132)
			check.size = Vector2(170, 18)
			check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			check.add_theme_font_size_override("font_size", 12)
			check.add_theme_color_override("font_color", Color(0.45, 0.9, 0.25))
			card.add_child(check)

	# Boss info label (bottom)
	var cur_boss = story_opponents[story_cursor]
	var cur_revealed = story_completed[story_cursor]

	# Temple name
	var temple_info = Label.new()
	temple_info.name = "TempleInfo"
	temple_info.text = temple_names[cur_boss]
	temple_info.position = Vector2(0, 540)
	temple_info.size = Vector2(1280, 24)
	temple_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	temple_info.add_theme_font_size_override("font_size", 15)
	temple_info.add_theme_color_override("font_color", Color(0.75, 0.6, 0.3))
	story_select_panel.add_child(temple_info)

	var boss_info = Label.new()
	boss_info.name = "BossInfo"
	boss_info.text = char_names[cur_boss] if cur_revealed else "???"
	boss_info.position = Vector2(0, 562)
	boss_info.size = Vector2(1280, 46)
	boss_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_info.add_theme_font_size_override("font_size", 34)
	boss_info.add_theme_color_override("font_color", char_colors[cur_boss] if cur_revealed else Color(0.5, 0.48, 0.42))
	story_select_panel.add_child(boss_info)

	var boss_desc_names = [
		"Hechicero clasico con magia estelar",
		"Maestro de las artes oscuras",
		"Guardian de espiritus ancestrales",
		"Guerrero jaguar con poder animal",
		"Invocador de almas y huesos",
		"Portador del fuego sagrado",
	]
	var boss_desc = Label.new()
	boss_desc.name = "BossDesc"
	boss_desc.text = boss_desc_names[cur_boss] if cur_revealed else "Un poderoso maestro te espera..."
	boss_desc.position = Vector2(0, 606)
	boss_desc.size = Vector2(1280, 24)
	boss_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_desc.add_theme_font_size_override("font_size", 15)
	boss_desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.68))
	story_select_panel.add_child(boss_desc)

	# Stage status
	var status = Label.new()
	status.name = "StageStatus"
	if story_completed[story_cursor]:
		status.text = "COMPLETADO"
		status.add_theme_color_override("font_color", Color(0.45, 0.9, 0.25))
	else:
		status.text = "ENTER: Pelear  |  Flechas: Navegar"
		status.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	status.position = Vector2(0, 640)
	status.size = Vector2(1280, 24)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 15)
	story_select_panel.add_child(status)

	# Hint
	var hint = Label.new()
	hint.text = "ESC: Volver al menu"
	hint.position = Vector2(0, 693)
	hint.size = Vector2(1280, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.38, 0.38, 0.45))
	story_select_panel.add_child(hint)


func _process_story_select() -> void:
	var moved = false
	if Input.is_action_just_pressed("p1_move_right"):
		story_cursor = (story_cursor + 1) % story_opponents.size()
		moved = true
	elif Input.is_action_just_pressed("p1_move_left"):
		story_cursor = (story_cursor + story_opponents.size() - 1) % story_opponents.size()
		moved = true
	elif Input.is_action_just_pressed("p1_move_up"):
		# Saltar a la fila de arriba si estamos abajo
		if story_cursor >= 3:
			story_cursor -= 3
		moved = true
	elif Input.is_action_just_pressed("p1_move_down"):
		# Saltar a la fila de abajo si estamos arriba
		if story_cursor < 3 and story_cursor + 3 < story_opponents.size():
			story_cursor += 3
		elif story_cursor < 3:
			story_cursor = mini(story_cursor + 2, story_opponents.size() - 1)
		moved = true

	if moved:
		AudioManager.play_sfx("select")
		_update_story_select_display()

	if Input.is_action_just_pressed("ui_confirm"):
		if not story_completed[story_cursor]:
			_finish_stage_select()
		else:
			AudioManager.play_sfx("select")


func _update_story_select_display() -> void:
	var char_names = ["Mago", "Hechicero", "Chaman", "Nahual", "Brujo", "Sacerdote Sol"]
	var char_descs = [
		"Hechicero clasico con magia estelar",
		"Maestro de las artes oscuras",
		"Guardian de espiritus ancestrales",
		"Guerrero jaguar con poder animal",
		"Invocador de almas y huesos",
		"Portador del fuego sagrado",
	]
	var char_colors = [
		Color(0.2, 0.8, 0.9), Color(0.9, 0.3, 0.6), Color(0.15, 0.75, 0.3),
		Color(0.95, 0.75, 0.1), Color(0.55, 0.15, 0.8), Color(1.0, 0.55, 0.1),
	]
	var temple_names = [
		"Templo Estelar", "Templo de Sombras", "Templo Ancestral",
		"Templo del Jaguar", "Templo de Huesos", "Templo del Sol",
	]

	if not is_instance_valid(story_select_panel):
		return

	var boss_idx = story_opponents[story_cursor]
	var cur_revealed = story_completed[story_cursor]
	var temple = story_select_panel.get_node_or_null("TempleInfo")
	if temple:
		temple.text = temple_names[boss_idx]
	var info = story_select_panel.get_node_or_null("BossInfo")
	if info:
		info.text = char_names[boss_idx] if cur_revealed else "???"
		info.add_theme_color_override("font_color", char_colors[boss_idx] if cur_revealed else Color(0.5, 0.48, 0.42))
	var desc = story_select_panel.get_node_or_null("BossDesc")
	if desc:
		desc.text = char_descs[boss_idx] if cur_revealed else "Un poderoso maestro te espera..."
	var status = story_select_panel.get_node_or_null("StageStatus")
	if status:
		if story_completed[story_cursor]:
			status.text = "COMPLETADO"
			status.add_theme_color_override("font_color", Color(0.4, 0.85, 0.2))
		else:
			status.text = "ENTER: Pelear  |  Flechas: Navegar"
			status.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))

	# Update card styles in-place (no rebuild)
	for i in story_opponents.size():
		var card = story_select_panel.get_node_or_null("StageCard" + str(i))
		if not card:
			continue
		var bc = char_colors[story_opponents[i]] if story_completed[i] else Color(0.45, 0.42, 0.38)
		var cs = StyleBoxFlat.new()
		if story_completed[i]:
			cs.bg_color = Color(0.08, 0.14, 0.06, 0.92)
			cs.border_color = Color(0.45, 0.85, 0.25)
		elif i == story_cursor:
			cs.bg_color = Color(bc.r * 0.18, bc.g * 0.18, bc.b * 0.18, 0.95)
			cs.border_color = bc
		else:
			cs.bg_color = Color(0.07, 0.07, 0.1, 0.85)
			cs.border_color = Color(0.3, 0.3, 0.38)
		cs.set_border_width_all(3 if i != story_cursor else 4)
		cs.set_corner_radius_all(10)
		cs.shadow_color = Color(bc.r * 0.2, bc.g * 0.2, bc.b * 0.2, 0.25) if i == story_cursor else Color(0, 0, 0, 0.1)
		cs.shadow_size = 10 if i == story_cursor else 4
		card.add_theme_stylebox_override("panel", cs)


func _cancel_story_select() -> void:
	story_select_active = false
	if is_instance_valid(story_select_panel):
		story_select_panel.queue_free()
	game_mode = 0
	mode_select_panel.visible = true
	mode_select_panel.modulate = Color(1, 1, 1, 1)
	# Restaurar fondo opaco y logo para menu
	var mbg = hud.get_node_or_null("MenuBG")
	if mbg: mbg.visible = true
	var ml = hud.get_node_or_null("MenuLogo")
	if ml: ml.visible = true


func _finish_stage_select() -> void:
	# Mantener story_select_active hasta que el fade termine para evitar
	# que _process caiga al check de waiting_to_start durante la transicion
	story_current_stage = story_cursor
	p2_char_idx = story_opponents[story_cursor]
	p1_char_idx = story_player_char

	AudioManager.play_sfx("confirm_power")

	var tw = create_tween()
	tw.tween_property(story_select_panel, "modulate", Color(1, 1, 1, 0), 0.4)
	tw.tween_callback(func():
		story_select_active = false
		story_select_panel.queue_free()
		_show_boss_intro()
	)


func _show_boss_intro() -> void:
	boss_intro_active = true

	var char_names = ["Mago", "Hechicero", "Chaman", "Nahual", "Brujo", "Sacerdote Sol"]
	var char_colors = [
		Color(0.2, 0.8, 0.9), Color(0.9, 0.3, 0.6), Color(0.15, 0.75, 0.3),
		Color(0.95, 0.75, 0.1), Color(0.55, 0.15, 0.8), Color(1.0, 0.55, 0.1),
	]
	var boss_phrases = [
		"Las estrellas dictan tu derrota...",
		"Las sombras devoran a los debiles...",
		"Los espiritus me protegen...",
		"El rugido del jaguar sera lo ultimo que escuches...",
		"Tus huesos seran mi ofrenda...",
		"El fuego sagrado te consumira...",
	]
	var temple_names = [
		"Templo Estelar", "Templo de Sombras", "Templo Ancestral",
		"Templo del Jaguar", "Templo de Huesos", "Templo del Sol",
	]

	var boss_idx = story_opponents[story_current_stage]
	var bc = char_colors[boss_idx]

	# Panel con fondo solido negro (sin flash al hacer fade)
	var intro_panel = Panel.new()
	intro_panel.name = "BossIntro"
	intro_panel.position = Vector2(0, 0)
	intro_panel.size = Vector2(1280, 720)
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.02, 0.01, 0.04, 1.0)
	intro_panel.add_theme_stylebox_override("panel", ps)
	hud.add_child(intro_panel)

	# Linea decorativa superior con color del boss
	var top_line = ColorRect.new()
	top_line.position = Vector2(340, 155)
	top_line.size = Vector2(600, 2)
	top_line.color = Color(bc.r, bc.g, bc.b, 0.3)
	intro_panel.add_child(top_line)

	# Temple name
	var temple_lbl = Label.new()
	temple_lbl.text = temple_names[boss_idx].to_upper()
	temple_lbl.position = Vector2(0, 170)
	temple_lbl.size = Vector2(1280, 30)
	temple_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	temple_lbl.add_theme_font_size_override("font_size", 16)
	temple_lbl.add_theme_color_override("font_color", Color(0.6, 0.5, 0.3))
	temple_lbl.modulate = Color(1, 1, 1, 0)
	intro_panel.add_child(temple_lbl)

	# Stage number
	var stage_lbl = Label.new()
	stage_lbl.text = "STAGE %d DE 5" % (story_current_stage + 1)
	stage_lbl.position = Vector2(0, 200)
	stage_lbl.size = Vector2(1280, 30)
	stage_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_lbl.add_theme_font_size_override("font_size", 14)
	stage_lbl.add_theme_color_override("font_color", Color(0.45, 0.4, 0.3))
	stage_lbl.modulate = Color(1, 1, 1, 0)
	intro_panel.add_child(stage_lbl)

	# Linea separadora
	var mid_line = ColorRect.new()
	mid_line.position = Vector2(440, 245)
	mid_line.size = Vector2(400, 1)
	mid_line.color = Color(bc.r, bc.g, bc.b, 0.2)
	intro_panel.add_child(mid_line)

	# Boss name (grande, centrado)
	var name_lbl = Label.new()
	name_lbl.text = char_names[boss_idx].to_upper()
	name_lbl.position = Vector2(0, 265)
	name_lbl.size = Vector2(1280, 60)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 46)
	name_lbl.add_theme_color_override("font_color", bc)
	name_lbl.modulate = Color(1, 1, 1, 0)
	intro_panel.add_child(name_lbl)

	# Boss phrase (italica feel)
	var phrase_lbl = Label.new()
	phrase_lbl.text = "\"" + boss_phrases[boss_idx] + "\""
	phrase_lbl.position = Vector2(0, 350)
	phrase_lbl.size = Vector2(1280, 30)
	phrase_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phrase_lbl.add_theme_font_size_override("font_size", 15)
	phrase_lbl.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45))
	phrase_lbl.modulate = Color(1, 1, 1, 0)
	intro_panel.add_child(phrase_lbl)

	# Difficulty
	var diff_names = ["Facil", "Normal", "Dificil"]
	var diff_colors = [Color(0.3, 0.8, 0.3), Color(1.0, 0.8, 0.2), Color(1.0, 0.3, 0.2)]
	var eff_diff = _get_stage_difficulty(story_current_stage)
	var diff_lbl = Label.new()
	diff_lbl.text = diff_names[eff_diff].to_upper()
	diff_lbl.position = Vector2(0, 410)
	diff_lbl.size = Vector2(1280, 24)
	diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_lbl.add_theme_font_size_override("font_size", 13)
	diff_lbl.add_theme_color_override("font_color", diff_colors[eff_diff].darkened(0.3))
	diff_lbl.modulate = Color(1, 1, 1, 0)
	intro_panel.add_child(diff_lbl)

	# Skip hint
	var skip_lbl = Label.new()
	skip_lbl.text = "ENTER"
	skip_lbl.position = Vector2(0, 520)
	skip_lbl.size = Vector2(1280, 24)
	skip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_lbl.add_theme_font_size_override("font_size", 13)
	skip_lbl.add_theme_color_override("font_color", Color(0.35, 0.45, 0.35))
	skip_lbl.modulate = Color(1, 1, 1, 0)
	intro_panel.add_child(skip_lbl)

	# Linea decorativa inferior
	var bot_line = ColorRect.new()
	bot_line.position = Vector2(340, 560)
	bot_line.size = Vector2(600, 2)
	bot_line.color = Color(bc.r, bc.g, bc.b, 0.3)
	intro_panel.add_child(bot_line)

	# Animacion secuencial de los elementos (sin flash global)
	var tw = create_tween()
	tw.tween_property(temple_lbl, "modulate", Color(1, 1, 1, 1), 0.3)
	tw.tween_property(stage_lbl, "modulate", Color(1, 1, 1, 1), 0.2)
	tw.tween_property(name_lbl, "modulate", Color(1, 1, 1, 1), 0.35).set_ease(Tween.EASE_OUT)
	tw.tween_property(phrase_lbl, "modulate", Color(1, 1, 1, 1), 0.3)
	tw.tween_property(diff_lbl, "modulate", Color(1, 1, 1, 1), 0.2)
	tw.tween_property(skip_lbl, "modulate", Color(1, 1, 1, 1), 0.2)


func _skip_boss_intro() -> void:
	if not boss_intro_active:
		return
	boss_intro_active = false

	var intro = hud.get_node_or_null("BossIntro")
	if intro:
		var tw = create_tween()
		tw.tween_property(intro, "modulate", Color(1, 1, 1, 0), 0.3)
		tw.tween_callback(func():
			intro.queue_free()
			_start_boss_battle()
		)
	else:
		_start_boss_battle()


func _start_boss_battle() -> void:
	# Progressive difficulty by stage position (ignores global setting)
	var stage_diff = _get_stage_difficulty(story_current_stage)

	_spawn_players()

	# Apply progressive difficulty to AI
	if is_instance_valid(player2) and player2.ai_controller:
		player2.ai_controller.difficulty = stage_diff
		player2.ai_controller._apply_difficulty()
		# Gradual reaction boost for mid-late stages
		if story_current_stage >= 2:
			var boost = 1.0 - float(story_current_stage - 1) * 0.05
			player2.ai_controller.reaction_min *= boost
			player2.ai_controller.reaction_max *= boost
		if story_current_stage >= 3:
			player2.ai_controller.mana_aggression = minf(player2.ai_controller.mana_aggression + 0.1, 1.0)
		if story_current_stage >= 4:
			player2.ai_controller.reaction_min *= 0.9
			player2.ai_controller.reaction_max *= 0.9
			player2.ai_controller.dodge_chance = minf(player2.ai_controller.dodge_chance + 0.1, 0.7)
			player2.ai_controller.defend_chance = minf(player2.ai_controller.defend_chance + 0.1, 0.5)

	_connect_signals()
	_setup_player_hud()
	_init_arena_particles()
	waiting_to_start = false
	var ab = hud.get_node_or_null("AbilityBar")
	if ab: ab.visible = true
	var ch = hud.get_node_or_null("ControlsHint")
	if ch: ch.visible = true
	var tb = hud.get_node_or_null("TimerBG")
	if tb: tb.visible = true
	var mbg = hud.get_node_or_null("MenuBG")
	if mbg: mbg.visible = false
	AudioManager.set_battle_mode(true)
	_start_round_intro()


func _story_match_result() -> void:
	if p1_wins >= _rounds_to_win():
		# Jugador gano - marcar stage completado
		story_completed[story_current_stage] = true
		_save_story_progress()
		AudioManager.play_sfx("stage_clear")

		# Checar si todos completados
		var all_done = true
		for s in story_completed:
			if not s:
				all_done = false
				break
		if all_done:
			_show_story_victory()
			return

		# Volver a stage select tras victoria
		_cleanup_battle()
		_start_story_select()
	else:
		# Derrota - mostrar historial
		_show_defeat_history()


# ── Defeat History ──

var defeat_panel_active = false
var defeat_name_input: LineEdit
var defeat_panel: Panel


func _show_defeat_history() -> void:
	_cleanup_battle()
	defeat_panel_active = true

	var char_names = ["Mago", "Hechicero", "Chaman", "Nahual", "Brujo", "Sacerdote Sol"]
	var char_colors = [
		Color(0.2, 0.8, 0.9), Color(0.9, 0.3, 0.6), Color(0.15, 0.75, 0.3),
		Color(0.95, 0.75, 0.1), Color(0.55, 0.15, 0.8), Color(1.0, 0.55, 0.1),
	]

	# Count completed
	var completed_count = 0
	for s in story_completed:
		if s:
			completed_count += 1

	defeat_panel = Panel.new()
	defeat_panel.name = "DefeatPanel"
	defeat_panel.position = Vector2(0, 0)
	defeat_panel.size = Vector2(1280, 720)
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.04, 0.02, 0.06, 0.97)
	ps.border_color = Color(0.6, 0.15, 0.15)
	ps.set_border_width_all(3)
	defeat_panel.add_theme_stylebox_override("panel", ps)
	defeat_panel.modulate = Color(1, 1, 1, 0)
	hud.add_child(defeat_panel)

	# Title
	var title = Label.new()
	title.text = "DERROTA"
	title.position = Vector2(0, 60)
	title.size = Vector2(1280, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.85, 0.2, 0.15))
	defeat_panel.add_child(title)

	# Character info
	var pc = char_colors[story_player_char]
	var char_lbl = Label.new()
	char_lbl.text = "Guerrero: " + char_names[story_player_char]
	char_lbl.position = Vector2(0, 130)
	char_lbl.size = Vector2(1280, 30)
	char_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	char_lbl.add_theme_font_size_override("font_size", 20)
	char_lbl.add_theme_color_override("font_color", pc)
	defeat_panel.add_child(char_lbl)

	# Progress
	var prog = Label.new()
	prog.text = "Templos conquistados: %d / %d" % [completed_count, story_opponents.size()]
	prog.position = Vector2(0, 168)
	prog.size = Vector2(1280, 26)
	prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prog.add_theme_font_size_override("font_size", 16)
	prog.add_theme_color_override("font_color", Color(0.75, 0.65, 0.4))
	defeat_panel.add_child(prog)

	# Defeated by
	var killer_idx = story_opponents[story_current_stage]
	var killed_lbl = Label.new()
	killed_lbl.text = "Caiste ante: " + char_names[killer_idx]
	killed_lbl.position = Vector2(0, 200)
	killed_lbl.size = Vector2(1280, 26)
	killed_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	killed_lbl.add_theme_font_size_override("font_size", 16)
	killed_lbl.add_theme_color_override("font_color", char_colors[killer_idx])
	defeat_panel.add_child(killed_lbl)

	# History section
	var hist_title = Label.new()
	hist_title.text = "── HISTORIAL DE AVANCE ──"
	hist_title.position = Vector2(0, 248)
	hist_title.size = Vector2(1280, 24)
	hist_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hist_title.add_theme_font_size_override("font_size", 14)
	hist_title.add_theme_color_override("font_color", Color(0.65, 0.55, 0.35))
	defeat_panel.add_child(hist_title)

	var hy = 280.0
	for i in story_opponents.size():
		var boss_idx = story_opponents[i]
		var bc = char_colors[boss_idx]
		var entry = Label.new()
		if story_completed[i]:
			entry.text = "Stage %d: %s - VICTORIA" % [i + 1, char_names[boss_idx]]
			entry.add_theme_color_override("font_color", Color(0.4, 0.85, 0.25))
		elif i == story_current_stage:
			entry.text = "Stage %d: %s - DERROTA" % [i + 1, char_names[boss_idx]]
			entry.add_theme_color_override("font_color", Color(0.85, 0.25, 0.2))
		else:
			entry.text = "Stage %d: %s - Pendiente" % [i + 1, char_names[boss_idx]]
			entry.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
		entry.position = Vector2(0, hy)
		entry.size = Vector2(1280, 22)
		entry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		entry.add_theme_font_size_override("font_size", 14)
		defeat_panel.add_child(entry)
		hy += 26.0

	# Separator
	var sep = ColorRect.new()
	sep.position = Vector2(340, hy + 10)
	sep.size = Vector2(600, 1)
	sep.color = Color(0.6, 0.45, 0.15, 0.5)
	defeat_panel.add_child(sep)

	# Name input
	var sign_label = Label.new()
	sign_label.text = "Firma tu nombre, guerrero:"
	sign_label.position = Vector2(0, hy + 30)
	sign_label.size = Vector2(1280, 24)
	sign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign_label.add_theme_font_size_override("font_size", 16)
	sign_label.add_theme_color_override("font_color", Color(0.85, 0.7, 0.3))
	defeat_panel.add_child(sign_label)

	defeat_name_input = LineEdit.new()
	defeat_name_input.position = Vector2(440, hy + 58)
	defeat_name_input.size = Vector2(400, 40)
	defeat_name_input.placeholder_text = "Tu nombre..."
	defeat_name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	defeat_name_input.max_length = 20
	var le_style = StyleBoxFlat.new()
	le_style.bg_color = Color(0.08, 0.06, 0.12, 0.9)
	le_style.border_color = Color(0.75, 0.55, 0.2, 0.8)
	le_style.set_border_width_all(2)
	le_style.set_corner_radius_all(6)
	defeat_name_input.add_theme_stylebox_override("normal", le_style)
	defeat_name_input.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	defeat_name_input.add_theme_font_size_override("font_size", 18)
	defeat_panel.add_child(defeat_name_input)

	# Confirm button hint
	var confirm_hint = Label.new()
	confirm_hint.text = "Presiona ENTER para guardar y volver"
	confirm_hint.position = Vector2(0, hy + 108)
	confirm_hint.size = Vector2(1280, 24)
	confirm_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_hint.add_theme_font_size_override("font_size", 14)
	confirm_hint.add_theme_color_override("font_color", Color(0.4, 0.65, 0.4))
	defeat_panel.add_child(confirm_hint)
	var tw_pulse = create_tween().set_loops()
	tw_pulse.tween_property(confirm_hint, "modulate", Color(1, 1, 1, 0.3), 0.8)
	tw_pulse.tween_property(confirm_hint, "modulate", Color(1, 1, 1, 1.0), 0.8)

	# Show leaderboard
	_draw_leaderboard_on_panel(defeat_panel, hy + 140)

	# Connect Enter in text field
	defeat_name_input.text_submitted.connect(func(_text): _confirm_defeat_sign())

	# Fade in
	var tw = create_tween()
	tw.tween_property(defeat_panel, "modulate", Color(1, 1, 1, 1), 0.5)
	tw.tween_callback(func():
		defeat_name_input.grab_focus()
	)


func _confirm_defeat_sign() -> void:
	var player_name = defeat_name_input.text.strip_edges()
	if player_name == "":
		player_name = "Anonimo"

	var char_names = ["Mago", "Hechicero", "Chaman", "Nahual", "Brujo", "Sacerdote Sol"]

	# Count completed stages
	var completed_count = 0
	for s in story_completed:
		if s:
			completed_count += 1

	# Save to leaderboard
	var entry = {
		"name": player_name,
		"character": char_names[story_player_char],
		"stages": completed_count,
		"total": story_opponents.size(),
		"killed_by": char_names[story_opponents[story_current_stage]],
	}
	_save_leaderboard_entry(entry)

	# Close panel and go to story select
	defeat_panel_active = false
	if is_instance_valid(defeat_panel):
		var tw = create_tween()
		tw.tween_property(defeat_panel, "modulate", Color(1, 1, 1, 0), 0.3)
		tw.tween_callback(func():
			defeat_panel.queue_free()
			_start_story_select()
		)


func _save_leaderboard_entry(entry) -> void:
	var entries = _load_leaderboard()
	entries.append(entry)
	# Sort by stages completed (descending)
	entries.sort_custom(func(a, b): return a.stages > b.stages)
	# Keep top 10
	if entries.size() > 10:
		entries.resize(10)
	var file = FileAccess.open("user://leaderboard.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(entries))
		file.close()


func _load_leaderboard() -> Array:
	if not FileAccess.file_exists("user://leaderboard.json"):
		return []
	var file = FileAccess.open("user://leaderboard.json", FileAccess.READ)
	if not file:
		return []
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		return []
	if json.data is Array:
		return json.data
	return []


func _draw_leaderboard_on_panel(panel: Panel, start_y: float) -> void:
	var entries = _load_leaderboard()
	if entries.size() == 0:
		return

	var lb_title = Label.new()
	lb_title.text = "── MEJORES GUERREROS ──"
	lb_title.position = Vector2(0, start_y)
	lb_title.size = Vector2(1280, 22)
	lb_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb_title.add_theme_font_size_override("font_size", 14)
	lb_title.add_theme_color_override("font_color", Color(0.65, 0.55, 0.35))
	panel.add_child(lb_title)

	var ly = start_y + 26.0
	var count = mini(entries.size(), 5)
	for i in count:
		var e = entries[i]
		var name_str = str(e.get("name", "???"))
		var char_str = str(e.get("character", "???"))
		var stages_num = int(e.get("stages", 0))
		var total_num = int(e.get("total", 5))
		var entry_lbl = Label.new()
		entry_lbl.text = "%d. %s (%s) - %d/%d templos" % [i + 1, name_str, char_str, stages_num, total_num]
		entry_lbl.position = Vector2(0, ly)
		entry_lbl.size = Vector2(1280, 20)
		entry_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		entry_lbl.add_theme_font_size_override("font_size", 13)
		if i == 0:
			entry_lbl.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
		else:
			entry_lbl.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
		panel.add_child(entry_lbl)
		ly += 22.0


func _cleanup_battle() -> void:
	# Free players
	if is_instance_valid(player1):
		player1.queue_free()
	if is_instance_valid(player2):
		player2.queue_free()

	# Free orbs, projectiles, area effects
	for orb in get_tree().get_nodes_in_group("orbs"):
		orb.queue_free()
	for proj in get_tree().get_nodes_in_group("projectiles"):
		proj.queue_free()
	for ae in get_tree().get_nodes_in_group("area_effects"):
		ae.queue_free()

	# Reset round state
	p1_wins = 0
	p2_wins = 0
	current_round = 1
	game_over = false
	game_timer = GAME_TIME
	waiting_to_start = true
	round_transition = false

	# Hide panels
	if is_instance_valid(game_over_panel):
		game_over_panel.visible = false
	var banner_bg = hud.get_node_or_null("BannerBG")
	if banner_bg:
		banner_bg.visible = false

	# Reset HUD
	if is_instance_valid(timer_label):
		timer_label.text = ""
	if is_instance_valid(p1_hp_bar):
		p1_hp_bar.visible = false
	if is_instance_valid(p2_hp_bar):
		p2_hp_bar.visible = false
	if is_instance_valid(p1_mana_bar):
		p1_mana_bar.visible = false
	if is_instance_valid(p2_mana_bar):
		p2_mana_bar.visible = false
	if is_instance_valid(p1_portrait_panel):
		p1_portrait_panel.visible = false
	if is_instance_valid(p2_portrait_panel):
		p2_portrait_panel.visible = false

	# Hide battle HUD elements
	var ab = hud.get_node_or_null("AbilityBar")
	if ab:
		ab.visible = false
	var ch = hud.get_node_or_null("ControlsHint")
	if ch:
		ch.visible = false
	var tb = hud.get_node_or_null("TimerBG")
	if tb:
		tb.visible = false
	var mbg = hud.get_node_or_null("MenuBG")
	if mbg:
		mbg.visible = true
	var ml = hud.get_node_or_null("MenuLogo")
	if ml:
		ml.visible = true

	# Hide instructions
	if is_instance_valid(instructions_panel):
		instructions_panel.visible = false

	# Reset wins display
	if is_instance_valid(p1_wins_label):
		p1_wins_label.text = "0"
	if is_instance_valid(p2_wins_label):
		p2_wins_label.text = "0"
	if is_instance_valid(round_label):
		round_label.text = "Ronda 1"


func _show_story_victory() -> void:
	_delete_story_progress()
	# Limpiar batalla primero
	_cleanup_battle()
	game_over = true
	story_select_active = false

	# Panel de victoria
	var victory_panel = Panel.new()
	victory_panel.name = "VictoryPanel"
	victory_panel.position = Vector2(0, 0)
	victory_panel.size = Vector2(1280, 720)
	var vps = StyleBoxFlat.new()
	vps.bg_color = Color(0.02, 0.02, 0.05, 0.95)
	vps.border_color = Color(0.85, 0.65, 0.15)
	vps.set_border_width_all(3)
	victory_panel.add_theme_stylebox_override("panel", vps)
	hud.add_child(victory_panel)

	var char_names = ["Mago", "Hechicero", "Chaman", "Nahual", "Brujo", "Sacerdote Sol"]
	var char_colors = [
		Color(0.2, 0.8, 0.9), Color(0.9, 0.3, 0.6), Color(0.15, 0.75, 0.3),
		Color(0.95, 0.75, 0.1), Color(0.55, 0.15, 0.8), Color(1.0, 0.55, 0.1),
	]

	# Titulo
	var t1 = Label.new()
	t1.text = "CAMPANA COMPLETA!"
	t1.position = Vector2(0, 80)
	t1.size = Vector2(1280, 60)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_font_size_override("font_size", 48)
	t1.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
	victory_panel.add_child(t1)

	# Nombre del personaje
	var t2 = Label.new()
	t2.text = char_names[story_player_char] + " es el campeon!"
	t2.position = Vector2(0, 150)
	t2.size = Vector2(1280, 40)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.add_theme_font_size_override("font_size", 24)
	t2.add_theme_color_override("font_color", char_colors[story_player_char])
	victory_panel.add_child(t2)

	# Lista de derrotados
	var t3 = Label.new()
	t3.text = "Maestros derrotados:"
	t3.position = Vector2(0, 220)
	t3.size = Vector2(1280, 30)
	t3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t3.add_theme_font_size_override("font_size", 16)
	t3.add_theme_color_override("font_color", Color(0.7, 0.6, 0.4))
	victory_panel.add_child(t3)

	for i in story_opponents.size():
		var boss_idx = story_opponents[i]
		var bl = Label.new()
		bl.text = str(i + 1) + ". " + char_names[boss_idx]
		bl.position = Vector2(0, 255 + float(i) * 30)
		bl.size = Vector2(1280, 24)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.add_theme_font_size_override("font_size", 16)
		bl.add_theme_color_override("font_color", char_colors[boss_idx])
		victory_panel.add_child(bl)

	# Save perfect run to leaderboard
	var victory_entry = {
		"name": "Campeon",
		"character": char_names[story_player_char],
		"stages": story_opponents.size(),
		"total": story_opponents.size(),
		"killed_by": "",
	}
	_save_leaderboard_entry(victory_entry)

	# Hint
	var hint = Label.new()
	hint.text = "Presiona ENTER para volver al menu"
	hint.position = Vector2(0, 550)
	hint.size = Vector2(1280, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4))
	victory_panel.add_child(hint)

	# Pulse animation
	var tw = create_tween().set_loops()
	tw.tween_property(hint, "modulate", Color(1, 1, 1, 0.3), 1.0).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(hint, "modulate", Color(1, 1, 1, 1.0), 1.0).set_ease(Tween.EASE_IN_OUT)

	screen_shake(10.0)
	screen_flash(Color(1, 0.9, 0.4), 0.2, 0.5)
	AudioManager.play_sfx("campaign_win")

	# Esperar input para volver
	# Manejado en _process via game_mode == 3 check
	story_select_active = false
	waiting_to_start = false
	# Usamos un flag especial
	game_over = true  # Reusar game_over para detectar el input


# ── Story Progress Save/Load ──

func _save_story_progress() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("story", "player_char", story_player_char)
	cfg.set_value("story", "current_stage", story_current_stage)
	var opp_str = ""
	for i in story_opponents.size():
		if i > 0:
			opp_str += ","
		opp_str += str(story_opponents[i])
	cfg.set_value("story", "opponents", opp_str)
	var comp_str = ""
	for i in story_completed.size():
		if i > 0:
			comp_str += ","
		comp_str += "1" if story_completed[i] else "0"
	cfg.set_value("story", "completed", comp_str)
	cfg.save("user://story_progress.cfg")


func _load_story_progress() -> bool:
	var cfg = ConfigFile.new()
	var err = cfg.load("user://story_progress.cfg")
	if err != OK:
		return false
	story_player_char = cfg.get_value("story", "player_char", 0)
	story_current_stage = cfg.get_value("story", "current_stage", 0)
	var opp_str = cfg.get_value("story", "opponents", "")
	var comp_str = cfg.get_value("story", "completed", "")
	if opp_str == "" or comp_str == "":
		return false
	story_opponents = []
	for s in opp_str.split(","):
		story_opponents.append(int(s))
	story_completed = []
	for s in comp_str.split(","):
		story_completed.append(s == "1")
	if story_opponents.size() == 0 or story_completed.size() != story_opponents.size():
		return false
	return true


func _delete_story_progress() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("story_progress.cfg")


# ── Settings System ──

func _init_key_bindings():
	key_bindings = [
		{"action": "p1_move_up", "label": "P1 Arriba", "key": KEY_UP},
		{"action": "p1_move_down", "label": "P1 Abajo", "key": KEY_DOWN},
		{"action": "p1_move_left", "label": "P1 Izq", "key": KEY_LEFT},
		{"action": "p1_move_right", "label": "P1 Der", "key": KEY_RIGHT},
		{"action": "p1_attack", "label": "P1 Golpe", "key": KEY_E},
		{"action": "p1_fire", "label": "P1 Fuego", "key": KEY_1},
		{"action": "p1_ice", "label": "P1 Hielo", "key": KEY_2},
		{"action": "p1_special", "label": "P1 Especial", "key": KEY_3},
		{"action": "p1_defend", "label": "P1 Defender", "key": KEY_Q},
		{"action": "p1_dodge", "label": "P1 Esquivar", "key": KEY_W},
		{"action": "p2_move_up", "label": "P2 Arriba", "key": KEY_I},
		{"action": "p2_move_down", "label": "P2 Abajo", "key": KEY_K},
		{"action": "p2_move_left", "label": "P2 Izq", "key": KEY_J},
		{"action": "p2_move_right", "label": "P2 Der", "key": KEY_L},
		{"action": "p2_attack", "label": "P2 Golpe", "key": KEY_SPACE},
		{"action": "p2_fire", "label": "P2 Fuego", "key": KEY_7},
		{"action": "p2_ice", "label": "P2 Hielo", "key": KEY_8},
		{"action": "p2_special", "label": "P2 Especial", "key": KEY_9},
		{"action": "p2_defend", "label": "P2 Defender", "key": KEY_O},
		{"action": "p2_dodge", "label": "P2 Esquivar", "key": KEY_P},
	]


func _create_brightness_overlay():
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	brightness_overlay = ColorRect.new()
	brightness_overlay.position = Vector2.ZERO
	brightness_overlay.size = Vector2(1280, 720)
	brightness_overlay.color = Color(0, 0, 0, 0)
	brightness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(brightness_overlay)


func _key_name(keycode) -> String:
	var names = {
		KEY_UP: "UP", KEY_DOWN: "DOWN", KEY_LEFT: "LEFT", KEY_RIGHT: "RIGHT",
		KEY_A: "A", KEY_B: "B", KEY_C: "C", KEY_D: "D", KEY_E: "E",
		KEY_F: "F", KEY_G: "G", KEY_H: "H", KEY_I: "I", KEY_J: "J",
		KEY_K: "K", KEY_L: "L", KEY_M: "M", KEY_N: "N", KEY_O: "O",
		KEY_P: "P", KEY_Q: "Q", KEY_R: "R", KEY_S: "S", KEY_T: "T",
		KEY_U: "U", KEY_V: "V", KEY_W: "W", KEY_X: "X", KEY_Y: "Y",
		KEY_Z: "Z", KEY_0: "0", KEY_1: "1", KEY_2: "2", KEY_3: "3",
		KEY_4: "4", KEY_5: "5", KEY_6: "6", KEY_7: "7", KEY_8: "8",
		KEY_9: "9", KEY_SPACE: "SPACE", KEY_ENTER: "ENTER", KEY_ESCAPE: "ESC",
		KEY_TAB: "TAB", KEY_SHIFT: "SHIFT", KEY_CTRL: "CTRL",
		KEY_BACKSPACE: "BACK", KEY_DELETE: "DEL", KEY_INSERT: "INS",
		KEY_HOME: "HOME", KEY_END: "END", KEY_PAGEUP: "PGUP", KEY_PAGEDOWN: "PGDN",
		KEY_KP_0: "NUM0", KEY_KP_1: "NUM1", KEY_KP_2: "NUM2", KEY_KP_3: "NUM3",
		KEY_KP_4: "NUM4", KEY_KP_5: "NUM5", KEY_KP_6: "NUM6", KEY_KP_7: "NUM7",
		KEY_KP_8: "NUM8", KEY_KP_9: "NUM9",
		KEY_SEMICOLON: ";", KEY_COMMA: ",", KEY_PERIOD: ".",
		KEY_SLASH: "/", KEY_BACKSLASH: "\\", KEY_MINUS: "-", KEY_EQUAL: "=",
		KEY_BRACKETLEFT: "[", KEY_BRACKETRIGHT: "]",
	}
	if names.has(keycode):
		return names[keycode]
	return "KEY_" + str(keycode)


func _open_settings():
	settings_active = true
	settings_cursor = 0
	settings_rebinding = false
	mode_select_panel.visible = false

	# items: 0=musica, 1=efectos, 2=brillo, 3..22=key bindings (P1+P2)
	settings_items.clear()
	settings_items.append({"type": "slider", "label": "Musica", "value": "music_vol"})
	settings_items.append({"type": "slider", "label": "Efectos", "value": "sfx_vol"})
	settings_items.append({"type": "slider", "label": "Brillo", "value": "brightness_val"})
	for kb in key_bindings:
		settings_items.append({"type": "key", "label": kb.label, "action": kb.action})

	settings_panel = Panel.new()
	settings_panel.position = Vector2(190, 10)
	settings_panel.size = Vector2(900, 700)
	settings_panel.clip_contents = true
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.08, 0.06, 0.1, 0.97)
	ps.border_color = Color(0.76, 0.58, 0.3, 0.95)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(8)
	ps.shadow_color = Color(0.55, 0.41, 0.08, 0.5)
	ps.shadow_size = 30
	settings_panel.add_theme_stylebox_override("panel", ps)
	hud.add_child(settings_panel)

	# Title
	var title = Label.new()
	title.text = "CONFIGURACION"
	title.position = Vector2(0, 12)
	title.size = Vector2(900, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.2))
	settings_panel.add_child(title)

	_rebuild_settings_display()


func _close_settings():
	settings_active = false
	settings_rebinding = false
	if settings_panel:
		settings_panel.queue_free()
		settings_panel = null
	mode_select_panel.visible = true
	_save_settings()


func _rebuild_settings_display():
	if not settings_panel:
		return
	# Remove old items (keep title at index 0)
	var children = settings_panel.get_children()
	for i in range(children.size() - 1, 0, -1):
		children[i].queue_free()

	var y = 46.0

	# Section: AUDIO
	var sec_audio = Label.new()
	sec_audio.text = "── AUDIO ──"
	sec_audio.position = Vector2(0, y)
	sec_audio.size = Vector2(900, 18)
	sec_audio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sec_audio.add_theme_font_size_override("font_size", 12)
	sec_audio.add_theme_color_override("font_color", Color(0.6, 0.5, 0.3))
	settings_panel.add_child(sec_audio)
	y += 22.0

	# Musica slider (item 0)
	_add_settings_row(0, y, "Musica", music_vol)
	y += 28.0
	# Efectos slider (item 1)
	_add_settings_row(1, y, "Efectos", sfx_vol)
	y += 28.0

	# Section: VIDEO
	y += 4.0
	var sec_video = Label.new()
	sec_video.text = "── VIDEO ──"
	sec_video.position = Vector2(0, y)
	sec_video.size = Vector2(900, 18)
	sec_video.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sec_video.add_theme_font_size_override("font_size", 12)
	sec_video.add_theme_color_override("font_color", Color(0.6, 0.5, 0.3))
	settings_panel.add_child(sec_video)
	y += 22.0

	# Brillo slider (item 2)
	_add_settings_row(2, y, "Brillo", brightness_val)
	y += 28.0

	# Section: CONTROLES P1
	y += 4.0
	var sec_ctrl = Label.new()
	sec_ctrl.text = "── JUGADOR 1 ──"
	sec_ctrl.position = Vector2(0, y)
	sec_ctrl.size = Vector2(900, 18)
	sec_ctrl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sec_ctrl.add_theme_font_size_override("font_size", 12)
	sec_ctrl.add_theme_color_override("font_color", Color(0.6, 0.5, 0.3))
	settings_panel.add_child(sec_ctrl)
	y += 22.0

	# Key bindings (items 3..22)
	for i in key_bindings.size():
		var kb = key_bindings[i]
		var item_idx = 3 + i
		var selected = (settings_cursor == item_idx)
		var is_rebinding = settings_rebinding and settings_rebind_action == kb.action

		# Add P2 section separator between P1 and P2 bindings
		if i == 10:
			y += 4.0
			var sec_p2 = Label.new()
			sec_p2.text = "── JUGADOR 2 ──"
			sec_p2.position = Vector2(0, y)
			sec_p2.size = Vector2(900, 18)
			sec_p2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sec_p2.add_theme_font_size_override("font_size", 12)
			sec_p2.add_theme_color_override("font_color", Color(0.6, 0.5, 0.3))
			settings_panel.add_child(sec_p2)
			y += 22.0

		# Row bg
		if selected:
			var bg = ColorRect.new()
			bg.position = Vector2(100, y - 2)
			bg.size = Vector2(700, 22)
			bg.color = Color(0.76, 0.58, 0.3, 0.15)
			settings_panel.add_child(bg)

		# Label
		var lbl = Label.new()
		lbl.text = kb.label
		lbl.position = Vector2(120, y)
		lbl.add_theme_font_size_override("font_size", 14)
		var lbl_color = Color(0.95, 0.85, 0.5) if selected else Color(0.7, 0.65, 0.55)
		lbl.add_theme_color_override("font_color", lbl_color)
		settings_panel.add_child(lbl)

		# Key display
		var key_lbl = Label.new()
		if is_rebinding:
			key_lbl.text = "[Presiona tecla...]"
			key_lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
		else:
			key_lbl.text = "[" + _key_name(kb.key) + "]"
			key_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0) if selected else Color(0.5, 0.6, 0.7))
		key_lbl.position = Vector2(420, y)
		key_lbl.add_theme_font_size_override("font_size", 14)
		settings_panel.add_child(key_lbl)

		if selected and not is_rebinding:
			var hint_lbl = Label.new()
			hint_lbl.text = "ENTER: cambiar"
			hint_lbl.position = Vector2(620, y)
			hint_lbl.add_theme_font_size_override("font_size", 11)
			hint_lbl.add_theme_color_override("font_color", Color(0.5, 0.45, 0.35))
			settings_panel.add_child(hint_lbl)

		y += 24.0

	# Footer
	y += 8.0
	var footer = Label.new()
	footer.text = "[ESC] Volver   |   Flechas: navegar   |   < > ajustar"
	footer.position = Vector2(0, y)
	footer.size = Vector2(900, 20)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color(0.45, 0.4, 0.3))
	settings_panel.add_child(footer)


func _add_settings_row(item_idx: int, y: float, label_text: String, value: float):
	var selected = (settings_cursor == item_idx)

	# Row bg
	if selected:
		var bg = ColorRect.new()
		bg.position = Vector2(100, y - 2)
		bg.size = Vector2(700, 26)
		bg.color = Color(0.76, 0.58, 0.3, 0.15)
		settings_panel.add_child(bg)

	# Label
	var lbl = Label.new()
	lbl.text = label_text + ":"
	lbl.position = Vector2(120, y)
	lbl.add_theme_font_size_override("font_size", 16)
	var lbl_color = Color(0.95, 0.85, 0.5) if selected else Color(0.7, 0.65, 0.55)
	lbl.add_theme_color_override("font_color", lbl_color)
	settings_panel.add_child(lbl)

	# Bar background
	var bar_bg = ColorRect.new()
	bar_bg.position = Vector2(320, y + 2)
	bar_bg.size = Vector2(200, 18)
	bar_bg.color = Color(0.15, 0.12, 0.18)
	settings_panel.add_child(bar_bg)

	# Bar fill
	var fill_w = value * 200.0
	if item_idx == 2:  # Brightness: 0.5 to 1.5 mapped to bar
		fill_w = clampf((value - 0.5) / 1.0, 0.0, 1.0) * 200.0
	var bar_fill = ColorRect.new()
	bar_fill.position = Vector2(320, y + 2)
	bar_fill.size = Vector2(fill_w, 18)
	var fill_color = Color(0.2, 0.8, 0.4) if selected else Color(0.3, 0.6, 0.35)
	if item_idx == 2:
		fill_color = Color(1.0, 0.85, 0.3) if selected else Color(0.7, 0.6, 0.2)
	bar_fill.color = fill_color
	settings_panel.add_child(bar_fill)

	# Percentage
	var pct = Label.new()
	var pct_val = int(value * 100)
	pct.text = str(pct_val) + "%"
	pct.position = Vector2(530, y)
	pct.add_theme_font_size_override("font_size", 16)
	pct.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6) if selected else Color(0.5, 0.48, 0.4))
	settings_panel.add_child(pct)

	# Hints
	if selected:
		var hint = Label.new()
		hint.text = "< >"
		hint.position = Vector2(590, y)
		hint.add_theme_font_size_override("font_size", 14)
		hint.add_theme_color_override("font_color", Color(0.5, 0.45, 0.35))
		settings_panel.add_child(hint)


func _process_settings(_delta):
	if settings_rebinding:
		# Waiting for key input - handled in _input()
		return

	if Input.is_action_just_pressed("ui_escape"):
		_close_settings()
		return

	var total = settings_items.size()

	if Input.is_action_just_pressed("p1_move_up") or Input.is_action_just_pressed("ui_up"):
		settings_cursor = (settings_cursor - 1 + total) % total
		AudioManager.play_sfx("select")
		_rebuild_settings_display()
	elif Input.is_action_just_pressed("p1_move_down") or Input.is_action_just_pressed("ui_down"):
		settings_cursor = (settings_cursor + 1) % total
		AudioManager.play_sfx("select")
		_rebuild_settings_display()

	var item = settings_items[settings_cursor]

	if item.type == "slider":
		var changed = false
		if Input.is_action_just_pressed("p1_move_left") or Input.is_action_just_pressed("ui_left"):
			changed = true
			if item.value == "music_vol":
				music_vol = clampf(music_vol - 0.1, 0.0, 1.0)
			elif item.value == "sfx_vol":
				sfx_vol = clampf(sfx_vol - 0.1, 0.0, 1.0)
			elif item.value == "brightness_val":
				brightness_val = clampf(brightness_val - 0.1, 0.5, 1.5)
		elif Input.is_action_just_pressed("p1_move_right") or Input.is_action_just_pressed("ui_right"):
			changed = true
			if item.value == "music_vol":
				music_vol = clampf(music_vol + 0.1, 0.0, 1.0)
			elif item.value == "sfx_vol":
				sfx_vol = clampf(sfx_vol + 0.1, 0.0, 1.0)
			elif item.value == "brightness_val":
				brightness_val = clampf(brightness_val + 0.1, 0.5, 1.5)
		if changed:
			# Round to avoid float drift
			music_vol = snapped(music_vol, 0.1)
			sfx_vol = snapped(sfx_vol, 0.1)
			brightness_val = snapped(brightness_val, 0.1)
			_apply_settings()
			AudioManager.play_sfx("select")
			_rebuild_settings_display()

	elif item.type == "key":
		if Input.is_action_just_pressed("ui_confirm") or Input.is_action_just_pressed("ui_accept"):
			_start_rebind(item.action)


func _start_rebind(action_name: String):
	settings_rebinding = true
	settings_rebind_action = action_name
	_rebuild_settings_display()


func _input(event):
	if not settings_rebinding:
		return
	if not event is InputEventKey:
		return
	if not event.pressed:
		return
	# Ignore modifier-only keys
	if event.keycode == KEY_SHIFT or event.keycode == KEY_CTRL or event.keycode == KEY_ALT:
		return
	# Cancel with ESC
	if event.keycode == KEY_ESCAPE:
		settings_rebinding = false
		_rebuild_settings_display()
		get_viewport().set_input_as_handled()
		return

	var new_key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode

	# Find the binding being changed
	for kb in key_bindings:
		if kb.action == settings_rebind_action:
			# Remove old keyboard events from InputMap
			var events = InputMap.action_get_events(kb.action)
			for ev in events:
				if ev is InputEventKey:
					InputMap.action_erase_event(kb.action, ev)
			# Add new key
			var new_ev = InputEventKey.new()
			new_ev.physical_keycode = new_key
			InputMap.action_add_event(kb.action, new_ev)
			kb.key = new_key
			break

	settings_rebinding = false
	AudioManager.play_sfx("select")
	_rebuild_settings_display()
	get_viewport().set_input_as_handled()


func _apply_settings():
	AudioManager.set_music_volume(music_vol)
	AudioManager.set_sfx_volume(sfx_vol)
	# Brightness overlay
	if brightness_overlay:
		if brightness_val < 1.0:
			var alpha = (1.0 - brightness_val) * 0.7
			brightness_overlay.color = Color(0, 0, 0, alpha)
		elif brightness_val > 1.0:
			var alpha = (brightness_val - 1.0) * 0.3
			brightness_overlay.color = Color(1, 1, 1, alpha)
		else:
			brightness_overlay.color = Color(0, 0, 0, 0)


func _save_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "music", music_vol)
	cfg.set_value("audio", "sfx", sfx_vol)
	cfg.set_value("video", "brightness", brightness_val)
	for kb in key_bindings:
		cfg.set_value("controls", kb.action, kb.key)
	cfg.save("user://settings.cfg")


func _load_settings():
	var cfg = ConfigFile.new()
	var err = cfg.load("user://settings.cfg")
	if err != OK:
		return  # No saved settings, use defaults
	music_vol = cfg.get_value("audio", "music", 0.8)
	sfx_vol = cfg.get_value("audio", "sfx", 0.8)
	brightness_val = cfg.get_value("video", "brightness", 1.0)
	for kb in key_bindings:
		var saved_key = cfg.get_value("controls", kb.action, -1)
		if saved_key != -1:
			kb.key = saved_key


func _draw_settings_bg():
	# Dim overlay behind settings panel
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.3))
