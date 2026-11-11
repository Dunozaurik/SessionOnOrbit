extends Node3D

## Медленно вращает узел и покачивает его — для подбираемых предметов, чтобы бросались в глаза.

@export var speed := 1.5
@export var bob := 0.05

var _base_y := 0.0
var _time := 0.0


func _ready() -> void:
	_base_y = position.y


func _process(delta: float) -> void:
	_time += delta
	rotate_y(speed * delta)
	position.y = _base_y + sin(_time * 2.0) * bob
