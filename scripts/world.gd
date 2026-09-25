extends Node2D

const UI = preload("res://scripts/ui_kit.gd")
const PROFESSOR_SCENE = preload("res://professor_ui.tscn")
const LAB_SCENE = preload("res://code_editor.tscn")

@onready var player: PlayerController = $Player
@onready var hud: CanvasLayer = $WorldHUD
var prompt_panel: Panel
var prompt_label: Label
var objective_label: Label
var status_label: Label
var toast_label: Label
var open_overlay: Control
var _toast_time: float = 0.0

func _ready() -> void:
	player.focus_changed.connect(_on_focus_changed)
	player.interacted.connect(_on_interaction)
	GameState.quest_changed.connect(_update_hud)
	GameState.experiment_completed.connect(_update_hud)
	_build_hud()
	_update_hud()

func _build_hud() -> void:
	var bar := UI.panel(Vector2(24, 18), Vector2(1104, 76), Color(0.02, 0.07, 0.07, 0.90))
	hud.add_child(bar)
	bar.add_child(UI.label("VZ // LAB 01", Vector2(20, 9), Vector2(195, 31), 20, UI.LIME, "bold"))
	bar.add_child(UI.label("THE GENETICS LAB  •  RESEARCH FLOOR", Vector2(20, 43), Vector2(410, 25), 11, UI.MUTED, "mono"))
	bar.add_child(UI.line(Vector2(205, 18), 1, UI.LIME))
	objective_label = UI.label("", Vector2(455, 13), Vector2(625, 35), 15, UI.TEXT)
	bar.add_child(objective_label)
	status_label = UI.label("", Vector2(455, 48), Vector2(625, 21), 11, UI.CYAN, "mono")
	bar.add_child(status_label)

	var professor_tag := UI.panel(Vector2(735, 240), Vector2(185, 31), Color(0.02, 0.07, 0.07, 0.86))
	hud.add_child(professor_tag)
	professor_tag.add_child(UI.label("01   PROFESSOR", Vector2(10, 3), Vector2(171, 23), 11, UI.LIME, "mono"))
	var computer_tag := UI.panel(Vector2(222, 315), Vector2(190, 31), Color(0.02, 0.07, 0.07, 0.86))
	hud.add_child(computer_tag)
	computer_tag.add_child(UI.label("02   GENETICS LAB", Vector2(10, 3), Vector2(178, 23), 11, UI.CYAN, "mono"))

	prompt_panel = UI.panel(Vector2(411, 565), Vector2(330, 55), Color(0.02, 0.09, 0.08, 0.98))
	hud.add_child(prompt_panel)
	prompt_label = UI.label("", Vector2(20, 11), Vector2(295, 35), 17, UI.LIME, "bold")
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_panel.add_child(prompt_label)
	prompt_panel.hide()

	toast_label = UI.label("", Vector2(265, 524), Vector2(622, 36), 13, UI.AMBER, "mono")
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(toast_label)
	hud.add_child(UI.label("WASD / MOVE                                              E / INTERACT", Vector2(25, 617), Vector2(600, 22), 11, UI.MUTED, "mono"))

func _update_hud(_unused: Variant = null) -> void:
	var quest: Dictionary = GameState.current_quest
	if quest.is_empty():
		objective_label.text = "Find the Professor to begin your study."
		status_label.text = "START → PROFESSOR → QUEST → LAB"
	elif GameState.status == "awaiting_professor":
		objective_label.text = "Evidence recorded. Return to the Professor."
		status_label.text = "EXPERIMENT COMPLETE  /  DEBRIEF REQUIRED"
	else:
		objective_label.text = str(quest.get("quest_title", "Current investigation"))
		status_label.text = "ACTIVE QUEST  /  " + str(quest.get("concept", "GENETICS")).to_upper() + "  /  WALK TO THE COMPUTER"

func _on_focus_changed(prompt: String) -> void:
	prompt_panel.visible = not prompt.is_empty() and open_overlay == null
	prompt_label.text = prompt

func _on_interaction(kind: String) -> void:
	if open_overlay != null:
		return
	if kind == "professor":
		_open(PROFESSOR_SCENE)
	elif kind == "computer":
		if GameState.current_quest.is_empty():
			_show_toast("Speak to the Professor and accept a quest first.")
		else:
			_open(LAB_SCENE)

func _open(scene: PackedScene) -> void:
	player.can_move = false
	prompt_panel.hide()
	open_overlay = scene.instantiate() as Control
	hud.add_child(open_overlay)
	open_overlay.connect("closed", _on_overlay_closed)

func _on_overlay_closed() -> void:
	if open_overlay != null:
		open_overlay.queue_free()
		open_overlay = null
	player.can_move = true
	_on_focus_changed(player.current_focus.prompt_text if player.current_focus != null else "")
	_update_hud()

func _show_toast(text: String) -> void:
	toast_label.text = text
	_toast_time = 3.0

func _process(delta: float) -> void:
	if _toast_time > 0.0:
		_toast_time -= delta
		if _toast_time <= 0.0:
			toast_label.text = ""
