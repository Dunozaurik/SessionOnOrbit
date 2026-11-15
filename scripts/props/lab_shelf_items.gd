class_name LabShelfItems
extends Node3D

## Содержимое шкафа с приборами: на трёх полках стоят осциллограф, маятник Фуко, банка «НЕ ОТКРЫВАТЬ (электроны)»,
## колбы, линейки, книги и ящик. Всё из примитивов. Узел ставится в центр шкафа, лицом (передом) в +Z,
## ширина полок — вдоль X. shelf_heights — высоты досок над полом шкафа (м, от низа шкафа).

@export var shelf_heights: Array[float] = [0.32, 0.89, 1.44]
@export var width := 1.35
## Высота низа шкафа относительно начала координат узла (узел стоит в центре по высоте).
@export var floor_offset := -1.0


func _ready() -> void:
	var top := floor_offset + shelf_heights[2] + 0.03
	var middle := floor_offset + shelf_heights[1] + 0.03
	var bottom := floor_offset + shelf_heights[0] + 0.03
	_oscilloscope(Vector3(-0.38, top, 0.0))
	_pendulum(Vector3(0.28, top, 0.0))
	_jar(Vector3(0.58, top, 0.0))
	_flask(Vector3(-0.55, middle, 0.0), Color(0.3, 0.9, 0.5), 0.09)
	_flask(Vector3(-0.38, middle, 0.0), Color(0.75, 0.4, 0.95), 0.07)
	_flask(Vector3(-0.22, middle, 0.0), Color(0.3, 0.7, 1.0), 0.06)
	_rulers(Vector3(0.1, middle, 0.0))
	_books(Vector3(0.52, middle, 0.0))
	_crate(Vector3(-0.35, bottom, 0.0), Vector3(0.5, 0.26, 0.28), Color(0.55, 0.38, 0.22))
	_crate(Vector3(0.2, bottom, 0.0), Vector3(0.4, 0.2, 0.28), Color(0.4, 0.45, 0.55))
	_spheres(Vector3(0.58, bottom, 0.0))


func _oscilloscope(base: Vector3) -> void:
	_box(base + Vector3(0, 0.15, 0), Vector3(0.42, 0.3, 0.28), _mat(Color(0.2, 0.22, 0.28), 0.0, 0.5))
	_box(base + Vector3(-0.06, 0.17, 0.145), Vector3(0.24, 0.18, 0.01), _mat(Color(0.05, 0.25, 0.1), 1.6, 0.0, Color(0.2, 1.0, 0.45)))
	for i in 3:
		var knob := _cyl(base + Vector3(0.13, 0.08 + i * 0.07, 0.15), 0.02, 0.03, _mat(Color(0.85, 0.85, 0.9), 0.0, 0.8))
		knob.rotation_degrees = Vector3(90, 0, 0)


func _pendulum(base: Vector3) -> void:
	var metal := _mat(Color(0.6, 0.62, 0.7), 0.0, 0.8)
	_cyl(base + Vector3(0, 0.02, 0), 0.1, 0.04, _mat(Color(0.2, 0.2, 0.25), 0.0, 0.5))
	_cyl(base + Vector3(-0.07, 0.25, 0), 0.012, 0.46, metal)
	var arm := _cyl(base + Vector3(0.0, 0.47, 0), 0.01, 0.16, metal)
	arm.rotation_degrees = Vector3(0, 0, 90)
	_cyl(base + Vector3(0.05, 0.33, 0), 0.004, 0.28, _mat(Color(0.9, 0.9, 0.9)))
	_sphere(base + Vector3(0.05, 0.16, 0), 0.05, _mat(Color(1.0, 0.8, 0.25), 0.0, 0.9, Color.BLACK, 0.2))


