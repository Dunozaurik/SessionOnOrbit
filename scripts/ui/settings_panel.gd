extends Control

## Окно настроек: громкость музыки и эффектов, чувствительность мыши.
## Открывается из главного меню и из паузы. Esc или «Закрыть» сохраняет настройки и закрывает окно.

signal closed


func _ready() -> void:
	hide()
	%MusicSlider.value_changed.connect(_on_music_changed)
	%SfxSlider.value_changed.connect(_on_sfx_changed)
	%MouseSlider.value_changed.connect(_on_mouse_changed)
	%SfxSlider.drag_ended.connect(func(_changed: bool) -> void: Sfx.play("ding"))
	%FullscreenToggle.toggled.connect(_on_fullscreen_toggled)
	Settings.changed.connect(_sync_fullscreen)
	%CloseButton.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	%MusicSlider.set_value_no_signal(Settings.music_volume * 100.0)
	%SfxSlider.set_value_no_signal(Settings.sfx_volume * 100.0)
	%MouseSlider.set_value_no_signal(Settings.mouse_sensitivity * 100.0)
	_refresh_labels()
	_sync_fullscreen()
	show()
	%CloseButton.grab_focus()


func close() -> void:
	if not visible:
		return
	Settings.save_settings()
	hide()
	closed.emit()


func _on_music_changed(value: float) -> void:
	Settings.set_music_volume(value / 100.0)
	_refresh_labels()


func _on_sfx_changed(value: float) -> void:
	Settings.set_sfx_volume(value / 100.0)
	_refresh_labels()


func _on_mouse_changed(value: float) -> void:
	Settings.set_mouse_sensitivity(value / 100.0)
	_refresh_labels()


func _on_fullscreen_toggled(pressed: bool) -> void:
	Settings.set_fullscreen(pressed)


## Кнопка всегда показывает реальное состояние (F11 мог переключить режим, пока окно открыто).
func _sync_fullscreen() -> void:
	%FullscreenToggle.set_pressed_no_signal(Settings.fullscreen)
	%FullscreenToggle.text = "Включён" if Settings.fullscreen else "Выключен"


func _refresh_labels() -> void:
	%MusicValue.text = "%d%%" % roundi(Settings.music_volume * 100.0)
	%SfxValue.text = "%d%%" % roundi(Settings.sfx_volume * 100.0)
	%MouseValue.text = "%d%%" % roundi(Settings.mouse_sensitivity * 100.0)
