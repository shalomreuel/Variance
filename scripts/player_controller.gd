class_name PlayerController
extends CharacterBody2D

signal focus_changed(prompt: String)
signal interacted(kind: String)

@export var walk_speed: float = 182.0
var can_move: bool = true
var nearby: Array[Interactable] = []
var current_focus: Interactable
var _stride: float = 0.0

@onready var artwork: Sprite2D = $Artwork

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	if can_move:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * walk_speed
	move_and_slide()
	if direction.length_squared() > 0.01:
		_stride += delta * 12.0
		if absf(direction.x) > 0.01:
			artwork.flip_h = direction.x < 0.0
	else:
		_stride = 0.0
	artwork.position.y = -63.0 + (sin(_stride) * 2.0 if direction.length_squared() > 0.01 else 0.0)
	_update_focus()

func _unhandled_input(event: InputEvent) -> void:
	if can_move and event.is_action_pressed("interact") and not event.is_echo() and current_focus != null:
		interacted.emit(current_focus.kind)
		get_viewport().set_input_as_handled()

func register_interactable(area: Interactable, entering: bool) -> void:
	if entering and not nearby.has(area):
		nearby.append(area)
	elif not entering:
		nearby.erase(area)
	_update_focus()

func _update_focus() -> void:
	var closest: Interactable = null
	var best_distance := INF
	for area in nearby:
		if not is_instance_valid(area):
			continue
		var distance := global_position.distance_squared_to(area.global_position)
		if distance < best_distance:
			best_distance = distance
			closest = area
	if current_focus != closest:
		current_focus = closest
		focus_changed.emit(closest.prompt_text if closest != null else "")
