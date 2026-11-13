extends Control

## Экран концовки: заголовок, текст, статистика прохождения и титры по кнопке.
## Какая концовка — берётся из GameState.ending_id (см. Endings).

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const CREDITS_SPEED := 45.0

var _scrolling := false

@onready var _page: Control = %Page
@onready var _credits_view: Control = %CreditsView
@onready var _credits: Label = %Credits


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AndreyTrip.active = false
	var id := GameState.ending_id if Endings.ENDINGS.has(GameState.ending_id) else "normal"
	var ending: Dictionary = Endings.ENDINGS[id]
	%Number.text = "КОНЦОВКА %d ИЗ %d" % [Endings.ORDER.find(id) + 1, Endings.ORDER.size()]
	%Title.text = ending["title"]
	%Text.text = ending["text"]
	%Stats.text = "Подписи: %d / %d   ·   Шпоры: %d / %d   ·   Пасхалки: %d / %d   ·   Время: %s" % [
		GameState.signatures.size(), GameState.TOTAL_SIGNATURES,
		GameState.cheat_sheets, GameState.TOTAL_CHEAT_SHEETS,
		GameState.easter_eggs.size(), GameState.EASTER_EGGS.size(),
		GameState.play_time_text()]
	_credits.text = Endings.CREDITS % Endings.AUTHOR
	_credits_view.hide()
	%CreditsButton.pressed.connect(_show_credits)
	%MenuButton.pressed.connect(_to_menu)
	%BackButton.pressed.connect(_hide_credits)
	Sfx.play("egg")
	# Плавное появление.
	_page.modulate.a = 0.0
	create_tween().tween_property(_page, "modulate:a", 1.0, 1.2)
	%CreditsButton.grab_focus()


func _process(delta: float) -> void:
	if not _scrolling:
		return
	_credits.position.y -= CREDITS_SPEED * delta
	if _credits.position.y + _credits.size.y < 0.0:
		_hide_credits()


func _show_credits() -> void:
	_page.hide()
	_credits_view.show()
	_credits.position.y = _credits_view.size.y
	_scrolling = true
	%BackButton.grab_focus()


func _hide_credits() -> void:
	_scrolling = false
	_credits_view.hide()
	_page.show()
	%CreditsButton.grab_focus()


func _to_menu() -> void:
	Transition.go(MAIN_MENU)
