# Combos ordered by priority (longest/strongest first)
static var combos = [
	{"name": "Golpe Fuerte", "orbs": ["red", "red", "red"], "damage": 30, "stun": 0.0, "duration": 0.5},
	{"name": "Ataque Especial", "orbs": ["red", "blue"], "damage": 20, "stun": 0.5, "duration": 0.45},
	{"name": "Golpe Rapido", "orbs": ["red", "red"], "damage": 15, "stun": 0.0, "duration": 0.3},
	{"name": "Stun Corto", "orbs": ["blue", "blue"], "damage": 5, "stun": 0.7, "duration": 0.35},
	{"name": "Golpe", "orbs": ["red"], "damage": 8, "stun": 0.0, "duration": 0.25},
	{"name": "Toque Frio", "orbs": ["blue"], "damage": 3, "stun": 0.35, "duration": 0.25},
]


static func get_best_combo(player_orbs: Array) -> Dictionary:
	for combo in combos:
		if _has_orbs(player_orbs, combo.orbs):
			return combo
	return {}


static func _has_orbs(available: Array, needed: Array) -> bool:
	var pool = available.duplicate()
	for orb in needed:
		var idx = pool.find(orb)
		if idx == -1:
			return false
		pool.remove_at(idx)
	return true
