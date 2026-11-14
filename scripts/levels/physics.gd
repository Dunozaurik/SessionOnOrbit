extends Room

## Лаборатория физики. Сломался генератор гравитации: предметы летают, гравитация
## для игрока ослаблена. Доц. Невесомовой нужны 3 предохранителя: один парит под
## потолком (допрыгнуть по летающим ящикам), один в шкафу с приборами, третий —
## у неё в кармане. Вставил в генератор — всё с грохотом падает, подпись у Невесомовой.

enum Stage { NOT_STARTED, SEARCHING, FIXED, DONE }

const TEACHER := "Доц. Невесомова"
const FUSES: Array[String] = ["fuse_ceiling", "fuse_cabinet", "fuse_pocket"]
## Гравитация для игрока, пока генератор сломан: прыжки почти втрое выше и медленнее.
## (По сюжету на предметы гравитация не действует совсем, а на студентов давит сессия.)
const LOW_GRAVITY := 0.35
const TEACHER_HOVER := 0.35

var stage: Stage:
	get:
		return GameState.flags.get("physics_stage", Stage.NOT_STARTED)
	set(value):
		GameState.flags["physics_stage"] = value

var _time := 0.0

@onready var _player: Player = $Player
@onready var _teacher: Npc = $Nevesomova
@onready var _apple: Interactable = $Apple


func _ready() -> void:
	super._ready()
	_teacher.interacted.connect(_on_teacher)
	$Generator.interacted.connect(_on_generator)
	$Cabinet.interacted.connect(_on_cabinet)
	$FuseCeiling.interacted.connect(_on_ceiling_fuse)
	_apple.interacted.connect(_on_apple)
	$Chalkboard.interacted.connect(_on_chalkboard)
	# Уходя из лаборатории, запоминаем, где лежат упавшие предметы.
	$ExitDoor.interacted.connect(_save_props.unbind(1))
	if _is_fixed():
		_apply_fixed_state(true)
		_restore_props()
	else:
		_player.gravity_scale = LOW_GRAVITY
		# Пока гравитации нет, Невесомова парит и разводит руками, как в невесомости.
		_teacher.set_weightless(true)
		GameState.post_message("Ноги отрываются от пола подозрительно легко. Гравитация здесь явно барахлит.")
	if GameState.flags.get("fuse_ceiling", false):
		$FuseCeiling.queue_free()


func _process(delta: float) -> void:
	if _is_fixed():
		return
	# Невесомова и яблоко парят, пока генератор не починен.
	_time += delta
	_teacher.position.y = TEACHER_HOVER + sin(_time * 1.3) * 0.1
	_apple.position.y = 1.7 + sin(_time * 0.9 + 1.0) * 0.08
	_apple.rotate_y(delta * 0.4)


func _is_fixed() -> bool:
	return GameState.flags.get("physics_fixed", false)


func _fuse_count() -> int:
	var count := 0
	for fuse in FUSES:
		if GameState.flags.get(fuse, false):
			count += 1
	return count


func _take_fuse(fuse: String, text: String) -> void:
	GameState.flags[fuse] = true
	Sfx.play("pickup")
	GameState.post_message("%s Предохранители: %d / %d" % [text, _fuse_count(), FUSES.size()])


