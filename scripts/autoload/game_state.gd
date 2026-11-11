extends Node

## Глобальное состояние прохождения (автозагрузка GameState):
## подписи в зачётке, шпоры, флаги заданий и найденные пасхалки.

signal message_posted(text: String)
signal signatures_changed(count: int, total: int)
signal cheat_sheets_changed(count: int, total: int)
signal easter_egg_found(id: String)

const TOTAL_SIGNATURES := 5
const TOTAL_CHEAT_SHEETS := 3

## Все пасхалки игры: id -> [название, подсказка до нахождения].
## Журнал в меню паузы строится по этому списку.
const EASTER_EGGS := {
	"coffee_overdose": ["Кофейный передоз", "Кофе бесконечен. Ты — нет."],
	"elevator": ["Лифт пришёл", "Настойчивость открывает любые двери. Даже лифта."],
	"cheat_sheets": ["Отличник по шпорам", "Шпоры прячутся там, куда никто не смотрит."],
	"andrey_stories": ["Пацаны, вы не поверите", "Кто-то на Гатчине-4 очень хочет выговориться."],
	"andrey_arrived": ["Невозможное возможно", "Говорят, однажды он всё-таки доедет."],
}

## teacher_id -> true
var signatures: Dictionary = {}
var cheat_sheets := 0
## Произвольные флаги заданий: "drone_found" -> true и т. п.
var flags: Dictionary = {}
var easter_eggs: Array[String] = []


func reset() -> void:
	signatures.clear()
	cheat_sheets = 0
	flags.clear()
	easter_eggs.clear()
	signatures_changed.emit(0, TOTAL_SIGNATURES)
	cheat_sheets_changed.emit(0, TOTAL_CHEAT_SHEETS)


func has_signature(teacher_id: String) -> bool:
	return signatures.has(teacher_id)


func add_signature(teacher_id: String) -> void:
	if has_signature(teacher_id):
		return
	signatures[teacher_id] = true
	Sfx.play("pickup")
	signatures_changed.emit(signatures.size(), TOTAL_SIGNATURES)


func collect_cheat_sheet(text: String) -> void:
	cheat_sheets += 1
	Sfx.play("pickup")
	cheat_sheets_changed.emit(cheat_sheets, TOTAL_CHEAT_SHEETS)
	post_message("Шпора %d/%d: «%s»" % [cheat_sheets, TOTAL_CHEAT_SHEETS, text])
	if cheat_sheets >= TOTAL_CHEAT_SHEETS:
		find_easter_egg("cheat_sheets")


func post_message(text: String) -> void:
	message_posted.emit(text)


func find_easter_egg(id: String) -> void:
	if id in easter_eggs:
		return
	easter_eggs.append(id)
	Sfx.play("egg")
	easter_egg_found.emit(id)
	post_message("Пасхалка найдена: «%s»  (%d/%d)" % [EASTER_EGGS[id][0], easter_eggs.size(), EASTER_EGGS.size()])
