extends Room

## Деканат — финал. Секретарь Справкина принимает зачётку с шестью подписями,
## но требует «справку о том, что вы студент» — её выдают тут же, после электронной очереди.
## Чем всё закончится, зависит от прохождения:
##   все пасхалки найдены   → «Новый декан» (можно отказаться → обычная);
##   Андрей долетел          → «Вместе до конца» (он тоже пришёл сдавать);
##   иначе                   → «Сессия закрыта».
## Отдельно: автомат с газировкой → «Автомат», если спрашивал Заглушкина про автомат.

enum Stage { NOT_STARTED, QUEUE, CALLED }

const SECRETARY := "Секретарь Справкина"
const MY_NUMBER := 404
const FIRST_NUMBER := 401
const QUEUE_STEP_TIME := 4.0

## Места в очереди: [0] — у окошка, дальше — в хвост по диагонали влево-назад,
## с шагом около полутора метров и в стороне от входа.
const QUEUE_SPOTS: Array[Vector3] = [Vector3(-1.0, 0, -1.15), Vector3(-2.0, 0, 0.0), Vector3(-3.0, 0, 1.15)]
## Путь обслуженного от окошка к выходу: прямо к двери (она на южной стене, x = 0).
const QUEUE_EXIT_PATH: Array[Vector3] = [Vector3(0.0, 0, 3.3)]
const QUEUE_WALK_SPEED := 1.6
## Что говорят люди из очереди (по имени узла).
const QUEUE_LINES := {
	"Queue401": "Я за справкой о том, что мне нужна справка. Без неё справку не дают.",
	"Queue402": "Мне сказали принести справку из деканата в деканат. Я уже третий раз прихожу.",
	"Queue403": "Я вообще-то за Лабонина стою. Он просил занять очередь. В 2054-м.",
}

var stage: Stage:
	get:
		return GameState.flags.get("deanery_stage", Stage.NOT_STARTED)
	set(value):
		GameState.flags["deanery_stage"] = value

var _serving := FIRST_NUMBER
var _queue_timer := 0.0
var _impatient := 0

@onready var _andrey: Npc = $Andrey
## Люди с номерами 401, 402, 403 — по порядку узлов в QueuePeople.
@onready var _queue_people: Array[Node] = $QueuePeople.get_children()


func _ready() -> void:
	super._ready()
	$Spravkina.interacted.connect(_on_secretary)
	$VendingMachine.interacted.connect(_on_vending)
	$Cactus.interacted.connect(_on_cactus)
	$EternalStudent.interacted.connect(_on_eternal_student)
	_andrey.interacted.connect(_on_andrey)
	_andrey.set_present(_andrey_arrived())
	for person in _queue_people:
		person.interacted.connect(_on_queue_person.bind(person))
	if stage == Stage.CALLED:
		_serving = MY_NUMBER
	_arrange_queue(true)
	_update_board()


func _andrey_arrived() -> bool:
	return AndreyTrip.stage == AndreyTrip.Stage.ARRIVED


func _process(delta: float) -> void:
	if stage != Stage.QUEUE:
		return
	_queue_timer += delta
	if _queue_timer < QUEUE_STEP_TIME:
		return
	_queue_timer = 0.0
	_serving += 1
	Sfx.play("ding", -8.0)
	_update_board()
	_arrange_queue(false)
	if _serving >= MY_NUMBER:
		stage = Stage.CALLED
		GameState.post_message("Справкина: «Номер %d! Подходите. Быстрее, у меня обед через минуту»." % MY_NUMBER)


## Расставляет людей в очереди по номеру, который сейчас обслуживается:
## уже обслуженные уходят к двери и исчезают, остальные продвигаются к окошку.
func _arrange_queue(instant: bool) -> void:
	var served := _serving - FIRST_NUMBER
	for i in _queue_people.size():
		var person: Npc = _queue_people[i]
		if i < served:
			if instant or not person.present:
				person.set_present(false)
			elif i == served - 1:
				_walk_out(person)
			continue
		var spot := QUEUE_SPOTS[i - served]
		if instant:
			person.position = spot
		else:
			create_tween().tween_property(person, "position", spot, 0.9).set_delay(0.6)


## Обслуженный уходит: идёт по точкам QUEUE_EXIT_PATH лицом по ходу движения,
## у двери звучит шлюз, и человек исчезает — вышел в атриум.
func _walk_out(person: Npc) -> void:
	person.enabled = false
	person.play_animation("Walk")
	var walk := create_tween()
	var from := person.position
	for point in QUEUE_EXIT_PATH:
		var direction := point - from
		# Персонаж «смотрит» вдоль +Z, поэтому угол поворота — atan2(x, z).
		walk.tween_callback(person.set.bind("rotation", Vector3(0, atan2(direction.x, direction.z), 0)))
		walk.tween_property(person, "position", point, direction.length() / QUEUE_WALK_SPEED)
		from = point
	walk.tween_callback(Sfx.play_at.bind("door", $ExitDoor.global_position, -4.0))
	walk.tween_callback(person.set_present.bind(false))


func _on_queue_person(_player: Player, person: Node) -> void:
	Dialogue.start([{"speaker": person.display_name, "text": QUEUE_LINES[person.name]}])


func _update_board() -> void:
	var mine := "—" if stage == Stage.NOT_STARTED else str(MY_NUMBER)
	$QueueBoard.text = "ЭЛЕКТРОННАЯ ОЧЕРЕДЬ\nСейчас обслуживается: %d\nВаш номер: %s" % [_serving, mine]


