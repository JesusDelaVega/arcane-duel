extends Node2D

var current_radius = 0.0
var max_radius = 80.0
var expand_speed = 280.0
var damage = 5
var stun_time = 0.5
var effect_color = Color(0.3, 0.5, 1.0)
var shooter = null
var hit_targets = []
var lifetime = 0.6
var time = 0.0
var shards = []


func _ready() -> void:
	for i in 14:
		shards.append({
			"angle": randf() * TAU,
			"dist": randf_range(0.3, 0.95),
			"size": randf_range(3.0, 7.0),
			"rot": randf() * TAU,
		})


func _process(delta: float) -> void:
	time += delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return

	current_radius += expand_speed * delta
	if current_radius > max_radius:
		current_radius = max_radius

	for node in get_tree().get_nodes_in_group("players"):
		if node == shooter:
			continue
		if not is_instance_valid(node):
			continue
		if hit_targets.has(node):
			continue
		if position.distance_to(node.global_position) < current_radius + 16:
			node.receive_hit(damage, stun_time, position)
			hit_targets.append(node)

	queue_redraw()


func _draw() -> void:
	var alpha = clamp(lifetime * 2.0, 0.05, 1.0)

	# Fill degradado
	var lc = effect_color.lightened(0.2)
	draw_circle(Vector2.ZERO, current_radius, Color(effect_color.r, effect_color.g, effect_color.b, alpha * 0.1))
	draw_circle(Vector2.ZERO, current_radius * 0.5, Color(lc.r, lc.g, lc.b, alpha * 0.15))

	# Anillos concentricos
	for ring in 3:
		var rr = current_radius * (0.4 + float(ring) * 0.3)
		var ra = alpha * (0.65 - float(ring) * 0.18)
		draw_arc(Vector2.ZERO, rr, 0, TAU, 48,
			Color(effect_color.r, effect_color.g, effect_color.b, ra), 2.5 - float(ring) * 0.6)

	# Cristales de hielo
	for shard in shards:
		var sp = Vector2(cos(shard.angle), sin(shard.angle)) * current_radius * shard.dist
		var sz = shard.size * (current_radius / max_radius)
		var pts = PackedVector2Array()
		var r = shard.rot
		pts.append(sp + Vector2(0, -sz).rotated(r))
		pts.append(sp + Vector2(sz * 0.35, 0).rotated(r))
		pts.append(sp + Vector2(0, sz * 0.5).rotated(r))
		pts.append(sp + Vector2(-sz * 0.35, 0).rotated(r))
		var sc = effect_color.lightened(0.4)
		draw_colored_polygon(pts, Color(sc.r, sc.g, sc.b, alpha * 0.6))

	# Sparkles en borde
	for i in 12:
		var angle = float(i) / 12.0 * TAU + time * 4.0
		var sp = Vector2(cos(angle), sin(angle)) * current_radius
		var fl = 0.4 + sin(time * 10.0 + float(i) * 2.0) * 0.3
		draw_circle(sp, 2.5, Color(1, 1, 1, alpha * fl))
		draw_circle(sp, 1.0, Color(1, 1, 1, alpha * fl * 1.5))

	# Flash central
	if time < 0.12:
		var fa = (1.0 - time / 0.12) * 0.4
		draw_circle(Vector2.ZERO, current_radius * 0.3, Color(1, 1, 1, fa))
