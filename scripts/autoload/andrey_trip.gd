extends Node

## Глобальная часть сюжетки Андрея Лабонина (автозагрузка AndreyTrip).
## Сообщения в чат группы и полёт шаттла с Гатчины-4 идут, в каком бы отсеке
## ни был игрок. Атриум (andrey_storyline.gd) только показывает это состояние:
## табло, терминал связи и самого Андрея в доке.
##
## 1. WAITING — Андрей «едет», в чат приходят его сообщения, терминал рассказывает истории.
## 2. Выслушаны все истории — TRAVELLING: обратный отсчёт и репортаж из полёта в чате.
## 3. ARRIVED — Андрей на станции. Пасхалка «Невозможное возможно».

signal arrived

enum Stage { WAITING, TRAVELLING, ARRIVED }

const TRAVEL_TIME := 60.0
const CHAT_INTERVAL := Vector2(50.0, 90.0)
const FIRST_CHAT_DELAY := 15.0

## Работает только во время игры (не в главном меню).
var active := false
var stage := Stage.WAITING
var story_index := 0
var travel_left := 0.0

var _chat_index := 0
var _chat_timer := FIRST_CHAT_DELAY
var _travel_chat_index := 0
var _last_ending := -1


func reset() -> void:
	active = true
	stage = Stage.WAITING
	story_index = 0
	travel_left = 0.0
	_chat_index = 0
	_chat_timer = FIRST_CHAT_DELAY
	_travel_chat_index = 0
	_last_ending = -1


func _process(delta: float) -> void:
	if not active:
		return
	match stage:
		Stage.WAITING:
			_chat_timer -= delta
			if _chat_timer <= 0.0:
				_chat_timer = randf_range(CHAT_INTERVAL.x, CHAT_INTERVAL.y)
				GameState.post_chat(AndreyLines.NAME, AndreyLines.CHAT_WAITING[_chat_index])
				_chat_index = (_chat_index + 1) % AndreyLines.CHAT_WAITING.size()
		Stage.TRAVELLING:
			travel_left -= delta
			var travel_chat := AndreyLines.CHAT_TRAVELLING
			if _travel_chat_index < travel_chat.size() and travel_left <= travel_chat[_travel_chat_index][0]:
				GameState.post_chat(AndreyLines.NAME, travel_chat[_travel_chat_index][1])
				_travel_chat_index += 1
			if travel_left <= 0.0:
				_arrive()


## Реплики для терминала связи: следующая история Андрея.
func next_story_lines() -> Array:
	var lines: Array = [
		{"speaker": AndreyLines.SPEAKER, "text": AndreyLines.OPENER},
		{"speaker": AndreyLines.SPEAKER, "text": AndreyLines.STORIES[story_index]},
	]
	story_index += 1
	if story_index >= AndreyLines.STORIES.size():
		lines.append({"speaker": AndreyLines.SPEAKER, "text": AndreyLines.DEPARTURE, "call": depart})
	else:
		lines.append({"speaker": AndreyLines.SPEAKER, "text": _random_ending()})
	return lines


func depart() -> void:
	GameState.find_easter_egg("andrey_stories")
	stage = Stage.TRAVELLING
	travel_left = TRAVEL_TIME


func _random_ending() -> String:
	var index := randi() % AndreyLines.STORY_ENDINGS.size()
	if index == _last_ending:
		index = (index + 1) % AndreyLines.STORY_ENDINGS.size()
	_last_ending = index
	return AndreyLines.STORY_ENDINGS[index]


func _arrive() -> void:
	stage = Stage.ARRIVED
	Sfx.play("shuttle", -2.0)
	GameState.post_message(AndreyLines.ANNOUNCEMENT)
	GameState.find_easter_egg("andrey_arrived")
	arrived.emit()
