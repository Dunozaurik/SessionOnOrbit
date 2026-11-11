extends CanvasLayer

## Меню паузы по Esc. Работает и при остановленном дереве (process_mode = Always).

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
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
	if paused:
		%ContinueButton.grab_focus()


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)
