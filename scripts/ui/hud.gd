extends CanvasLayer

## Игровой интерфейс: прицел, подсказка взаимодействия, сообщения и счётчик подписей.

@onready var _prompt: Label = %Prompt
@onready var _message: Label = %Message
@onready var _signatures: Label = %Signatures
@onready var _message_timer: Timer = %MessageTimer


func _ready() -> void:
	_prompt.hide()
	_message.hide()
	_message_timer.timeout.connect(_message.hide)

	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.focus_changed.connect(_on_focus_changed)
	GameState.message_posted.connect(_show_message)
	GameState.signatures_changed.connect(_update_signatures)
	_update_signatures(GameState.signatures.size(), GameState.TOTAL_SIGNATURES)


func _on_focus_changed(target: Interactable) -> void:
	_prompt.visible = target != null
	if target:
		_prompt.text = "[E] " + target.prompt


func _show_message(text: String) -> void:
	_message.text = text
	_message.show()
	_message_timer.start()


func _update_signatures(count: int, total: int) -> void:
	_signatures.text = "Зачётка: %d / %d подписей" % [count, total]
