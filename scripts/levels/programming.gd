extends Room

## Компьютерный класс. Ст. преп. Синтаксисов подпишет зачётку, когда заработает
## компилятор станции: три раунда «найди строку с ошибкой» на терминале, а потом
## выясняется, что точку с запятой кто-то из студентов украл — она лежит под одним
## из столов. Её надо найти, вставить в терминал и вернуться к Синтаксисову за подписью.

enum Stage { NOT_STARTED, DEBUGGING, SEMICOLON_LOST, SEMICOLON_FOUND, COMPILED, DONE }

const TEACHER := "Ст. преп. Синтаксисов"

const ROUNDS: Array[Dictionary] = [
	{
		"output": "error: программа не собирается. Причина: есть.",
		"lines": [
			"void start_lecture() {",
			"    int oxygen = 100;",
			"    int students = 25",
			"    print(\"Пара началась\");",
			"}",
		],
		"correct": 2,
	},
	{
		"output": "error: что-то не так с печатью. Или с принтером. Или с тобой.",
		"hint": "Скомпилировалось! ...Нет. Новая ошибка. Кликни по строке с ошибкой.",
		"lines": [
			"void start_shift() {",
			"    open_door(AIRLOCK_3);",
			"    check_oxygen();",
			"    pirnt(\"Сессия началась\");",
			"    close_door(AIRLOCK_3);",
			"}",
		],
		"correct": 3,
	},
	{
		"output": "error: expected ';' at line 42",
		"hint": "Скомпилировалось! ...Нет. Найди ошибку в строке 42.",
		"dead_end_text": "В строке %d всё правильно. Да и во всех остальных тоже. А строки 42 в файле... просто нет. Может, компилятор врёт? Так ему и скажи.",
		"lines": [
			"void fix_schedule() {",
			"    load(schedule);",
			"    validate(schedule);",
			"    save(schedule);",
			"}",
		],
		"correct": -1,
	},
]

var stage: Stage:
	get:
		return GameState.flags.get("prog_stage", Stage.NOT_STARTED)
	set(value):
		GameState.flags["prog_stage"] = value

@onready var _puzzle: CodePuzzle = $CodePuzzle
@onready var _semicolon: Interactable = $Semicolon


func _ready() -> void:
	super._ready()
	$Syntaksisov.interacted.connect(_on_teacher)
	$CompilerTerminal.interacted.connect(_on_terminal)
	_semicolon.interacted.connect(_on_semicolon)
	$SomeonesPC.interacted.connect(_on_someones_pc)
	_puzzle.solved.connect(_on_round_solved)
	_set_semicolon_visible(stage == Stage.SEMICOLON_LOST)


func _set_semicolon_visible(value: bool) -> void:
	_semicolon.visible = value
	_semicolon.enabled = value
	$Semicolon/Collision.disabled = not value


func _on_teacher(_player: Player) -> void:
	match stage:
		Stage.NOT_STARTED:
			var start := func(): self.stage = Stage.DEBUGGING
			Dialogue.start([
				{
					"speaker": TEACHER,
					"text": "О, студент. За подписью? Подпись будет, когда заработает компилятор станции. Он третьи сутки не может собрать расписание.",
					"choices": [
						["Я помогу.", [
							{"speaker": TEACHER, "text": "Вот это настрой. Терминал у стены. Найди строку с ошибкой — компилятор подскажет. Ну, как подскажет. Намекнёт."},
						]],
						["А в чём проблема?", [
							{"speaker": TEACHER, "text": "Если бы я знал, в чём проблема, это была бы не проблема, а задача. Терминал у стены. Найди ошибку."},
						]],
						["А можно я просто посмотрю на звёзды?", [
							{"speaker": TEACHER, "text": "Можно. Это те самые 10% нашей работы. Но сначала — 90%: терминал у стены, ищи ошибку."},
						]],
					],
				},
				{"speaker": TEACHER, "text": "Починишь — возвращайся за подписью. Я буду тут: мне, в отличие от программы, идти некуда.", "call": start},
			])
		Stage.DEBUGGING:
			Dialogue.start([{"speaker": TEACHER, "text": "Терминал у стены. Ошибки сами себя не найдут. Хотя было бы удобно."}])
		Stage.SEMICOLON_LOST:
			Dialogue.start(_semicolon_lost_lines())
		Stage.SEMICOLON_FOUND:
			var verdict := "Лабонин. Ну конечно. Как он умудрился её стащить, если сам до станции так и не доехал?!"
			if AndreyTrip.stage == AndreyTrip.Stage.ARRIVED:
				verdict = "Лабонин. Первый раз за три года доехал до станции — и сразу на кражу. Растёт парень."
			Dialogue.start([
				{"speaker": TEACHER, "text": "Нашёл?! Под столом? И записка «А.Л.»?.."},
				{"speaker": TEACHER, "text": verdict + " Ладно, неси в терминал."},
			])
		Stage.COMPILED:
			_give_signature()
		Stage.DONE:
			Dialogue.start([{"speaker": TEACHER, "text": "Иди, любуйся звёздами. Ты заслужил свои 10%."}])


