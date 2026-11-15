class_name SodaMachine
extends Node3D

## Автомат с газировкой из примитивов: синий корпус, подсвеченная вывеска, витрина с банками на полках,
## панель с кнопками и экранчиком, лоток выдачи. Лицом смотрит в +Z, начало координат — на полу в центре.

const WIDTH := 0.9
const HEIGHT := 2.0
const DEPTH := 0.8
const CAN_COLORS: Array[Color] = [
	Color(0.9, 0.15, 0.15), Color(0.2, 0.75, 0.3), Color(0.98, 0.78, 0.15), Color(0.95, 0.5, 0.1), Color(0.35, 0.6, 0.95),
]

@export var sign_text := "ГАЗИРОВКА"
@export var body_color := Color(0.12, 0.32, 0.78)


func _ready() -> void:
	var front := DEPTH * 0.5
	var body := _material(body_color, 0.0, 0.35, 0.45)
	var dark := _material(Color(0.08, 0.09, 0.12), 0.0, 0.5, 0.5)
	var white := _material(Color(0.95, 0.96, 1.0), 0.0, 0.1, 0.5)
	# Корпус, цоколь и белая полоса по бокам.
	_box("Body", Vector3(WIDTH, HEIGHT - 0.1, DEPTH), Vector3(0, 0.05 + (HEIGHT - 0.1) * 0.5, 0), body)
	_box("Plinth", Vector3(WIDTH + 0.04, 0.1, DEPTH + 0.04), Vector3(0, 0.05, 0), dark)
	_box("StripeL", Vector3(0.015, HEIGHT - 0.3, DEPTH * 0.7), Vector3(-WIDTH * 0.5 - 0.005, 1.05, 0.0), white)
	_box("StripeR", Vector3(0.015, HEIGHT - 0.3, DEPTH * 0.7), Vector3(WIDTH * 0.5 + 0.005, 1.05, 0.0), white)
	# Вывеска со светящимся фоном.
	var sign_glow := _material(Color(1.0, 0.85, 0.3), 1.6, 0.0, 0.4)
	_box("SignBack", Vector3(WIDTH - 0.06, 0.26, 0.05), Vector3(0, HEIGHT - 0.2, front + 0.005), sign_glow)
	var label := Label3D.new()
	label.name = "SignText"
	label.text = sign_text
	label.font_size = 54
	label.pixel_size = 0.0025
	label.modulate = Color(0.12, 0.2, 0.55)
	label.outline_size = 0
	label.position = Vector3(0, HEIGHT - 0.2, front + 0.034)
	add_child(label)
	# Витрина: тёмная рамка, подсвеченная задняя стенка, полки с банками.
	var window_center := Vector3(-0.11, 1.28, front)
	_box("WindowFrame", Vector3(0.64, 1.14, 0.04), window_center, dark)
	_box("WindowBack", Vector3(0.58, 1.08, 0.02), window_center + Vector3(0, 0, 0.015), _material(Color(0.75, 0.88, 1.0), 0.55, 0.0, 0.5))
	var shelf_heights := [0.84, 1.1, 1.36, 1.62]
	for shelf_index in shelf_heights.size():
		var y: float = shelf_heights[shelf_index]
		_box("Shelf", Vector3(0.58, 0.02, 0.1), Vector3(window_center.x, y - 0.075, front + 0.03), dark)
		for can_index in 5:
			var can_color: Color = CAN_COLORS[(shelf_index * 2 + can_index) % CAN_COLORS.size()]
			var can := MeshInstance3D.new()
			can.name = "Can"
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.04
			cylinder.bottom_radius = 0.04
			cylinder.height = 0.13
			cylinder.radial_segments = 10
			cylinder.material = _material(can_color, 0.0, 0.6, 0.35)
			can.mesh = cylinder
			can.position = Vector3(window_center.x - 0.22 + can_index * 0.11, y - 0.0, front + 0.03)
			add_child(can)
	# Стекло витрины — едва заметное, чтобы банки были видны.
	var glass := _material(Color(0.7, 0.85, 1.0, 0.12), 0.0, 0.0, 0.1)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_box("Glass", Vector3(0.58, 1.08, 0.01), window_center + Vector3(0, 0, 0.065), glass)
	# Панель справа: экранчик, кнопки, монетоприёмник.
	var panel_x := 0.33
	_box("Panel", Vector3(0.2, 0.9, 0.04), Vector3(panel_x, 1.28, front), dark)
	_box("Display", Vector3(0.15, 0.08, 0.012), Vector3(panel_x, 1.62, front + 0.026), _material(Color(0.2, 1.0, 0.5), 1.5, 0.0, 0.4))
	var button_colors: Array[Color] = [Color(0.9, 0.9, 0.95), Color(0.95, 0.4, 0.3), Color(0.4, 0.8, 0.5)]
	for row in 4:
		for col in 3:
			_box("Button", Vector3(0.036, 0.036, 0.014), Vector3(panel_x - 0.05 + col * 0.05, 1.48 - row * 0.06, front + 0.027), _material(button_colors[(row + col) % 3], 0.0, 0.2, 0.5))
	_box("CoinSlot", Vector3(0.1, 0.02, 0.014), Vector3(panel_x, 1.1, front + 0.027), _material(Color(0.7, 0.7, 0.75), 0.0, 0.8, 0.3))
	_box("CoinFace", Vector3(0.14, 0.14, 0.01), Vector3(panel_x, 1.0, front + 0.025), _material(Color(0.25, 0.27, 0.32), 0.0, 0.6, 0.4))
	# Лоток выдачи: тёмный проём с лёгким свечением и створка.
	_box("DispenserFrame", Vector3(0.62, 0.3, 0.05), Vector3(-0.05, 0.4, front), dark)
	_box("DispenserGap", Vector3(0.5, 0.2, 0.02), Vector3(-0.05, 0.4, front + 0.03), _material(Color(0.02, 0.03, 0.05), 0.0, 0.0, 0.8))
	var flap := _box("Flap", Vector3(0.5, 0.2, 0.012), Vector3(-0.05, 0.4, front + 0.045), _material(Color(0.35, 0.4, 0.5, 0.45), 0.0, 0.2, 0.3))
	(flap.mesh as BoxMesh).material.set("transparency", BaseMaterial3D.TRANSPARENCY_ALPHA)
	# Мягкий свет от автомата.
	var glow := OmniLight3D.new()
	glow.name = "Glow"
	glow.position = Vector3(0, 1.4, front + 0.5)
	glow.light_color = Color(0.7, 0.85, 1.0)
	glow.light_energy = 0.5
	glow.omni_range = 2.8
	add_child(glow)


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


func _material(color: Color, emission_energy := 0.0, metallic := 0.0, roughness := 0.6) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material
