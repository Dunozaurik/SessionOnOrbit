extends Control

## Живой фон меню: градиент, туманности, мерцающие звёзды, планета с атмосферой и падающие звёзды.
## Всё рисуется кодом — внешних картинок нет.

const STAR_COUNT := 170

var _stars: Array[Dictionary] = []
var _time := 0.0
var _comet_timer := 2.5
var _comet := {}
var _city_lights: Array[Vector2] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 2057
	for i in STAR_COUNT:
		_stars.append({
			"pos": Vector2(_rng.randf(), _rng.randf() * 0.9),
			"size": _rng.randf_range(0.8, 2.6),
			"speed": _rng.randf_range(0.002, 0.012),
			"phase": _rng.randf() * TAU,
			"freq": _rng.randf_range(0.6, 2.2),
		})
	for i in 40:
		_city_lights.append(Vector2(_rng.randf_range(-0.55, 0.55), _rng.randf_range(0.02, 0.9)))


func _process(delta: float) -> void:
	_time += delta
	for star in _stars:
		var pos: Vector2 = star["pos"]
		pos.x -= star["speed"] * delta
		if pos.x < 0.0:
			pos.x += 1.0
		star["pos"] = pos
	_comet_timer -= delta
	if _comet_timer <= 0.0:
		_comet_timer = _rng.randf_range(5.0, 9.0)
		_comet = {
			"from": Vector2(_rng.randf_range(0.3, 0.9), _rng.randf_range(0.02, 0.3)),
			"age": 0.0,
		}
	if not _comet.is_empty():
		_comet["age"] += delta
		if _comet["age"] > 1.1:
			_comet = {}
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([Color(0.02, 0.03, 0.09), Color(0.02, 0.03, 0.09), Color(0.06, 0.09, 0.2), Color(0.06, 0.09, 0.2)]))
	_draw_nebula(Vector2(w * 0.2, h * 0.3), h * 0.55, Color(0.35, 0.2, 0.6, 0.05))
	_draw_nebula(Vector2(w * 0.8, h * 0.2), h * 0.5, Color(0.15, 0.4, 0.7, 0.05))

	for star in _stars:
		var pos: Vector2 = star["pos"]
		var twinkle := 0.45 + 0.55 * sin(_time * star["freq"] + star["phase"])
		draw_circle(Vector2(pos.x * w, pos.y * h), star["size"], Color(0.85, 0.92, 1.0, 0.25 + 0.7 * twinkle))

	_draw_planet(w, h)
	_draw_comet(w, h)


func _draw_nebula(center: Vector2, radius: float, color: Color) -> void:
	for i in 28:
		var k := 1.0 - i / 28.0
		_disc(center, radius * k, Color(color.r, color.g, color.b, color.a * 0.3), 72, true)


func _draw_planet(w: float, h: float) -> void:
	var radius := w * 0.85
	var center := Vector2(w * 0.5, h + radius - h * 0.17)
	# Атмосфера: ореол из полупрозрачных колец.
	for i in 14:
		_disc(center, radius + (14 - i) * 5.0, Color(0.3, 0.6, 1.0, 0.012 + i * 0.0025))
	_disc(center, radius + 4.0, Color(0.45, 0.75, 1.0, 0.55))
	_disc(center, radius, Color(0.2, 0.42, 0.78))
	# Тень: тёмный круг сдвинут вниз — освещённой остаётся тонкая дуга сверху.
	_disc(center + Vector2(26, 46), radius, Color(0.03, 0.06, 0.15))
	# Огни городов на ночной стороне.
	for light in _city_lights:
		var pos := Vector2(center.x + light.x * w, center.y - radius + 28.0 + light.y * h * 0.12)
		if pos.distance_to(center) < radius - 16.0:
			var blink := 0.5 + 0.5 * sin(_time * 1.3 + light.x * 40.0)
			draw_circle(pos, 1.6, Color(1.0, 0.85, 0.45, 0.35 + 0.5 * blink))


func _draw_comet(w: float, h: float) -> void:
	if _comet.is_empty():
		return
	var t: float = _comet["age"] / 1.1
	var start: Vector2 = Vector2(_comet["from"].x * w, _comet["from"].y * h)
	var dir := Vector2(-1.0, 0.45).normalized()
	var head := start + dir * t * w * 0.45
	for i in 18:
		var k := i / 18.0
		var tail := head - dir * k * 150.0
		draw_circle(tail, 2.4 * (1.0 - k), Color(0.9, 0.95, 1.0, (1.0 - k) * (1.0 - t) * 0.9))


## Гладкий диск: draw_circle у огромной планеты рисуется угловатым, поэтому полигон вручную.
## top_only — только верхняя половина (низ планеты всё равно за экраном).
func _disc(center: Vector2, radius: float, color: Color, segments := 240, full := false) -> void:
	var points := PackedVector2Array()
	var from := 0.0 if full else PI
	var span := TAU if full else PI
	for i in segments + 1:
		var angle := from + span * i / segments
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)
