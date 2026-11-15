class_name RoomSkin
extends Node3D

## «Обшивка» комнаты: поверх голых CSG-коробок (пол, потолок, стены) раскладывает панели Kenney.
## Сами коробки остаются на месте невидимыми — они дают коллизию, а панели только красят.
## Цвет панелей берётся из материала стены/пола комнаты, поэтому у каждой комнаты свой оттенок.

const FLOOR_MODEL := "res://assets/models/station/floor.glb"
const WALL_MODEL := "res://assets/models/station/wall.glb"
## Высота одного яруса панелей: в высоких комнатах (физика, 9,5 м) панели ставятся в несколько ярусов.
const WALL_ROW_HEIGHT := 3.5
## Толщина панелей (м): стена — тоньше коробки, поэтому панель целиком помещается внутри неё.
const WALL_PANEL_DEPTH := 0.3
const FLOOR_PANEL_HEIGHT := 0.4
const CEILING_PANEL_HEIGHT := 0.25

@export var geometry_path: NodePath = ^"../Geometry"
@export var floor_names: PackedStringArray = ["Floor"]
@export var ceiling_names: PackedStringArray = ["Ceiling"]
@export var wall_names: PackedStringArray = ["WallNorth", "WallSouth", "WallEast", "WallWest"]
## Стены, которые видны с обеих сторон (перегородка между двумя комнатами): панели ставятся на обе грани.
@export var double_sided_names: PackedStringArray = []
## Желаемый размер плитки пола и потолка (м).
@export var floor_tile := 2.0
## Насколько оттенок панелей смешивается с белым (0 — цвет коробки, 1 — родной цвет панели).
@export_range(0.0, 1.0) var wall_tint_blend := 0.5
@export_range(0.0, 1.0) var floor_tint_blend := 0.35

## Потолочные светильники: под каждой потолочной лампой (OmniLight3D «Light…») рисуется светящаяся панель.
@export var light_panels := true
@export var light_panel_size := Vector2(1.8, 0.7)
## Лампы с этими фрагментами в имени не потолочные (над столом, подсветка приборов и т. п.).
const LIGHT_NAME_EXCLUDE: Array[String] = ["Desk", "Generator", "Moodle", "Dock", "Glow", "Warning", "Blink"]
## Лампа считается потолочной, если висит не ниже, чем на столько метров под потолком.
const LIGHT_MAX_DROP := 2.2

var _floor_centers: Array[Vector3] = []


func _ready() -> void:
	var geometry := get_node_or_null(geometry_path)
	if geometry == null:
		push_warning("RoomSkin: нет узла геометрии %s" % geometry_path)
		return
	for box_name in floor_names:
		var box := geometry.get_node_or_null(NodePath(box_name)) as CSGBox3D
		if box:
			_floor_centers.append(box.global_position)
	for box_name in floor_names:
		_skin_horizontal(geometry.get_node_or_null(NodePath(box_name)) as CSGBox3D, false)
	for box_name in ceiling_names:
		_skin_horizontal(geometry.get_node_or_null(NodePath(box_name)) as CSGBox3D, true)
	for box_name in wall_names:
		_skin_wall(geometry.get_node_or_null(NodePath(box_name)) as CSGBox3D, box_name in double_sided_names)
	if light_panels:
		_add_ceiling_lights(geometry)


## Пол (плитки floor.glb сверху коробки) или потолок (те же плитки вверх ногами снизу коробки).
func _skin_horizontal(box: CSGBox3D, ceiling: bool) -> void:
	if box == null:
		return
	var box_size := box.size
	var nx := maxi(1, roundi(box_size.x / floor_tile))
	var nz := maxi(1, roundi(box_size.z / floor_tile))
	var tile_height := CEILING_PANEL_HEIGHT if ceiling else FLOOR_PANEL_HEIGHT
	var tile := Vector3(box_size.x / nx, tile_height, box_size.z / nz)
	var tint := _tint_of(box, floor_tint_blend)
	var corner := box.global_position - Vector3(box_size.x, 0, box_size.z) * 0.5
	var top := box.global_position.y + box_size.y * 0.5
	var bottom := box.global_position.y - box_size.y * 0.5
	for ix in nx:
		for iz in nz:
			var prop := ModelProp.new()
			prop.model_path = FLOOR_MODEL
			prop.size = tile
			prop.tint = tint
			add_child(prop)
			var center := corner + Vector3((ix + 0.5) * tile.x, 0, (iz + 0.5) * tile.z)
			if ceiling:
				prop.global_position = Vector3(center.x, bottom + tile.y, center.z)
				prop.rotation = Vector3(PI, 0, 0)
			else:
				prop.global_position = Vector3(center.x, top - tile.y, center.z)
	box.visible = false


## Стена: ряд панелей вдоль коробки, лицом в сторону ближайшего пола (и в обратную, если стена двусторонняя).
func _skin_wall(box: CSGBox3D, double_sided: bool) -> void:
	if box == null:
		return
	var box_size := box.size
	var along_x := box_size.x >= box_size.z
	var inward := _inward_direction(box.global_position, along_x)
	var yaw := 0.0
	if along_x:
		yaw = 0.0 if inward.z > 0.0 else PI
	else:
		yaw = PI * 0.5 if inward.x > 0.0 else -PI * 0.5
	_build_wall_side(box, along_x, yaw)
	if double_sided:
		_build_wall_side(box, along_x, yaw + PI)
	box.visible = false


