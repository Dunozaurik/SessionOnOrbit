class_name Npc
extends Interactable

## Персонаж: табличка с именем над головой и цветная капсула-заглушка вместо модели.
## Разговор описывается в скрипте уровня через сигнал interacted и Dialogue.start().

@export var display_name := "NPC"
@export var subtitle := ""
@export var color := Color(0.6, 0.6, 0.62)
## false — персонажа пока нет на сцене (невидим и неосязаем), см. set_present().
@export var present := true


func _ready() -> void:
	%NameTag.text = display_name if subtitle.is_empty() else display_name + "\n" + subtitle
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	%Mesh.material_override = material
	set_present(present)


func set_present(value: bool) -> void:
	present = value
	visible = value
	enabled = value
	%Collision.disabled = not value
