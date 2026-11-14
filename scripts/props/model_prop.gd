class_name ModelProp
extends Node3D

## Ставит модель (.glb) вместо кубов-заглушек: масштабирует её до заданных габаритов,
## центрирует по X/Z и ставит на пол (низ модели — на y = 0 этого узла).
## Размеры моделей Kenney нестандартные (стул 0,2 м), поэтому подгоняем по осям под нужный размер.

@export_file("*.glb") var model_path := "":
	set(value):
		model_path = value
		if is_node_ready():
			_build()
## Итоговые габариты в метрах: x — ширина, y — высота, z — глубина.
@export var size := Vector3(1, 1, 1)
## Повернуть на 180° вокруг вертикали (у моделей Kenney «перед» смотрит в +Z, у нашей мебели — в -Z).
@export var flip := false

var _model: Node3D


func _ready() -> void:
	_build()


func _build() -> void:
	if _model:
		_model.queue_free()
		_model = null
	if model_path.is_empty():
		return
	var scene: PackedScene = load(model_path)
	if scene == null:
		push_warning("ModelProp: не удалось загрузить %s" % model_path)
		return
	_model = scene.instantiate()
	add_child(_model)
	var box := _local_aabb(_model, Transform3D.IDENTITY)
	if box.size.x <= 0.0 or box.size.y <= 0.0 or box.size.z <= 0.0:
		return
	var factor := Vector3(size.x / box.size.x, size.y / box.size.y, size.z / box.size.z)
	var center := Vector3(box.position.x + box.size.x * 0.5, box.position.y, box.position.z + box.size.z * 0.5)
	var rotation_basis := Basis(Vector3.UP, PI) if flip else Basis.IDENTITY
	var scale_basis := Basis.from_scale(factor)
	_model.transform = Transform3D(rotation_basis * scale_basis, rotation_basis * (-(scale_basis * center)))


## Габариты всех мешей модели в пространстве её корня (с учётом поворотов и масштабов узлов).
func _local_aabb(node: Node, parent_transform: Transform3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.get_children():
		if not child is Node3D:
			continue
		var child_transform: Transform3D = parent_transform * (child as Node3D).transform
		var sub := AABB()
		if child is MeshInstance3D:
			sub = child_transform * (child as MeshInstance3D).get_aabb()
		else:
			sub = _local_aabb(child, child_transform)
		if sub.size != Vector3.ZERO:
			result = sub if first else result.merge(sub)
			first = false
	return result
