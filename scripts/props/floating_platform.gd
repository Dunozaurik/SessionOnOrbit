extends AnimatableBody3D

## Летающий ящик-платформа в невесомости: покачивается вверх-вниз и, если задан
## travel, летает туда-сюда вдоль этого вектора. На нём можно стоять — он везёт игрока.
## drop() — гравитация вернулась, ящик падает на пол там, где летел.

@export var amplitude := 0.15
@export var speed := 1.2
@export var phase := 0.0
## Смещение от исходной точки до края пути (ящик ходит от -travel до +travel).
@export var travel := Vector3.ZERO
@export var travel_speed := 0.5
## Высота центра ящика, когда он лежит на полу.
@export var floor_height := 0.15

var _base := Vector3.ZERO
var _time := 0.0
var _floating := true


func _ready() -> void:
	_base = position


func _physics_process(delta: float) -> void:
	if not _floating:
		return
	_time += delta
	position = _base + travel * sin(_time * travel_speed + phase) \
			+ Vector3.UP * sin(_time * speed + phase) * amplitude


func drop(instant := false) -> void:
	_floating = false
	if instant:
		position.y = floor_height
		return
	var fall_time := sqrt(2.0 * maxf(position.y - floor_height, 0.01) / 9.8)
	create_tween().tween_property(self, "position:y", floor_height, fall_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
