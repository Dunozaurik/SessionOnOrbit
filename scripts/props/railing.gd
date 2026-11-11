extends Node3D

## Ограждение из поручней по списку отрезков на полу (y = 0 в локальных координатах).
## segments — пары точек: [начало1, конец1, начало2, конец2, ...].
## Для каждого отрезка строятся стойки, два горизонтальных поручня и сплошная
## невидимая стенка-коллизия, через которую не пройти.

@export var segments: PackedVector3Array = []
@export var height := 1.1
@export var post_spacing := 1.2
@export var color := Color(0.95, 0.75, 0.1)


func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.4
	material.roughness = 0.4
	for i in range(0, segments.size() - 1, 2):
		_build_segment(segments[i], segments[i + 1], material)


func _build_segment(from: Vector3, to: Vector3, material: Material) -> void:
	var length := from.distance_to(to)
	if length < 0.01:
		return
	var direction := (to - from) / length
	var basis := Basis.looking_at(direction, Vector3.UP)  # -Z смотрит вдоль отрезка
	var middle := (from + to) * 0.5

	# Невидимая стенка на всю высоту поручня — чтобы нельзя было перешагнуть.
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.1, height + 0.2, length)
	shape.shape = box
	body.add_child(shape)
	body.transform = Transform3D(basis, middle + Vector3.UP * (height + 0.2) * 0.5)
	add_child(body)

	# Два горизонтальных поручня.
	for rail_height in [height, height * 0.5]:
		var rail := MeshInstance3D.new()
		var rail_mesh := BoxMesh.new()
		rail_mesh.size = Vector3(0.05, 0.05, length)
		rail_mesh.material = material
		rail.mesh = rail_mesh
		rail.transform = Transform3D(basis, middle + Vector3.UP * rail_height)
		add_child(rail)

	# Стойки.
	var posts := maxi(1, ceili(length / post_spacing))
	for p in posts + 1:
		var post := MeshInstance3D.new()
		var post_mesh := CylinderMesh.new()
		post_mesh.top_radius = 0.025
		post_mesh.bottom_radius = 0.03
		post_mesh.height = height
		post_mesh.radial_segments = 6
		post_mesh.material = material
		post.mesh = post_mesh
		post.position = from.lerp(to, float(p) / posts) + Vector3.UP * height * 0.5
		add_child(post)
