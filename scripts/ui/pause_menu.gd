extends CanvasLayer

## Меню паузы по Esc с журналом пасхалок. Работает и при остановленном дереве (process_mode = Always).

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const FIRST_LEVEL := "res://scenes/levels/atrium.tscn"
const RESTART_TEXT := "Начать заново"
const RESTART_CONFIRM_TEXT := "Точно? Прогресс сбросится"

## «Начать заново» срабатывает со второго нажатия — чтобы не потерять прогресс случайно.
var _restart_armed := false


func _ready() -> void:
	hide()
	%ContinueButton.pressed.connect(toggle)
	%RestartButton.pressed.connect(_on_restart)
	%MenuButton.pressed.connect(_on_menu)
	%QuitButton.pressed.connect(get_tree().quit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	visible = paused
	var need_cursor: bool = paused or Dialogue.is_active() or GameState.input_locked
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if need_cursor else Input.MOUSE_MODE_CAPTURED
	_restart_armed = false
	%RestartButton.text = RESTART_TEXT
	if paused:
		_refresh_journal()
		%ContinueButton.grab_focus()


func _refresh_journal() -> void:
	var lines: Array[String] = []
	for id in GameState.EASTER_EGGS:
		var egg: Array = GameState.EASTER_EGGS[id]
		if id in GameState.easter_eggs:
			lines.append("[+]  " + egg[0])
		else:
			lines.append("[  ]  ???  — " + egg[1])
	%EggsTitle.text = "Пасхалки: %d / %d" % [GameState.easter_eggs.size(), GameState.EASTER_EGGS.size()]
	%EggsList.text = "\n".join(lines)


## Новая игра с самого начала: подписи, шпоры, пасхалки и задания сбрасываются.
func _on_restart() -> void:
	if not _restart_armed:
		_restart_armed = true
		%RestartButton.text = RESTART_CONFIRM_TEXT
		return
	hide()
	Dialogue.cancel()
	GameState.reset()
	Transition.go(FIRST_LEVEL)


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)
