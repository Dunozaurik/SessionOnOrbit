class_name SpaceSuitDisplay
extends Node3D

## Скафандр на стене в шкафчике: белый скафандр с шлемом, тёмным визором, нагрудным блоком с экранчиком и кнопками,
## оранжевыми полосами, ранцем и перчатками, а за ним — задняя панель шкафчика с оранжевой рамкой.
## Лицом смотрит в +Z, начало координат — на полу под скафандром (высота шкафчика 2 м, ширина 1 м).

const WIDTH := 1.0
const HEIGHT := 2.0
const DEPTH := 0.5

var _white: StandardMaterial3D
var _grey: StandardMaterial3D
var _orange: StandardMaterial3D
## Сам скафандр (без шкафчика): его прячем, пока скафандр надет на игроке.
var suit: Node3D
var _parent: Node3D


func _ready() -> void:
	_white = _material(Color(0.93, 0.95, 1.0), 0.0, 0.1, 0.55)
	_grey = _material(Color(0.42, 0.45, 0.55), 0.0, 0.5, 0.5)
	_orange = _material(Color(1.0, 0.58, 0.12), 0.0, 0.2, 0.5)
	var dark := _material(Color(0.07, 0.09, 0.14), 0.0, 0.5, 0.4)
	var front := DEPTH * 0.5
	_parent = self

	# Шкафчик: задняя панель, рамка с оранжевым кантом, подсвеченная ниша.
	_box("Back", Vector3(WIDTH, HEIGHT, 0.06), Vector3(0, HEIGHT * 0.5, -front + 0.03), dark)
	_box("FrameTop", Vector3(WIDTH, 0.08, DEPTH), Vector3(0, HEIGHT - 0.04, 0), _grey)
	_box("FrameBottom", Vector3(WIDTH, 0.1, DEPTH), Vector3(0, 0.05, 0), _grey)
	_box("FrameLeft", Vector3(0.08, HEIGHT, DEPTH), Vector3(-WIDTH * 0.5 + 0.04, HEIGHT * 0.5, 0), _grey)
	_box("FrameRight", Vector3(0.08, HEIGHT, DEPTH), Vector3(WIDTH * 0.5 - 0.04, HEIGHT * 0.5, 0), _grey)
	var glow := _material(Color(1.0, 0.62, 0.15), 1.4, 0.0, 0.5)
	_box("GlowLeft", Vector3(0.02, HEIGHT - 0.2, 0.02), Vector3(-WIDTH * 0.5 + 0.095, HEIGHT * 0.5, front - 0.02), glow)
	_box("GlowRight", Vector3(0.02, HEIGHT - 0.2, 0.02), Vector3(WIDTH * 0.5 - 0.095, HEIGHT * 0.5, front - 0.02), glow)
	_box("LightStrip", Vector3(WIDTH - 0.3, 0.04, 0.04), Vector3(0, HEIGHT - 0.14, front - 0.1), _material(Color(0.9, 0.95, 1.0), 2.0, 0.0, 0.5))

	# Дальше — сам скафандр, он лежит в отдельном узле.
	suit = Node3D.new()
	suit.name = "Suit"
	add_child(suit)
	_parent = suit

	# Крюк, на котором висит скафандр.
	_cyl("Hook", 0.02, 0.12, Vector3(0, 1.84, -0.1), _grey)

	# Ранец за спиной.
	_box("Backpack", Vector3(0.36, 0.5, 0.14), Vector3(0, 1.22, -0.13), _grey)
	_box("BackpackStripe", Vector3(0.32, 0.05, 0.145), Vector3(0, 1.1, -0.128), _orange)
	_cyl("Tank", 0.05, 0.36, Vector3(-0.1, 1.22, -0.21), _white)
	_cyl("Tank", 0.05, 0.36, Vector3(0.1, 1.22, -0.21), _white)

	# Туловище, нагрудный блок и пояс.
	_box("Torso", Vector3(0.44, 0.5, 0.24), Vector3(0, 1.22, 0), _white)
	_box("Chest", Vector3(0.26, 0.2, 0.05), Vector3(0, 1.28, 0.145), _grey)
	_box("ChestScreen", Vector3(0.14, 0.06, 0.012), Vector3(0, 1.32, 0.172), _material(Color(0.2, 1.0, 0.55), 1.6, 0.0, 0.4))
	var button_colors: Array[Color] = [Color(1.0, 0.3, 0.25), Color(1.0, 0.8, 0.2), Color(0.35, 0.65, 1.0)]
	for i in 3:
		_cyl("Button", 0.016, 0.014, Vector3(-0.07 + i * 0.07, 1.24, 0.174), _material(button_colors[i], 0.5, 0.0, 0.5)).rotation_degrees = Vector3(90, 0, 0)
	_box("Belt", Vector3(0.46, 0.07, 0.26), Vector3(0, 0.95, 0), _orange)

	# Шея и шлем с визором.
	_cyl("Neck", 0.09, 0.07, Vector3(0, 1.5, 0), _grey)
	_sphere("Helmet", 0.19, Vector3(0, 1.64, 0.0), _white)
	var visor := _sphere("Visor", 0.13, Vector3(0, 1.64, 0.1), _material(Color(0.1, 0.22, 0.5), 0.5, 0.8, 0.15, Color(0.2, 0.4, 0.9)))
	visor.scale = Vector3(1.0, 0.75, 0.55)
	_sphere("HelmetLamp", 0.025, Vector3(0.14, 1.72, 0.1), _material(Color(1.0, 0.95, 0.7), 2.5, 0.0, 0.3))

	# Руки: плечо, оранжевая манжета и перчатка.
	for side in [-1.0, 1.0]:
		var arm := _cyl("Arm", 0.065, 0.5, Vector3(0.3 * side, 1.18, 0), _white)
		arm.rotation_degrees = Vector3(0, 0, 8 * side)
		var cuff := _cyl("Cuff", 0.07, 0.07, Vector3(0.335 * side, 0.94, 0), _orange)
		cuff.rotation_degrees = Vector3(0, 0, 8 * side)
		_sphere("Glove", 0.07, Vector3(0.345 * side, 0.88, 0), _grey)
		_sphere("Shoulder", 0.085, Vector3(0.27 * side, 1.42, 0), _white)

	# Ноги и ботинки.
	for side in [-1.0, 1.0]:
		_cyl("Leg", 0.085, 0.62, Vector3(0.12 * side, 0.62, 0), _white)
		_cyl("Knee", 0.09, 0.07, Vector3(0.12 * side, 0.62, 0.01), _orange)
		_box("Boot", Vector3(0.15, 0.1, 0.24), Vector3(0.12 * side, 0.2, 0.04), _orange)

	# Подсветка шкафчика.
	_parent = self
	var lamp := OmniLight3D.new()
	lamp.name = "Glow"
	lamp.position = Vector3(0, 1.6, 0.6)
	lamp.light_color = Color(0.9, 0.95, 1.0)
	lamp.light_energy = 0.4
	lamp.omni_range = 2.4
	add_child(lamp)


func _box(part_name: String, size: Vector3, position_: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	instance.mesh = mesh
	instance.position = position_
	_parent.add_child(instance)
	return instance


func _cyl(part_name: String, radius: float, height: float, position_: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 14
	mesh.material = material
	instance.mesh = mesh
	instance.position = position_
	_parent.add_child(instance)
	return instance


func _sphere(part_name: String, radius: float, position_: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	mesh.material = material
	instance.mesh = mesh
	instance.position = position_
	_parent.add_child(instance)
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
