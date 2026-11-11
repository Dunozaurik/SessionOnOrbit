extends CanvasLayer

## Игровой интерфейс: прицел, подсказка взаимодействия, сообщения, зачётка и шпоры.

@onready var _crosshair: Control = %Crosshair
@onready var _prompt: Label = %Prompt
@onready var _message: Label = %Message
@onready var _signatures: Label = %Signatures
@onready var _cheat_sheets: Label = %CheatSheets
@onready var _message_timer: Timer = %MessageTimer

var _focused: Interactable


func _ready() -> void:
	_prompt.hide()
	_message.hide()
	_message_timer.timeout.connect(_message.hide)

	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.focus_changed.connect(_on_focus_changed)
	GameState.message_posted.connect(_show_message)
	GameState.signatures_changed.connect(_update_signatures)
	GameState.cheat_sheets_changed.connect(_update_cheat_sheets)
	Dialogue.started.connect(_refresh_prompt)
	Dialogue.finished.connect(_refresh_prompt)
	_update_signatures(GameState.signatures.size(), GameState.TOTAL_SIGNATURES)
	_update_cheat_sheets(GameState.cheat_sheets, GameState.TOTAL_CHEAT_SHEETS)


func _on_focus_changed(target: Interactable) -> void:
	_focused = target
	_refresh_prompt()


func _refresh_prompt() -> void:
	var in_dialogue: bool = Dialogue.is_active()
	_crosshair.visible = not in_dialogue
	_prompt.visible = _focused != null and not in_dialogue
	if _focused:
		_prompt.text = "[E] " + _focused.prompt


func _show_message(text: String) -> void:
	_message.text = text
	_message.show()
	_message_timer.start()


func _update_signatures(count: int, total: int) -> void:
	_signatures.text = "Зачётка: %d / %d подписей" % [count, total]


func _update_cheat_sheets(count: int, total: int) -> void:
	_cheat_sheets.text = "Шпоры: %d / %d" % [count, total]
	_cheat_sheets.visible = count > 0
