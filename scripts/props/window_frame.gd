class_name WindowFrame
extends Node3D

## Рама для окна в космос: берёт размеры и положение CSG-коробки окна и строит вокруг неё
## широкую металлическую раму, перекладины-средники, подоконник и огоньки по периметру.
## Узел кладётся в корень уровня без поворота (координаты — как у окна).

@export var window_path: NodePath = ^"../Geometry/Window"
@export var frame_width := 0.18
## Расстояние между вертикальными средниками (м).
@export var mullion_spacing := 1.5
@export var frame_color := Color(0.45, 0.48, 0.62)
@export var accent_color := Color(1.0, 0.62, 0.15)

var _window: CSGBox3D


func _ready() -> void:
	_window = get_node_or_null(window_path) as CSGBox3D
	if _window == null:
		push_warning("WindowFrame: не найдено окно %s" % window_path)
		return
	var window_size := _window.size
	# Окно тонкое по одной из осей X/Z: вдоль другой оно «широкое».
	var along_x := window_size.x > window_size.z
	var width := window_size.x if along_x else window_size.z
	var height := window_size.y
	var center := _window.global_position
	var metal := _material(frame_color, 0.0, 0.6, 0.4)
	var accent := _material(accent_color, 1.4, 0.0, 0.4)
	var dark := _material(frame_color.darkened(0.35), 0.0, 0.7, 0.4)
	# Рама: верх, низ, лево, право. Глубина захватывает панели стены за стеклом.
	var depth := 0.3
	# Сторона стены: окно стоит в плоскости чуть впереди панелей, поэтому рама уходит вглубь стены.
	var back := _wall_direction(center, along_x)
	_add_part("Top", metal, center + Vector3(0, height * 0.5 + frame_width * 0.5, 0), width + frame_width * 2.0, frame_width, depth, along_x, back)
	_add_part("Bottom", metal, center + Vector3(0, -height * 0.5 - frame_width * 0.5, 0), width + frame_width * 2.0, frame_width, depth, along_x, back)
	var side_offset := (width * 0.5 + frame_width * 0.5)
	_add_part("Left", metal, center + _along(-side_offset, along_x), frame_width, height, depth, along_x, back)
	_add_part("Right", metal, center + _along(side_offset, along_x), frame_width, height, depth, along_x, back)
	# Средники.
	var count := maxi(0, roundi(width / mullion_spacing) - 1)
	for i in count:
		var offset := -width * 0.5 + (i + 1) * width / (count + 1)
		_add_part("Mullion", dark, center + _along(offset, along_x), 0.06, height, 0.12, along_x, back)
	# Подоконник и светящийся кант на нём.
	_add_part("Sill", metal, center + Vector3(0, -height * 0.5 - frame_width - 0.03, 0) + back * -0.08, width + frame_width * 2.0 + 0.3, 0.06, 0.34, along_x, back)
	_add_part("SillGlow", accent, center + Vector3(0, -height * 0.5 - frame_width - 0.005, 0) + back * -0.22, width + frame_width * 2.0 + 0.2, 0.02, 0.03, along_x, back)
	# Огоньки по верхней раме.
	var lights := maxi(3, roundi(width / 0.8))
	for i in lights:
		var offset := -width * 0.5 + (i + 0.5) * width / lights
		var lamp := MeshInstance3D.new()
		lamp.name = "Lamp"
		var sphere := SphereMesh.new()
		sphere.radius = 0.03
		sphere.height = 0.06
		sphere.material = accent
		lamp.mesh = sphere
		lamp.global_position = center + _along(offset, along_x) + Vector3(0, height * 0.5 + frame_width * 0.5, 0) + back * -0.1
		add_child(lamp)


## Вектор от окна «вглубь стены»: окно смотрит в комнату, стена — с противоположной стороны.
func _wall_direction(center: Vector3, along_x: bool) -> Vector3:
	# Комната лежит ближе к началу координат, чем её стены.
	if along_x:
		return Vector3(0, 0, signf(center.z) if absf(center.z) > 0.01 else 1.0)
	return Vector3(signf(center.x) if absf(center.x) > 0.01 else 1.0, 0, 0)


func _along(offset: float, along_x: bool) -> Vector3:
	return Vector3(offset, 0, 0) if along_x else Vector3(0, 0, offset)


func _add_part(part_name: String, material: Material, position_: Vector3, width: float, height: float, depth: float, along_x: bool, back: Vector3) -> void:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	var mesh := BoxMesh.new()
	# width — вдоль окна, depth — вглубь стены.
	mesh.size = Vector3(width, height, depth) if along_x else Vector3(depth, height, width)
	mesh.material = material
	instance.mesh = mesh
	add_child(instance)
	instance.global_position = position_ + back * (depth * 0.5 - 0.05)


func _material(color: Color, emission_energy := 0.0, metallic := 0.0, roughness := 0.7) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material
