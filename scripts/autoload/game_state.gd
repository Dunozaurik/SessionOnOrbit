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

const TOTAL_SIGNATURES := 6
const TOTAL_CHEAT_SHEETS := 4

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


func reset() -> void:
	signatures.clear()
	picked_cheat_sheets.clear()
	flags.clear()
	easter_eggs.clear()
	spawn_id = ""
	input_locked = false
	AndreyTrip.reset()
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
