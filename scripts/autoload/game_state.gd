extends Node

## Глобальное состояние прохождения (автозагрузка GameState):
## подписи в зачётке, шпоры, флаги заданий и найденные пасхалки.
## Живёт между сценами, поэтому всё, что должно пережить переход между отсеками, хранится здесь.

signal message_posted(text: String)
## Сообщение в «чат группы» — показывается уведомлением в углу экрана.
signal chat_posted(author: String, text: String)
signal signatures_changed(count: int, total: int)
signal cheat_sheets_changed(count: int, total: int)
signal easter_egg_found(id: String)

const TOTAL_CHEAT_SHEETS := 5

## Предметы сессии в порядке сдачи: следующий открывается только после подписи за предыдущий.
## id — ключ подписи, room — где искать преподавателя (для зачётки по Tab).
const SUBJECTS: Array[Dictionary] = [
	{"id": "zaglushkin", "title": "Пробный зачёт", "teacher": "Проф. Заглушкин", "room": "центр атриума"},
	{"id": "syntaksisov", "title": "Программирование", "teacher": "Ст. преп. Синтаксисов", "room": "компьютерный класс"},
	{"id": "integralov", "title": "Высшая математика", "teacher": "Проф. Интегралов", "room": "кафедра высшей математики"},
	{"id": "transistorova", "title": "ФОМ", "teacher": "Доц. Транзисторова", "room": "аудитория ФОМ"},
	{"id": "nevesomova", "title": "Физика", "teacher": "Доц. Невесомова", "room": "лаборатория физики"},
	{"id": "perestrakhov", "title": "БЖД", "teacher": "Инструктор Перестрахов", "room": "шлюз БЖД"},
]
const TOTAL_SIGNATURES := 6

## Все пасхалки игры: id -> [название, подсказка до нахождения].
## Журнал в меню паузы строится по этому списку.
const EASTER_EGGS := {
	"coffee_overdose": ["Кофейный передоз", "Кофе бесконечен. Ты — нет."],
	"elevator": ["Пассажир 1957 года", "Настойчивость открывает любые двери. Даже лифта."],
	"cheat_sheets": ["Отличник по шпорам", "Шпоры прячутся там, куда никто не смотрит."],
	"andrey_stories": ["Пацаны, вы не поверите", "Кто-то на Гатчине-4 очень хочет выговориться."],
	"andrey_arrived": ["Невозможное возможно", "Говорят, однажды он всё-таки доедет."],
	"final_final": ["Финал точно финал", "Загляни в чужой компьютер. Там всегда что-то интересное."],
	"six_seven": ["Six seven", "Попробуй ввести в сейф самое мемное число."],
	"retake": ["Пересдача — мой путь", "Иногда нужно проиграть, чтобы победить. Трижды."],
	"newton": ["Ньютон доволен", "Некоторые законы физики стоит проверить дважды: до и после."],
	"bzhd_textbook": ["Учебник БЖД в картинках", "Есть много способов не сдать БЖД. Попробуй хотя бы три."],
}

## teacher_id -> true
var signatures: Dictionary = {}
## id подобранных шпор — чтобы они не появлялись снова при возвращении в отсек.
var picked_cheat_sheets: Array[String] = []
var cheat_sheets: int:
	get:
		return picked_cheat_sheets.size()
## Произвольные флаги заданий и состояния отсеков: "coffee_cups" -> 3 и т. п.
var flags: Dictionary = {}
var easter_eggs: Array[String] = []
## Маркер, у которого появится игрок в следующей сцене (см. Room, Transition).
var spawn_id := ""
## true, пока открыт экран-головоломка: игрок не ходит и не крутит камерой.
var input_locked := false
## Какой концовкой закончилась игра (см. Endings) и когда она началась — для экрана титров.
var ending_id := ""
var start_msec := 0
## Концовки, которые игрок уже видел. Хранятся в файле и переживают перезапуск игры —
## их показывает раздел «Концовки» в главном меню.
var unlocked_endings: Array[String] = []
var progress_file := "user://progress.cfg"


