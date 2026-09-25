class_name Interactable
extends Area2D
## Reusable proximity interaction. The player chooses the nearest overlapping area.

@export var kind: String = ""
@export var prompt_text: String = "[E] INTERACT"

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		(body as PlayerController).register_interactable(self, true)

func _on_body_exited(body: Node2D) -> void:
	if body is PlayerController:
		(body as PlayerController).register_interactable(self, false)
