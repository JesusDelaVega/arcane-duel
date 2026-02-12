extends Node2D

# Portrait Drawer - Retratos de busto frontal para seleccion de personaje
# Cada personaje se dibuja ~4-5x mas grande, vista frontal, medio torso

var character_type = 0
var char_color = Color(0.2, 0.8, 0.9)
var anim_time = 0.0
var is_selected = false
var select_time = 0.0

# Colores derivados (se calculan en _draw)
var _bc = Color.WHITE
var _rc = Color.WHITE
var _dc = Color.WHITE
var _lc = Color.WHITE


func _process(delta):
	anim_time += delta
	if is_selected:
		select_time += delta
	queue_redraw()


func _draw():
	_bc = char_color
	_rc = char_color.darkened(0.15)
	_dc = char_color.darkened(0.4)
	_lc = char_color.lightened(0.3)

	# Glow de fondo cuando esta seleccionado
	if is_selected:
		var pulse = sin(select_time * 4.0) * 0.08 + 0.2
		for i in 5:
			var r = 120.0 - float(i) * 15.0
			draw_circle(Vector2(0, -20), r, Color(char_color.r, char_color.g, char_color.b, pulse * (1.0 - float(i) * 0.18)))

	match character_type:
		0: _draw_portrait_mago()
		1: _draw_portrait_hechicero()
		2: _draw_portrait_chaman()
		3: _draw_portrait_nahual()
		4: _draw_portrait_brujo()
		5: _draw_portrait_sacerdote()
		6: _draw_portrait_atlante()
		_: _draw_portrait_mago()

	# Particulas de seleccion
	if is_selected:
		_draw_select_particles()


func _draw_select_particles():
	for i in 8:
		var a = select_time * 2.5 + float(i) * TAU / 8.0
		var r = 80.0 + sin(select_time * 3.0 + float(i)) * 15.0
		var px = cos(a) * r
		var py = sin(a) * r * 0.6 - 20.0
		var pa = sin(select_time * 4.0 + float(i) * 1.5) * 0.3 + 0.5
		draw_circle(Vector2(px, py), 3.0, Color(char_color.r, char_color.g, char_color.b, pa * 0.6))
		draw_circle(Vector2(px, py), 1.5, Color(1, 1, 1, pa * 0.4))


# ══════════════════════════════════════════════════════
# MAGO - Sombrero puntiagudo, vara estelar
# ══════════════════════════════════════════════════════

func _draw_portrait_mago():
	var sel_s = 1.15 if is_selected else 1.0
	var by = 20.0  # base Y del torso

	# Vara estelar (detras, lado derecho)
	var staff_x = 50.0 * sel_s
	var staff_top = Vector2(staff_x, -100 * sel_s)
	var staff_bot = Vector2(staff_x - 5, by + 40)
	draw_line(staff_bot, staff_top, Color(0.45, 0.3, 0.15), 5.0)
	# Estrella en la punta
	var sg = sin(anim_time * 4.0) * 0.2 + 0.8
	draw_circle(staff_top, 8 * sel_s, Color(1, 1, 0.5, sg * 0.4))
	draw_circle(staff_top, 5 * sel_s, Color(1, 1, 0.5, sg))
	for i in 6:
		var ra = anim_time * 1.5 + float(i) * TAU / 6.0
		draw_line(staff_top + Vector2(cos(ra), sin(ra)) * 5, staff_top + Vector2(cos(ra), sin(ra)) * 12, Color(1, 1, 0.6, sg * 0.4), 2.0)

	# Hombros/torso
	var shoulder_w = 45.0 * sel_s
	draw_polygon(PackedVector2Array([
		Vector2(-shoulder_w, -15 * sel_s + by), Vector2(shoulder_w, -15 * sel_s + by),
		Vector2(shoulder_w + 10, by + 60), Vector2(-shoulder_w - 10, by + 60)
	]), PackedColorArray([_rc, _rc, _rc.darkened(0.1), _rc.darkened(0.1)]))
	# Borde tunica
	draw_polyline(PackedVector2Array([
		Vector2(-shoulder_w, -15 * sel_s + by), Vector2(-shoulder_w - 10, by + 60),
		Vector2(shoulder_w + 10, by + 60), Vector2(shoulder_w, -15 * sel_s + by)
	]), _dc, 2.0)

	# Pliegues
	draw_line(Vector2(-15, by + 10), Vector2(-18, by + 55), Color(_dc.r, _dc.g, _dc.b, 0.3), 1.5)
	draw_line(Vector2(15, by + 10), Vector2(18, by + 55), Color(_dc.r, _dc.g, _dc.b, 0.3), 1.5)

	# Cinturon
	draw_line(Vector2(-shoulder_w - 2, by + 15), Vector2(shoulder_w + 2, by + 15), _dc, 4.0)

	# Estrella emblema en pecho
	var emb_y = by - 2
	draw_circle(Vector2(0, emb_y), 8, _lc)
	for i in 4:
		var ra = float(i) * TAU / 4.0 + PI / 4.0
		draw_line(Vector2(0, emb_y) + Vector2(cos(ra), sin(ra)) * 4,
			Vector2(0, emb_y) + Vector2(cos(ra), sin(ra)) * 10, _lc, 2.0)

	# Hombreras redondas
	for side in [-1, 1]:
		var sx = float(side) * shoulder_w
		var sy = -15.0 * sel_s + by
		draw_circle(Vector2(sx, sy), 14 * sel_s, _rc.lightened(0.1))
		draw_arc(Vector2(sx, sy), 14 * sel_s, 0, TAU, 20, _dc, 2.0)
		draw_circle(Vector2(sx, sy), 5, _lc)

	# Cuello
	draw_rect(Rect2(-8, by - 30, 16, 20), _bc.darkened(0.1))

	# Cabeza
	var hy = by - 55.0
	draw_circle(Vector2(0, hy), 28 * sel_s, Color(0.85, 0.7, 0.55))
	draw_arc(Vector2(0, hy), 28 * sel_s, 0, TAU, 32, Color(0.6, 0.45, 0.3), 2.0)

	# Ojos
	var ey = hy - 2
	for side in [-1, 1]:
		var ex = float(side) * 10
		draw_circle(Vector2(ex, ey), 6, Color.WHITE)
		draw_circle(Vector2(ex, ey), 3.5, Color(0.2, 0.5, 0.9))
		draw_circle(Vector2(ex + 1, ey - 1), 1.5, Color(0.05, 0.05, 0.05))
		# Brillo
		draw_circle(Vector2(ex + 2, ey - 2), 1.0, Color(1, 1, 1, 0.8))

	# Cejas relajadas
	draw_line(Vector2(-15, ey - 8), Vector2(-5, ey - 9), Color(0.4, 0.3, 0.2), 2.5)
	draw_line(Vector2(15, ey - 8), Vector2(5, ey - 9), Color(0.4, 0.3, 0.2), 2.5)

	# Sonrisa leve
	draw_arc(Vector2(0, hy + 10), 6, 0.2, PI - 0.2, 12, Color(0.4, 0.3, 0.2), 2.0)

	# Sombrero puntiagudo
	var hat_base = hy - 24
	draw_polygon(PackedVector2Array([
		Vector2(5, hat_base - 70 * sel_s),
		Vector2(-38 * sel_s, hat_base + 5),
		Vector2(38 * sel_s, hat_base + 5)
	]), PackedColorArray([_rc.lightened(0.2), _dc, _dc]))
	# Ala del sombrero
	draw_line(Vector2(-40 * sel_s, hat_base + 5), Vector2(40 * sel_s, hat_base + 5), _dc, 6.0)
	# Estrella en la punta
	var hat_star_a = sin(anim_time * 3.0) * 0.3 + 0.7
	draw_circle(Vector2(5, hat_base - 70 * sel_s), 6.0, Color(1, 1, 0.5, hat_star_a))
	draw_circle(Vector2(5, hat_base - 70 * sel_s), 3.0, Color(1, 1, 0.9))

	# Chispas orbitando (mas grandes en portrait)
	for i in 5:
		var sa = anim_time * 1.8 + float(i) * TAU / 5.0
		var sr = 55.0 + sin(anim_time * 2.0 + float(i)) * 8.0
		var sp = Vector2(cos(sa), sin(sa)) * sr + Vector2(0, hy - 20)
		var sparkle = sin(anim_time * 6.0 + float(i) * 2.0) * 0.3 + 0.7
		draw_circle(sp, 3.0, Color(0.8, 0.9, 1, sparkle * 0.5))
		draw_circle(sp, 1.5, Color(1, 1, 1, sparkle * 0.7))

	# Pose seleccionado: vara levantada con constelacion
	if is_selected:
		for i in 6:
			var sx = randf_range(-60, 60)
			var sy = randf_range(-130, -40)
			var sa = sin(select_time * 3.0 + float(i) * 1.7) * 0.4 + 0.6
			draw_circle(Vector2(sx, sy), 2.0, Color(1, 1, 0.8, sa * 0.5))


