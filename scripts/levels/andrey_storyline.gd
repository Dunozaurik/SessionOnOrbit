extends Node

## Сюжетная пасхалка про Андрея Лабонина.
##
## 1. Пока Андрей «едет», в чат группы (уведомление в углу экрана) приходят его сообщения,
##    а табло в доке показывает очередной абсурдный статус шаттла с Гатчины-4.
## 2. Терминал связи рассказывает его истории «вы не поверите, что произошло».
## 3. Выслушал все истории — Андрей выезжает, на табло обратный отсчёт, в чат — репортаж из полёта.
## 4. Шаттл прилетает, Андрей появляется в доке. Пасхалка «Невозможное возможно».

enum Stage { WAITING, TRAVELLING, ARRIVED }

const TRAVEL_TIME := 60.0
const BOARD_SWITCH_TIME := 20.0
const CHAT_INTERVAL := Vector2(50.0, 90.0)

@export var terminal: Interactable
@export var board: Label3D
@export var andrey: Npc
@export var dock_point: Node3D

var stage := Stage.WAITING
var _story_index := 0
var _chat_index := 0
var _board_timer := 0.0
var _board_status := 0
var _chat_timer := 15.0
var _travel_left := 0.0
var _travel_chat_index := 0
var _last_ending := -1


func _ready() -> void:
	terminal.interacted.connect(_on_terminal)
	andrey.interacted.connect(_on_andrey)
	andrey.set_present(false)
	_update_board()


func _process(delta: float) -> void:
	match stage:
		Stage.WAITING:
			_board_timer += delta
			if _board_timer >= BOARD_SWITCH_TIME:
				_board_timer = 0.0
				_board_status = (_board_status + 1) % AndreyLines.BOARD_STATUSES.size()
				_update_board()
			_chat_timer -= delta
			if _chat_timer <= 0.0:
				_chat_timer = randf_range(CHAT_INTERVAL.x, CHAT_INTERVAL.y)
				_post_chat()
		Stage.TRAVELLING:
			_travel_left -= delta
			_update_board()
			var travel_chat := AndreyLines.CHAT_TRAVELLING
			if _travel_chat_index < travel_chat.size() and _travel_left <= travel_chat[_travel_chat_index][0]:
				GameState.post_chat(AndreyLines.NAME, travel_chat[_travel_chat_index][1])
				_travel_chat_index += 1
			if _travel_left <= 0.0:
				_arrive()


func _post_chat() -> void:
	GameState.post_chat(AndreyLines.NAME, AndreyLines.CHAT_WAITING[_chat_index])
	_chat_index = (_chat_index + 1) % AndreyLines.CHAT_WAITING.size()


func _update_board() -> void:
	var status: String
	match stage:
		Stage.WAITING:
			status = AndreyLines.BOARD_STATUSES[_board_status]
		Stage.TRAVELLING:
			status = "ЛЕТИТ (?!)  ПРИБЫТИЕ ЧЕРЕЗ %d С" % ceili(_travel_left)
		Stage.ARRIVED:
			status = "ПРИБЫЛ. ЭТО НЕ ОШИБКА."
	board.text = "ШАТТЛ  ГАТЧИНА-4 — ОРБИТМЕХ\n" + status


func _on_terminal(_player: Player) -> void:
	match stage:
		Stage.WAITING:
			_tell_story()
		Stage.TRAVELLING:
			Dialogue.start([{"speaker": "Терминал связи", "text": AndreyLines.AFTER_DEPARTURE}])
		Stage.ARRIVED:
			Dialogue.start([{"speaker": "Терминал связи", "text": AndreyLines.AFTER_ARRIVAL}])


func _tell_story() -> void:
	var lines: Array = [
		{"speaker": AndreyLines.SPEAKER, "text": AndreyLines.OPENER},
		{"speaker": AndreyLines.SPEAKER, "text": AndreyLines.STORIES[_story_index]},
	]
	_story_index += 1
	if _story_index >= AndreyLines.STORIES.size():
		lines.append({"speaker": AndreyLines.SPEAKER, "text": AndreyLines.DEPARTURE, "call": _depart})
	else:
		lines.append({"speaker": AndreyLines.SPEAKER, "text": _random_ending()})
	Dialogue.start(lines)


func _random_ending() -> String:
	var index := randi() % AndreyLines.STORY_ENDINGS.size()
	if index == _last_ending:
		index = (index + 1) % AndreyLines.STORY_ENDINGS.size()
	_last_ending = index
	return AndreyLines.STORY_ENDINGS[index]


func _depart() -> void:
	GameState.find_easter_egg("andrey_stories")
	stage = Stage.TRAVELLING
	_travel_left = TRAVEL_TIME
	_update_board()


func _arrive() -> void:
	stage = Stage.ARRIVED
	_update_board()
	Sfx.play_at("shuttle", dock_point.global_position, 4.0)
	andrey.set_present(true)
	GameState.post_message(AndreyLines.ANNOUNCEMENT)
	GameState.find_easter_egg("andrey_arrived")


func _on_andrey(_player: Player) -> void:
	var speaker := andrey.display_name
	if GameState.flags.get("andrey_talked", false):
		Dialogue.start([{
			"speaker": speaker,
			"text": "Я тут подумал... а обратно-то как? Последний шаттл на Гатчину-4 ушёл в 2019-м.",
		}])
		return
	GameState.flags["andrey_talked"] = true
	Dialogue.start([
		{"speaker": speaker, "text": "...Пацаны."},
		{"speaker": speaker, "text": "Вы не поверите, что произошло."},
		{"speaker": speaker, "text": "Я ПРИЕХАЛ.", "choices": [
			["Как?!", [
				{"speaker": speaker, "text": "Сам не понял. Шаттл пришёл по расписанию, я сел, он полетел. Даже в парке не потерялся. Подозрительно, да?"},
			]],
			["Пары уже закончились.", [
				{"speaker": speaker, "text": "...Как закончились? Я же почти вовремя. Ну, в масштабах вселенной."},
			]],
			["Это точно ты, а не голограмма?", [
				{"speaker": speaker, "text": "Не знаю. Ущипни меня. Нет, не надо, у меня справка."},
			]],
			["Только пакеты из «Вкусно и точка» у кабинета не оставляй.", [
				{"speaker": speaker, "text": "Это было ОДИН раз! И вообще там ещё Ярик с Костей были! Почему всегда я?!"},
			]],
		]},
		{"speaker": speaker, "text": "Ладно, раз уж я здесь — отметьте меня. Пусть все видят."},
	])
