class_name Door
extends Interactable

## Дверь-шлюз в другой отсек. Табличка над дверью — title,
## огонёк зелёный, если открыто, и красный, если заперто.

const OPEN_COLOR := Color(0.3, 1, 0.45)
const LOCKED_COLOR := Color(1, 0.2, 0.15)

@export var title := "ОТСЕК"
@export_file("*.tscn") var target_scene := ""
## Имя маркера появления в целевой сцене.
@export var spawn_id := ""
@export var locked := false:
	set(value):
		locked = value
		if is_node_ready():
			_update_light()
@export_multiline var locked_message := "Закрыто."
## Предмет за этой дверью (id из GameState.SUBJECTS). Если задан, дверь открывается
## только когда до этого предмета дошла очередь — сессия сдаётся по порядку.
@export var subject_id := ""


func _ready() -> void:
	%Sign.text = title
	interacted.connect(_on_interacted)
	if not subject_id.is_empty():
		GameState.signatures_changed.connect(_update_subject_lock.unbind(2))
		_update_subject_lock()
	_update_light()


func _update_subject_lock() -> void:
	locked = not GameState.is_subject_open(subject_id)
	if locked:
		var current: Dictionary = GameState.SUBJECTS[GameState.current_subject_index()]
		locked_message = "Сюда пока рано: сессия сдаётся по порядку. Сначала — «%s» (%s, %s). Порядок — в зачётке по Tab." % [
			current["title"], current["teacher"], current["room"]]


func _update_light() -> void:
	var material := StandardMaterial3D.new()
	var color := LOCKED_COLOR if locked else OPEN_COLOR
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	%Light.material_override = material


func _on_interacted(_player: Player) -> void:
	if locked:
		Sfx.play("denied", -4.0)
		GameState.post_message(locked_message)
		return
	Sfx.play("door")
	Transition.go(target_scene, spawn_id)