# ══════════════════════════════════════════════════════
# HECHICERO - Capucha con cuernos, cristal oscuro
# ══════════════════════════════════════════════════════

func _draw_portrait_hechicero():
	var sel_s = 1.15 if is_selected else 1.0
	var by = 20.0

	# Vara cristal (lado izquierdo)
	var staff_x = -50.0 * sel_s
	var staff_top = Vector2(staff_x, -105 * sel_s)
	var staff_bot = Vector2(staff_x + 5, by + 40)
	draw_line(staff_bot, staff_top, Color(0.35, 0.25, 0.4), 5.0)
	# Cristal en la punta
	var gp = sin(anim_time * 3.0) * 0.15 + 0.85
	draw_polygon(PackedVector2Array([
		staff_top + Vector2(0, -12), staff_top + Vector2(8, 0),
		staff_top + Vector2(0, 12), staff_top + Vector2(-8, 0)
	]), PackedColorArray([
		Color(0.9, 0.4, 1, gp), Color(0.6, 0.1, 0.8, gp),
		Color(0.9, 0.4, 1, gp), Color(0.6, 0.1, 0.8, gp)
	]))
	draw_circle(staff_top, 6, Color(0.8, 0.2, 1.0, gp * 0.6))

	# Torso
	var shoulder_w = 44.0 * sel_s
	draw_polygon(PackedVector2Array([
		Vector2(-shoulder_w, -15 * sel_s + by), Vector2(shoulder_w, -15 * sel_s + by),
		Vector2(shoulder_w + 8, by + 60), Vector2(-shoulder_w - 8, by + 60)
	]), PackedColorArray([_rc, _rc, _rc.darkened(0.15), _rc.darkened(0.15)]))
	draw_polyline(PackedVector2Array([
		Vector2(-shoulder_w, -15 * sel_s + by), Vector2(-shoulder_w - 8, by + 60),
		Vector2(shoulder_w + 8, by + 60), Vector2(shoulder_w, -15 * sel_s + by)
	]), _dc, 2.0)

	# Gema emblema en pecho
	var emb_y = by - 2
	draw_polygon(PackedVector2Array([
		Vector2(0, emb_y - 8), Vector2(7, emb_y), Vector2(0, emb_y + 8), Vector2(-7, emb_y)
	]), PackedColorArray([_lc, _lc, _lc, _lc]))
	var gem_pulse = sin(anim_time * 2.5) * 0.2 + 0.6
	draw_circle(Vector2(0, emb_y), 4, Color(0.9, 0.3, 0.7, gem_pulse))

	# Cinturon
	draw_line(Vector2(-shoulder_w - 2, by + 15), Vector2(shoulder_w + 2, by + 15), _dc, 4.0)

	# Hombreras puntiagudas
	for side in [-1, 1]:
		var sx = float(side) * shoulder_w
		var sy = -15.0 * sel_s + by
		draw_polygon(PackedVector2Array([
			Vector2(sx - 10, sy + 5), Vector2(sx, sy - 18 * sel_s), Vector2(sx + 10, sy + 5)
		]), PackedColorArray([_dc, _rc.lightened(0.1), _dc]))
		draw_polyline(PackedVector2Array([
			Vector2(sx - 10, sy + 5), Vector2(sx, sy - 18 * sel_s), Vector2(sx + 10, sy + 5)
		]), _dc.darkened(0.2), 2.0)

	# Cuello
	draw_rect(Rect2(-8, by - 30, 16, 20), _bc.darkened(0.1))

	# Cabeza
	var hy = by - 55.0
	draw_circle(Vector2(0, hy), 28 * sel_s, Color(0.8, 0.65, 0.55))
	draw_arc(Vector2(0, hy), 28 * sel_s, 0, TAU, 32, Color(0.5, 0.35, 0.3), 2.0)

	# Ojos (rojos/magenta)
	var ey = hy - 2
	for side in [-1, 1]:
		var ex = float(side) * 10
		draw_circle(Vector2(ex, ey), 6, Color.WHITE)
		draw_circle(Vector2(ex, ey), 3.5, Color(0.8, 0.2, 0.4))
		draw_circle(Vector2(ex + 1, ey - 1), 1.5, Color(0.05, 0.05, 0.05))
		draw_circle(Vector2(ex + 2, ey - 2), 1.0, Color(1, 1, 1, 0.8))

	# Cejas afiladas
	draw_line(Vector2(-16, ey - 6), Vector2(-5, ey - 10), Color(0.3, 0.15, 0.2), 2.5)
	draw_line(Vector2(16, ey - 6), Vector2(5, ey - 10), Color(0.3, 0.15, 0.2), 2.5)

	# Boca seria
	draw_line(Vector2(-6, hy + 10), Vector2(6, hy + 10), Color(0.35, 0.2, 0.25), 2.0)

	# Capucha con cuernos
	var hat_base = hy - 22
	draw_polygon(PackedVector2Array([
		Vector2(0, hat_base - 35 * sel_s),
		Vector2(-35 * sel_s, hat_base + 3),
		Vector2(-30 * sel_s, hat_base + 15),
		Vector2(30 * sel_s, hat_base + 15),
		Vector2(35 * sel_s, hat_base + 3)
	]), PackedColorArray([_rc.lightened(0.1), _dc, _dc, _dc, _dc]))

	# Cuernos
	draw_line(Vector2(-24 * sel_s, hat_base), Vector2(-38 * sel_s, hat_base - 50 * sel_s), _dc, 5.0)
	draw_line(Vector2(24 * sel_s, hat_base), Vector2(38 * sel_s, hat_base - 50 * sel_s), _dc, 5.0)
	# Glow en cuernos
	var hg = sin(anim_time * 2.5) * 0.3 + 0.7
	draw_circle(Vector2(-38 * sel_s, hat_base - 50 * sel_s), 5, Color(1, 0.3, 0.5, hg))
	draw_circle(Vector2(38 * sel_s, hat_base - 50 * sel_s), 5, Color(1, 0.3, 0.5, hg))

	# Niebla oscura abajo
	for i in 6:
		var ma = anim_time * 1.2 + float(i) * 1.1
		var mx = sin(ma) * 50.0
		var my = cos(ma * 0.7) * 8.0
		draw_circle(Vector2(mx, by + 50 + my), 10.0 + sin(anim_time + float(i)) * 3.0, Color(0.3, 0.1, 0.4, 0.06))

	if is_selected:
		# Energia oscura emanando
		for i in 4:
			var sa = select_time * 2.0 + float(i) * TAU / 4.0
			var sr = 70.0 + sin(select_time * 3.0) * 10.0
			var sp = Vector2(cos(sa) * sr, sin(sa) * sr * 0.5 + hy)
			draw_circle(sp, 4.0, Color(0.8, 0.2, 0.6, 0.3))


