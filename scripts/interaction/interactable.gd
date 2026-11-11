class_name Interactable
extends StaticBody3D

## Объект, с которым игрок взаимодействует клавишей E.
## Логику реакции подключают к сигналу interacted (в скрипте уровня или наследнике).

signal interacted(player: Player)

## Текст подсказки: «[E] <prompt>»
@export var prompt := "Взаимодействовать"
@export var enabled := true


func interact(player: Player) -> void:
	if enabled:
		Sfx.play("interact", -6.0)
		interacted.emit(player)
