extends Node3D

## Звёзды за иллюминатором: при загрузке раскидывает по плоскости окна
## маленькие светящиеся точки. Окно лежит в локальной плоскости YZ (смотрит вдоль -X).

@export var size := Vector2(5.0, 1.4)
@export var count := 40
@export var seed_value := 1957


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var mesh := SphereMesh.new()
	mesh.radius = 0.012
	mesh.height = 0.024
	mesh.radial_segments = 6
	mesh.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.WHITE
	material.emission_enabled = true
	material.emission = Color(0.85, 0.9, 1)
	material.emission_energy_multiplier = 3.0
	mesh.material = material
	for i in count:
		var star := MeshInstance3D.new()
		star.mesh = mesh
		star.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		star.position = Vector3(0, rng.randf_range(-size.y, size.y) * 0.5, rng.randf_range(-size.x, size.x) * 0.5)
		star.scale = Vector3.ONE * rng.randf_range(0.6, 1.8)
		add_child(star)
