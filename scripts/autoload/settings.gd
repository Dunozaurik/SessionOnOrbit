extends Node

## Настройки игрока (автозагрузка Settings): громкость музыки и эффектов, чувствительность мыши.
## Хранятся в user://settings.cfg и действуют сразу. Шины "Music" и "SFX" создаются здесь же.

signal changed

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

var settings_file := "user://settings.cfg"
## Громкость от 0 до 1 (линейная).
var music_volume := 0.4
var sfx_volume := 0.8
## Множитель к чувствительности мыши игрока.
var mouse_sensitivity := 1.0
var fullscreen := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")
	load_settings()


## F11 переключает полный экран из любого места игры.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F11:
		set_fullscreen(not fullscreen)
		save_settings()
		get_viewport().set_input_as_handled()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_file) == OK:
		music_volume = clampf(config.get_value("audio", "music", music_volume), 0.0, 1.0)
		sfx_volume = clampf(config.get_value("audio", "sfx", sfx_volume), 0.0, 1.0)
		mouse_sensitivity = clampf(config.get_value("input", "mouse", mouse_sensitivity), 0.25, 3.0)
		fullscreen = bool(config.get_value("video", "fullscreen", fullscreen))
	_apply()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("input", "mouse", mouse_sensitivity)
	config.set_value("video", "fullscreen", fullscreen)
	config.save(settings_file)


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply()


func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.25, 3.0)
	_apply()


func _apply() -> void:
	_set_bus_volume(MUSIC_BUS, music_volume)
	_set_bus_volume(SFX_BUS, sfx_volume)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	changed.emit()


func _set_bus_volume(bus: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_mute(index, linear <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.001)))
