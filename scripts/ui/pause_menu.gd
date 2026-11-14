extends CanvasLayer

## Меню паузы по Esc с журналом пасхалок. Работает и при остановленном дереве (process_mode = Always).

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const FIRST_LEVEL := "res://scenes/levels/atrium.tscn"


func _ready() -> void:
	hide()
	%ContinueButton.pressed.connect(toggle)
	%RestartButton.pressed.connect(_ask_restart)
	%ConfirmRestart.confirmed.connect(_restart)
	%ConfirmRestart.cancelled.connect(%RestartButton.grab_focus)
	%SettingsButton.pressed.connect(%SettingsPanel.open)
	%SettingsPanel.closed.connect(%SettingsButton.grab_focus)
	%MenuButton.pressed.connect(_on_menu)
	%QuitButton.pressed.connect(_ask_quit)
	%ConfirmQuit.confirmed.connect(get_tree().quit)
	%ConfirmQuit.cancelled.connect(%QuitButton.grab_focus)


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
	if paused:
		_refresh_journal()
		%ContinueButton.grab_focus()


func _refresh_journal() -> void:
	var lines: Array[String] = []
	for id in GameState.EASTER_EGGS:
		var egg: Array = GameState.EASTER_EGGS[id]
		if id in GameState.easter_eggs:
			lines.append("[color=#7ee68f][b]+[/b]  %s[/color]" % egg[0])
		else:
			lines.append("[color=#7a7f8c]-  ???  —  %s[/color]" % egg[1])
	%EggsTitle.text = "Пасхалки: %d / %d" % [GameState.easter_eggs.size(), GameState.EASTER_EGGS.size()]
	%EggsList.text = "\n".join(lines)


func _ask_restart() -> void:
	%ConfirmRestart.ask("Начать заново?", "Подписи, шпоры и пасхалки этой сессии сбросятся. Деканат ничего не забудет, но сделает вид.", "Начать заново", "Остаться")


## Новая игра с самого начала: подписи, шпоры, пасхалки и задания сбрасываются.
func _restart() -> void:
	hide()
	Dialogue.cancel()
	GameState.reset()
	Transition.go(FIRST_LEVEL)


func _ask_quit() -> void:
	%ConfirmQuit.ask("Выйти из игры?", "Прогресс сессии не сохраняется. Андрей, кстати, тоже так и не доехал.", "Выйти", "Остаться")


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)
