class_name BoardFrame
extends Node3D

## Оформление доски или табло из примитивов. Стоит дочерним узлом объекта-доски: центр доски — в начале
## координат узла, лицевая сторона смотрит в +Z (поворачивай узел, если доска висит на другой стене).
##   CHALK  — классная доска: рама, лоток для мела и мелки (поверхность остаётся чисто зелёной);
##   SCREEN — светящееся табло: тёмная рама с оранжевым кантом, экран, цветная шапка и строки-«списки».

enum Style { CHALK, SCREEN }

## Размер самой доски (ширина, высота) в метрах.
@export var size := Vector2(4.4, 1.7)
@export var style := Style.CHALK
@export var frame_color := Color(0.45, 0.32, 0.2)
@export var accent_color := Color(1.0, 0.62, 0.15)
## SCREEN: цвет экрана, цвет шапки и число строк-заглушек под шапкой.
@export var screen_color := Color(0.05, 0.1, 0.22)
@export var header_color := Color(1.0, 0.55, 0.1)
@export var rows := 5
@export_range(0.05, 0.35) var header_fraction := 0.2
## Спрятать плоский «Mesh» родителя (старая коробка), если рамка рисует экран сама.
@export var hide_parent_mesh := false

const FRAME := 0.1
const DEPTH := 0.14


func _ready() -> void:
	if hide_parent_mesh:
		var old := get_parent().get_node_or_null("Mesh") as Node3D
		if old:
			old.visible = false
	_build_frame()
	if style == Style.CHALK:
		_build_chalk_extras()
	else:
		_build_screen()


func _build_frame() -> void:
	var color := frame_color
	var metal := 0.0
	if style == Style.SCREEN:
		color = frame_color
		metal = 0.6
	var material := _material(color, 0.0, metal, 0.5)
	var w := size.x
	var h := size.y
	_box("Top", Vector3(w + FRAME * 2.0, FRAME, DEPTH), Vector3(0, h * 0.5 + FRAME * 0.5, 0.02), material)
	_box("Bottom", Vector3(w + FRAME * 2.0, FRAME, DEPTH), Vector3(0, -h * 0.5 - FRAME * 0.5, 0.02), material)
	_box("Left", Vector3(FRAME, h, DEPTH), Vector3(-w * 0.5 - FRAME * 0.5, 0, 0.02), material)
	_box("Right", Vector3(FRAME, h, DEPTH), Vector3(w * 0.5 + FRAME * 0.5, 0, 0.02), material)
	# Угловые заклёпки.
	var rivet := _material(accent_color, 0.0, 0.7, 0.3)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var cylinder := _cylinder("Rivet", 0.025, 0.03, Vector3((w * 0.5 + FRAME * 0.5) * sx, (h * 0.5 + FRAME * 0.5) * sy, 0.1), rivet)
			cylinder.rotation_degrees = Vector3(90, 0, 0)


func _build_chalk_extras() -> void:
	var w := size.x
	var h := size.y
	var tray_material := _material(frame_color.darkened(0.15), 0.0, 0.2, 0.6)
	_box("Tray", Vector3(w * 0.92, 0.05, 0.18), Vector3(0, -h * 0.5 - FRAME - 0.01, 0.1), tray_material)
	_box("TrayLip", Vector3(w * 0.92, 0.07, 0.02), Vector3(0, -h * 0.5 - FRAME + 0.005, 0.2), tray_material)
	var chalk_colors: Array[Color] = [Color(0.96, 0.96, 0.92), Color(0.95, 0.55, 0.6), Color(0.98, 0.9, 0.4), Color(0.6, 0.85, 0.95)]
	for i in chalk_colors.size():
		var chalk := _cylinder("Chalk", 0.012, 0.09, Vector3(-w * 0.25 + i * 0.07, -h * 0.5 - FRAME + 0.03, 0.1), _material(chalk_colors[i], 0.0, 0.0, 0.9))
		chalk.rotation_degrees = Vector3(0, 20.0 * i, 90)


func _build_screen() -> void:
	var w := size.x
	var h := size.y
	var edge := _material(accent_color, 1.4, 0.0, 0.5)
	# Светящийся кант по периметру экрана.
	_box("EdgeTop", Vector3(w, 0.02, 0.03), Vector3(0, h * 0.5 - 0.01, 0.05), edge)
	_box("EdgeBottom", Vector3(w, 0.02, 0.03), Vector3(0, -h * 0.5 + 0.01, 0.05), edge)
	_box("EdgeLeft", Vector3(0.02, h, 0.03), Vector3(-w * 0.5 + 0.01, 0, 0.05), edge)
	_box("EdgeRight", Vector3(0.02, h, 0.03), Vector3(w * 0.5 - 0.01, 0, 0.05), edge)
	_box("Screen", Vector3(w - 0.04, h - 0.04, 0.03), Vector3(0, 0, 0.03), _material(screen_color, 0.9, 0.0, 0.3, screen_color))
	var header_height := h * header_fraction
	_box("Header", Vector3(w - 0.1, header_height, 0.015), Vector3(0, h * 0.5 - header_height * 0.5 - 0.05, 0.055), _material(header_color, 1.3, 0.0, 0.4, header_color))
	# Строки-заглушки под шапкой, как список в Moodle или расписании.
	var row_material := _material(Color(0.5, 0.75, 1.0), 0.8, 0.0, 0.4, Color(0.5, 0.75, 1.0))
	var area_top := h * 0.5 - header_height - 0.14
	var area_height := h - header_height - 0.28
	for i in rows:
		var row_width := (w - 0.3) * (0.95 if i % 3 == 0 else (0.7 if i % 3 == 1 else 0.82))
		var y := area_top - (i + 0.5) * (area_height / rows)
		_box("Row", Vector3(row_width, area_height / rows * 0.32, 0.01), Vector3(-(w - 0.3 - row_width) * 0.5, y, 0.052), row_material)


func _box(box_name: String, box_size: Vector3, position_: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = box_name
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh.material = material
	instance.mesh = mesh
	instance.position = position_
	add_child(instance)
	return instance


func _cylinder(cylinder_name: String, radius: float, height: float, position_: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = cylinder_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.material = material
	instance.mesh = mesh
	instance.position = position_
	add_child(instance)
	return instance


func _material(color: Color, emission_energy := 0.0, metallic := 0.0, roughness := 0.7, emission_color := Color.BLACK) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission_color if emission_color != Color.BLACK else color
		material.emission_energy_multiplier = emission_energy
	return material
