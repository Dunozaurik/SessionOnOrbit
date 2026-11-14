extends Node

## Фоновая музыка (автозагрузка Music): космический эмбиент по кругу, громкость — шина "Music".
## В меню и прологе играет в полную силу, в самой игре — тихо на фоне (set_menu_mode).
## Дорожка сделана скриптом tools/generate_music.py.

const TRACK := "res://assets/audio/music/ambient.wav"
## Громкость плеера в меню и в игре (дБ). Общий регулятор — в настройках.
const MENU_DB := -7.0
const GAME_DB := -22.0
const FADE_TIME := 1.5

var _player := AudioStreamPlayer.new()
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var stream: AudioStreamWAV = load(TRACK)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2  # 16 бит, моно: кадров вдвое меньше байт
	_player.stream = stream
	_player.bus = Settings.MUSIC_BUS
	_player.volume_db = MENU_DB
	add_child(_player)
	_player.play()


## true — меню и пролог (громко), false — игра (тихий фон). Громкость меняется плавно.
func set_menu_mode(menu: bool) -> void:
	var target := MENU_DB if menu else GAME_DB
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_player, "volume_db", target, FADE_TIME)
