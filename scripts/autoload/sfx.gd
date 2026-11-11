extends Node

## Звуковые эффекты (автозагрузка Sfx).
## Sfx.play("pickup") — звук интерфейса, Sfx.play_at("ding", позиция) — звук в 3D-пространстве.
## Кнопки интерфейса озвучиваются автоматически.

const SOUND_DIR := "res://assets/audio/sfx/"
const SOUNDS: Array[String] = [
	"click", "interact", "blip", "pickup", "egg", "denied", "ding", "chat", "shuttle",
	"door", "success",
]
const POOL_SIZE := 8

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sound in SOUNDS:
		_streams[sound] = load(SOUND_DIR + sound + ".wav")
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)
	get_tree().node_added.connect(_on_node_added)


func play(sound: String, volume_db := 0.0, pitch := 1.0) -> void:
	var player := _free_player()
	player.stream = _streams[sound]
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()


func play_at(sound: String, position: Vector3, volume_db := 0.0) -> void:
	var player := AudioStreamPlayer3D.new()
	player.stream = _streams[sound]
	player.volume_db = volume_db
	player.finished.connect(player.queue_free)
	get_tree().current_scene.add_child(player)
	player.global_position = position
	player.play()


func _free_player() -> AudioStreamPlayer:
	for player in _pool:
		if not player.playing:
			return player
	return _pool[0]


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(play.bind("click"))
