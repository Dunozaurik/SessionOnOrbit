extends Room

## Шлюз БЖД. Инструктор Перестрахов подпишет, если выйти в открытый космос
## строго по инструкции и вернуть его кружку, улетевшую за борт.
##
## Порядок (на стене висит только «страница 2» с шагами 4–6):
##   1. надеть скафандр  2. проверить кислород  3. пристегнуть трос
##   4. закрыть внутреннюю дверь  5. разгерметизировать шлюз  6. открыть внешнюю дверь
## Безобидные ошибки — ворчание инструктора. Опасные — «НЕЗАЧЁТ» и попытка заново.

enum Stage { NOT_STARTED, BRIEFED, RETURNED, DONE }

const TEACHER := "Инструктор Перестрахов"
const DOOR_OPEN_SHIFT := 2.7
## Скорость в магнитных ботинках: тяжело, но надёжно.
const BOOTS_WALK_SPEED := 2.2
## Ниже этой высоты снаружи трос возвращает игрока на платформу у шлюза.
const FALL_LIMIT := -6.0
## Сколько разных «незачётов» нужно для пасхалки.
const DEATHS_FOR_EGG := 3

const DEATHS := {
	"station": "Вы разгерметизировали шлюз с открытой внутренней дверью. Вместе со шлюзом — всю станцию.\nДеканат в ярости.",
	"oxygen": "Кислород вы так и не проверили. Через пять минут выяснилось, что баллон пустой.\nПоследнее, что вы услышали: «Я же говорил».",
	"air": "Вы открыли внешнюю дверь, не стравив воздух. Воздух вылетел в космос. Вместе с вами.\nКрасиво, но не по инструкции.",
	"gatchina": "Вы вышли в открытый космос без страховочного троса. Вас унесло в сторону Гатчины-4.\nАндрей передаёт привет.",
}

var stage: Stage:
	get:
		return GameState.flags.get("bzhd_stage", Stage.NOT_STARTED)
	set(value):
		GameState.flags["bzhd_stage"] = value

# Состояние шлюза — сбрасывается при каждом «незачёте» и при входе в отсек.
var _suit := false
var _oxygen := false
var _tether := false
var _inner_closed := false
var _depressurized := false
var _outer_open := false
var _busy := false
## Шлюз заперт навсегда — зачёт уже получен.
var _locked := false
var _boots_explained := false

@onready var _player: Player = $Player
@onready var _inner_door: Node3D = $InnerDoor
@onready var _outer_door: Node3D = $OuterDoor
@onready var _inner_closed_y: float = $InnerDoor.position.y
@onready var _outer_closed_y: float = $OuterDoor.position.y
@onready var _default_walk_speed: float = $Player.walk_speed
@onready var _default_sprint_speed: float = $Player.sprint_speed


func _ready() -> void:
	super._ready()
	$Perestrakhov.interacted.connect(_on_teacher)
	$Poster.interacted.connect(_on_poster)
	$SuitLocker.interacted.connect(_on_suit)
	$OxygenPanel.interacted.connect(_on_oxygen)
	$TetherHook.interacted.connect(_on_tether)
	$InnerButton.interacted.connect(_on_inner_button)
	$PressureLever.interacted.connect(_on_lever)
	$OuterButton.interacted.connect(_on_outer_button)
	$Mug.interacted.connect(_on_mug)
	$AirlockZone.body_entered.connect(_on_airlock_entered)
	$AirlockZone.body_exited.connect(_on_airlock_exited)
	$OutsideZone.body_entered.connect(_on_outside_entered)
	$OutsideZone.body_exited.connect(_on_outside_exited)
	for debris in $Debris.get_children():
		debris.interacted.connect(_on_debris.bind(debris))
	$DeathLayer/Death.hide()
	_inner_door.position.y = _inner_closed_y + DOOR_OPEN_SHIFT
	if GameState.flags.get("bzhd_mug", false):
		$Mug.queue_free()
	if stage >= Stage.RETURNED:
		_lock_airlock(true)
	_update_overlay()


func _process(_delta: float) -> void:
	_update_tether_rope()
	if _player.global_position.y < FALL_LIMIT:
		_player.velocity = Vector3.ZERO
		_player.global_transform = $OutsideSpawn.global_transform
		GameState.post_message("Трос натянулся и вернул вас на платформу. Видите — не зря пристёгивались!")


# --- Инструктор и инструкция ---

