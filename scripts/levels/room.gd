class_name Room
extends Node3D

## Базовый скрипт отсека станции. После перехода через дверь ставит игрока
## к маркеру появления (Marker3D в группе "spawn"), имя которого передала дверь.
## Скрипты конкретных отсеков наследуются от Room и вызывают super._ready().


func _ready() -> void:
	Music.set_menu_mode(false)
	_place_player()


func _place_player() -> void:
	if GameState.spawn_id.is_empty():
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	for marker in get_tree().get_nodes_in_group("spawn"):
		if marker.name == GameState.spawn_id:
			player.global_transform = marker.global_transform
			return
	push_warning("Маркер появления %s не найден в %s" % [GameState.spawn_id, name])
