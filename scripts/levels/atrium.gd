extends Room

## Атриум Орбитмеха — центральный хаб станции. Отсюда двери ведут во все отсеки.
## Здесь же Заглушкин, кофемашина, лифт с Петровым, расписание и док с Андреем
## (сюжетка Андрея — в andrey_storyline.gd). Состояние хранится в GameState.flags,
## чтобы не сбрасываться при возвращении из отсеков.

const COFFEE_LINES: Array[String] = [
	"Кофе. Горячий. Почти как дедлайн.",
	"Вторая чашка. Руки слегка вибрируют.",
	"Третья. Ты понимаешь матан.",
	"Четвёртая. Ты слышишь, как гудит реактор. Он поёт.",
]

const ELEVATOR_LINES: Array[String] = [
	"Лифт не работает с 1957 года. Ремонт запланирован на завтра.",
	"Кнопка нажалась. Это уже прогресс.",
	"Из шахты доносится: «Ждите». Голос звучит очень, очень старым.",
	"Ничего не происходит.",
	"Ничего не происходит. Но уже настойчивее.",
	"На кнопке появилась надпись: «ХВАТИТ».",
	"Из шахты кто-то кашлянул. Кажется, там кто-то есть...",
	"Где-то наверху заскрипели тросы. Впервые за сто лет.",
	"Лифт дёрнулся. Ещё разок!",
]
const ELEVATOR_DOOR_SHIFT := 1.6

const ZAGLUSHKIN := "Проф. Заглушкин"
## Студент, который застрял в лифте по дороге на вторую пару в 1957 году.
const PETROV := "Студент Петров (набор 1957 г.)"


func _ready() -> void:
	super._ready()
	$MoodleTerminal.interacted.connect(_on_moodle)
	$CoffeeMachine.interacted.connect(_on_coffee)
	$ProfZaglushkin.interacted.connect(_on_zaglushkin)
	$ElevatorButton.interacted.connect(_on_elevator)
	$ScheduleBoard.interacted.connect(_on_schedule)
	$ElevatorStudent.interacted.connect(_on_petrov)
	$EscapePod.interacted.connect(_on_escape_pod)
	_restore_state()
	if not GameState.flags.get("shift_started", false):
		GameState.flags["shift_started"] = true
		GameState.post_message("Смена началась. Собери %d подписей и сдай зачётку в деканат. Список предметов — по Tab." % GameState.TOTAL_SIGNATURES)


## Возвращает атриум в то состояние, в котором его оставили.
func _restore_state() -> void:
	$CoffeeMachine.enabled = GameState.flags.get("coffee_cups", 0) <= COFFEE_LINES.size()
	if GameState.flags.get("elevator_open", false):
		$ElevatorButton.enabled = false
		$ElevatorDoor.position.z += ELEVATOR_DOOR_SHIFT
		$ElevatorSign.text = "ЛИФТ\nприехал (впервые с 1957 г.)"
		$ElevatorStudent.set_present(true)


func _on_moodle(_player: Player) -> void:
	var left := GameState.TOTAL_SIGNATURES - GameState.signatures.size()
	if left > 0:
		GameState.post_message("MOODLE: У вас %d незакрытых предметов. Срок сдачи: вчера." % left)
	else:
		GameState.post_message("MOODLE: Все предметы закрыты. Ошибка: такого не бывает. Перезагрузка...")


func _on_coffee(_player: Player) -> void:
	var cups: int = GameState.flags.get("coffee_cups", 0) + 1
	GameState.flags["coffee_cups"] = cups
	if cups <= COFFEE_LINES.size():
		GameState.post_message(COFFEE_LINES[cups - 1])
	else:
		GameState.find_easter_egg("coffee_overdose")
		GameState.post_message("Пятая чашка. Ты видишь звуки. Кофемашина отказывается с тобой работать.")
		$CoffeeMachine.enabled = false


func _on_zaglushkin(_player: Player) -> void:
	if GameState.has_signature("zaglushkin"):
		Dialogue.start([{
			"speaker": ZAGLUSHKIN,
			"text": "Я уже расписался. Остальные преподаватели сидят по отсекам, и сдавать их надо строго по порядку — загляни в зачётку, клавиша Tab. Иди. А я постою тут и попритворяюсь мебелью — у меня это отлично получается.",
		}])
		return
	var sign_line := {
		"speaker": ZAGLUSHKIN,
		"text": "Ладно, подпишу, раз я пока капсула. Но модельку мне потом нормальную сделай! Дальше — компьютерный класс. Сдаём строго по порядку: он у тебя в зачётке, клавиша Tab.",
		"call": GameState.add_signature.bind("zaglushkin"),
	}
	Dialogue.start([
		{"speaker": ZAGLUSHKIN, "text": "А, студент. Я тут временно — пока мне не сделали нормальную модель. Ты за подписью?", "choices": [
			["Да, распишитесь, пожалуйста.", [sign_line]],
			["А почему вы капсула?", [
				{"speaker": ZAGLUSHKIN, "text": "Это называется «заглушка», молодой человек. Перечитай требования ко второму этапу курсового проекта."},
				{"speaker": ZAGLUSHKIN, "text": "Стоп. Какого ещё курсового проекта? Я ничего не говорил.", "choices": [
					["...Так вы подпишете?", [sign_line]],
				]},
			]],
			["Можно автоматом?", [
				{
					"speaker": ZAGLUSHKIN,
					"text": "Автоматом? Ха. Ха-ха. Автоматы в деканате, там газировку продают.",
					"call": func(): GameState.flags["asked_automat"] = true,
				},
				sign_line,
			]],
		]},
	])


