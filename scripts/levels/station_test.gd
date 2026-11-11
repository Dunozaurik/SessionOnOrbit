extends Node3D

## Атриум Орбитмеха (прототип): проверка управления, диалогов, зачётки и пасхалок
## до того, как появится настоящая станция. Сюжетка Андрея — в andrey_storyline.gd.

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

## Студент, который застрял в лифте по дороге на вторую пару в 1957 году.
const PETROV := "Студент Петров (набор 1957 г.)"

var _coffee_cups := 0
var _elevator_presses := 0


func _ready() -> void:
	$MoodleTerminal.interacted.connect(_on_moodle)
	$CoffeeMachine.interacted.connect(_on_coffee)
	$ProfZaglushkin.interacted.connect(_on_zaglushkin)
	$ElevatorButton.interacted.connect(_on_elevator)
	$ScheduleBoard.interacted.connect(_on_schedule)
	$ElevatorStudent.interacted.connect(_on_petrov)
	GameState.post_message("Смена началась. До конца сессии — одна смена. Удачи.")


func _on_moodle(_player: Player) -> void:
	GameState.post_message("MOODLE: У вас 5 несданных работ. Срок сдачи: вчера.")


func _on_coffee(_player: Player) -> void:
	_coffee_cups += 1
	if _coffee_cups <= COFFEE_LINES.size():
		GameState.post_message(COFFEE_LINES[_coffee_cups - 1])
	else:
		GameState.find_easter_egg("coffee_overdose")
		GameState.post_message("Пятая чашка. Ты видишь звуки. Кофемашина отказывается с тобой работать.")
		$CoffeeMachine.enabled = false


func _on_zaglushkin(_player: Player) -> void:
	const SPEAKER := "Проф. Заглушкин"
	if GameState.has_signature("zaglushkin"):
		Dialogue.start([{
			"speaker": SPEAKER,
			"text": "Я уже расписался. Я вообще временный, не задерживай. Остальные преподаватели ещё не загрузились.",
		}])
		return
	var sign_line := {
		"speaker": SPEAKER,
		"text": "Ладно, подпишу, раз я пока капсула. Но модельку мне потом нормальную сделай!",
		"call": GameState.add_signature.bind("zaglushkin"),
	}
	Dialogue.start([
		{"speaker": SPEAKER, "text": "А, студент. Я тут временно — пока мне не сделали нормальную модель. Ты за подписью?", "choices": [
			["Да, распишитесь, пожалуйста.", [sign_line]],
			["А почему вы капсула?", [
				{"speaker": SPEAKER, "text": "Это называется «заглушка», молодой человек. Перечитай требования ко второму этапу курсового проекта."},
				{"speaker": SPEAKER, "text": "Стоп. Какого ещё курсового проекта? Я ничего не говорил.", "choices": [
					["...Так вы подпишете?", [sign_line]],
				]},
			]],
			["Можно автоматом?", [
				{"speaker": SPEAKER, "text": "Автоматом? Ха. Ха-ха. Автоматы на третьей палубе, там газировку продают."},
				sign_line,
			]],
		]},
	])


func _on_elevator(_player: Player) -> void:
	_elevator_presses += 1
	if _elevator_presses <= ELEVATOR_LINES.size():
		Sfx.play("denied", -4.0)
		GameState.post_message(ELEVATOR_LINES[_elevator_presses - 1])
		return
	# Лифт наконец приехал: дверь отъезжает в сторону, внутри — Петров.
	$ElevatorButton.enabled = false
	Sfx.play_at("ding", $ElevatorDoor.global_position)
	GameState.post_message("*дзынь* Лифт приехал. Впервые с 1957 года. И в нём кто-то есть...")
	$ElevatorSign.text = "ЛИФТ\nприехал (впервые с 1957 г.)"
	$ElevatorStudent.set_present(true)
	var tween := create_tween()
	tween.tween_property($ElevatorDoor, "position:z", $ElevatorDoor.position.z + 1.6, 1.2) \
			.set_trans(Tween.TRANS_SINE)


func _on_petrov(_player: Player) -> void:
	if GameState.flags.get("petrov_talked", false):
		Dialogue.start([{
			"speaker": PETROV,
			"text": "Я тут постою немного. Отвык от открытых пространств. И от людей. И от двадцать первого века.",
		}])
		return
	GameState.flags["petrov_talked"] = true
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
			"call": GameState.collect_cheat_sheet.bind("4 октября 1957 — запущен первый спутник. Сам слышал, как он пищит, прямо через шахту лифта."),
		},
		{
			"speaker": PETROV,
			"text": "Ладно, побегу. Может, хоть на третью пару успею. По лестнице.",
			"call": GameState.find_easter_egg.bind("elevator"),
		},
	])


func _on_schedule(_player: Player) -> void:
	Dialogue.start([{"speaker": "Расписание на сегодня", "text": ScheduleLines.generate()}])
