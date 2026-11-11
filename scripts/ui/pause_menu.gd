extends CanvasLayer

## Меню паузы по Esc с журналом пасхалок. Работает и при остановленном дереве (process_mode = Always).

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"


func _ready() -> void:
	hide()
	%ContinueButton.pressed.connect(toggle)
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
	var need_cursor: bool = paused or Dialogue.is_active()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if need_cursor else Input.MOUSE_MODE_CAPTURED
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


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)