# ══════════════════════════════════════════════════════
# CHAMAN - Penacho de plumas, pintura tribal
# ══════════════════════════════════════════════════════

func _draw_portrait_chaman():
	var sel_s = 1.15 if is_selected else 1.0
	var by = 20.0

	# Vara con sonaja (lado derecho)
	var staff_x = 55.0 * sel_s
	var staff_top = Vector2(staff_x, -90 * sel_s)
	var staff_bot = Vector2(staff_x - 5, by + 40)
	draw_line(staff_bot, staff_top, Color(0.5, 0.35, 0.15), 5.0)
	# Sonaja
	var rattle = sin(anim_time * 4.0) * 3.0
	draw_circle(staff_top + Vector2(rattle, 0), 8, Color(0.8, 0.5, 0.1))
	draw_circle(staff_top + Vector2(-rattle, -5), 5, Color(0.6, 0.3, 0.05))
	# Pluma colgante
	draw_line(staff_top, staff_top + Vector2(sin(anim_time * 2.0) * 4, 15), Color(0.8, 0.2, 0.1), 2.5)

	# Huipil (poncho ancho)
	var shoulder_w = 50.0 * sel_s
	draw_polygon(PackedVector2Array([
		Vector2(-shoulder_w, -12 * sel_s + by), Vector2(shoulder_w, -12 * sel_s + by),
		Vector2(shoulder_w + 15, by + 60), Vector2(-shoulder_w - 15, by + 60)
	]), PackedColorArray([_rc, _rc, _rc.darkened(0.05), _rc.darkened(0.05)]))
	draw_polyline(PackedVector2Array([
		Vector2(-shoulder_w, -12 * sel_s + by), Vector2(-shoulder_w - 15, by + 60),
		Vector2(shoulder_w + 15, by + 60), Vector2(shoulder_w, -12 * sel_s + by)
	]), _dc, 2.0)

	# Patron zigzag
	for i in 8:
		var zx = -32.0 + float(i) * 9.0
		var zy = by + 30
		draw_line(Vector2(zx, zy), Vector2(zx + 4.5, zy - 8), Color(0.9, 0.6, 0.1, 0.7), 2.5)
		draw_line(Vector2(zx + 4.5, zy - 8), Vector2(zx + 9, zy), Color(0.9, 0.6, 0.1, 0.7), 2.5)

	# Espiral emblema
	draw_arc(Vector2(0, by), 10, 0, TAU * 0.75, 16, _lc, 2.5)
	draw_arc(Vector2(0, by), 5, PI, PI + TAU * 0.75, 12, _lc, 2.5)

	# Cinturon
	draw_line(Vector2(-shoulder_w - 2, by + 15), Vector2(shoulder_w + 2, by + 15), _dc, 4.0)

	# Hombreras de plumas
	for side in [-1, 1]:
		var sx = float(side) * shoulder_w
		var sy = -12.0 * sel_s + by
		draw_polygon(PackedVector2Array([
			Vector2(sx, sy + 5), Vector2(sx + float(side) * 18, sy - 10 * sel_s), Vector2(sx, sy - 5)
		]), PackedColorArray([Color(0.1, 0.6, 0.2), Color(0.8, 0.5, 0.1), Color(0.1, 0.6, 0.2)]))

	# Cuello
	draw_rect(Rect2(-8, by - 28, 16, 18), Color(0.55, 0.35, 0.2))

	# Cabeza
	var hy = by - 52.0
	draw_circle(Vector2(0, hy), 27 * sel_s, Color(0.65, 0.45, 0.3))
	draw_arc(Vector2(0, hy), 27 * sel_s, 0, TAU, 32, Color(0.45, 0.3, 0.18), 2.0)

	# Ojos verdes
	var ey = hy - 2
	for side in [-1, 1]:
		var ex = float(side) * 10
		draw_circle(Vector2(ex, ey), 5.5, Color.WHITE)
		draw_circle(Vector2(ex, ey), 3, Color(0.3, 0.6, 0.2))
		draw_circle(Vector2(ex + 1, ey - 1), 1.5, Color(0.05, 0.05, 0.05))
		draw_circle(Vector2(ex + 2, ey - 2), 1.0, Color(1, 1, 1, 0.8))

	# Cejas sabias
	draw_line(Vector2(-15, ey - 7), Vector2(-5, ey - 8), Color(0.35, 0.25, 0.15), 2.5)
	draw_line(Vector2(15, ey - 7), Vector2(5, ey - 8), Color(0.35, 0.25, 0.15), 2.5)

	# Pintura facial - lineas en mejillas
	for side in [-1, 1]:
		var cx = float(side) * 17
		for j in 3:
			var ly = hy + 2 + float(j) * 4
			draw_line(Vector2(cx, ly), Vector2(cx + float(side) * 10, ly), Color(0.9, 0.3, 0.1, 0.7), 2.0)
	# Punto en frente
	draw_circle(Vector2(0, hy - 12), 4, Color(0.1, 0.7, 0.3))

	# Boca serena
	draw_arc(Vector2(0, hy + 10), 5, 0.3, PI - 0.3, 10, Color(0.35, 0.25, 0.15), 2.0)

	# Penacho de plumas (abanico frontal)
	var hat_y = hy - 25
	var feather_colors = [Color(0.9, 0.15, 0.1), Color(0.1, 0.7, 0.2), Color(0.9, 0.7, 0.1), Color(0.1, 0.5, 0.8), Color(0.9, 0.15, 0.1)]
	for i in 5:
		var angle = -0.5 + float(i) * 0.25
		var fdir = Vector2(sin(angle), -cos(angle))
		var flen = (55.0 + float(i % 2) * 12.0) * sel_s
		var fbase = Vector2(0, hat_y)
		var ftip = fbase + fdir * flen
		draw_line(fbase, ftip, feather_colors[i].darkened(0.3), 5.0)
		draw_line(fbase, ftip, feather_colors[i], 3.0)
		draw_circle(ftip, 4, feather_colors[i].lightened(0.3))

	# Banda base
	draw_line(Vector2(-28 * sel_s, hat_y + 3), Vector2(28 * sel_s, hat_y + 3), Color(0.6, 0.4, 0.1), 5.0)
	draw_line(Vector2(-25 * sel_s, hat_y + 7), Vector2(25 * sel_s, hat_y + 7), Color(0.4, 0.25, 0.05), 3.0)

	# Orbes espirituales flotando
	for i in 3:
		var sa = anim_time * 1.5 + float(i) * TAU / 3.0
		var sr = 65.0
		var sp = Vector2(cos(sa) * sr, sin(sa) * sr * 0.4 + hy)
		var sa2 = sin(anim_time * 3.0 + float(i)) * 0.15 + 0.2
		draw_circle(sp, 5, Color(0.3, 0.9, 0.4, sa2))
		draw_circle(sp, 2.5, Color(0.5, 1, 0.6, sa2 * 1.5))

	if is_selected:
		# Plumas se abren mas, espiritus brillan
		for i in 4:
			var sa = select_time * 2.0 + float(i) * TAU / 4.0
			var sp = Vector2(cos(sa) * 50, sin(sa) * 30 + hy - 30)
			draw_circle(sp, 6, Color(0.2, 0.8, 0.3, 0.25))