func _jar(base: Vector3) -> void:
	var glass := _mat(Color(0.6, 0.9, 0.8, 0.45), 0.0, 0.0, Color.BLACK, 0.1)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cyl(base + Vector3(0, 0.12, 0), 0.08, 0.24, glass)
	_cyl(base + Vector3(0, 0.255, 0), 0.085, 0.03, _mat(Color(0.8, 0.2, 0.2), 0.0, 0.3))
	# Внутри «электроны» — светящиеся шарики.
	var glow := _mat(Color(0.4, 1.0, 0.9), 2.0, 0.0, Color(0.4, 1.0, 0.9))
	for i in 5:
		_sphere(base + Vector3(sin(i * 2.4) * 0.04, 0.05 + i * 0.035, cos(i * 2.4) * 0.04), 0.015, glow)
	var label := Label3D.new()
	label.text = "НЕ\nОТКРЫВАТЬ"
	label.font_size = 26
	label.pixel_size = 0.0016
	label.modulate = Color(0.9, 0.1, 0.1)
	label.outline_size = 0
	label.position = base + Vector3(0, 0.12, 0.082)
	add_child(label)


func _flask(base: Vector3, color: Color, radius: float) -> void:
	var glass := _mat(Color(color.r, color.g, color.b, 0.6), 0.6, 0.0, color, 0.15)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_sphere(base + Vector3(0, radius, 0), radius, glass)
	_cyl(base + Vector3(0, radius * 2.0 + 0.04, 0), radius * 0.28, 0.1, glass)


func _rulers(base: Vector3) -> void:
	var colors: Array[Color] = [Color(0.95, 0.8, 0.3), Color(0.9, 0.9, 0.95), Color(0.5, 0.75, 0.95)]
	for i in colors.size():
		var ruler := _box(base + Vector3(-0.08 + i * 0.08, 0.2, 0.0), Vector3(0.025, 0.4, 0.01), _mat(colors[i], 0.0, 0.2))
		ruler.rotation_degrees = Vector3(0, 0, -8 + i * 8)


func _books(base: Vector3) -> void:
	var colors: Array[Color] = [Color(0.7, 0.2, 0.2), Color(0.2, 0.4, 0.7), Color(0.85, 0.7, 0.2), Color(0.25, 0.55, 0.35)]
	for i in colors.size():
		_box(base + Vector3(-0.1 + i * 0.055, 0.14 + (i % 2) * 0.01, 0.0), Vector3(0.045, 0.28 - (i % 2) * 0.03, 0.2), _mat(colors[i], 0.0, 0.2))


func _crate(base: Vector3, size: Vector3, color: Color) -> void:
	_box(base + Vector3(0, size.y * 0.5, 0), size, _mat(color, 0.0, 0.2))
	_box(base + Vector3(0, size.y * 0.5, size.z * 0.5 + 0.003), Vector3(size.x * 0.7, 0.04, 0.006), _mat(Color(0.95, 0.85, 0.3), 0.8, 0.0, Color(0.95, 0.85, 0.3)))


func _spheres(base: Vector3) -> void:
	var colors: Array[Color] = [Color(0.95, 0.4, 0.4), Color(0.4, 0.8, 0.95), Color(0.95, 0.9, 0.4)]
	for i in colors.size():
		_sphere(base + Vector3(-0.1 + i * 0.1, 0.05, 0.0), 0.05, _mat(colors[i], 0.0, 0.4))


func _box(position_: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	instance.mesh = mesh
	instance.position = position_
	add_child(instance)
	return instance


func _cyl(position_: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.material = material
	instance.mesh = mesh
	instance.position = position_
	add_child(instance)
	return instance


func _sphere(position_: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 14
	mesh.rings = 7
	mesh.material = material
	instance.mesh = mesh
	instance.position = position_
	add_child(instance)
	return instance


func _mat(color: Color, emission_energy := 0.0, metallic := 0.0, emission_color := Color.BLACK, roughness := 0.6) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission_color if emission_color != Color.BLACK else color
		material.emission_energy_multiplier = emission_energy
	return material
