extends Node2D

var direction = Vector2.ZERO
var speed = 300.0
var damage = 10
var stun_time = 0.0
var radius = 8.0
var proj_color = Color.RED
var shooter = null
var lifetime = 2.0
var time = 0.0

var trail_points = []
var trail_max = 14

const ARENA = Rect2(140, 60, 1000, 600)


func _ready() -> void:
	add_to_group("projectiles")


func _process(delta: float) -> void:
	time += delta
	position += direction * speed * delta

	trail_points.push_front(position)
	if trail_points.size() > trail_max:
		trail_points.pop_back()

	if time > lifetime or not ARENA.has_point(position):
		queue_free()
		return

	for node in get_tree().get_nodes_in_group("players"):
		if node == shooter:
			continue
		if not is_instance_valid(node):
			continue
		if position.distance_to(node.global_position) < radius + 16:
			node.receive_hit(damage, stun_time, position)
			var main = get_tree().current_scene
			if main.has_method("spawn_hit_particles"):
				main.spawn_hit_particles(position, proj_color.lightened(0.3), 14)
			queue_free()
			return

	queue_redraw()


func _draw() -> void:
	var is_arcane = stun_time > 0.3
	var pulse = 1.0 + sin(time * 14.0) * 0.12

	# Trail degradado
	for i in trail_points.size():
		var lp = trail_points[i] - position
		var t = float(i) / float(trail_points.size())
		var ta = (1.0 - t) * 0.4
		var tr = radius * (1.0 - t * 0.6)
		draw_circle(lp, tr, Color(proj_color.r, proj_color.g, proj_color.b, ta * 0.25))
		if i > 0:
			var prev = trail_points[i - 1] - position
			draw_line(prev, lp, Color(proj_color.r, proj_color.g, proj_color.b, ta * 0.3), tr * 0.5)

	# Glow exterior
	draw_circle(Vector2.ZERO, radius * 2.2 * pulse, Color(proj_color.r, proj_color.g, proj_color.b, 0.07))
	draw_circle(Vector2.ZERO, radius * 1.6 * pulse, Color(proj_color.r, proj_color.g, proj_color.b, 0.15))

	# Anillo de distorsion
	draw_arc(Vector2.ZERO, radius * 1.5 * pulse, 0, TAU, 24,
		Color(proj_color.r, proj_color.g, proj_color.b, 0.22), 1.5)

	# Body
	draw_circle(Vector2.ZERO, radius * pulse, proj_color)

	# Core brillante
	draw_circle(Vector2.ZERO, radius * 0.5, Color(1, 1, 1, 0.85))
	draw_circle(Vector2.ZERO, radius * 0.2, Color(1, 1, 1, 0.95))

	# Sparkles orbitando
	var ns = 4 if is_arcane else 3
	for i in ns:
		var sa = time * 8.0 + float(i) * TAU / float(ns)
		var sp = Vector2(cos(sa), sin(sa)) * radius * 1.4
		draw_circle(sp, 1.5, Color(1, 1, 1, 0.5 + sin(time * 12.0 + float(i)) * 0.3))

	# Arcane extra
	if is_arcane:
		draw_arc(Vector2.ZERO, radius * 1.9, time * 3.0, time * 3.0 + TAU * 0.7, 20,
			Color(proj_color.lightened(0.3).r, proj_color.lightened(0.3).g, proj_color.lightened(0.3).b, 0.35), 2.0)
		for i in 3:
			var ra = time * 2.0 + float(i) * TAU / 3.0
			var rp = Vector2(cos(ra), sin(ra)) * radius * 2.2
			draw_circle(rp, 2.0, Color(proj_color.lightened(0.5).r, proj_color.lightened(0.5).g, proj_color.lightened(0.5).b, 0.45))
