extends RigidBody3D

## Предмет в невесомости: медленно дрейфует и вращается, отскакивая от стен.
## restore_gravity() — гравитация вернулась, предмет падает по-настоящему.

@export var drift := 0.3
@export var spin := 0.6


func _ready() -> void:
	if GameState.flags.get("physics_fixed", false):
		return
	gravity_scale = 0.0
	linear_velocity = Vector3(randf_range(-1, 1), randf_range(-0.5, 0.5), randf_range(-1, 1)).normalized() * drift
	angular_velocity = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * spin


func restore_gravity() -> void:
	gravity_scale = 1.0
	sleeping = false
