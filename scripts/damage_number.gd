extends Node2D

var text = ""
var color = Color.WHITE
var time = 0.0
var duration = 1.0
var rise_speed = 50.0
var sway_phase = 0.0
var is_crit = false


func setup(pos: Vector2, amount: int, is_stun: bool = false) -> void:
	position = pos + Vector2(randf_range(-15, 15), -25)
	sway_phase = randf() * TAU
	if is_stun:
		text = "STUN!"
		color = Color(0.3, 0.7, 1.0)
		is_crit = true
	else:
		text = str(amount)
		if amount >= 25:
			color = Color(1, 0.2, 0.15)
			is_crit = true
		elif amount >= 15:
			color = Color(1, 0.5, 0.15)
		elif amount >= 8:
			color = Color(1, 0.85, 0.2)
		else:
			color = Color(0.85, 0.85, 0.9)


func _process(delta: float) -> void:
	time += delta
	position.y -= rise_speed * delta
	position.x += sin(time * 3.0 + sway_phase) * 15.0 * delta
	rise_speed *= 0.97
	if time >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t = time / duration
	var alpha = clamp(1.0 - t * t, 0, 1)

	# Pop scale
	var scale_f = 1.0
	if time < 0.1:
		scale_f = 1.0 + (1.0 - time / 0.1) * 0.5
	elif time < 0.18:
		scale_f = 1.0 + sin((time - 0.1) / 0.08 * PI) * 0.12

	var font = ThemeDB.fallback_font
	if not font:
		return

	var base_sz = 16
	if is_crit:
		base_sz = 24
	elif text != "STUN!":
		base_sz = clampi(14 + text.to_int() / 2, 14, 26)

	var sz = int(float(base_sz) * scale_f)

	# Wobble rotacional para crits
	if is_crit and time < 0.3:
		var rot_amount = sin(time * 30.0) * 0.05 * (1.0 - time / 0.3)
		draw_set_transform(Vector2.ZERO, rot_amount)

	# Outline grueso
	var oc = Color(0, 0, 0, alpha * 0.8)
	for ox in range(-2, 3):
		for oy in range(-2, 3):
			if ox == 0 and oy == 0:
				continue
			draw_string(font, Vector2(ox, oy), text, HORIZONTAL_ALIGNMENT_CENTER, 80, sz, oc)

	# Glow para crits
	if is_crit:
		draw_string(font, Vector2(0, -1), text, HORIZONTAL_ALIGNMENT_CENTER, 80, sz + 2,
			Color(color.r, color.g, color.b, alpha * 0.3))

	# Texto principal
	draw_string(font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_CENTER, 80, sz, Color(color.r, color.g, color.b, alpha))

	# Highlight
	if time < 0.25:
		var ha = (1.0 - time / 0.25) * alpha * 0.35
		draw_string(font, Vector2(0, -1), text, HORIZONTAL_ALIGNMENT_CENTER, 80, sz, Color(1, 1, 1, ha))

	# Reset transform
	if is_crit and time < 0.3:
		draw_set_transform(Vector2.ZERO, 0.0)
