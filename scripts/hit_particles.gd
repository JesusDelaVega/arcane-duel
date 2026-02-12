extends Node2D

var particles = []
var lifetime = 0.5


func spawn(pos: Vector2, color: Color, count: int = 8, spread: float = 150.0) -> void:
	position = pos
	for i in count:
		var angle = randf() * TAU
		var spd = randf_range(80, spread)
		var sz = randf_range(2.0, 5.0)
		var type = randi() % 3
		particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * spd,
			"color": color.lightened(randf_range(0.0, 0.35)),
			"size": sz,
			"life": lifetime * randf_range(0.5, 1.0),
			"max_life": lifetime,
			"type": type,
			"rot": randf() * TAU,
			"rot_speed": randf_range(-8.0, 8.0),
			"gravity": randf_range(40, 100),
		})
	# Flash central (mas grande y brillante)
	particles.append({
		"pos": Vector2.ZERO,
		"vel": Vector2.ZERO,
		"color": Color(1, 1, 1, 0.9),
		"size": spread * 0.15,
		"life": 0.1,
		"max_life": 0.1,
		"type": 3,
		"rot": 0.0,
		"rot_speed": 0.0,
		"gravity": 0.0,
	})


func _process(delta: float) -> void:
	var alive = false
	for p in particles:
		p.life -= delta
		if p.life > 0:
			p.pos += p.vel * delta
			p.vel *= 0.90
			p.vel.y += p.gravity * delta
			p.rot += p.rot_speed * delta
			alive = true
	if not alive:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	for p in particles:
		if p.life <= 0:
			continue
		var t = clamp(p.life / p.max_life, 0, 1)
		var c = Color(p.color.r, p.color.g, p.color.b, p.color.a * t)
		var s = p.size * (0.3 + t * 0.7)

		# Afterglow trail para particulas en movimiento
		if p.type != 3 and p.vel.length() > 10:
			var trail_dir = -p.vel.normalized()
			var trail_len = min(p.vel.length() * 0.03, 8.0) * t
			draw_line(p.pos, p.pos + trail_dir * trail_len,
				Color(c.r, c.g, c.b, c.a * 0.3), s * 0.5)

		match p.type:
			0:  # Circle con glow
				draw_circle(p.pos, s * 1.6, Color(c.r, c.g, c.b, c.a * 0.2))
				draw_circle(p.pos, s, c)
			1:  # Diamond rotado
				var half = s * 0.6
				var pts = PackedVector2Array()
				for corner in 4:
					var ca = p.rot + float(corner) * TAU / 4.0
					pts.append(p.pos + Vector2(cos(ca), sin(ca)) * half)
				draw_colored_polygon(pts, c)
			2:  # Spark line
				var dir = p.vel.normalized() if p.vel.length() > 1 else Vector2.RIGHT
				var ll = s * 2.5 * t
				draw_line(p.pos - dir * ll, p.pos + dir * ll, c, s * 0.4)
			3:  # Flash
				draw_circle(p.pos, s * t, c)
