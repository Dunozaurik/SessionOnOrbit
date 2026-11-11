class_name CodePuzzle
extends CanvasLayer

## Экран терминала с кодом: игрок кликает по строке, в которой ошибка.
## open({"output": "текст компилятора", "lines": [...], "correct": индекс строки})
##
## Кнопка «Да тут же всё верно!» есть на каждом этапе. Обычно компилятор на неё
## огрызается, но в тупиковом раунде ("correct": -1 — ошибки в строках нет)
## именно она засчитывает раунд. Клик по строке там показывает "dead_end_text".
##
## Сигнал solved — раунд пройден, closed — экран закрыт (в т. ч. по Esc).

signal solved
signal closed

const WRONG_LINES: Array[String] = [
	"Здесь ошибки нет. Компилятор смотрит на тебя с жалостью.",
	"Мимо. -1 к самооценке.",
	"Нет. Но ход мыслей интересный.",
	"Не здесь. Попробуй посмотреть внимательнее. Или выпить кофе.",
]

const ALL_CORRECT_REPLIES: Array[String] = [
	"Компилятор: «Вообще-то ошибка есть. Я на неё уже пять минут показываю.»",
	"Компилятор: «Всё верно — это когда я не горю красным. А я горю.»",
	"Компилятор: «Ага. И у тебя всё работало на твоей машине, да?»",
	"Компилятор: «Знаешь, сколько студентов мне это говорили? И где они теперь?»",
]

var _round: Dictionary = {}
var _wrong_count := 0
var _reply_count := 0

@onready var _output: Label = %Output
@onready var _lines: VBoxContainer = %Lines
@onready var _status: Label = %Status


func _ready() -> void:
	hide()
	%CloseButton.pressed.connect(close)
	%AllCorrectButton.pressed.connect(_on_all_correct_pressed)


func open(round_data: Dictionary) -> void:
	_round = round_data
	_wrong_count = 0
	_output.text = round_data.get("output", "")
	_status.text = round_data.get("hint", "Кликни по строке с ошибкой.")
	for child in _lines.get_children():
		_lines.remove_child(child)
		child.queue_free()
	var code: Array = round_data["lines"]
	for i in code.size():
		var button := Button.new()
		button.text = "%2d | %s" % [i + 1, code[i]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.flat = true
		button.add_theme_font_size_override("font_size", 19)
		button.add_theme_color_override("font_color", Color(0.75, 0.95, 0.8))
		button.pressed.connect(_on_line_pressed.bind(i))
		_lines.add_child(button)
	if not visible:
		show()
		GameState.input_locked = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	if not visible:
		return
	hide()
	GameState.input_locked = false
	if not Dialogue.is_active():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func _is_dead_end() -> bool:
	return _round.get("correct", -1) == -1


func _on_line_pressed(index: int) -> void:
	if _is_dead_end():
		Sfx.play("denied", -6.0)
		_status.text = _round.get("dead_end_text", "В строке %d всё правильно.") % (index + 1)
		return
	if index == _round["correct"]:
		Sfx.play("success")
		solved.emit()
		return
	Sfx.play("denied", -4.0)
	_status.text = WRONG_LINES[_wrong_count % WRONG_LINES.size()]
	_wrong_count += 1


func _on_all_correct_pressed() -> void:
	if _is_dead_end():
		solved.emit()
		return
	Sfx.play("denied", -4.0)
	_status.text = ALL_CORRECT_REPLIES[_reply_count % ALL_CORRECT_REPLIES.size()]
	_reply_count += 1
