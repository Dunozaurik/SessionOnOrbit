class_name CodeLock
extends CanvasLayer

## Экран кодового замка: несколько цифр, каждая крутится кнопками «+» и «–».
## open("072") — открыть замок с правильным кодом. Сигналы: unlocked — код верный,
## code_entered(code) — введён неверный код (для пасхалок и подсказок), closed — экран закрыт.

signal unlocked
signal code_entered(code: String)
signal closed

const WRONG_REPLIES: Array[String] = [
	"Неверно. Попыток осталось: бесконечно много. Я не зверь.",
	"Неверно. Сейф тяжело вздохнул.",
	"Неверно. Но близко. (Нет.)",
	"Неверно. Сейф советует перечитать конспект. Если он у тебя есть.",
]

var _code := ""
var _digits: Array[int] = []
var _wrong_count := 0
var _digit_labels: Array[Label] = []

@onready var _row: HBoxContainer = %Digits
@onready var _status: Label = %Status


func _ready() -> void:
	hide()
	%OpenButton.pressed.connect(_on_open_pressed)
	%CloseButton.pressed.connect(close)


func open(code: String, title := "КОДОВЫЙ ЗАМОК") -> void:
	_code = code
	%Title.text = title
	_status.text = "Подбери цифры и нажми «Открыть»."
	_build_digits(code.length())
	show()
	GameState.input_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%OpenButton.grab_focus()


func close() -> void:
	if not visible:
		return
	hide()
	GameState.input_locked = false
	if not Dialogue.is_active():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


func _build_digits(count: int) -> void:
	if _digits.size() == count:
		return
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	_digits.clear()
	_digit_labels.clear()
	for i in count:
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 6)
		var up := Button.new()
		up.text = "+"
		up.custom_minimum_size = Vector2(80, 44)
		up.pressed.connect(_change.bind(i, 1))
		var label := Label.new()
		label.text = "0"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 64)
		label.add_theme_color_override("font_color", Color(1, 0.86, 0.45))
		var down := Button.new()
		down.text = "–"
		down.custom_minimum_size = Vector2(80, 44)
		down.pressed.connect(_change.bind(i, -1))
		column.add_child(up)
		column.add_child(label)
		column.add_child(down)
		_row.add_child(column)
		_digits.append(0)
		_digit_labels.append(label)


func _change(index: int, delta: int) -> void:
	_digits[index] = (_digits[index] + delta + 10) % 10
	_digit_labels[index].text = str(_digits[index])
	Sfx.play("blip", -6.0, 1.0 + _digits[index] * 0.05)


func _current_code() -> String:
	var code := ""
	for digit in _digits:
		code += str(digit)
	return code


func _on_open_pressed() -> void:
	var code := _current_code()
	if code == _code:
		Sfx.play("success")
		_status.text = "*щёлк*"
		unlocked.emit()
		return
	Sfx.play("denied", -4.0)
	_status.text = WRONG_REPLIES[_wrong_count % WRONG_REPLIES.size()]
	_wrong_count += 1
	# После стандартного ответа — чтобы отсек мог заменить его своим (пасхалки, подсказки).
	code_entered.emit(code)


func show_status(text: String) -> void:
	_status.text = text


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
