class_name CheatSheet
extends Interactable

## Шпора — собираемый предмет. Текст показывается при подборе.

@export_multiline var text := ""


func _ready() -> void:
	interacted.connect(_on_picked)


func _on_picked(_player: Player) -> void:
	# Сначала выключаем, чтобы подсказка «[E] Подобрать» сразу исчезла.
	enabled = false
	GameState.collect_cheat_sheet(text)
	queue_free()
