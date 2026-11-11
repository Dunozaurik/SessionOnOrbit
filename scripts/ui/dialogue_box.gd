extends CanvasLayer

## Окно диалогов (автозагрузка Dialogue).
##
## Диалог — массив реплик-словарей:
##   {"speaker": "Имя", "text": "Реплика"}
##   {"speaker": "Имя", "text": "Вопрос?", "choices": [["Ответ 1", [реплики...]], ["Ответ 2", [...]]]}
##   {"text": "...", "call": func(): ...}  — функция вызывается, когда реплика появляется
##
## Dialogue.start(lines) показывает окно, Dialogue.finished сообщает о закрытии.

signal started
signal finished

const CHARS_PER_SECOND := 50.0

var _queue: Array = []
var _current: Dictionary = {}
var _typing := false
var _char_progress := 0.0

@onready var _speaker: Label = %Speaker
@onready var _text: Label = %Text
@onready var _choices: VBoxContainer = %Choices
@onready var _hint: Label = %Hint


func _ready() -> void:
	hide()


func is_active() -> bool:
	return visible


func start(lines: Array) -> void:
	_queue = lines.duplicate()
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	started.emit()
	_next()


func _next() -> void:
	_clear_choices()
	if _queue.is_empty():
		_finish()
		return
	_current = _queue.pop_front()
	_speaker.text = _current.get("speaker", "")
	_speaker.visible = _speaker.text != ""
	_text.text = _current.get("text", "")
	_text.visible_characters = 0
	_char_progress = 0.0
	_typing = true
	_hint.hide()
	if _current.has("call"):
		_current["call"].call()


func _process(delta: float) -> void:
	if not _typing:
		return
	_char_progress += delta * CHARS_PER_SECOND
	var shown := int(_char_progress)
	if shown != _text.visible_characters:
		if shown % 3 == 0:
			Sfx.play("blip", -10.0, randf_range(0.9, 1.15))
		_text.visible_characters = shown
	if shown >= _text.get_total_character_count():
		_finish_typing()


func _finish_typing() -> void:
	_typing = false
	_text.visible_characters = -1
	if _current.has("choices"):
		for choice in _current["choices"]:
			var button := Button.new()
			button.text = choice[0]
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.pressed.connect(_on_choice.bind(choice[1]))
			_choices.add_child(button)
		_choices.get_child(0).grab_focus()
	else:
		_hint.show()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var advance: bool = event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") \
			or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not advance:
		return
	get_viewport().set_input_as_handled()
	if _typing:
		_finish_typing()
	elif not _current.has("choices"):
		_next()


func _on_choice(branch: Array) -> void:
	_queue = branch + _queue
	_next()


func _clear_choices() -> void:
	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()


func _finish() -> void:
	hide()
	_current = {}
	if not get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	finished.emit()