func _on_teacher(_player_node: Player) -> void:
	match stage:
		Stage.NOT_STARTED:
			Dialogue.start([
				{"speaker": TEACHER, "text": "Стоять! Каска есть? Нет? Ладно, в космосе каска всё равно не поможет."},
				{
					"speaker": TEACHER,
					"text": "Это БЖД — самый сложный предмет на станции. Программирование сдали? Ха. Это БЖД.",
					"choices": [
						["Почему БЖД сложнее программирования?", [
							{"speaker": TEACHER, "text": "Потому что в программировании ошибка — это баг. А у нас ошибка — это некролог. Отсюда и требования."},
						]],
						["Я буду перестраховываться, честно.", [
							{"speaker": TEACHER, "text": "Перестраховываться — моя работа. Ваша — делать всё строго по инструкции."},
						]],
						["А можно просто тест решить?", [
							{"speaker": TEACHER, "text": "Тест — это в ФОМе. У нас практика. Выживание — это и есть зачёт."},
						]],
					],
				},
				{"speaker": TEACHER, "text": "Задание: выйти в открытый космос и вернуть мою кружку. Она улетела за борт, когда я... перестраховывался."},
				{"speaker": TEACHER, "text": "Инструкция висит на стене. Первая страница, правда, потерялась. Но вы же студент технического вуза — догадаетесь, с чего начинать."},
				{
					"speaker": TEACHER,
					"text": "Всё оборудование — в шлюзе за этой дверью. Ошибётесь — будет незачёт. В лучшем случае.",
					"call": func(): self.stage = Stage.BRIEFED,
				},
			])
		Stage.BRIEFED:
			Dialogue.start([{"speaker": TEACHER, "text": "Инструкция на стене. Начните с того, без чего в космосе не дышат. И не забудьте проверить то, чем дышат."}])
		Stage.RETURNED:
			stage = Stage.DONE
			Dialogue.start([
				{"speaker": TEACHER, "text": "Моя кружка! Цела! Вы первый, кто вернулся с ней, а не вместо неё."},
				{
					"speaker": TEACHER,
					"text": "Зачёт. Перестраховываясь, ставлю две подписи. Шучу. Одну. Но очень уверенно.",
					"call": GameState.add_signature.bind("perestrakhov"),
				},
			])
		Stage.DONE:
			Dialogue.start([{"speaker": TEACHER, "text": "Помните: лучше перебдеть, чем недобдеть. Это не я придумал. Это тоже инструкция."}])


func _on_poster(_player_node: Player) -> void:
	var lines: Array = [{
		"speaker": "Инструкция (страница 2 из 2)",
		"text": "...\n4. Закрыть внутреннюю дверь шлюза.\n5. Разгерметизировать шлюз (рычаг).\n6. Открыть внешнюю дверь.\n\nСтраница 1 утеряна. Шаги 1–3 — по здравому смыслу.",
	}]
	if _death_kinds().size() >= 2:
		lines.append({"speaker": "", "text": "Внизу кто-то приписал ручкой: «1. Скафандр. 2. Кислород. 3. Трос. Не повторяй моих ошибок. — А.Л.»"})
	Dialogue.start(lines)


func _require_briefing() -> bool:
	if stage != Stage.NOT_STARTED:
		return true
	Dialogue.start([{"speaker": TEACHER, "text": "Стоять! Без инструктажа — ни шагу! Подойдите ко мне."}])
	return false


func _grumble(text: String) -> void:
	Sfx.play("denied", -4.0)
	Dialogue.start([{"speaker": TEACHER, "text": text}])


# --- Шаги шлюза ---

func _on_suit(_player_node: Player) -> void:
	if not _require_briefing():
		return
	if _suit:
		GameState.post_message("Скафандр уже на вас. Второй сверху не налезет.")
		return
	_suit = true
	Sfx.play("pickup")
	GameState.post_message("Скафандр надет. Шлем щёлкнул. Дышать стало тесно, но надёжно.")
	_update_overlay()


func _on_oxygen(_player_node: Player) -> void:
	if not _require_briefing():
		return
	if not _suit:
		_grumble("Вы проверили кислород... в комнате. Его тут много, поздравляю. В СКАФАНДРЕ проверять надо!")
		return
	_oxygen = true
	Sfx.play("blip")
	GameState.post_message("Кислород в баллоне скафандра: 100%. Хватит на 6 часов или на одну пару.")
	_update_overlay()


