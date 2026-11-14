class_name Npc
extends Interactable

## Персонаж: табличка с именем над головой и модель человека (или капсула-заглушка, если модель не задана).
## Разговор описывается в скрипте уровня через сигнал interacted и Dialogue.start().

const IDLE_ANIMATION := "Idle"
## Модели Quaternius иногда держат оружие отдельным узлом — преподавателям оно ни к чему.
const HIDDEN_PART_NAMES: Array[String] = ["Pistol"]
## Костяк, который двигаем в невесомости (имена костей риг-а Quaternius).
const WEIGHTLESS_BONES: Array[String] = ["UpperArm.L", "UpperArm.R", "LowerArm.L", "LowerArm.R", "UpperLeg.L", "UpperLeg.R", "LowerLeg.L", "LowerLeg.R"]
## Насколько широко разведены руки в невесомости (радианы) и как сильно они покачиваются.
const WEIGHTLESS_ARM_SPREAD := 1.05
const WEIGHTLESS_ARM_FLAP := 0.22

@export var display_name := "NPC"
@export var subtitle := ""
## Цвет капсулы-заглушки (используется, только если model_path пуст).
@export var color := Color(0.6, 0.6, 0.62)
## Модель персонажа (.glb из assets/models/characters). Пусто — серая капсула-заглушка (как у Заглушкина).
@export_file("*.glb") var model_path := ""
## false — персонажа пока нет на сцене (невидим и неосязаем), см. set_present().
@export var present := true
## Перекраска материалов модели: {"Имя материала": Color}. Так из одной модели получаются разные люди.
@export var tint: Dictionary = {}

var _animation_player: AnimationPlayer
var _skeleton: Skeleton3D
var _weightless := false
var _weightless_time := 0.0
var _base_poses: Dictionary = {}


func _ready() -> void:
	%NameTag.text = display_name if subtitle.is_empty() else display_name + "\n" + subtitle
	if model_path.is_empty():
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		%Mesh.material_override = material
	else:
		_replace_placeholder_with_model()
	set_present(present)


func _process(delta: float) -> void:
	if _weightless:
		_weightless_time += delta
		_apply_weightless_pose()


func set_present(value: bool) -> void:
	present = value
	visible = value
	enabled = value
	%Collision.disabled = not value


## Включает анимацию модели (Idle, Walk, Wave, Interact...). У капсулы-заглушки ничего не делает.
func play_animation(animation: String) -> void:
	if _animation_player and _animation_player.has_animation(animation):
		_animation_player.play(animation)


## true — персонаж парит в невесомости: разводит руки и ноги и покачивается.
## false — снова стоит как обычно (анимация Idle).
func set_weightless(value: bool) -> void:
	if value == _weightless or _skeleton == null or _animation_player == null:
		return
	_weightless = value
	if value:
		_animation_player.pause()
		_base_poses.clear()
		for bone_name in WEIGHTLESS_BONES:
			var bone := _skeleton.find_bone(bone_name)
			if bone != -1:
				_base_poses[bone] = _skeleton.get_bone_pose(bone)
	else:
		for bone in _base_poses:
			_skeleton.set_bone_pose(bone, _base_poses[bone])
		play_animation(IDLE_ANIMATION)


## Поза невесомости поверх позы Idle: вращаем кости в пространстве скелета.
func _apply_weightless_pose() -> void:
	for bone in _base_poses:
		_skeleton.set_bone_pose(bone, _base_poses[bone])
	var flap := sin(_weightless_time * 1.5) * WEIGHTLESS_ARM_FLAP
	var flap_back := sin(_weightless_time * 1.5 + 1.7) * WEIGHTLESS_ARM_FLAP
	_rotate_bone("UpperArm.L", Vector3.BACK, WEIGHTLESS_ARM_SPREAD + flap)
	_rotate_bone("UpperArm.R", Vector3.BACK, -(WEIGHTLESS_ARM_SPREAD + flap_back))
	_rotate_bone("UpperLeg.L", Vector3.BACK, 0.25 + flap_back * 0.4)
	_rotate_bone("UpperLeg.R", Vector3.BACK, -(0.25 + flap * 0.4))


func _rotate_bone(bone_name: String, axis: Vector3, angle: float) -> void:
	var bone := _skeleton.find_bone(bone_name)
	if bone == -1:
		return
	var pose := _skeleton.get_bone_global_pose(bone)
	pose.basis = Basis(axis, angle) * pose.basis
	_skeleton.set_bone_global_pose(bone, pose)


## Прячет капсулу и глаза, ставит вместо них модель и запускает Idle по кругу.
func _replace_placeholder_with_model() -> void:
	var scene: PackedScene = load(model_path)
	if scene == null:
		push_warning("Не удалось загрузить модель %s у %s" % [model_path, name])
		return
	%Mesh.hide()
	for node_name in ["EyeL", "EyeR"]:
		get_node(node_name).hide()
	var body := scene.instantiate()
	body.name = "Body"
	add_child(body)
	_remove_hidden_parts(body)
	_apply_tint(body)
	_skeleton = _find_node_of_class(body, "Skeleton3D") as Skeleton3D
	_animation_player = _find_animation_player(body)
	if _animation_player:
		for animation_name in [IDLE_ANIMATION, "Walk"]:
			if _animation_player.has_animation(animation_name):
				_animation_player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
		play_animation(IDLE_ANIMATION)


func _find_animation_player(node: Node) -> AnimationPlayer:
	return _find_node_of_class(node, "AnimationPlayer") as AnimationPlayer


func _find_node_of_class(node: Node, class_name_: String) -> Node:
	if node.is_class(class_name_):
		return node
	for child in node.get_children():
		var found := _find_node_of_class(child, class_name_)
		if found:
			return found
	return null


func _remove_hidden_parts(node: Node) -> void:
	for child in node.get_children():
		if child.name in HIDDEN_PART_NAMES:
			child.queue_free()
		else:
			_remove_hidden_parts(child)


## Перекрашивает материалы по именам из tint (у каждого персонажа свои копии материалов).
func _apply_tint(node: Node) -> void:
	if tint.is_empty():
		return
	for child in node.get_children():
		if child is MeshInstance3D:
			var mesh_instance := child as MeshInstance3D
			for surface in mesh_instance.mesh.get_surface_count():
				var original := mesh_instance.mesh.surface_get_material(surface) as StandardMaterial3D
				if original and tint.has(original.resource_name):
					var copy := original.duplicate() as StandardMaterial3D
					copy.albedo_color = tint[original.resource_name]
					mesh_instance.set_surface_override_material(surface, copy)
		_apply_tint(child)