func _on_elevator(_player: Player) -> void:
	var presses: int = GameState.flags.get("elevator_presses", 0) + 1
	GameState.flags["elevator_presses"] = presses
	if presses <= ELEVATOR_LINES.size():
		Sfx.play("denied", -4.0)
		GameState.post_message(ELEVATOR_LINES[presses - 1])
		return
	# Лифт наконец приехал: дверь отъезжает в сторону, внутри — Петров.
	GameState.flags["elevator_open"] = true
	$ElevatorButton.enabled = false
	Sfx.play_at("ding", $ElevatorDoor.global_position)
	GameState.post_message("*дзынь* Лифт приехал. Впервые с 1957 года. И в нём кто-то есть...")
	$ElevatorSign.text = "ЛИФТ\nприехал (впервые с 1957 г.)"
	$ElevatorStudent.set_present(true)
	create_tween().tween_property($ElevatorDoor, "position:z", $ElevatorDoor.position.z + ELEVATOR_DOOR_SHIFT, 1.2) \
			.set_trans(Tween.TRANS_SINE)


func _on_petrov(_player: Player) -> void:
	if GameState.flags.get("petrov_talked", false):
		Dialogue.start([{
			"speaker": PETROV,
			"text": "Я тут постою немного. Отвык от открытых пространств. И от людей. И от двадцать первого века.",
		}])
		return
	Dialogue.start([
		{"speaker": PETROV, "text": "Двери... открылись? ОТКРЫЛИСЬ! Товарищ, какой сейчас год?", "choices": [
			["2057-й.", [
				{"speaker": PETROV, "text": "Сто лет?! Я еду на вторую пару уже СТО ЛЕТ. Староста меня убьёт."},
			]],
			["А вы кто вообще?", [
				{"speaker": PETROV, "text": "Петров. Первый курс, набор пятьдесят седьмого. Сел в лифт на вторую пару, а он застрял между этажами. Ну, я и решил подождать."},
			]],
			["Вы что, всё это время сидели в лифте?", [
				{"speaker": PETROV, "text": "Так ремонт же обещали. К обеду. Обед, видимо, ещё не наступил."},
			]],
		]},
		{
			"speaker": PETROV,
			"text": "Хорошо хоть шпору с собой взял. Держи — мне она уже не пригодится, а у тебя сессия.",
			"call": GameState.collect_cheat_sheet.bind("petrov", "4 октября 1957 — запущен первый спутник. Сам слышал, как он пищит, прямо через шахту лифта."),
		},
		{
			"speaker": PETROV,
			"text": "Ладно, побегу. Может, хоть на третью пару успею. По лестнице.",
			"call": _petrov_done,
		},
	])


## Разговор с Петровым дослушан до конца (если выйти раньше — можно поговорить заново).
func _petrov_done() -> void:
	GameState.flags["petrov_talked"] = true
	GameState.find_easter_egg("elevator")


## Концовка «Отчислился сам»: улететь от сессии можно в любой момент.
func _on_escape_pod(_player: Player) -> void:
	Dialogue.start([
		{"speaker": "Спасательная капсула", "text": "Табличка: «Только для экстренных случаев». Ниже кто-то дописал ручкой: «Сессия — экстренный случай? — Да. — А.Л.»", "choices": [
			["Улететь от сессии навсегда", [
				{"speaker": "", "text": "Люк закрывается. На табло капсулы мигает: «КУРС: ГАТЧИНА-4. ВРЕМЯ В ПУТИ: НЕИЗВЕСТНО»."},
				{"speaker": "", "text": "*пш-ш-ш... отстыковка*", "call": GameState.finish_after_dialogue.bind("dropout")},
			]],
			["Остаться и всё сдать", [
				{"speaker": "", "text": "Правильно. Зачётка сама себя не заполнит."},
			]],
		]},
	])


func _on_schedule(_player: Player) -> void:
	Dialogue.start([{"speaker": "Расписание на сегодня", "text": ScheduleLines.generate()}])
