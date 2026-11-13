extends Control

## Главное меню. Подзаголовок каждый раз выбирается случайно — первая мелкая пасхалка.
## Раздел «Концовки» показывает, какие финалы уже открыты (хранятся в GameState.unlocked_endings).

const FIRST_LEVEL := "res://scenes/levels/atrium.tscn"

const TAGLINES: Array[String] = [
	"В космосе никто не услышит, как ты не сдал курсовую.",
	"Сдай сессию. Выживи. Повтори.",
	"Дедлайн ближе, чем кажется.",
	"Собрано на кубах-заглушках. С любовью.",
	"Зачётка не заполнит себя сама.",
	"Кислорода хватит до конца пары. Наверное.",
	"Андрей уже выехал. (Нет.)",
	"Орбитмех: учиться здесь — не ракетостроение. Хотя нет, именно оно.",
]


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AndreyTrip.active = false
	%Tagline.text = TAGLINES.pick_random()
	%StartButton.pressed.connect(_on_start)
	%QuitButton.pressed.connect(get_tree().quit)
	%EndingsButton.pressed.connect(_show_endings)
	%EndingsClose.pressed.connect(_hide_endings)
	%EndingsButton.text = "Концовки: %d / %d" % [GameState.unlocked_endings.size(), Endings.ORDER.size()]
	%StartButton.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if %EndingsOverlay.visible and event.is_action_pressed("pause"):
		_hide_endings()
		get_viewport().set_input_as_handled()


## Раздел «Концовки»: открытые показываются целиком, закрытые — «???» с подсказкой.
func _show_endings() -> void:
	var lines: Array[String] = []
	for i in Endings.ORDER.size():
		var id: String = Endings.ORDER[i]
		var ending: Dictionary = Endings.ENDINGS[id]
		if id in GameState.unlocked_endings:
			lines.append("[color=#7ee68f][b]%d. %s[/b][/color]\n%s" % [i + 1, ending["title"], ending["text"].replace("\n\n", " ")])
		else:
			lines.append("[color=#7a7f8c][b]%d. ???[/b]\nПодсказка: %s[/color]" % [i + 1, ending["hint"]])
	%EndingsTitle.text = "КОНЦОВКИ: %d / %d" % [GameState.unlocked_endings.size(), Endings.ORDER.size()]
	%EndingsList.text = "\n\n".join(lines)
	%EndingsOverlay.show()
	%EndingsClose.grab_focus()


func _hide_endings() -> void:
	%EndingsOverlay.hide()
	%EndingsButton.grab_focus()


func _on_start() -> void:
	GameState.reset()
	Transition.go(FIRST_LEVEL)