func _build_wall_side(box: CSGBox3D, along_x: bool, yaw: float) -> void:
	var box_size := box.size
	var length := box_size.x if along_x else box_size.z
	var rows := maxi(1, ceili(box_size.y / WALL_ROW_HEIGHT - 0.01))
	var row_height := box_size.y / rows
	var count := maxi(1, roundi(length / row_height))
	var tile_width := length / count
	var center := box.global_position
	var tint := _tint_of(box, wall_tint_blend)
	var bottom := center.y - box_size.y * 0.5
	for row in rows:
		for i in count:
			var offset := -length * 0.5 + (i + 0.5) * tile_width
			var prop := ModelProp.new()
			prop.model_path = WALL_MODEL
			prop.size = Vector3(tile_width, row_height, WALL_PANEL_DEPTH)
			prop.tint = tint
			add_child(prop)
			var y := bottom + row * row_height
			if along_x:
				prop.global_position = Vector3(center.x + offset, y, center.z)
			else:
				prop.global_position = Vector3(center.x, y, center.z + offset)
			prop.rotation = Vector3(0, yaw, 0)


## В какую сторону смотрит внутренняя поверхность стены: к ближайшему полу.
func _inward_direction(wall_center: Vector3, along_x: bool) -> Vector3:
	var nearest := Vector3.ZERO
	var best := INF
	for floor_center in _floor_centers:
		var distance := wall_center.distance_to(floor_center)
		if distance < best:
			best = distance
			nearest = floor_center
	var direction := nearest - wall_center
	if along_x:
		return Vector3(0, 0, signf(direction.z))
	return Vector3(signf(direction.x), 0, 0)


## Оттенок панелей: цвет материала коробки, разбавленный белым (иначе тёмный пол убил бы свет в комнате).
func _tint_of(box: CSGBox3D, blend: float) -> Color:
	var material := box.material as StandardMaterial3D
	var color := material.albedo_color if material else Color.WHITE
	return color.lerp(Color.WHITE, blend)


## Под каждой потолочной лампой — светящаяся панель; сама лампа поднимается почти к потолку, чтобы свет шёл «из панели».
func _add_ceiling_lights(geometry: Node) -> void:
	var ceilings: Array[CSGBox3D] = []
	for box_name in ceiling_names:
		var box := geometry.get_node_or_null(NodePath(box_name)) as CSGBox3D
		if box:
			ceilings.append(box)
	for child in get_parent().get_children():
		if not (child is OmniLight3D) or not child.name.begins_with("Light"):
			continue
		var excluded := false
		for part in LIGHT_NAME_EXCLUDE:
			if part in child.name:
				excluded = true
		if excluded:
			continue
		var light := child as OmniLight3D
		var bottom := _ceiling_bottom_above(light.global_position, ceilings)
		if is_inf(bottom) or light.global_position.y < bottom - LIGHT_MAX_DROP:
			continue
		_build_light_panel(Vector3(light.global_position.x, bottom, light.global_position.z))
		light.global_position.y = bottom - 0.4


## Нижняя грань потолка над точкой (INF, если над ней нет потолка).
func _ceiling_bottom_above(point: Vector3, ceilings: Array[CSGBox3D]) -> float:
	for ceiling in ceilings:
		var local := point - ceiling.global_position
		if absf(local.x) <= ceiling.size.x * 0.5 and absf(local.z) <= ceiling.size.z * 0.5:
			return ceiling.global_position.y - ceiling.size.y * 0.5
	return INF


func _build_light_panel(center: Vector3) -> void:
	var frame_material := StandardMaterial3D.new()
	frame_material.albedo_color = Color(0.16, 0.18, 0.26)
	frame_material.metallic = 0.6
	frame_material.roughness = 0.4
	var plate_material := StandardMaterial3D.new()
	plate_material.albedo_color = Color(0.92, 0.96, 1.0)
	plate_material.emission_enabled = true
	plate_material.emission = Color(0.88, 0.94, 1.0)
	plate_material.emission_energy_multiplier = 2.4
	var divider_material := StandardMaterial3D.new()
	divider_material.albedo_color = Color(0.5, 0.55, 0.7)
	divider_material.emission_enabled = true
	divider_material.emission = Color(0.55, 0.62, 0.85)
	divider_material.emission_energy_multiplier = 0.6
	var frame := _panel_box("LightFrame", Vector3(light_panel_size.x + 0.16, 0.05, light_panel_size.y + 0.16), frame_material)
	frame.global_position = center + Vector3(0, -0.02, 0)
	var plate := _panel_box("LightPlate", Vector3(light_panel_size.x, 0.03, light_panel_size.y), plate_material)
	plate.global_position = center + Vector3(0, -0.055, 0)
	# Две тонкие перекладины делят панель на три секции.
	for i in 2:
		var divider := _panel_box("LightDivider", Vector3(0.03, 0.035, light_panel_size.y), divider_material)
		divider.global_position = center + Vector3(-light_panel_size.x / 6.0 + i * light_panel_size.x / 3.0, -0.057, 0)


func _panel_box(box_name: String, box_size: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = box_name
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh.material = material
	instance.mesh = mesh
	add_child(instance)
	return instance
