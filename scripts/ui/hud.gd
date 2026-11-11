extends CanvasLayer

## Игровой интерфейс: прицел, подсказка взаимодействия, сообщения, зачётка и шпоры.

@onready var _crosshair: Control = %Crosshair
@onready var _prompt: Label = %Prompt
@onready var _message: Label = %Message
@onready var _signatures: Label = %Signatures
@onready var _cheat_sheets: Label = %CheatSheets
@onready var _message_timer: Timer = %MessageTimer
@onready var _chat_card: Control = %ChatCard
@onready var _chat_author: Label = %ChatAuthor
@onready var _chat_text: Label = %ChatText
@onready var _chat_timer: Timer = %ChatTimer

var _focused: Interactable
var _chat_tween: Tween


func _ready() -> void:
	_prompt.hide()
	_message.hide()
	_message_timer.timeout.connect(_message.hide)
	_chat_card.hide()
	_chat_timer.timeout.connect(_hide_chat)
	GameState.chat_posted.connect(_show_chat)

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
	if not is_instance_valid(_focused):
		_focused = null
	_crosshair.visible = not in_dialogue
	_prompt.visible = _focused != null and not in_dialogue
	if _focused:
		_prompt.text = "[E] " + _focused.prompt


func _show_message(text: String) -> void:
	_message.text = text
	_message.show()
	_message_timer.start()


## Уведомление «как на телефоне» в правом нижнем углу: выезжает справа.
func _show_chat(author: String, text: String) -> void:
	_chat_author.text = author
	_chat_text.text = text
	_chat_card.show()
	_chat_card.modulate.a = 0.0
	if _chat_tween:
		_chat_tween.kill()
	_chat_tween = create_tween().set_parallel()
	_chat_tween.tween_property(_chat_card, "modulate:a", 1.0, 0.25)
	_chat_tween.tween_property(_chat_card, "offset_left", -400.0, 0.25).from(-340.0)
	_chat_tween.tween_property(_chat_card, "offset_right", -20.0, 0.25).from(40.0)
	_chat_timer.start()


func _hide_chat() -> void:
	if _chat_tween:
		_chat_tween.kill()
	_chat_tween = create_tween()
	_chat_tween.tween_property(_chat_card, "modulate:a", 0.0, 0.4)
	_chat_tween.tween_callback(_chat_card.hide)


func _update_signatures(count: int, total: int) -> void:
	_signatures.text = "Зачётка: %d / %d подписей" % [count, total]


func _update_cheat_sheets(count: int, total: int) -> void:
	_cheat_sheets.text = "Шпоры: %d / %d" % [count, total]
	_cheat_sheets.visible = count > 0
