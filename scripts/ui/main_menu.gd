extends Control

## Главное меню. Подзаголовок каждый раз выбирается случайно — первая мелкая пасхалка.

const FIRST_LEVEL := "res://scenes/levels/station_test.tscn"

const TAGLINES: Array[String] = [
	"В космосе никто не услышит, как ты не сдал курсовую.",
	"Сдай сессию. Выживи. Повтори.",
	"Дедлайн ближе, чем кажется.",
	"Собрано на кубах-заглушках. С любовью.",
	"Зачётка не заполнит себя сама.",
	"Кислорода хватит до конца пары. Наверное.",
]


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%Tagline.text = TAGLINES.pick_random()
	%StartButton.pressed.connect(_on_start)
	%QuitButton.pressed.connect(get_tree().quit)
	%StartButton.grab_focus()


func _on_start() -> void:
	GameState.reset()
	get_tree().change_scene_to_file(FIRST_LEVEL)