func _on_secretary(_player: Player) -> void:
	match stage:
		Stage.NOT_STARTED:
			var to_queue := func():
				self.stage = Stage.QUEUE
				_update_board()
			Dialogue.start([
				{"speaker": SECRETARY, "text": "Зачётка? Давайте. Так... раз, два... шесть подписей. Надо же. Все на месте."},
				{"speaker": SECRETARY, "text": "А справка?", "choices": [
					["Какая справка?", [
						{"speaker": SECRETARY, "text": "Справка о том, что вы студент. Без неё зачётку принять не могу."},
					]],
					["Но я же стою тут, с зачёткой!", [
						{"speaker": SECRETARY, "text": "Зачётка — это не справка. Справка — это справка."},
					]],
				]},
				{"speaker": SECRETARY, "text": "Справки выдаются в деканате.", "choices": [
					["Это и есть деканат.", [
						{"speaker": SECRETARY, "text": "Вот именно. Значит, здесь и получите. В порядке живой электронной очереди."},
					]],
					["...", [
						{"speaker": SECRETARY, "text": "Вот и я так думаю. Берите номерок и ждите."},
					]],
				]},
				{"speaker": SECRETARY, "text": "Ваш номер — %d. Следите за табло. Подойдёте, когда вызовут." % MY_NUMBER, "call": to_queue},
			])
		Stage.QUEUE:
			_impatient += 1
			var lines: Array[String] = [
				"Ждите. Номер на табло.",
				"Вы опять? Ваш номер ещё не подошёл.",
				"Слушайте, очередь не ускорится, если подходить чаще. Можете пока полить кактус.",
			]
			Dialogue.start([{"speaker": SECRETARY, "text": lines[mini(_impatient - 1, lines.size() - 1)]}])
		Stage.CALLED:
			_final_dialogue()


func _final_dialogue() -> void:
	var lines: Array = [
		{"speaker": SECRETARY, "text": "Номер %d? Наконец-то. Справка о том, что вы студент... вот." % MY_NUMBER, "call": Sfx.play.bind("success")},
		{"speaker": "", "text": "*печать* *печать* *ещё одна печать — на всякий случай*"},
	]
	if GameState.easter_eggs.size() >= GameState.EASTER_EGGS.size():
		lines.append({"speaker": SECRETARY, "text": "Подождите-ка. Вы нашли на этой станции абсолютно всё. По зачётке видно — там даже следы пятой чашки кофе."})
		lines.append({"speaker": SECRETARY, "text": "Прошлый декан застрял в лифте в 1957 году. Должность до сих пор свободна. Не хотите?", "choices": [
			["Хочу! Я буду деканом!", [
				{"speaker": SECRETARY, "text": "Поздравляю. Ваш кабинет — вот этот. Обед с 14:01.", "call": GameState.finish_after_dialogue.bind("new_dean")},
			]],
			["Нет, спасибо. Я просто хочу на каникулы.", [
				{"speaker": SECRETARY, "text": "Мудро. Зачётка принята. Сессия закрыта. Следующий!", "call": GameState.finish_after_dialogue.bind("normal")},
			]],
		]})
	elif _andrey_arrived():
		lines.append({"speaker": SECRETARY, "text": "А это кто с вами? ...Лабонин? Вы же у нас числились пропавшим без вести."})
		lines.append({"speaker": "Андрей Лабонин", "text": "Пацаны... то есть, товарищ секретарь... вы не поверите, что произошло."})
		lines.append({"speaker": SECRETARY, "text": "...Ладно. Закрываю обоим. Только рассказывать не надо.", "call": GameState.finish_after_dialogue.bind("together")})
	else:
		lines.append({"speaker": SECRETARY, "text": "Зачётка принята. Сессия закрыта. Следующий!", "call": GameState.finish_after_dialogue.bind("normal")})
	Dialogue.start(lines)


func _on_vending(_player: Player) -> void:
	if not GameState.flags.get("asked_automat", false):
		Dialogue.start([{"speaker": "Автомат с газировкой", "text": "Газировка закончилась в 2049 году. На стекле табличка: «Про автоматы спрашивайте у преподавателей»."}])
		return
	Dialogue.start([
		{"speaker": "Автомат с газировкой", "text": "Газировки нет. Зато на одной кнопке кто-то вывел маркером: «ЗАЧЁТ АВТОМАТОМ».\nЗаглушкин что-то такое говорил...", "choices": [
			["Нажать «ЗАЧЁТ АВТОМАТОМ»", [
				{"speaker": "", "text": "*бз-з-з... щёлк... дзынь*", "call": GameState.finish_after_dialogue.bind("automat")},
			]],
			["Не трогать. Сдам по-честному.", [
				{"speaker": "", "text": "Автомат разочарованно гудит."},
			]],
		]},
	])


func _on_cactus(_player: Player) -> void:
	Dialogue.start([{"speaker": "Кактус деканата", "text": "Единственный сотрудник деканата, который работает без перерыва на обед. Колется, но справки не требует."}])


func _on_eternal_student(_player: Player) -> void:
	Dialogue.start([
		{"speaker": "Вечный студент", "text": "Ты за справкой? Я тоже. Я здесь с 2041 года. Мой номер — 12."},
		{"speaker": "Вечный студент", "text": "Не смотри на табло. Оно показывает 401, но это уже пятый круг. Говорят, вот-вот примут."},
	])


func _on_andrey(_player: Player) -> void:
	Dialogue.start([{"speaker": "Андрей Лабонин", "text": "О, ты тоже сдавать? Я вот тоже. Ну, как сдавать — я пришёл. Это уже больше, чем обычно."}])
