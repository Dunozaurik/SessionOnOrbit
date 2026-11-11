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
	"Лифт не работает с 2057 года. Ремонт запланирован на 2057 год.",
	"Кнопка нажалась. Это уже прогресс.",
	"Из шахты доносится: «Ждите». Голос подозрительно похож на твой.",
	"Ничего не происходит.",
	"Ничего не происходит. Но уже настойчивее.",
	"На кнопке появилась надпись: «ХВАТИТ».",
	"Где-то наверху кто-то вздохнул.",
	"Ничего не происходит. Совсем-совсем.",
	"Кажется, лифт тоже на сессии.",
]

const SCHEDULES: Array[String] = [
	"1 пара — Матанализ, ауд. 404. Аудитория не найдена.\n2 пара — Физика, ауд. 3¾ (вход через шлюз между 3 и 4).\n3 пара — Перенесена на вчера.",
	"1 пара — Физкультура в невесомости. Форма одежды: скафандр.\n2 пара — Начертательная геометрия в 4D.\n3 пара — Окно. В космос. Не открывать.",
	"ВНИМАНИЕ: расписание изменено.\nНовое расписание будет изменено.\nСледите за изменениями изменений.",
	"1 пара — Программирование, ауд. 0x1F.\n2 пара — Сопромат. Сопротивление бесполезно.\n3 пара — Деканат. Явка обязательна. Причина: узнаешь на месте.",
	"1 пара — Военная кафедра. Ауд. [ЗАСЕКРЕЧЕНО].\n2 пара — История космонавтики. Опоздавшие отправляются в историю.\n3 пара — Самостоятельная работа (самостоятельно найди аудиторию).",
]

var _coffee_cups := 0
var _elevator_presses := 0
var _schedule_index := 0


func _ready() -> void:
	$MoodleTerminal.interacted.connect(_on_moodle)
	$CoffeeMachine.interacted.connect(_on_coffee)
	$ProfZaglushkin.interacted.connect(_on_zaglushkin)
	$ElevatorButton.interacted.connect(_on_elevator)
	$ScheduleBoard.interacted.connect(_on_schedule)
	$Ambience.finished.connect($Ambience.play)
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
	Sfx.play_at("ding", $ElevatorDoor.global_position)
	Dialogue.start([
		{"speaker": "", "text": "*дзынь*"},
		{"speaker": "", "text": "Двери лифта открылись. Внутри никого. Двери закрылись."},
		{"speaker": "", "text": "Ты решаешь сделать вид, что этого не было.", "call": GameState.find_easter_egg.bind("elevator")},
	])
	$ElevatorButton.enabled = false
	$ElevatorSign.text = "ЛИФТ\nуехал навсегда"


func _on_schedule(_player: Player) -> void:
	Dialogue.start([{"speaker": "Расписание на сегодня", "text": SCHEDULES[_schedule_index]}])
	_schedule_index = (_schedule_index + 1) % SCHEDULES.size()
