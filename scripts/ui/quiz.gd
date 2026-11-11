class_name Quiz
extends CanvasLayer

## Экран теста «как в Moodle»: вопросы на время, ответы кнопками, результат в конце.
## start(вопросы, лимит_времени, проходной_балл). Вопрос — {"q": ..., "answers": [...]},
## первый ответ правильный (кнопки перемешиваются).
## Сигналы: finished(passed, score) — попытка завершена, closed — экран закрыт.

signal finished(passed: bool, score: int)
signal closed

## Moodle «загружается», а таймер уже идёт.
const LOADING_TIME := 2.0

var _all_questions: Array = []
var _questions: Array = []
var _per_try := 5
var _time_limit := 20.0
var _pass_score := 4

var _index := 0
var _score := 0
var _time_left := 0.0
var _loading := 0.0
var _running := false

@onready var _timer: Label = %Timer
@onready var _progress: Label = %Progress
@onready var _question: Label = %Question
@onready var _answers: VBoxContainer = %Answers
@onready var _result: Label = %Result
@onready var _retry: Button = %RetryButton


func _ready() -> void:
	hide()
	_retry.pressed.connect(_begin)
	%ExitButton.pressed.connect(close)


func start(questions: Array, per_try: int, time_limit: float, pass_score: int) -> void:
	_all_questions = questions
	_per_try = mini(per_try, questions.size())
	_time_limit = time_limit
	_pass_score = pass_score
	show()
	GameState.input_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_begin()


func close() -> void:
	if not visible:
		return
	_running = false
	hide()
	GameState.input_locked = false
	if not Dialogue.is_active():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


func _begin() -> void:
	var pool := _all_questions.duplicate()
	pool.shuffle()
	_questions = pool.slice(0, _per_try)
	_index = 0
	_score = 0
	_time_left = _time_limit
	_loading = LOADING_TIME
	_running = true
	_result.hide()
	_retry.hide()
	_answers.show()
	_clear_answers()
	_progress.text = ""
	_question.text = "Moodle загружается...\n(таймер уже идёт)"
	_update_timer()


func _process(delta: float) -> void:
	if not _running:
		return
	_time_left -= delta
	_update_timer()
	if _loading > 0.0:
		_loading -= delta
		if _loading <= 0.0:
			_show_question()
	if _time_left <= 0.0:
		_finish(true)


func _update_timer() -> void:
	_timer.text = "Осталось: %.1f с" % maxf(_time_left, 0.0)
	_timer.modulate = Color(1, 0.35, 0.3) if _time_left < 5.0 else Color.WHITE


func _show_question() -> void:
	_clear_answers()
	var question: Dictionary = _questions[_index]
	_progress.text = "Вопрос %d из %d" % [_index + 1, _questions.size()]
	_question.text = question["q"]
	var answers: Array = question["answers"]
	var order := range(answers.size())
	order.shuffle()
	for i in order:
		var button := Button.new()
		button.text = answers[i]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 40)
		button.pressed.connect(_on_answer.bind(i == 0))
		_answers.add_child(button)


func _on_answer(correct: bool) -> void:
	if not _running:
		return
	if correct:
		_score += 1
	Sfx.play("blip", -4.0)
	_index += 1
	if _index >= _questions.size():
		_finish(false)
	else:
		_show_question()


func _finish(timed_out: bool) -> void:
	_running = false
	_clear_answers()
	_answers.hide()
	var passed := _score >= _pass_score
	_progress.text = "Попытка завершена"
	_question.text = ""
	var text := "Правильных ответов: %d из %d.\nОценка: %s" % [_score, _questions.size(), "ЗАЧЁТ" if passed else "НЕЗАЧЁТ"]
	if timed_out:
		text += "\nВремя вышло. Как и всегда."
	if not passed:
		text += "\nПересдача доступна немедленно. Как и в жизни — бесконечно."
	_result.text = text
	_result.modulate = Color(0.5, 1, 0.6) if passed else Color(1, 0.55, 0.5)
	_result.show()
	_retry.visible = not passed
	Sfx.play("success" if passed else "denied")
	finished.emit(passed, _score)


func _clear_answers() -> void:
	for child in _answers.get_children():
		_answers.remove_child(child)
		child.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