# ══════════════════════════════════════════════════════
# NAHUAL - Mascara de jaguar, garras
# ══════════════════════════════════════════════════════

func _draw_portrait_nahual():
	var sel_s = 1.15 if is_selected else 1.0
	var by = 20.0

	# Macuahuitl (lado izquierdo, al frente en pose de poder)
	var wpn_x = -55.0 * sel_s
	if is_selected:
		wpn_x = -30.0
	var wpn_top = Vector2(wpn_x, -100 * sel_s)
	var wpn_bot = Vector2(wpn_x + 5, by + 35)
	draw_line(wpn_bot, wpn_top, Color(0.4, 0.3, 0.1), 7.0)
	# Obsidiana
	var blade_dir = (wpn_top - wpn_bot).normalized()
	var blade_perp = Vector2(-blade_dir.y, blade_dir.x)
	for i in 4:
		var bp = wpn_bot.lerp(wpn_top, 0.3 + float(i) * 0.15)
		draw_polygon(PackedVector2Array([
			bp + blade_perp * 8, bp + blade_dir * 6, bp - blade_perp * 8
		]), PackedColorArray([Color(0.15, 0.15, 0.2), Color(0.3, 0.3, 0.35), Color(0.15, 0.15, 0.2)]))

	# Capa de piel de jaguar (detras)
	var cape_col = Color(0.75, 0.55, 0.15)
	var sw = sin(anim_time * 2.0) * 4.0
	draw_polygon(PackedVector2Array([
		Vector2(-50 * sel_s, by - 10), Vector2(50 * sel_s, by - 10),
		Vector2(55 * sel_s + sw, by + 65), Vector2(-55 * sel_s + sw, by + 65)
	]), PackedColorArray([cape_col, cape_col, cape_col.darkened(0.3), cape_col.darkened(0.3)]))
	# Manchas en capa
	for i in 5:
		var mx = -30.0 + float(i) * 15.0
		var my = by + 30 + sin(float(i)) * 10.0
		draw_circle(Vector2(mx, my), 5, Color(0.3, 0.2, 0.05, 0.5))

	# Cuerpo guerrero (cuadrado)
	var shoulder_w = 48.0 * sel_s
	draw_polygon(PackedVector2Array([
		Vector2(-shoulder_w, -18 * sel_s + by), Vector2(shoulder_w, -18 * sel_s + by),
		Vector2(shoulder_w + 5, by + 55), Vector2(-shoulder_w - 5, by + 55)
	]), PackedColorArray([_rc, _rc, _rc, _rc]))
	draw_polyline(PackedVector2Array([
		Vector2(-shoulder_w, -18 * sel_s + by), Vector2(-shoulder_w - 5, by + 55),
		Vector2(shoulder_w + 5, by + 55), Vector2(shoulder_w, -18 * sel_s + by)
	]), _dc, 2.0)

	# Manchas jaguar en torso
	draw_circle(Vector2(-12, by + 10), 5, _dc.darkened(0.15))
	draw_circle(Vector2(15, by + 20), 4, _dc.darkened(0.15))
	draw_circle(Vector2(3, by - 5), 4, _dc.darkened(0.15))
	draw_circle(Vector2(-20, by + 25), 3, _dc.darkened(0.15))

	# Cinturon con colmillo
	draw_line(Vector2(-shoulder_w - 2, by + 12), Vector2(shoulder_w + 2, by + 12), _dc, 4.0)
	draw_polygon(PackedVector2Array([
		Vector2(-3, by + 12), Vector2(3, by + 12), Vector2(0, by + 22)
	]), PackedColorArray([Color(0.9, 0.85, 0.7), Color(0.9, 0.85, 0.7), Color(0.7, 0.65, 0.5)]))

	# Hombreras de garra
	for side in [-1, 1]:
		var sx = float(side) * shoulder_w
		var sy = -18.0 * sel_s + by
		draw_polygon(PackedVector2Array([
			Vector2(sx, sy + 5), Vector2(sx + float(side) * 22 * sel_s, sy - 8 * sel_s), Vector2(sx, sy - 8)
		]), PackedColorArray([Color(0.7, 0.5, 0.1), Color(0.5, 0.35, 0.05), Color(0.7, 0.5, 0.1)]))
		# Garras en hombreras
		for c in 3:
			var cx = sx + float(side) * (12 + float(c) * 4)
			draw_line(Vector2(cx, sy - 5), Vector2(cx + float(side) * 4, sy + 4), Color(0.2, 0.2, 0.2), 1.5)

	# Cuello
	draw_rect(Rect2(-9, by - 32, 18, 20), Color(0.55, 0.4, 0.2))

	# Cabeza
	var hy = by - 55.0
	draw_circle(Vector2(0, hy), 27 * sel_s, Color(0.65, 0.45, 0.25))
	draw_arc(Vector2(0, hy), 27 * sel_s, 0, TAU, 32, Color(0.45, 0.3, 0.15), 2.0)

	# Ojos feroces amarillos rasgados
	var ey = hy - 2
	for side in [-1, 1]:
		var ex = float(side) * 10
		# Forma de ojo rasgado
		draw_polygon(PackedVector2Array([
			Vector2(ex - 7, ey), Vector2(ex, ey - 5), Vector2(ex + 7, ey), Vector2(ex, ey + 3)
		]), PackedColorArray([
			Color(1, 0.9, 0.3), Color(1, 0.9, 0.3), Color(1, 0.9, 0.3), Color(1, 0.9, 0.3)
		]))
		# Pupila vertical
		draw_line(Vector2(ex, ey - 4), Vector2(ex, ey + 2), Color(0.05, 0.05, 0.05), 2.5)

	# Cejas agresivas
	draw_line(Vector2(-17, ey - 4), Vector2(-5, ey - 9), Color(0.3, 0.2, 0.05), 3.0)
	draw_line(Vector2(17, ey - 4), Vector2(5, ey - 9), Color(0.3, 0.2, 0.05), 3.0)

	# Pintura facial jaguar
	draw_line(Vector2(-18, hy + 3), Vector2(-28, hy + 3), Color(0.1, 0.1, 0.1, 0.6), 3.0)
	draw_line(Vector2(18, hy + 3), Vector2(28, hy + 3), Color(0.1, 0.1, 0.1, 0.6), 3.0)

	# Colmillos
	draw_line(Vector2(-6, hy + 12), Vector2(-6, hy + 20), Color(0.95, 0.9, 0.8), 2.5)
	draw_line(Vector2(6, hy + 12), Vector2(6, hy + 20), Color(0.95, 0.9, 0.8), 2.5)
	# Boca gruñendo
	draw_line(Vector2(-8, hy + 12), Vector2(8, hy + 12), Color(0.3, 0.2, 0.1), 2.0)

	# Capucha jaguar con orejas
	var hat_base = hy - 23
	draw_polygon(PackedVector2Array([
		Vector2(0, hat_base - 20 * sel_s),
		Vector2(-34 * sel_s, hat_base + 5),
		Vector2(-28 * sel_s, hat_base + 15),
		Vector2(28 * sel_s, hat_base + 15),
		Vector2(34 * sel_s, hat_base + 5)
	]), PackedColorArray([Color(0.75, 0.55, 0.15), _dc, _dc, _dc, _dc]))

	# Orejas puntiagudas
	draw_polygon(PackedVector2Array([
		Vector2(-28 * sel_s, hat_base), Vector2(-40 * sel_s, hat_base - 35 * sel_s), Vector2(-15 * sel_s, hat_base - 5)
	]), PackedColorArray([Color(0.75, 0.55, 0.15), Color(0.6, 0.4, 0.1), Color(0.75, 0.55, 0.15)]))
	draw_polygon(PackedVector2Array([
		Vector2(28 * sel_s, hat_base), Vector2(40 * sel_s, hat_base - 35 * sel_s), Vector2(15 * sel_s, hat_base - 5)
	]), PackedColorArray([Color(0.75, 0.55, 0.15), Color(0.6, 0.4, 0.1), Color(0.75, 0.55, 0.15)]))

	# Manchas capucha
	draw_circle(Vector2(-14, hat_base - 5), 4, Color(0.3, 0.2, 0.05, 0.5))
	draw_circle(Vector2(14, hat_base - 5), 4, Color(0.3, 0.2, 0.05, 0.5))

	# Espiritu jaguar detras
	var jaguar_a = sin(anim_time * 1.0) * 0.08 + 0.12
	draw_circle(Vector2(0, by + 50), 25, Color(0.4, 0.3, 0.05, jaguar_a))
	# Ojos del espiritu
	var je = sin(anim_time * 2.0) * 0.15 + 0.2
	draw_circle(Vector2(-8, by + 45), 3, Color(1, 0.8, 0.1, je))
	draw_circle(Vector2(8, by + 45), 3, Color(1, 0.8, 0.1, je))

	if is_selected:
		# Jaguar rugiendo mas visible
		draw_circle(Vector2(0, by + 45), 30, Color(0.6, 0.4, 0.05, 0.15))
		draw_circle(Vector2(-8, by + 40), 4, Color(1, 0.9, 0.2, 0.5))
		draw_circle(Vector2(8, by + 40), 4, Color(1, 0.9, 0.2, 0.5))


