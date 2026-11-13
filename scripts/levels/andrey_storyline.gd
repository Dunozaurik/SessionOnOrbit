extends Node

## Сюжетка Андрея Лабонина в атриуме: табло в доке, терминал связи с Гатчиной-4
## и сам Андрей, когда долетит. Само состояние (истории, полёт, чат) — в AndreyTrip.

const BOARD_SWITCH_TIME := 20.0

@export var terminal: Interactable
@export var board: Label3D
@export var andrey: Npc

var _board_timer := 0.0
var _board_status := 0


func _ready() -> void:
	terminal.interacted.connect(_on_terminal)
	andrey.interacted.connect(_on_andrey)
	andrey.set_present(AndreyTrip.stage == AndreyTrip.Stage.ARRIVED)
	AndreyTrip.arrived.connect(_on_arrived)
	_update_board()


func _process(delta: float) -> void:
	match AndreyTrip.stage:
		AndreyTrip.Stage.WAITING:
			_board_timer += delta
			if _board_timer >= BOARD_SWITCH_TIME:
				_board_timer = 0.0
				_board_status = (_board_status + 1) % AndreyLines.BOARD_STATUSES.size()
				_update_board()
		AndreyTrip.Stage.TRAVELLING:
			_update_board()


func _update_board() -> void:
	var status: String
	match AndreyTrip.stage:
		AndreyTrip.Stage.WAITING:
			status = AndreyLines.BOARD_STATUSES[_board_status]
		AndreyTrip.Stage.TRAVELLING:
			status = "ЛЕТИТ (?!)  ПРИБЫТИЕ ЧЕРЕЗ %d С" % ceili(AndreyTrip.travel_left)
		AndreyTrip.Stage.ARRIVED:
			status = "ПРИБЫЛ. ЭТО НЕ ОШИБКА."
	board.text = "ШАТТЛ  ГАТЧИНА-4 — ОРБИТМЕХ\n" + status


func _on_arrived() -> void:
	_update_board()
	andrey.set_present(true)


func _on_terminal(_player: Player) -> void:
	match AndreyTrip.stage:
		AndreyTrip.Stage.WAITING:
			Dialogue.start(AndreyTrip.next_story_lines())
		AndreyTrip.Stage.TRAVELLING:
			Dialogue.start([{"speaker": "Терминал связи", "text": AndreyLines.AFTER_DEPARTURE}])
		AndreyTrip.Stage.ARRIVED:
			Dialogue.start([{"speaker": "Терминал связи", "text": AndreyLines.AFTER_ARRIVAL}])


func _on_andrey(_player: Player) -> void:
	var speaker := andrey.display_name
	if GameState.flags.get("andrey_talked", false):
		Dialogue.start([{
			"speaker": speaker,
			"text": "Я тут подумал... а обратно-то как? Последний шаттл на Гатчину-4 ушёл в 2019-м.",
		}])
		return
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
		]},
		{
			"speaker": speaker,
			"text": "Ладно, раз уж я здесь — отметьте меня. Пусть все видят.",
			"call": func(): GameState.flags["andrey_talked"] = true,
		},
	])
