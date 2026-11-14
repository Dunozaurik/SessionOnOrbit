class_name Furniture
extends StaticBody3D

## Стол или стул из набора Kenney. Коллизия остаётся в сцене, а вместо кубов ставится модель.
## station_style = true (по умолчанию) — космический стиль (Space Station Kit), иначе деревянная мебель (Furniture Kit).

enum Kind { DESK, CHAIR }

const MODELS := {
	Kind.DESK: {
		false: ["res://assets/models/furniture/table.glb", Vector3(1.8, 0.78, 0.8), false],
		true: ["res://assets/models/station/table-large.glb", Vector3(1.8, 0.78, 0.85), false],
	},
	Kind.CHAIR: {
		false: ["res://assets/models/furniture/chair.glb", Vector3(0.5, 0.95, 0.5), true],
		true: ["res://assets/models/station/chair.glb", Vector3(0.5, 0.95, 0.55), true],
	},
}

const COMPUTER_MODEL := "res://assets/models/station/computer-wide.glb"

@export var kind := Kind.DESK
@export var station_style := true
## true — на столе стоит компьютер (для столов, за которыми «сидят в Moodle»).
@export var with_computer := false


func _ready() -> void:
	var data: Array = MODELS[kind][station_style]
	var model := ModelProp.new()
	model.name = "Model"
	model.model_path = data[0]
	model.size = data[1]
	model.flip = data[2]
	add_child(model)
	if with_computer and kind == Kind.DESK:
		var computer := ModelProp.new()
		computer.name = "Computer"
		computer.model_path = COMPUTER_MODEL
		computer.size = Vector3(0.8, 0.5, 0.5)
		computer.position = Vector3(0, 0.78, -0.1)
		add_child(computer)
