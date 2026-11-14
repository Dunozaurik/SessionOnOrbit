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
