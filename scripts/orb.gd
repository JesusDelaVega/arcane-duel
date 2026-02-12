extends Area2D

@export var orb_color: String = "red"

var time: float = 0.0
var collected: bool = false
var collected_timer: float = 0.0
var bob_offset: float = 0.0


func _ready() -> void:
	add_to_group("orbs")
	bob_offset = randf() * TAU


func _process(delta: float) -> void:
	time += delta

	if collected:
		collected_timer += delta
		modulate.a = 1.0 - collected_timer / 0.2
		scale = Vector2.ONE * (1.0 + collected_timer * 6)
		if collected_timer > 0.2:
			queue_free()
		return

	var pulse = 1.0 + sin(time * 3.0 + bob_offset) * 0.12
	scale = Vector2.ONE * pulse
	queue_redraw()


func pickup(p) -> void:
	if collected:
		return
	if p.has_method("collect_orb"):
		p.collect_orb(orb_color)
	collected = true
	remove_from_group("orbs")
	$OrbShape.set_deferred("disabled", true)
	# Burst de coleccion mejorado
	var main = get_tree().current_scene
	if main.has_method("spawn_hit_particles"):
		main.spawn_hit_particles(global_position, Color(0.95, 0.85, 0.2), 10)
		main.spawn_hit_particles(global_position, Color(1.0, 1.0, 0.7), 6)


func _draw() -> void:
	var base = Color(0.95, 0.8, 0.2)
	var glow = Color(1.0, 0.85, 0.3)
	var pulse_a = 0.1 + sin(time * 4.0 + bob_offset) * 0.05

	# Outer glow pulsante
	draw_circle(Vector2.ZERO, 20, Color(glow.r, glow.g, glow.b, pulse_a * 0.5))
	draw_circle(Vector2.ZERO, 14, Color(glow.r, glow.g, glow.b, pulse_a + 0.15))

	# Anillo magico giratorio
	draw_arc(Vector2.ZERO, 11, time * 1.5, time * 1.5 + TAU, 20,
		Color(1.0, 0.9, 0.4, 0.25), 1.0)

	# Core
	draw_circle(Vector2.ZERO, 7, base)
	draw_circle(Vector2.ZERO, 5, base.lightened(0.2))

	# Cruz runica interior rotando
	var rune_a = time * 2.0
	for i in 4:
		var ra = rune_a + float(i) * TAU / 4.0
		var rp1 = Vector2(cos(ra), sin(ra)) * 3.0
		var rp2 = Vector2(cos(ra), sin(ra)) * 5.5
		draw_line(rp1, rp2, Color(1.0, 0.95, 0.6, 0.4), 1.0)

	# Shine
	draw_circle(Vector2(-2, -2.5), 2.5, Color(1, 1, 0.85, 0.75))

	# Sparkle particles girando (orbitas elipticas variadas)
	for i in 6:
		var sa = time * (2.0 + float(i) * 0.3) + float(i) * TAU / 6.0
		var sr_x = 10.0 + sin(time * 2.0 + float(i)) * 2.0
		var sr_y = 7.0 + cos(time * 1.5 + float(i)) * 2.0
		var sp = Vector2(cos(sa) * sr_x, sin(sa) * sr_y)
		var sa2 = 0.25 + sin(time * 5.0 + float(i) * 1.5) * 0.2
		draw_circle(sp, 1.0, Color(1, 1, 0.7, sa2))
