extends Node

## Глобальное состояние прохождения (автозагрузка GameState):
## подписи в зачётке, флаги заданий и найденные пасхалки.

signal message_posted(text: String)
signal signatures_changed(count: int, total: int)
signal easter_egg_found(id: String)

const TOTAL_SIGNATURES := 5

## teacher_id -> true
var signatures: Dictionary = {}
## Произвольные флаги заданий: "drone_found" -> true и т. п.
var flags: Dictionary = {}
var easter_eggs: Array[String] = []


func reset() -> void:
	signatures.clear()
	flags.clear()
	easter_eggs.clear()
	signatures_changed.emit(0, TOTAL_SIGNATURES)


func has_signature(teacher_id: String) -> bool:
	return signatures.has(teacher_id)


func add_signature(teacher_id: String) -> void:
	if has_signature(teacher_id):
		return
	signatures[teacher_id] = true
	signatures_changed.emit(signatures.size(), TOTAL_SIGNATURES)


func post_message(text: String) -> void:
	message_posted.emit(text)


func find_easter_egg(id: String, text: String) -> void:
	if id in easter_eggs:
		return
	easter_eggs.append(id)
	easter_egg_found.emit(id)
	post_message("Пасхалка найдена: " + text)