func _on_tether(_player_node: Player) -> void:
	if not _require_briefing():
		return
	if not _suit:
		_grumble("Вы пристегнули страховочный трос к своей футболке. Я даже не знаю, что на это сказать.")
		return
	if _tether:
		GameState.post_message("Трос уже пристёгнут. Дважды пристегнуться — это уже я.")
		return
	_tether = true
	Sfx.play("pickup")
	GameState.post_message("Страховочный трос пристёгнут к поясу скафандра.")
	_update_overlay()


func _on_inner_button(_player_node: Player) -> void:
	if not _require_briefing():
		return
	if _outer_open:
		GameState.post_message("Сначала закройте внешнюю дверь. Хотя бы ради приличия.")
		return
	if not _inner_closed:
		if not _suit:
			_grumble("Куда?! Вы закрываетесь в шлюзе без скафандра. Откройте немедленно — это не по инструкции!")
			return
		_inner_closed = true
		_move_door(_inner_door, _inner_closed_y)
		GameState.post_message("Внутренняя дверь шлюза закрыта.")
	elif not _depressurized:
		_inner_closed = false
		_move_door(_inner_door, _inner_closed_y + DOOR_OPEN_SHIFT)
		GameState.post_message("Внутренняя дверь открыта.")
	else:
		_grumble("Шлюз разгерметизирован! Открыв внутреннюю дверь, вы отправите в космос весь атриум. Включая меня.")


func _on_lever(_player_node: Player) -> void:
	if not _require_briefing():
		return
	if _depressurized:
		GameState.post_message("Шлюз уже разгерметизирован. Воздуха тут больше нет — как и пути назад. Шутка. Путь есть.")
		return
	if not _inner_closed:
		_fail("station")
		return
	if not _oxygen:
		_fail("oxygen")
		return
	_depressurized = true
	Sfx.play("hiss")
	$WarningLight.light_energy = 3.0
	GameState.post_message("Ш-ш-ш-ш... Воздух стравлен. Шлюз разгерметизирован.")


func _on_outer_button(_player_node: Player) -> void:
	if not _require_briefing():
		return
	if _outer_open:
		GameState.post_message("Внешняя дверь уже открыта. Космос ждёт.")
		return
	if not _depressurized:
		_fail("air")
		return
	if not _tether:
		_fail("gatchina")
		return
	_outer_open = true
	_move_door(_outer_door, _outer_closed_y + DOOR_OPEN_SHIFT)
	GameState.post_message("Внешняя дверь открыта. Магнитные ботинки включены. Не смотрите вниз — низа здесь нет.")


func _move_door(door: Node3D, y: float) -> void:
	Sfx.play_at("door", door.global_position)
	create_tween().tween_property(door, "position:y", y, 0.8).set_trans(Tween.TRANS_SINE)


# --- Космос и возвращение ---

func _on_mug(_player_node: Player) -> void:
	GameState.flags["bzhd_mug"] = true
	Sfx.play("pickup")
	GameState.post_message("Кружка поймана! На ней надпись: «Лучший перестраховщик 2056». Теперь — обратно в шлюз.")
	$Mug.queue_free()


func _on_airlock_entered(body: Node3D) -> void:
	if body != _player or not _outer_open or not GameState.flags.get("bzhd_mug", false):
		return
	# Обратный цикл: шлюз всё делает сам — Перестрахов перестраховался.
	_outer_open = false
	_move_door(_outer_door, _outer_closed_y)
	get_tree().create_timer(1.0).timeout.connect(_finish_return)


func _finish_return() -> void:
	Sfx.play("hiss", -4.0)
	_depressurized = false
	$WarningLight.light_energy = 0.0
	_inner_closed = false
	_move_door(_inner_door, _inner_closed_y + DOOR_OPEN_SHIFT)
	_suit = false
	_oxygen = false
	_tether = false
	_update_overlay()
	stage = Stage.RETURNED
	GameState.post_message("Шлюз: обратный цикл выполнен автоматически. Скафандр снят. Инструктор ждёт свою кружку.")


func _on_airlock_exited(body: Node3D) -> void:
	# Вышли из шлюза с кружкой — Перестрахов запирает его, чтобы никто больше не рисковал.
	if body == _player and stage >= Stage.RETURNED and not _locked:
		_lock_airlock(false)


