extends Control

## Экран концовки: заголовок, текст, статистика прохождения и титры по кнопке.
## Какая концовка — берётся из GameState.ending_id (см. Endings).

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const CREDITS_TRACK := "res://assets/audio/music/labodni2.mp3"
## Скорость прокрутки титров, px/с. Песня длится дольше титров: когда они дошли до конца,
## последняя строка остаётся на экране, пока песня не доиграет (или не нажали «Назад»).
const CREDITS_SPEED := 20.0
## На какой высоте экрана (доля от верха) последняя строка останавливается.
const END_SCREEN_FRACTION := 0.4

var _scroll_target_y := 0.0
var _track: AudioStreamPlayer
var _fade_tween: Tween

var _scrolling := false

@onready var _page: Control = %Page
@onready var _credits_view: Control = %CreditsView
@onready var _credits: RichTextLabel = %Credits


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
	_track = AudioStreamPlayer.new()
	_track.bus = Settings.MUSIC_BUS
	_track.stream = load(CREDITS_TRACK)
	_track.finished.connect(_on_track_finished)
	add_child(_track)
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
	_credits.position.y = maxf(_credits.position.y - CREDITS_SPEED * delta, _scroll_target_y)


func _show_credits() -> void:
	_page.hide()
	_credits_view.show()
	_start_credits_track()
	_scrolling = true
	%BackButton.grab_focus()


## Запускает песню и титры: последняя строка встаёт посреди экрана и ждёт конца песни.
func _start_credits_track() -> void:
	Music.fade_out(1.5)
	_credits.reset_size()
	var view_h := _credits_view.size.y
	_credits.position.y = view_h
	_scroll_target_y = view_h * END_SCREEN_FRACTION - _credits.size.y
	_track.volume_db = 0.0
	_track.play()


func _stop_credits_track(fade_time := 0.8) -> void:
	if _fade_tween:
		_fade_tween.kill()
	if not _track.playing:
		return
	_fade_tween = create_tween()
	_fade_tween.tween_property(_track, "volume_db", -60.0, fade_time)
	_fade_tween.tween_callback(_track.stop)


func _on_track_finished() -> void:
	if _scrolling:
		_hide_credits()


func _hide_credits() -> void:
	_scrolling = false
	_stop_credits_track()
	Music.set_menu_mode(false)
	_credits_view.hide()
	_page.show()
	%CreditsButton.grab_focus()


func _to_menu() -> void:
	_stop_credits_track(0.3)
	Transition.go(MAIN_MENU)
