extends Room

## Кафедра высшей математики. Проф. Интегралов забыл код от сейфа с ведомостью.
## Код — ответы на три примера, которые он «разбросал по кафедре, чтобы не забыть»:
## на доске, в черновике на столе и на бумажке под стулом. Сейф открыт — подпись
## ставит сам Интегралов.

enum Stage { NOT_STARTED, SEARCHING, OPENED, DONE }

const TEACHER := "Проф. Интегралов"
const SAFE_CODE := "072"
## Сколько неверных попыток до подсказки, где искать примеры.
const HINT_AFTER := 4

const CLUES := {
	"board": "На доске мелом:\n«Цифра №1:   (5)' = ?»\nНиже приписка: «Производная от константы. Это же очевидно.»",
	"draft": "Черновик профессора:\n«Цифра №2:   i² + 8 = ?»\nНа полях: «не забыть, что i² = -1». И рисунок кота.",
	"chair": "Под стулом приклеена бумажка:\n«Цифра №3: интеграл от 0 до 2 от x dx.\nТолько никому не говори».",
}

var stage: Stage:
	get:
		return GameState.flags.get("math_stage", Stage.NOT_STARTED)
	set(value):
		GameState.flags["math_stage"] = value

var _wrong_attempts := 0

@onready var _lock: CodeLock = $CodeLock


func _ready() -> void:
	super._ready()
	$Integralov.interacted.connect(_on_teacher)
	$Safe.interacted.connect(_on_safe)
	$Chalkboard.interacted.connect(_on_clue.bind("board"))
	$Draft.interacted.connect(_on_clue.bind("draft"))
	$ChairNote.interacted.connect(_on_clue.bind("chair"))
	$Poster.interacted.connect(_on_poster)
	_lock.unlocked.connect(_on_unlocked)
	_lock.code_entered.connect(_on_code_entered)


func _on_teacher(_player: Player) -> void:
	match stage:
		Stage.NOT_STARTED:
			Dialogue.start([
				{"speaker": TEACHER, "text": "Подпись? Конечно. Ведомость в сейфе. А код от сейфа я... забыл."},
				{
					"speaker": TEACHER,
					"text": "Но помню, что он состоит из ответов на три примера. Я их разбросал по кафедре, чтобы не забыть. Логично же?",
					"call": func(): self.stage = Stage.SEARCHING,
					"choices": [
						["Логично.", [
							{"speaker": TEACHER, "text": "Вот! Наконец-то студент с математическим мышлением. Ищи."},
						]],
						["Может, просто записать код на бумажке?", [
							{"speaker": TEACHER, "text": "Записать? Как дилетант? Нет уж. Код должен быть выводим. Ищи примеры."},
						]],
						["А можно калькулятор?", [
							{"speaker": TEACHER, "text": "Калькулятор лежит в сейфе. Вместе с ведомостью. Ирония, да."},
						]],
					],
				},
			])
		Stage.SEARCHING:
			Dialogue.start([{"speaker": TEACHER, "text": "Примеры на доске, на моём столе и... где-то под стулом. Не спрашивай, как он туда попал. Ответы по порядку — и будет код."}])
		Stage.OPENED:
			stage = Stage.DONE
			Dialogue.start([
				{"speaker": TEACHER, "text": "Открыл? Без калькулятора? Моё уважение. Даже в мнимой части."},
				{
					"speaker": TEACHER,
					"text": "Расписываюсь. Только бутерброд в сейфе не трогай — он мой. С 2019 года.",
					"call": GameState.add_signature.bind("integralov"),
				},
			])
		Stage.DONE:
			Dialogue.start([{"speaker": TEACHER, "text": "Иди. Предел твоих мучений на этой кафедре достигнут."}])


func _on_clue(_player: Player, clue: String) -> void:
	GameState.flags["math_clue_" + clue] = true
	Dialogue.start([{"speaker": "", "text": CLUES[clue]}])


func _on_safe(_player: Player) -> void:
	match stage:
		Stage.NOT_STARTED:
			Dialogue.start([{"speaker": TEACHER, "text": "Это мой сейф. Сначала поговори со мной, а потом уже взламывай."}])
		Stage.SEARCHING:
			_lock.open(SAFE_CODE, "СЕЙФ ПРОФ. ИНТЕГРАЛОВА")
		_:
			GameState.post_message("Сейф открыт. Внутри ведомость, три калькулятора и бутерброд 2019 года.")


func _on_code_entered(code: String) -> void:
	if code == "067":
		_lock.show_status("Сейф: «SIX SEVEN!» *машет дверцей вверх-вниз*\nКод неверный, но вайб правильный.")
		GameState.find_easter_egg("six_seven")
		return
	_wrong_attempts += 1
	if _wrong_attempts == HINT_AFTER:
		_lock.show_status("Неверно. Подсказка от сейфа: примеры на доске, на столе и под стулом. Считай по порядку.")


func _on_unlocked() -> void:
	stage = Stage.OPENED
	_lock.close()
	Dialogue.start([
		{"speaker": "", "text": "*щёлк* Сейф открылся. Внутри: ведомость, три калькулятора и бутерброд с датой «2019»."},
		{"speaker": "", "text": "Интегралов смотрит на тебя с гордостью. И немного на бутерброд."},
	])


func _on_poster(_player: Player) -> void:
	Dialogue.start([{"speaker": "Плакат", "text": "«Если ты читаешь этот плакат, значит, ты сейчас не решаешь пример».\n\nМелко внизу: «Проф. Интегралов следит за тобой»."}])