# ══════════════════════════════════════════════════════
# BRUJO - Mascara de calavera, huesos
# ══════════════════════════════════════════════════════

func _draw_portrait_brujo():
	var sel_s = 1.15 if is_selected else 1.0
	var by = 20.0

	# Vara de hueso (lado derecho)
	var staff_x = 52.0 * sel_s
	var staff_top = Vector2(staff_x, -100 * sel_s)
	var staff_bot = Vector2(staff_x - 3, by + 40)
	draw_line(staff_bot, staff_top, Color(0.8, 0.75, 0.65), 5.0)
	# Calavera en la punta
	draw_circle(staff_top, 10, Color(0.85, 0.8, 0.7))
	draw_circle(staff_top + Vector2(-3, -3), 2.5, Color(0.1, 0.1, 0.1))
	draw_circle(staff_top + Vector2(3, -3), 2.5, Color(0.1, 0.1, 0.1))
	draw_line(staff_top + Vector2(-3, 3), staff_top + Vector2(3, 3), Color(0.2, 0.2, 0.15), 1.5)
	# Glow espectral
	var glow_a = sin(anim_time * 3.0) * 0.2 + 0.4
	draw_circle(staff_top, 15, Color(0.4, 0.9, 0.3, glow_a * 0.3))

	# Capa rasgada (detras)
	for i in 5:
		var off = float(i - 2) * 18.0
		var sw = sin(anim_time * 1.5 + float(i)) * 6.0
		var base = Vector2(off, by - 10)
		var tip = Vector2(off + sw, by + 70 + float(i % 2) * 10)
		draw_line(base, tip, Color(0.3, 0.15, 0.4, 0.35 - float(i) * 0.04), 6.0)

	# Torso rasgado
	var shoulder_w = 44.0 * sel_s
	draw_polygon(PackedVector2Array([
		Vector2(-shoulder_w, -15 * sel_s + by), Vector2(shoulder_w, -15 * sel_s + by),
		Vector2(shoulder_w + 8, by + 55), Vector2(-shoulder_w - 8, by + 55)
	]), PackedColorArray([_rc, _rc, _rc.darkened(0.1), _rc.darkened(0.1)]))

	# Costillas
	for i in 4:
		var ry = by + 8 + float(i) * 10
		draw_line(Vector2(-20, ry), Vector2(20, ry), Color(0.8, 0.75, 0.65, 0.4), 3.0)

	# Cinturon de huesos
	draw_line(Vector2(-shoulder_w, by + 12), Vector2(shoulder_w, by + 12), Color(0.8, 0.75, 0.65), 4.0)

	# Hombreras de hueso
	for side in [-1, 1]:
		var sx = float(side) * shoulder_w
		var sy = -15.0 * sel_s + by
		draw_circle(Vector2(sx, sy), 12 * sel_s, Color(0.8, 0.75, 0.65))
		draw_circle(Vector2(sx, sy), 5, Color(0.1, 0.1, 0.1))

	# Cuello huesudo
	draw_rect(Rect2(-7, by - 28, 14, 18), Color(0.7, 0.65, 0.55))

	# Cabeza calavera (sin piel, directo calavera)
	var hy = by - 55.0
	draw_circle(Vector2(0, hy), 28 * sel_s, Color(0.85, 0.8, 0.7))
	draw_arc(Vector2(0, hy), 28 * sel_s, 0, TAU, 32, Color(0.5, 0.45, 0.35), 2.0)

	# Cuencas de ojos
	var ey = hy - 4
	for side in [-1, 1]:
		var ex = float(side) * 10
		draw_circle(Vector2(ex, ey), 8, Color(0.05, 0.05, 0.05))
		# Brillo espectral verde
		var eg = sin(anim_time * 3.0 + float(side)) * 0.2 + 0.7
		draw_circle(Vector2(ex, ey), 4, Color(0.4, 0.9, 0.3, eg))
		draw_circle(Vector2(ex, ey), 2, Color(0.6, 1, 0.5, eg * 0.8))

	# Nariz (triangulo)
	draw_polygon(PackedVector2Array([
		Vector2(-3, hy + 2), Vector2(3, hy + 2), Vector2(0, hy + 8)
	]), PackedColorArray([Color(0.15, 0.15, 0.1), Color(0.15, 0.15, 0.1), Color(0.15, 0.15, 0.1)]))

	# Boca cosida
	var mouth_y = hy + 14
	draw_line(Vector2(-12, mouth_y), Vector2(12, mouth_y), Color(0.2, 0.2, 0.15), 2.0)
	for i in 6:
		var sx = -10.0 + float(i) * 4.0
		draw_line(Vector2(sx, mouth_y - 3), Vector2(sx, mouth_y + 3), Color(0.2, 0.2, 0.15), 1.5)

	# Capucha rasgada
	var hat_base = hy - 24
	draw_polygon(PackedVector2Array([
		Vector2(0, hat_base - 35 * sel_s),
		Vector2(-34 * sel_s, hat_base + 3),
		Vector2(-26 * sel_s, hat_base + 15),
		Vector2(26 * sel_s, hat_base + 15),
		Vector2(34 * sel_s, hat_base + 3)
	]), PackedColorArray([_rc.darkened(0.2), _dc, _dc, _dc, _dc]))
	# Rasgaduras
	draw_line(Vector2(-20 * sel_s, hat_base + 15), Vector2(-26 * sel_s, hat_base + 28), _dc.darkened(0.2), 3.0)
	draw_line(Vector2(10 * sel_s, hat_base + 15), Vector2(16 * sel_s, hat_base + 25), _dc.darkened(0.2), 3.0)

	# Almas flotando
	for i in 4:
		var sa = anim_time * 1.0 + float(i) * TAU / 4.0
		var sr = 70.0 + sin(anim_time * 2.0 + float(i)) * 10.0
		var sx = cos(sa) * sr
		var sy = sin(sa) * sr * 0.5 + hy
		var ghost_a = sin(anim_time * 2.5 + float(i) * 2.0) * 0.1 + 0.15
		draw_circle(Vector2(sx, sy), 6, Color(0.3, 0.9, 0.2, ghost_a))
		# Estela
		var prev = sa - 0.4
		draw_line(Vector2(sx, sy), Vector2(cos(prev) * sr, sin(prev) * sr * 0.5 + hy), Color(0.3, 0.9, 0.2, ghost_a * 0.4), 2.5)

	# Particulas espectrales
	for i in 4:
		var pa = anim_time * 1.5 + float(i) * 2.0
		var pp = Vector2(sin(pa) * 40, cos(pa * 0.7) * 25 + hy)
		draw_circle(pp, 4, Color(0.4, 0.9, 0.3, 0.1))

	if is_selected:
		# Ojos flamean mas
		for side in [-1, 1]:
			var ex = float(side) * 10
			draw_circle(Vector2(ex, ey), 10, Color(0.3, 0.9, 0.2, 0.3))
		# Almas mas visibles
		for i in 3:
			var sa = select_time * 3.0 + float(i) * TAU / 3.0
			var sp = Vector2(cos(sa) * 50, sin(sa) * 30 + hy)
			draw_circle(sp, 8, Color(0.3, 1, 0.2, 0.2))