func _lock_airlock(instant: bool) -> void:
	_locked = true
	$AirlockSign.text = "ШЛЮЗ ЗАКРЫТ\n(зачёт получен — перестраховались)"
	if instant:
		_inner_door.position.y = _inner_closed_y
		return
	_move_door(_inner_door, _inner_closed_y)
	GameState.post_message("Перестрахов закрыл шлюз на три замка. «Больше туда никто не пойдёт. На всякий случай».")


# --- Открытый космос: магнитные ботинки ---

func _on_outside_entered(body: Node3D) -> void:
	if body != _player:
		return
	_player.can_jump = false
	_player.walk_speed = BOOTS_WALK_SPEED
	_player.sprint_speed = BOOTS_WALK_SPEED
	if not _boots_explained:
		_boots_explained = true
		Dialogue.start([
			{"speaker": "Скафандр", "text": "Гравитация: 0. Магнитные ботинки: ВКЛЮЧЕНЫ.\nПрыжки отключены — оттолкнётесь и улетите к Гатчине-4."},
			{"speaker": "Скафандр", "text": "Передвигайтесь только по платформам и ферме. Держитесь поручней. Ничего не трогайте. Особенно себя."},
		])


func _on_outside_exited(body: Node3D) -> void:
	if body != _player:
		return
	_player.can_jump = true
	_player.walk_speed = _default_walk_speed
	_player.sprint_speed = _default_sprint_speed


func _on_debris(_player_node: Player, debris: Node3D) -> void:
	Dialogue.start([{"speaker": "Космический мусор", "text": debris.get_meta("description", "Что-то летает. Лучше не трогать.")}])


# --- «Незачёт» ---

func _death_kinds() -> Array:
	return GameState.flags.get("bzhd_deaths", [])


func _fail(kind: String) -> void:
	if _busy:
		return
	_busy = true
	var kinds := _death_kinds()
	if kind not in kinds:
		kinds.append(kind)
		GameState.flags["bzhd_deaths"] = kinds
	Sfx.play("fail")
	GameState.input_locked = true
	# Подсказки и сообщения не должны просвечивать сквозь экран «НЕЗАЧЁТ».
	$HUD.hide()
	$Overlay.hide()
	var death: Control = $DeathLayer/Death
	%DeathReason.text = DEATHS[kind]
	death.modulate.a = 0.0
	death.show()
	var tween := create_tween()
	tween.tween_property(death, "modulate:a", 1.0, 0.4)
	tween.tween_interval(3.2)
	tween.tween_callback(_reset_airlock)
	tween.tween_property(death, "modulate:a", 0.0, 0.5)
	tween.tween_callback(death.hide)
	tween.tween_callback(_after_fail)


func _reset_airlock() -> void:
	_suit = false
	_oxygen = false
	_tether = false
	_inner_closed = false
	_depressurized = false
	_outer_open = false
	_inner_door.position.y = _inner_closed_y + DOOR_OPEN_SHIFT
	_outer_door.position.y = _outer_closed_y
	$WarningLight.light_energy = 0.0
	_player.velocity = Vector3.ZERO
	_player.global_transform = $BriefingSpawn.global_transform
	_update_overlay()


func _after_fail() -> void:
	_busy = false
	$HUD.show()
	$Overlay.show()
	GameState.input_locked = false
	if _death_kinds().size() >= DEATHS_FOR_EGG:
		GameState.find_easter_egg("bzhd_textbook")
	Dialogue.start([{"speaker": TEACHER, "text": "Незачёт. Ничего, на пересдаче все так начинают. Ещё раз — по инструкции."}])


# --- Шлем и трос ---

func _update_overlay() -> void:
	$Overlay/Helmet.visible = _suit
	%SuitStatus.text = "СКАФАНДР  ·  O2: %s  ·  ТРОС: %s" % [
		"100%" if _oxygen else "не проверен", "пристёгнут" if _tether else "—"]


func _update_tether_rope() -> void:
	var rope: MeshInstance3D = $TetherRope
	rope.visible = _tether
	if not _tether:
		return
	var from: Vector3 = $TetherHook.global_position
	var to: Vector3 = _player.global_position + Vector3(0, 1.0, 0)
	var length := from.distance_to(to)
	if length < 0.05:
		return
	rope.global_position = (from + to) * 0.5
	# Цилиндр вытянут по Y — разворачиваем его вдоль троса.
	var axis := (to - from) / length
	var side := axis.cross(Vector3.FORWARD)
	if side.length() < 0.01:
		side = axis.cross(Vector3.RIGHT)
	side = side.normalized()
	rope.global_basis = Basis(side, axis * length, side.cross(axis))
