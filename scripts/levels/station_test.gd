extends Node3D

## Тестовый отсек: проверка управления, взаимодействия и зачётки
## до того, как появится настоящая станция.

const COFFEE_LINES: Array[String] = [
	"Кофе. Горячий. Почти как дедлайн.",
	"Вторая чашка. Руки слегка вибрируют.",
	"Третья. Ты понимаешь матан.",
	"Четвёртая. Ты слышишь, как гудит реактор. Он поёт.",
]

var _coffee_cups := 0


func _ready() -> void:
	$MoodleTerminal.interacted.connect(_on_moodle)
	$CoffeeMachine.interacted.connect(_on_coffee)
	$ProfZaglushkin.interacted.connect(_on_zaglushkin)
	GameState.post_message("Смена началась. До конца сессии — одна смена. Удачи.")


func _on_moodle(_player: Player) -> void:
	GameState.post_message("MOODLE: У вас 5 несданных работ. Срок сдачи: вчера.")


func _on_coffee(_player: Player) -> void:
	_coffee_cups += 1
	if _coffee_cups <= COFFEE_LINES.size():
		GameState.post_message(COFFEE_LINES[_coffee_cups - 1])
	else:
		GameState.find_easter_egg("coffee_overdose", "пятая чашка. Ты видишь звуки.")
		$CoffeeMachine.enabled = false


func _on_zaglushkin(_player: Player) -> void:
	if GameState.has_signature("zaglushkin"):
		GameState.post_message("Заглушкин: Я уже расписался. Я вообще временный, не задерживай.")
		return
	GameState.add_signature("zaglushkin")
	GameState.post_message("Заглушкин: Подпишу, раз я пока капсула. Модельку мне потом нормальную сделай!")
