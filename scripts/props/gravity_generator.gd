class_name GravityGenerator
extends Node3D

## Внешний вид генератора гравитации из примитивов: корпус с оранжевыми стойками, светящееся ядро с вращающимся
## кольцом, три гнезда предохранителей, вентиляция и кабели до потолка. Сломан — ядро и гнёзда красные;
## когда вставлены предохранители, гнёзда загораются зелёным по очереди, а ядро становится бирюзовым.
## Лицом смотрит в +Z, начало координат — в центре корпуса (корпус 2,2 × 2,2 × 1 м).

const BODY := Vector3(2.2, 2.2, 1.0)
const BROKEN_COLOR := Color(1.0, 0.18, 0.1)
const FIXED_COLOR := Color(0.2, 1.0, 0.65)
const SOCKET_X: Array[float] = [-0.6, 0.0, 0.6]

## Высота потолка комнаты над центром корпуса: кабели тянутся до него.
@export var ceiling_height := 8.4

var _core_material: StandardMaterial3D
var _ring_material: StandardMaterial3D
var _sockets: Array[StandardMaterial3D] = []
var _light: OmniLight3D
var _ring: Node3D
var _fixed := false


func _ready() -> void:
	var metal := _material(Color(0.14, 0.16, 0.24), 0.0, 0.6, 0.4)
	var orange := _material(Color(0.95, 0.58, 0.12), 0.0, 0.5, 0.4)
	var dark := _material(Color(0.07, 0.08, 0.11), 0.0, 0.6, 0.5)
	_box("Body", BODY, Vector3.ZERO, metal)
	_box("Base", Vector3(2.4, 0.16, 1.2), Vector3(0, -BODY.y * 0.5 + 0.08, 0), dark)
	_box("Cap", Vector3(2.3, 0.14, 1.1), Vector3(0, BODY.y * 0.5 + 0.03, 0), orange)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box("Pillar", Vector3(0.14, BODY.y, 0.14), Vector3(BODY.x * 0.5 * sx, 0, BODY.z * 0.5 * sz), orange)
	# Ядро и кольцо.
	_core_material = _material(Color(0.1, 0.02, 0.02), 2.2, 0.0, 0.3, BROKEN_COLOR)
	var core := _cylinder("Core", 0.5, 0.2, Vector3(0, 0.35, BODY.z * 0.5 + 0.02), _core_material)
	core.rotation_degrees = Vector3(90, 0, 0)
	_ring_material = _material(Color(0.25, 0.27, 0.35), 0.6, 0.7, 0.3, BROKEN_COLOR)
	_ring = Node3D.new()
	_ring.name = "Ring"
	_ring.position = Vector3(0, 0.35, BODY.z * 0.5 + 0.06)
	add_child(_ring)
	var torus_mesh := TorusMesh.new()
	torus_mesh.inner_radius = 0.58
	torus_mesh.outer_radius = 0.7
	torus_mesh.material = _ring_material
	var torus := MeshInstance3D.new()
	torus.name = "Torus"
	torus.mesh = torus_mesh
	torus.rotation_degrees = Vector3(90, 0, 0)
	_ring.add_child(torus)
	# Зубцы на кольце, чтобы было видно вращение.
	for i in 6:
		var tooth := MeshInstance3D.new()
		tooth.name = "Tooth"
		var tooth_mesh := BoxMesh.new()
		tooth_mesh.size = Vector3(0.1, 0.1, 0.1)
		tooth_mesh.material = orange
		tooth.mesh = tooth_mesh
		var angle := TAU * i / 6.0
		tooth.position = Vector3(cos(angle) * 0.74, sin(angle) * 0.74, 0)
		tooth.rotation.z = angle
		_ring.add_child(tooth)
	# Гнёзда предохранителей.
	for i in SOCKET_X.size():
		_box("SocketHousing", Vector3(0.42, 0.42, 0.08), Vector3(SOCKET_X[i], -0.62, BODY.z * 0.5 + 0.02), dark)
		var lamp_material := _material(Color(0.3, 0.05, 0.05), 1.8, 0.0, 0.4, BROKEN_COLOR)
		_sockets.append(lamp_material)
		_box("SocketLamp", Vector3(0.28, 0.28, 0.05), Vector3(SOCKET_X[i], -0.62, BODY.z * 0.5 + 0.075), lamp_material)
	# Вентиляция по бокам.
	for side in [-1.0, 1.0]:
		for i in 5:
			_box("Vent", Vector3(0.34, 0.05, 0.02), Vector3(0.82 * side, 0.1 + i * 0.13, BODY.z * 0.5 + 0.012), dark)
	# Кабели вверх до потолка, с оранжевыми муфтами.
	for x in [-0.7, 0.7]:
		var height := ceiling_height - BODY.y * 0.5
		_cylinder("Pipe", 0.06, height, Vector3(x, BODY.y * 0.5 + height * 0.5, -0.2), dark)
		for i in 5:
			_cylinder("Coupling", 0.085, 0.12, Vector3(x, BODY.y * 0.5 + 0.8 + i * (height - 1.0) / 4.0, -0.2), orange)
	_light = OmniLight3D.new()
	_light.name = "Glow"
	_light.position = Vector3(0, 0.35, BODY.z * 0.5 + 0.9)
	_light.light_color = BROKEN_COLOR
	_light.light_energy = 1.2
	_light.omni_range = 4.0
	add_child(_light)


func _process(delta: float) -> void:
	if _ring:
		_ring.rotate_z(delta * (0.5 if _fixed else 2.2))


## Зажечь гнездо (0, 1 или 2) зелёным.
func light_socket(index: int) -> void:
	if index < 0 or index >= _sockets.size():
		return
	var material := _sockets[index]
	material.albedo_color = Color(0.05, 0.3, 0.12)
	material.emission = FIXED_COLOR


## Генератор починен: все гнёзда зелёные, ядро и кольцо бирюзовые, вращение замедляется.
func set_fixed(fixed: bool) -> void:
	_fixed = fixed
	var color := FIXED_COLOR if fixed else BROKEN_COLOR
	for i in _sockets.size():
		if fixed:
			light_socket(i)
	if _core_material:
		_core_material.emission = color
		_core_material.albedo_color = Color(0.02, 0.15, 0.1) if fixed else Color(0.1, 0.02, 0.02)
	if _ring_material:
		_ring_material.emission = color
	if _light:
		_light.light_color = color


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
	mesh.radial_segments = 16
	mesh.material = material
	instance.mesh = mesh
	instance.position = position_
	add_child(instance)
	return instance


func _material(color: Color, emission_energy := 0.0, metallic := 0.0, roughness := 0.6, emission_color := Color.BLACK) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission_color if emission_color != Color.BLACK else color
		material.emission_energy_multiplier = emission_energy
	return material