# ══════════════════════════════════════════════════════
# SACERDOTE SOL - Corona solar, fuego divino
# ══════════════════════════════════════════════════════

func _draw_portrait_sacerdote():
	var sel_s = 1.15 if is_selected else 1.0
	var by = 20.0

	# Vara con disco solar (lado izquierdo)
	var staff_x = -52.0 * sel_s
	var staff_top = Vector2(staff_x, -95 * sel_s)
	var staff_bot = Vector2(staff_x + 3, by + 40)
	draw_line(staff_bot, staff_top, Color(0.7, 0.55, 0.1), 5.0)
	draw_line(staff_bot, staff_top, Color(0.9, 0.7, 0.2), 2.5)
	# Disco solar
	var sg = sin(anim_time * 3.0) * 0.15 + 0.85
	draw_circle(staff_top, 14, Color(1, 0.7, 0.1, sg * 0.4))
	draw_circle(staff_top, 10, Color(1, 0.85, 0.2, sg))
	draw_circle(staff_top, 5, Color(1, 0.95, 0.6))
	for i in 8:
		var ra = anim_time * 1.0 + float(i) * TAU / 8.0
		draw_line(staff_top + Vector2(cos(ra), sin(ra)) * 10,
			staff_top + Vector2(cos(ra), sin(ra)) * 18,
			Color(1, 0.8, 0.2, sg * 0.5), 2.5)

	# Capa dorada (detras)
	var cape_col = Color(0.8, 0.5, 0.05)
	var csw = sin(anim_time * 2.5) * 4.0
	draw_polygon(PackedVector2Array([
		Vector2(-52 * sel_s, by - 5), Vector2(52 * sel_s, by - 5),
		Vector2(58 * sel_s + csw, by + 65), Vector2(-58 * sel_s + csw, by + 65)
	]), PackedColorArray([cape_col, cape_col, cape_col.darkened(0.3), cape_col.darkened(0.3)]))
	# Borde dorado
	draw_polyline(PackedVector2Array([
		Vector2(-58 * sel_s + csw, by + 65), Vector2(58 * sel_s + csw, by + 65)
	]), Color(1, 0.85, 0.3, 0.6), 3.0)

	# Torso ornamental
	var shoulder_w = 46.0 * sel_s
	draw_polygon(PackedVector2Array([
		Vector2(-shoulder_w, -15 * sel_s + by), Vector2(shoulder_w, -15 * sel_s + by),
		Vector2(shoulder_w + 10, by + 55), Vector2(-shoulder_w - 10, by + 55)
	]), PackedColorArray([_rc, _rc, _rc, _rc]))
	draw_polyline(PackedVector2Array([
		Vector2(-shoulder_w, -15 * sel_s + by), Vector2(-shoulder_w - 10, by + 55),
		Vector2(shoulder_w + 10, by + 55), Vector2(shoulder_w, -15 * sel_s + by)
	]), Color(1, 0.8, 0.2, 0.5), 2.0)

	# Patron solar en pecho
	var sun_y = by + 2
	draw_circle(Vector2(0, sun_y), 12, Color(1, 0.7, 0.1, 0.5))
	draw_arc(Vector2(0, sun_y), 12, 0, TAU, 20, _lc, 2.0)
	for i in 8:
		var ra = float(i) * TAU / 8.0
		draw_line(Vector2(0, sun_y) + Vector2(cos(ra), sin(ra)) * 12,
			Vector2(0, sun_y) + Vector2(cos(ra), sin(ra)) * 18, _lc, 2.0)

	# Cinturon dorado
	draw_line(Vector2(-shoulder_w - 2, by + 15), Vector2(shoulder_w + 2, by + 15), Color(0.9, 0.7, 0.15), 5.0)

	# Hombreras con rayos
	for side in [-1, 1]:
		var sx = float(side) * shoulder_w
		var sy = -15.0 * sel_s + by
		draw_circle(Vector2(sx, sy), 14 * sel_s, Color(0.9, 0.6, 0.1))
		draw_circle(Vector2(sx, sy), 8, Color(1, 0.8, 0.2))
		for i in 6:
			var ra = float(i) * TAU / 6.0 + anim_time * 0.5
			draw_line(Vector2(sx, sy) + Vector2(cos(ra), sin(ra)) * 8,
				Vector2(sx, sy) + Vector2(cos(ra), sin(ra)) * 16,
				Color(1, 0.8, 0.2, 0.4), 2.0)

	# Cuello
	draw_rect(Rect2(-8, by - 30, 16, 20), Color(0.7, 0.5, 0.3))

	# Cabeza
	var hy = by - 55.0
	draw_circle(Vector2(0, hy), 27 * sel_s, Color(0.75, 0.55, 0.35))
	draw_arc(Vector2(0, hy), 27 * sel_s, 0, TAU, 32, Color(0.5, 0.35, 0.2), 2.0)

	# Ojos dorados
	var ey = hy - 2
	for side in [-1, 1]:
		var ex = float(side) * 10
		draw_circle(Vector2(ex, ey), 6, Color.WHITE)
		draw_circle(Vector2(ex, ey), 3.5, Color(0.9, 0.65, 0.1))
		draw_circle(Vector2(ex + 1, ey - 1), 1.5, Color(0.05, 0.05, 0.05))
		draw_circle(Vector2(ex + 2, ey - 2), 1.0, Color(1, 1, 1, 0.8))

	# Cejas reales
	draw_line(Vector2(-16, ey - 8), Vector2(-5, ey - 9), Color(0.4, 0.3, 0.15), 2.5)
	draw_line(Vector2(16, ey - 8), Vector2(5, ey - 9), Color(0.4, 0.3, 0.15), 2.5)

	# Marcas doradas faciales
	draw_line(Vector2(0, hy - 14), Vector2(0, hy - 22), Color(1, 0.8, 0.2, 0.6), 3.0)
	for side in [-1, 1]:
		draw_line(Vector2(float(side) * 16, hy + 2), Vector2(float(side) * 24, hy + 2), Color(1, 0.8, 0.2, 0.5), 2.0)

	# Boca serena
	draw_arc(Vector2(0, hy + 10), 5, 0.2, PI - 0.2, 10, Color(0.4, 0.3, 0.15), 2.0)

	# Corona solar
	var crown_y = hy - 30
	# Disco base
	draw_circle(Vector2(0, crown_y), 22 * sel_s, Color(0.9, 0.6, 0.1))
	draw_circle(Vector2(0, crown_y), 16 * sel_s, Color(1, 0.8, 0.2))
	draw_circle(Vector2(0, crown_y), 8, Color(1, 0.95, 0.5))
	# Rayos de la corona
	var ray_glow = sin(anim_time * 2.0) * 0.2 + 0.8
	for i in 12:
		var ra = float(i) * TAU / 12.0 + anim_time * 0.3
		var rlen = (32.0 if i % 2 == 0 else 24.0) * sel_s
		draw_line(Vector2(0, crown_y) + Vector2(cos(ra), sin(ra)) * 18 * sel_s,
			Vector2(0, crown_y) + Vector2(cos(ra), sin(ra)) * rlen,
			Color(1, 0.85, 0.2, ray_glow), 3.0)

	# Rayos de luz divina
	for i in 4:
		var la = anim_time * 0.6 + float(i) * 0.8
		var lx = sin(la) * 30.0
		var light_a = sin(anim_time * 2.0 + float(i)) * 0.06 + 0.08
		draw_line(Vector2(lx, -120), Vector2(lx + sin(la) * 5, by + 40), Color(1, 0.9, 0.4, light_a), 3.0)

	if is_selected:
		# Sol intensifica
		draw_circle(Vector2(0, crown_y), 30 * sel_s, Color(1, 0.8, 0.2, 0.15))
		for i in 8:
			var ra = float(i) * TAU / 8.0 + select_time * 0.5
			draw_line(Vector2(0, crown_y) + Vector2(cos(ra), sin(ra)) * 25,
				Vector2(0, crown_y) + Vector2(cos(ra), sin(ra)) * 45,
				Color(1, 0.9, 0.3, 0.25), 3.0)