func _semicolon_lost_lines() -> Array:
	return [
		{"speaker": TEACHER, "text": "«Всё верно»? Строка 42? Да в файле всего пять строк... Дай-ка гляну."},
		{"speaker": TEACHER, "text": "Так. Из буфера компилятора пропала точка с запятой. Её украли. Опять кто-то из студентов спёр для своей лабы — у них их вечно не хватает."},
		{"speaker": TEACHER, "text": "Обыщи аудиторию. Посмотри у столов — студенты всегда всё роняют возле столов. Найдёшь — неси в терминал."},
	]


func _on_terminal(_player: Player) -> void:
	match stage:
		Stage.NOT_STARTED:
			Dialogue.start([{"speaker": TEACHER, "text": "Э-э, не трогай терминал! Сначала поговори со мной."}])
		Stage.DEBUGGING:
			_puzzle.open(ROUNDS[GameState.flags.get("prog_round", 0)])
		Stage.SEMICOLON_LOST:
			GameState.post_message("Компилятор ждёт точку с запятой. Её нигде нет. Даже в строке 42.")
		Stage.SEMICOLON_FOUND:
			_compile()
		Stage.COMPILED:
			GameState.post_message("Сборка успешна. Синтаксисов уже потирает руки — иди к нему за подписью.")
		Stage.DONE:
			GameState.post_message("Сборка успешна. Терминал гордо светится зелёным.")


func _on_round_solved() -> void:
	var next_round: int = GameState.flags.get("prog_round", 0) + 1
	GameState.flags["prog_round"] = next_round
	if next_round < ROUNDS.size():
		_puzzle.open(ROUNDS[next_round])
		return
	_puzzle.close()
	stage = Stage.SEMICOLON_LOST
	_set_semicolon_visible(true)
	Dialogue.start(_semicolon_lost_lines())


func _on_semicolon(_player: Player) -> void:
	stage = Stage.SEMICOLON_FOUND
	_set_semicolon_visible(false)
	Sfx.play("pickup")
	GameState.post_message("Точка с запятой найдена у стола! Рядом записка: «Взял для лабы, верну. А.Л.»")


func _compile() -> void:
	stage = Stage.COMPILED
	Sfx.play("success")
	Dialogue.start([
		{"speaker": "Терминал", "text": "Вставка символа «;»... Строка 42 создана.\nСборка завершена успешно. Ошибок: 0. Предупреждений: 847."},
		{"speaker": "", "text": "Синтаксисов машет тебе из-за стола. Кажется, он что-то хочет сказать."},
	])


func _give_signature() -> void:
	Dialogue.start([
		{"speaker": TEACHER, "text": "Работает! Расписание станции снова собирается. Теперь все пары опять будут переноситься автоматически."},
		{
			"speaker": TEACHER,
			"text": "90% времени — ищем точку с запятой, 10% — любуемся звёздами. Сегодня ты успел и то и другое. Давай зачётку.",
			"call": _sign,
		},
	])


## Подпись и завершение задания — одним действием, на реплике с подписью.
## Если выйти из диалога раньше, задание не считается сданным и разговор можно повторить.
func _sign() -> void:
	stage = Stage.DONE
	GameState.add_signature("syntaksisov")


func _on_someones_pc(_player: Player) -> void:
	Dialogue.start([
		{"speaker": "Чей-то компьютер", "text": "Открытые файлы:\nкурсовая.docx\nкурсовая_финал.docx\nкурсовая_финал_2.docx\nкурсовая_финал_ТОЧНО.docx\nкурсовая_финал_ТОЧНО_v7_исправленная (1).docx"},
		{
			"speaker": "Чей-то компьютер",
			"text": "На панели задач: «Сессия на орбите — Godot (не отвечает)». Кто-то делает курсовой проект — игру про сессию. Как иронично.",
			"call": GameState.find_easter_egg.bind("final_final"),
		},
	])
