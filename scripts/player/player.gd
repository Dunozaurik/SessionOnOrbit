class_name Player
extends CharacterBody3D

## Игрок от первого лица: ходьба, бег, прыжок, обзор мышью и взаимодействие с объектами.

signal focus_changed(target: Interactable)

@export var walk_speed := 4.0
@export var sprint_speed := 7.0
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.002

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _focused: Interactable

@onready var _head: Node3D = $Head
@onready var _ray: RayCast3D = $Head/Camera3D/InteractRay


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_ray.add_exception(self)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_head.rotate_x(-event.relative.y * mouse_sensitivity)
		_head.rotation.x = clampf(_head.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))
	elif event is InputEventMouseButton and event.pressed:
		# После alt-tab мышь могла освободиться — клик возвращает захват.
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("interact") and _focused:
		_focused.interact(self)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()

	_update_focus()


func _update_focus() -> void:
	var target := _ray.get_collider() as Interactable
	if target and not target.enabled:
		target = null
	if target != _focused:
		_focused = target
		focus_changed.emit(_focused)
