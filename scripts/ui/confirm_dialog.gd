extends Control

## Окно подтверждения («Точно выйти?»). Использование:
##   confirm.confirmed.connect(get_tree().quit)
##   confirm.ask("Заголовок", "Текст", "Да", "Нет")
## Esc или «Нет» закрывают окно. Фокус по умолчанию на «Нет», чтобы случайный Enter ничего не ломал.

signal confirmed
signal cancelled


func _ready() -> void:
	hide()
	%YesButton.pressed.connect(_on_yes)
	%NoButton.pressed.connect(_on_no)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		_on_no()
		get_viewport().set_input_as_handled()


func ask(title: String, text: String, yes_text := "Да", no_text := "Нет") -> void:
	%Title.text = title
	%Text.text = text
	%YesButton.text = yes_text
	%NoButton.text = no_text
	show()
	%NoButton.grab_focus()


func _on_yes() -> void:
	hide()
	confirmed.emit()


func _on_no() -> void:
	hide()
	cancelled.emit()
