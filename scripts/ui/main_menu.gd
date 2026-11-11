extends Control

## Главное меню. Подзаголовок каждый раз выбирается случайно — первая мелкая пасхалка.

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
	%StartButton.grab_focus()


func _on_start() -> void:
	GameState.reset()
	Transition.go(FIRST_LEVEL)
