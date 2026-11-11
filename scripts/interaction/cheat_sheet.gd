class_name CheatSheet
extends Interactable

## Шпора — собираемый предмет. Текст показывается при подборе.
## id нужен, чтобы подобранная шпора не появлялась снова при возвращении в отсек.

@export var id := ""
@export_multiline var text := ""


func _ready() -> void:
	if id in GameState.picked_cheat_sheets:
		queue_free()
		return
	interacted.connect(_on_picked)


func _on_picked(_player: Player) -> void:
	# Сначала выключаем, чтобы подсказка «[E] Подобрать» сразу исчезла.
	enabled = false
	GameState.collect_cheat_sheet(id, text)
	queue_free()