# ══════════════════════════════════════════════════════
# ATLANTE - Guerrero de piedra tolteca, atlatl
# ══════════════════════════════════════════════════════

func _draw_portrait_atlante():
	var sel_s = 1.15 if is_selected else 1.0
	var by = 20.0
	var stone = Color(0.55, 0.58, 0.55)
	var stone_d = Color(0.4, 0.43, 0.4)
	var turq = Color(0.2, 0.7, 0.65)
	var turq_l = Color(0.3, 0.85, 0.8)

	# Atlatl (lado derecho, detras)
	var staff_x = 52.0 * sel_s
	var staff_top = Vector2(staff_x, -90 * sel_s)
	var staff_bot = Vector2(staff_x - 3, by + 40)
	draw_line(staff_bot, staff_top, Color(0.5, 0.4, 0.25), 5.0)
	# Gancho del atlatl
	var hook_end = Vector2(staff_x + 8, -95 * sel_s)
	draw_line(staff_top, hook_end, Color(0.45, 0.35, 0.2), 4.0)
	# Dardo
	var dart_top = Vector2(staff_x, -115 * sel_s)
	draw_line(staff_top + Vector2(0, -5), dart_top, Color(0.6, 0.55, 0.45), 3.0)
	# Punta de obsidiana
	draw_polygon(PackedVector2Array([
		dart_top, dart_top + Vector2(-4, -8), dart_top + Vector2(4, -8)
	]), PackedColorArray([Color(0.15, 0.15, 0.2), Color(0.25, 0.25, 0.3), Color(0.15, 0.15, 0.2)]))

	# Torso columnar (piedra, rigido)
	var shoulder_w = 44.0 * sel_s
	draw_polygon(PackedVector2Array([
		Vector2(-shoulder_w, -12 * sel_s + by), Vector2(shoulder_w, -12 * sel_s + by),
		Vector2(shoulder_w + 4, by + 55), Vector2(-shoulder_w - 4, by + 55)
	]), PackedColorArray([_rc, _rc, _rc, _rc]))
	# Bordes de piedra
	draw_polyline(PackedVector2Array([
		Vector2(-shoulder_w, -12 * sel_s + by), Vector2(-shoulder_w - 4, by + 55),
		Vector2(shoulder_w + 4, by + 55), Vector2(shoulder_w, -12 * sel_s + by)
	]), _dc, 2.0)
	# Grietas
	draw_line(Vector2(-20, by + 5), Vector2(-28, by + 30), Color(0.3, 0.32, 0.3, 0.4), 1.5)
	draw_line(Vector2(15, by + 10), Vector2(22, by + 35), Color(0.3, 0.32, 0.3, 0.4), 1.5)
	draw_line(Vector2(-5, by + 25), Vector2(8, by + 40), Color(0.3, 0.32, 0.3, 0.4), 1.5)

	# Pectoral de mariposa estilizada grande
	var bpx = 0.0
	var bpy = by + 0.0
	# Ala izquierda
	draw_polygon(PackedVector2Array([
		Vector2(bpx, bpy), Vector2(bpx - 20, bpy - 12),
		Vector2(bpx - 24, bpy + 4), Vector2(bpx - 12, bpy + 12)
	]), PackedColorArray([turq, turq.darkened(0.2), turq.darkened(0.3), turq]))
	# Ala derecha
	draw_polygon(PackedVector2Array([
		Vector2(bpx, bpy), Vector2(bpx + 20, bpy - 12),
		Vector2(bpx + 24, bpy + 4), Vector2(bpx + 12, bpy + 12)
	]), PackedColorArray([turq, turq.darkened(0.2), turq.darkened(0.3), turq]))
	# Centro turquesa brillante
	draw_circle(Vector2(bpx, bpy), 5, turq_l)
	draw_circle(Vector2(bpx, bpy), 3, Color(0.5, 0.95, 0.9))
	# Detalles en alas
	draw_line(Vector2(bpx - 5, bpy - 2), Vector2(bpx - 18, bpy - 8), turq_l, 1.5)
	draw_line(Vector2(bpx + 5, bpy - 2), Vector2(bpx + 18, bpy - 8), turq_l, 1.5)

	# Cinturon de piedra con disco turquesa
	draw_line(Vector2(-shoulder_w - 2, by + 18), Vector2(shoulder_w + 2, by + 18), stone_d, 5.0)
	draw_circle(Vector2(0, by + 18), 6, turq)
	draw_circle(Vector2(0, by + 18), 3, turq_l)

	# Hombreras cuadradas de piedra
	for side in [-1, 1]:
		var sx = float(side) * shoulder_w
		var sy = -12.0 * sel_s + by
		draw_polygon(PackedVector2Array([
			Vector2(sx, sy - 8), Vector2(sx + float(side) * 18, sy - 10),
			Vector2(sx + float(side) * 16, sy + 6), Vector2(sx, sy + 4)
		]), PackedColorArray([stone, stone_d, stone_d, stone]))
		# Turquesa en hombreras
		draw_circle(Vector2(sx + float(side) * 9, sy - 2), 4, Color(turq.r, turq.g, turq.b, 0.7))

	# Cuello
	draw_rect(Rect2(-10, by - 28, 20, 20), stone)

	# Cabeza
	var hy = by - 52.0
	draw_circle(Vector2(0, hy), 26 * sel_s, _bc)
	draw_arc(Vector2(0, hy), 26 * sel_s, 0, TAU, 32, _dc, 2.0)

	# Ojos turquesa brillante (sin pupilas, ojos de piedra)
	var ey = hy - 2
	var eye_glow = sin(anim_time * 2.5) * 0.15 + 0.85
	for side in [-1, 1]:
		var ex = float(side) * 10
		draw_circle(Vector2(ex, ey), 6, Color(0.2, 0.75, 0.7, eye_glow))
		draw_circle(Vector2(ex, ey), 3.5, Color(0.5, 0.95, 0.9, eye_glow * 0.8))
		draw_circle(Vector2(ex, ey), 1.5, Color(0.8, 1, 0.98, eye_glow * 0.5))

	# Cejas rectas estoicas
	draw_line(Vector2(-16, ey - 8), Vector2(-5, ey - 8), stone_d, 3.0)
	draw_line(Vector2(16, ey - 8), Vector2(5, ey - 8), stone_d, 3.0)

	# Boca recta estoica
	draw_line(Vector2(-8, hy + 10), Vector2(8, hy + 10), Color(0.3, 0.32, 0.3), 2.5)

	# Tocado columnar rectangular con plumas
	var crown_y = hy - 28
	# Base rectangular del tocado
	draw_polygon(PackedVector2Array([
		Vector2(-28 * sel_s, crown_y + 15), Vector2(28 * sel_s, crown_y + 15),
		Vector2(30 * sel_s, crown_y - 10), Vector2(-30 * sel_s, crown_y - 10)
	]), PackedColorArray([stone, stone, stone_d, stone_d]))
	# Banda turquesa
	draw_line(Vector2(-30 * sel_s, crown_y), Vector2(30 * sel_s, crown_y), turq, 3.0)
	# Glifos en el tocado
	for i in 3:
		var gx = -14.0 + float(i) * 14.0
		draw_rect(Rect2(gx - 3, crown_y + 3, 6, 8), turq.darkened(0.2))
		draw_rect(Rect2(gx - 1.5, crown_y + 5, 3, 4), turq_l)

	# Plumas superiores (turquesa y rojo)
	for i in 7:
		var fx = -21.0 + float(i) * 7.0
		var fh = (28.0 + sin(anim_time * 1.5 + float(i) * 0.8) * 4.0) * sel_s
		var feather_col = turq.darkened(0.1) if i % 2 == 0 else Color(0.8, 0.2, 0.15)
		draw_line(Vector2(fx, crown_y - 10), Vector2(fx + sin(anim_time * 1.0 + float(i)) * 3.0, crown_y - 10 - fh), feather_col, 3.0)
		# Punta suave
		var tip_y = crown_y - 10 - fh
		draw_circle(Vector2(fx + sin(anim_time * 1.0 + float(i)) * 3.0, tip_y), 2.0, feather_col.lightened(0.2))

	# Disco frontal del tocado
	draw_circle(Vector2(0, crown_y + 5), 7, turq)
	draw_circle(Vector2(0, crown_y + 5), 4, turq_l)

	# Particulas de polvo de piedra
	for i in 4:
		var pa = anim_time * 1.2 + float(i) * 1.5
		var pp = Vector2(sin(pa) * 35, cos(pa * 0.5) * 20 + by)
		var dust_a = sin(anim_time * 2.0 + float(i)) * 0.06 + 0.08
		draw_circle(pp, 3.0, Color(0.5, 0.52, 0.48, dust_a))

	# Aura turquesa al seleccionar
	if is_selected:
		var aura_pulse = sin(select_time * 3.0) * 0.08 + 0.12
		draw_circle(Vector2(0, by - 10), 70 * sel_s, Color(turq.r, turq.g, turq.b, aura_pulse))
		# Glifos flotantes
		for i in 6:
			var ga = select_time * 1.5 + float(i) * TAU / 6.0
			var gr = 60.0 * sel_s
			var gx = cos(ga) * gr
			var gy = sin(ga) * gr * 0.5 + by - 20
			draw_rect(Rect2(gx - 3, gy - 3, 6, 6), Color(turq.r, turq.g, turq.b, 0.25))
