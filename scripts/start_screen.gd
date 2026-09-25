extends Control

const UI = preload("res://scripts/ui_kit.gd")

func _ready() -> void:
	var shade := ColorRect.new()
	shade.position = Vector2.ZERO
	shade.size = Vector2(570, 648)
	shade.color = Color(0.015, 0.045, 0.044, 0.85)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	add_child(UI.label("VARIANT ZERO   /   FIELD STUDY 01", Vector2(62, 59), Vector2(450, 32), 13, UI.LIME, "mono"))
	add_child(UI.line(Vector2(62, 105), 430, UI.LIME))
	add_child(UI.label("VARIANT\nZERO", Vector2(56, 126), Vector2(485, 180), 60, UI.TEXT, "bold"))
	add_child(UI.label("THE GENETICS LAB", Vector2(62, 307), Vector2(430, 28), 18, UI.LIME, "mono"))
	add_child(UI.label("A hypothesis is only the beginning.\nMeet your mentor. Build an organism. Predict its offspring.\nLet the evidence change your mind.", Vector2(62, 354), Vector2(448, 104), 17, UI.TEXT))
	var launch := UI.button("ENTER THE LAB    →", Vector2(62, 491), Vector2(302, 53), true)
	launch.pressed.connect(_enter_lab)
	add_child(launch)
	add_child(UI.label("W A S D  MOVE     •     E  INTERACT     •     ESC  CLOSE", Vector2(62, 568), Vector2(500, 33), 11, UI.MUTED, "mono"))
	var save_label := "NEW STUDY"
	if GameState.has_progress():
		save_label = "PROGRESS SAVED  /  CONTINUE YOUR STUDY"
	add_child(UI.label(save_label, Vector2(62, 607), Vector2(485, 25), 11, UI.CYAN, "mono"))
	launch.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		_enter_lab()

func _enter_lab() -> void:
	get_tree().change_scene_to_file("res://lab.tscn")