func _on_teacher(_player_node: Player) -> void:
	match stage:
		Stage.NOT_STARTED:
			# Объяснение про гравитацию звучит один раз: либо как ответ на вопрос, либо следом за другим ответом.
			var gravity_note := {"speaker": TEACHER, "text": "Заметили, как высоко прыгается? На людей гравитация сейчас действует только на треть — предметам повезло меньше, на них не действует вовсе. Это нам и поможет."}
			Dialogue.start([
				{"speaker": TEACHER, "text": "Осторожно, не ударьтесь о стул! Он летает с самого утра."},
				{
					"speaker": TEACHER,
					"text": "У нас сломался генератор гравитации. Перегорели три предохранителя — и всё, что не прикручено, улетело.",
					"choices": [
						["А вы почему тоже парите?", [
							{"speaker": TEACHER, "text": "Я не парю. Я левитирую от возмущения."},
							gravity_note,
						]],
						["Это вообще безопасно?", [
							{"speaker": TEACHER, "text": "По технике безопасности — нет. Но инструктор по БЖД сейчас тоже где-то летает, так что жаловаться некому."},
							gravity_note,
						]],
						["А почему я тогда не летаю?", [
							{"speaker": TEACHER, "text": "Хороший вопрос. Генератор сломан не до конца: на предметы гравитация не действует совсем, а на людей — только на треть."},
							{"speaker": TEACHER, "text": "А на студентов ещё давит сессия. Это тоже своего рода гравитация. Поэтому вы прыгаете высоко, но не улетаете. Пока что."},
						]],
					],
				},
				{"speaker": TEACHER, "text": "Нужно три запасных предохранителя. Один улетел под самый потолок — придётся прыгать по летающим ящикам у правой стены. Только они, сами видите, на месте не стоят. Второй где-то в шкафу с приборами. А третий... не помню."},
				{
					"speaker": TEACHER,
					"text": "Вставите все три в генератор у стены — и я подпишу зачётку. Если, конечно, смогу удержать ручку.",
					"call": func(): self.stage = Stage.SEARCHING,
				},
			])
		Stage.SEARCHING:
			var has_others: bool = GameState.flags.get("fuse_ceiling", false) and GameState.flags.get("fuse_cabinet", false)
			if has_others and not GameState.flags.get("fuse_pocket", false):
				Dialogue.start([
					{"speaker": TEACHER, "text": "Два нашли? Отлично. А третий... так, дайте-ка посмотрю в карманах."},
					{
						"speaker": TEACHER,
						"text": "Ой. Вот же он. В кармане. С утра лежал. Физика — наука о внимательности, как видите.",
						"call": _take_fuse.bind("fuse_pocket", "Невесомова отдала предохранитель из кармана."),
					},
					{"speaker": TEACHER, "text": "Несите все три к генератору!"},
				])
			elif _fuse_count() == FUSES.size():
				Dialogue.start([{"speaker": TEACHER, "text": "Все три у вас? Чего ждёте — к генератору у стены, скорее!"}])
			else:
				Dialogue.start([{"speaker": TEACHER, "text": "Один предохранитель — под самым потолком: начните с ящика у правой стены и прыгайте всё выше. Второй — в шкафу с приборами у левой. У вас сейчас: %d / 3." % _fuse_count()}])
		Stage.FIXED:
			Dialogue.start([
				{"speaker": TEACHER, "text": "Гравитация вернулась! А вместе с ней — и мой авторитет."},
				{
					"speaker": TEACHER,
					"text": "Подписываю. Ровно. Впервые за весь день.",
					"call": _sign,
				},
			])
		Stage.DONE:
			Dialogue.start([{"speaker": TEACHER, "text": "Спасибо. Если что-то снова полетит — это уже не я. Это, наверное, сессия."}])


## Подпись и завершение задания — одним действием, на реплике с подписью.
## Если выйти из диалога раньше, задание не считается сданным и разговор можно повторить.
func _sign() -> void:
	stage = Stage.DONE
	GameState.add_signature("nevesomova")


func _on_ceiling_fuse(_player_node: Player) -> void:
	_take_fuse("fuse_ceiling", "Предохранитель снят из-под потолка!")
	$FuseCeiling.queue_free()


func _on_cabinet(_player_node: Player) -> void:
	if GameState.flags.get("fuse_cabinet", false):
		Dialogue.start([{"speaker": "", "text": "В шкафу: осциллограф, маятник Фуко (остановился, обиделся) и чей-то конспект 2003 года."}])
		return
	Dialogue.start([
		{"speaker": "", "text": "В шкафу с приборами: осциллограф, маятник Фуко, три линейки и банка с надписью «НЕ ОТКРЫВАТЬ (электроны)»."},
		{
			"speaker": "",
			"text": "А за банкой — предохранитель! Немного пыльный, но рабочий.",
			"call": _take_fuse.bind("fuse_cabinet", "Предохранитель найден в шкафу!"),
		},
	])


