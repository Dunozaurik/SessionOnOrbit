extends CanvasLayer

## Переходы между сценами с затемнением (автозагрузка Transition).
## Transition.go("res://scenes/levels/atrium.tscn", "FromProgramming") — уйти в сцену
## и появиться у маркера FromProgramming (см. Room).

const FADE_TIME := 0.3

var _busy := false

@onready var _fade: ColorRect = $Fade


func go(scene_path: String, spawn_id := "") -> void:
	if _busy:
		return
	_busy = true
	GameState.spawn_id = spawn_id
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	await create_tween().tween_property(_fade, "color:a", 1.0, FADE_TIME).finished
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
	# Ждём, пока новая сцена появится и расставит игрока.
	await get_tree().process_frame
	await get_tree().process_frame
	await create_tween().tween_property(_fade, "color:a", 0.0, FADE_TIME).finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
