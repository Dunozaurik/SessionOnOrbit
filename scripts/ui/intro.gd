extends Control

## Пролог: короткая предыстория перед первым входом в атриум.
## Дальше — любая клавиша или клик (первое нажатие дописывает текст сразу), Esc — пропустить.

const FIRST_LEVEL := "res://scenes/levels/atrium.tscn"
const CHARS_PER_SECOND := 45.0

var _index := 0
var _typing: Tween
var _finishing := false
var _changing := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Music.set_menu_mode(true)
	%Content.modulate.a = 0.0
	_show_slide()


func _input(event: InputEvent) -> void:
	if _finishing or _changing:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_finish()
		return
	var advance := false
	if event is InputEventKey and event.pressed and not event.echo:
		advance = true
	elif event is InputEventMouseButton and event.pressed:
		advance = true
	if not advance:
		return
	get_viewport().set_input_as_handled()
	if _typing and _typing.is_running():
		_typing.kill()
		%Text.visible_ratio = 1.0
		return
	_next()


func _show_slide() -> void:
	var slide: Dictionary = IntroLines.SLIDES[_index]
	var total: int = IntroLines.SLIDES.size()
	%Title.text = slide["title"]
	%Text.text = slide["text"]
	%Text.visible_ratio = 0.0
	var last := _index == total - 1
	%Hint.text = "Любая клавиша или клик — начать сессию" if last else "Любая клавиша или клик — дальше   ·   Esc — пропустить"
	%Counter.text = "%d / %d" % [_index + 1, total]
	create_tween().tween_property(%Content, "modulate:a", 1.0, 0.35)
	var duration: float = maxf(0.4, float(slide["text"].length()) / CHARS_PER_SECOND)
	_typing = create_tween()
	_typing.tween_property(%Text, "visible_ratio", 1.0, duration)


func _next() -> void:
	if _index >= IntroLines.SLIDES.size() - 1:
		_finish()
		return
	_changing = true
	_index += 1
	var fade := create_tween()
	fade.tween_property(%Content, "modulate:a", 0.0, 0.25)
	await fade.finished
	_show_slide()
	_changing = false


func _finish() -> void:
	if _finishing:
		return
	_finishing = true
	Transition.go(FIRST_LEVEL)
