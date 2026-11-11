extends Node3D

## Звёздное небо для открытого космоса: раскидывает светящиеся точки по сфере
## вокруг узла. Одна MultiMesh на все звёзды — дёшево даже для сотен штук.

@export var count := 400
@export var radius := 150.0
@export var seed_value := 1957


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var mesh := SphereMesh.new()
	mesh.radius = 0.25
	mesh.height = 0.5
	mesh.radial_segments = 6
	mesh.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.WHITE
	mesh.material = material

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = count
	for i in count:
		# Равномерно по сфере.
		var direction := Vector3(rng.randfn(), rng.randfn(), rng.randfn()).normalized()
		var size := rng.randf_range(0.4, 1.6)
		multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * size), direction * radius))

	var stars := MultiMeshInstance3D.new()
	stars.multimesh = multimesh
	stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(stars)