func _ready() -> void:
	load_progress()


func load_progress() -> void:
	unlocked_endings.clear()
	var config := ConfigFile.new()
	if config.load(progress_file) != OK:
		return
	for id in config.get_value("endings", "unlocked", []):
		if id not in unlocked_endings:
			unlocked_endings.append(id)


func _unlock_ending(ending: String) -> void:
	if ending in unlocked_endings:
		return
	unlocked_endings.append(ending)
	var config := ConfigFile.new()
	config.set_value("endings", "unlocked", unlocked_endings)
	config.save(progress_file)


func reset() -> void:
	signatures.clear()
	picked_cheat_sheets.clear()
	flags.clear()
	easter_eggs.clear()
	spawn_id = ""
	input_locked = false
	ending_id = ""
	start_msec = Time.get_ticks_msec()
	AndreyTrip.reset()
	signatures_changed.emit(0, TOTAL_SIGNATURES)
	cheat_sheets_changed.emit(0, TOTAL_CHEAT_SHEETS)


func has_signature(teacher_id: String) -> bool:
	return signatures.has(teacher_id)


## Индекс текущего предмета в SUBJECTS (первый без подписи); SUBJECTS.size() — всё сдано.
func current_subject_index() -> int:
	for i in SUBJECTS.size():
		if not has_signature(SUBJECTS[i]["id"]):
			return i
	return SUBJECTS.size()


## Можно ли идти сдавать предмет: он уже сдан или следующий по очереди.
## "deanery" — деканат, открыт только с полной зачёткой.
func is_subject_open(teacher_id: String) -> bool:
	if teacher_id == "deanery":
		return current_subject_index() >= SUBJECTS.size()
	for i in SUBJECTS.size():
		if SUBJECTS[i]["id"] == teacher_id:
			return i <= current_subject_index()
	return true


func add_signature(teacher_id: String) -> void:
	if has_signature(teacher_id):
		return
	signatures[teacher_id] = true
	Sfx.play("pickup")
	signatures_changed.emit(signatures.size(), TOTAL_SIGNATURES)
	post_message("Подпись получена! Зачётка: %d / %d" % [signatures.size(), TOTAL_SIGNATURES])


func collect_cheat_sheet(id: String, text: String) -> void:
	if id in picked_cheat_sheets:
		return
	picked_cheat_sheets.append(id)
	Sfx.play("pickup")
	cheat_sheets_changed.emit(cheat_sheets, TOTAL_CHEAT_SHEETS)
	post_message("Шпора %d/%d: «%s»" % [cheat_sheets, TOTAL_CHEAT_SHEETS, text])
	if cheat_sheets >= TOTAL_CHEAT_SHEETS:
		find_easter_egg("cheat_sheets")


## Завершить игру концовкой ending: экран концовки со статистикой и титрами.
func finish_game(ending: String) -> void:
	ending_id = ending
	_unlock_ending(ending)
	AndreyTrip.active = false
	Transition.go("res://scenes/ui/ending_screen.tscn")


## То же, но после того, как закроется текущий диалог (удобно вызывать из "call" реплики).
func finish_after_dialogue(ending: String) -> void:
	if Dialogue.is_active():
		Dialogue.finished.connect(finish_game.bind(ending), CONNECT_ONE_SHOT)
	else:
		finish_game(ending)


func play_time_text() -> String:
	var seconds := (Time.get_ticks_msec() - start_msec) / 1000
	return "%d:%02d" % [seconds / 60, seconds % 60]


func post_message(text: String) -> void:
	message_posted.emit(text)


func post_chat(author: String, text: String) -> void:
	Sfx.play("chat", -4.0)
	chat_posted.emit(author, text)


func find_easter_egg(id: String) -> void:
	if id in easter_eggs:
		return
	easter_eggs.append(id)
	Sfx.play("egg")
	easter_egg_found.emit(id)
	post_message("Пасхалка найдена: «%s»  (%d/%d)" % [EASTER_EGGS[id][0], easter_eggs.size(), EASTER_EGGS.size()])
