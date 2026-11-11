extends Room

## Аудитория ФОМ (физические основы микроэлектроники). Доц. Транзисторова подпишет,
## если сдать тест в Moodle: 5 вопросов за 20 секунд, нужно 4 правильных.
## Каждая найденная шпора даёт +5 секунд. Пересдавать можно бесконечно.

enum Stage { NOT_STARTED, TESTING, PASSED, DONE }

const TEACHER := "Доц. Транзисторова"
## Сколько проваленных попыток нужно для пасхалки «Пересдача — мой путь».
const FAILS_FOR_EGG := 3

const HALL_OF_FAME := "ДОСКА ПОЧЁТА ТЕСТА ПО ФОМ\n\n1. Доц. Транзисторова — 4 мин\n    (единственная сдавшая)\n2. Лабонин А. — 47 попыток, в процессе"

var stage: Stage:
	get:
		return GameState.flags.get("fom_stage", Stage.NOT_STARTED)
	set(value):
		GameState.flags["fom_stage"] = value

@onready var _quiz: Quiz = $Quiz


func _ready() -> void:
	super._ready()
	$Transistorova.interacted.connect(_on_teacher)
	$MoodleTerminal.interacted.connect(_on_terminal)
	_quiz.finished.connect(_on_quiz_finished)
	_update_hall_of_fame()


func _time_limit() -> float:
	return FomQuestions.BASE_TIME + GameState.cheat_sheets * FomQuestions.SECONDS_PER_CHEAT_SHEET


func _update_hall_of_fame() -> void:
	var text := HALL_OF_FAME
	if stage >= Stage.PASSED:
		text += "\n3. Ты — ЗАЧЁТ! (Moodle в шоке)"
	$HallOfFame.text = text


func _on_teacher(_player: Player) -> void:
	match stage:
		Stage.NOT_STARTED:
			var sheets_line := "Кстати, шпоры у нас разрешены: каждая даёт +%d секунд к тесту. Так что лучше соберите их заранее. Сейчас у вас шпор: %d — это +%d секунд." % [
				int(FomQuestions.SECONDS_PER_CHEAT_SHEET), GameState.cheat_sheets,
				int(GameState.cheat_sheets * FomQuestions.SECONDS_PER_CHEAT_SHEET)]
			Dialogue.start([
				{"speaker": TEACHER, "text": "Подпись по ФОМу? Конечно. Нужно всего лишь сдать тест в Moodle."},
				{
					"speaker": TEACHER,
					"text": "На тест даётся 20 минут. Ой, простите, это у нас на Земле. На станции время идёт быстрее — у вас 20 секунд.",
					"call": func(): self.stage = Stage.TESTING,
					"choices": [
						["20 СЕКУНД?!", [
							{"speaker": TEACHER, "text": "Не переживайте. Я его решаю за четыре. Минуты. Но вы справитесь быстрее."},
						]],
						["А шпоры можно?", [
							{"speaker": TEACHER, "text": "Можно! Это официальная методика кафедры. Как раз хотела об этом сказать."},
						]],
						["А сколько раз можно пересдавать?", [
							{"speaker": TEACHER, "text": "Бесконечно. Лабонин пересдаёт уже 47-й раз. Говорит, что вот-вот."},
						]],
					],
				},
				{"speaker": TEACHER, "text": sheets_line},
				{"speaker": TEACHER, "text": "Терминал Moodle — у правой стены. Удачи. Она вам понадобится."},
			])
		Stage.TESTING:
			Dialogue.start([{"speaker": TEACHER, "text": "Терминал Moodle у правой стены. Время у вас: %d секунд. Ну, когда начнёте." % int(_time_limit())}])
		Stage.PASSED:
			stage = Stage.DONE
			Dialogue.start([
				{"speaker": TEACHER, "text": "Сдали?! С первой... с какой попытки? А, неважно. Это успех. Это прорыв в микроэлектронике."},
				{
					"speaker": TEACHER,
					"text": "Расписываюсь. Только Лабонину не говорите — он расстроится.",
					"call": GameState.add_signature.bind("transistorova"),
				},
			])
		Stage.DONE:
			Dialogue.start([{"speaker": TEACHER, "text": "Вы теперь на доске почёта. Сразу после меня. И перед Лабониным."}])


func _on_terminal(_player: Player) -> void:
	match stage:
		Stage.NOT_STARTED:
			GameState.post_message("MOODLE: Тест не назначен. Обратитесь к преподавателю.")
		Stage.TESTING:
			_quiz.start(FomQuestions.QUESTIONS, FomQuestions.QUESTIONS_PER_TRY, _time_limit(), FomQuestions.PASS_SCORE)
		_:
			GameState.post_message("MOODLE: Тест завершён. Оценка: зачёт. Moodle до сих пор не верит.")


func _on_quiz_finished(passed: bool, _score: int) -> void:
	if passed:
		stage = Stage.PASSED
		_update_hall_of_fame()
		GameState.post_message("Транзисторова роняет ручку. Кажется, она хочет с тобой поговорить.")
		return
	var fails: int = GameState.flags.get("fom_fails", 0) + 1
	GameState.flags["fom_fails"] = fails
	if fails == FAILS_FOR_EGG:
		GameState.find_easter_egg("retake")