func _on_generator(_player_node: Player) -> void:
	if _is_fixed():
		GameState.post_message("Генератор гравитации ровно гудит. Всё лежит там, где и должно.")
		return
	var count := _fuse_count()
	if count < FUSES.size():
		Sfx.play("denied", -4.0)
		GameState.post_message("Генератору нужно 3 предохранителя. У тебя: %d." % count)
		return
	_fix_gravity()


func _fix_gravity() -> void:
	GameState.flags["physics_fixed"] = true
	stage = Stage.FIXED
	Sfx.play("success")
	_apply_fixed_state(false)
	# Грохот падающих предметов — вразнобой.
	for i in 6:
		get_tree().create_timer(0.25 + i * 0.18 + randf() * 0.1).timeout.connect(Sfx.play.bind("thud", -2.0, randf_range(0.8, 1.2)))
	Dialogue.start([
		{"speaker": "", "text": "*щёлк-щёлк-щёлк* Генератор загудел. Гравитация возвращается..."},
		{"speaker": "", "text": "*БА-БАХ* Всё, что летало, разом падает на пол. Где-то разбилась колба."},
		{"speaker": TEACHER, "text": "Ай! ...Вот это я понимаю — эксперимент. Идите сюда, распишусь."},
	])


## Возвращает гравитацию: предметы падают, ящики и Невесомова опускаются на пол.
func _apply_fixed_state(instant: bool) -> void:
	_player.gravity_scale = 1.0
	$GeneratorLabel.text = "ГЕНЕРАТОР ГРАВИТАЦИИ\nстатус: всё упало (норма)"
	for prop in $FloatingProps.get_children():
		prop.restore_gravity()
	for platform in $Platforms.get_children():
		platform.drop(instant)
	var apple_floor := Vector3(_apple.position.x, 0.08, _apple.position.z)
	if instant:
		_teacher.position.y = 0.0
		_teacher.set_weightless(false)
		_apple.position = apple_floor
	else:
		# Приземлилась — опускает руки и стоит как обычно.
		var landing := create_tween()
		landing.tween_property(_teacher, "position:y", 0.0, 0.35).set_ease(Tween.EASE_IN)
		landing.tween_callback(_teacher.set_weightless.bind(false))
		create_tween().tween_property(_apple, "position", apple_floor, 0.55) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _save_props() -> void:
	if not _is_fixed():
		return
	var saved := {}
	for prop in $FloatingProps.get_children():
		saved[prop.name] = prop.global_transform
	GameState.flags["physics_props"] = saved


## Кладёт предметы туда, где они лежали, когда игрок уходил, — без повторного падения.
## Предметы замораживаются: они уже лежат, а столкновения CSG-пола появляются
## на пару кадров позже, и без заморозки предметы провалились бы сквозь него.
func _restore_props() -> void:
	var saved: Dictionary = GameState.flags.get("physics_props", {})
	for prop in $FloatingProps.get_children():
		if saved.has(prop.name):
			prop.freeze = true
			prop.global_transform = saved[prop.name]


func _on_apple(_player_node: Player) -> void:
	if not _is_fixed():
		GameState.flags["apple_floating_seen"] = true
		Dialogue.start([{"speaker": "Яблоко Ньютона", "text": "Яблоко висит в воздухе и наотрез отказывается падать. Ньютон бы расстроился."}])
		return
	Dialogue.start([{"speaker": "Яблоко Ньютона", "text": "Яблоко лежит на полу. Закон всемирного тяготения подтверждён. Опять."}])
	if GameState.flags.get("apple_floating_seen", false):
		GameState.find_easter_egg("newton")


func _on_chalkboard(_player_node: Player) -> void:
	Dialogue.start([{"speaker": "Доска", "text": "F = ma\n(кроме понедельников и дней сессии)\n\nНиже мелом: «g = 9,8. Сегодня — 3,4 для людей и 0 для всего остального. Не ругайтесь, чиним»."}])
