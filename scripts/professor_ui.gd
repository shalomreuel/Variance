extends Control

signal closed

const UI = preload("res://scripts/ui_kit.gd")
const MENTOR = preload("res://scripts/local_professor.gd")

var proposed_quest: Dictionary = {}
var speech: Label
var feedback: Label
var quest_details: Label
var mastery_details: Label
var input: LineEdit
var action: Button
var connection: Label

func _ready() -> void:
	_build()
	_refresh()
	if GameState.status == "awaiting_professor":
		var local: String = MENTOR.analyze(GameState.last_result)
		speech.text = local
		AIManager.request_analyze(GameState.professor_context(), local, _on_analysis)

func _build() -> void:
	var veil := ColorRect.new()
	veil.color = Color(0.005, 0.019, 0.018, 0.79)
	veil.size = Vector2(1152, 648)
	add_child(veil)
	var frame := UI.panel(Vector2(55, 40), Vector2(1042, 570), Color(0.025, 0.065, 0.066, 0.98))
	add_child(frame)
	frame.add_child(UI.label("01  /  RESEARCH MENTOR", Vector2(28, 19), Vector2(550, 34), 22, UI.LIME, "bold"))
	frame.add_child(UI.label("OBSERVE  →  ASK  →  TEST  →  REVISE", Vector2(29, 54), Vector2(600, 24), 11, UI.MUTED, "mono"))
	frame.add_child(UI.line(Vector2(27, 84), 985))
	var exit_button := UI.button("CLOSE  ×", Vector2(909, 19), Vector2(104, 40))
	exit_button.pressed.connect(func() -> void: closed.emit())
	frame.add_child(exit_button)

	frame.add_child(UI.label("PROFESSOR  /  FIELD NOTES", Vector2(30, 99), Vector2(560, 26), 12, UI.CYAN, "mono"))
	var speech_card := UI.panel(Vector2(28, 128), Vector2(613, 142), Color(0.065, 0.13, 0.115))
	frame.add_child(speech_card)
	speech = UI.label("", Vector2(16, 14), Vector2(581, 114), 15, UI.TEXT)
	speech_card.add_child(speech)
	frame.add_child(UI.label("YOUR HYPOTHESIS", Vector2(30, 284), Vector2(440, 22), 12, UI.CYAN, "mono"))
	var guess_1 := UI.button("The stronger allele", Vector2(28, 312), Vector2(194, 37))
	var guess_2 := UI.button("Shows with one copy", Vector2(231, 312), Vector2(202, 37))
	var guess_3 := UI.button("I'm not sure", Vector2(442, 312), Vector2(199, 37))
	frame.add_child(guess_1)
	frame.add_child(guess_2)
	frame.add_child(guess_3)
	guess_1.pressed.connect(_suggest.bind("I think dominant means the stronger allele."))
	guess_2.pressed.connect(_suggest.bind("A dominant allele shows with one copy in a heterozygote."))
	guess_3.pressed.connect(_suggest.bind("I'm not sure what dominant means yet."))

	input = LineEdit.new()
	input.position = Vector2(28, 360)
	input.size = Vector2(490, 43)
	input.placeholder_text = "Or write your own answer / question…"
	input.max_length = 300
	input.add_theme_stylebox_override("normal", UI.box(Color(0.045, 0.11, 0.10), UI.CYAN))
	input.add_theme_color_override("font_color", UI.TEXT)
	input.add_theme_color_override("font_placeholder_color", UI.MUTED)
	input.add_theme_font_override("font", UI.FONT)
	input.add_theme_font_size_override("font_size", 14)
	input.text_submitted.connect(func(_text: String) -> void: _submit_answer())
	frame.add_child(input)
	var send := UI.button("SEND ↗", Vector2(527, 360), Vector2(114, 43), true)
	send.pressed.connect(_submit_answer)
	frame.add_child(send)
	var feedback_card := UI.panel(Vector2(28, 416), Vector2(613, 91), Color(0.042, 0.10, 0.09))
	frame.add_child(feedback_card)
	feedback = UI.label("Reply to begin your investigation. A guess is useful data, not a grade.", Vector2(13, 11), Vector2(582, 70), 13, UI.TEXT)
	feedback_card.add_child(feedback)

	frame.add_child(UI.label("LEARNER SIGNAL", Vector2(669, 99), Vector2(335, 22), 12, UI.CYAN, "mono"))
	var telemetry := UI.panel(Vector2(665, 128), Vector2(348, 183), Color(0.042, 0.10, 0.09))
	frame.add_child(telemetry)
	mastery_details = UI.label("", Vector2(17, 13), Vector2(318, 160), 12, UI.TEXT, "mono")
	telemetry.add_child(mastery_details)
	frame.add_child(UI.label("CURRENT INVESTIGATION", Vector2(669, 321), Vector2(335, 23), 12, UI.CYAN, "mono"))
	var quest_card := UI.panel(Vector2(665, 348), Vector2(348, 159), Color(0.042, 0.10, 0.09))
	frame.add_child(quest_card)
	quest_details = UI.label("", Vector2(15, 11), Vector2(318, 137), 13, UI.TEXT)
	quest_card.add_child(quest_details)

	action = UI.button("PLAN A QUEST  →", Vector2(665, 518), Vector2(348, 43), true)
	action.pressed.connect(_on_action)
	frame.add_child(action)
	connection = UI.label("LOCAL-FIRST MENTOR  •  YOUR EXPERIMENTS STAY ON DEVICE", Vector2(28, 522), Vector2(612, 30), 10, UI.MUTED, "mono")
	frame.add_child(connection)

func _refresh() -> void:
	speech.text = MENTOR.greeting(GameState.status, GameState.current_quest, GameState.last_result)
	_render_mastery()
	_render_quest()

func _render_mastery() -> void:
	var content := "OBSERVED MASTERY  /  UNTESTED = —\n"
	var mastery: Dictionary = GameState.profile.get("mastery", {})
	for concept in ["genes", "alleles", "genotype", "phenotype", "dominance", "inheritance"]:
		var value := "—"
		if mastery.has(concept):
			value = "%d%%" % roundi(float(mastery[concept]) * 100.0)
		content += "%s   %s\n" % [ConceptGraph.label_for(concept).rpad(18), value]
	mastery_details.text = content

func _render_quest() -> void:
	var quest: Dictionary = proposed_quest if not proposed_quest.is_empty() else GameState.current_quest
	if not quest.is_empty():
		var task: Dictionary = quest.get("lab_task", {})
		var parents: Array = task.get("parents", [])
		var first: String = str(parents[0].get("genotype", "?")) if parents.size() > 0 else "?"
		var second: String = str(parents[1].get("genotype", "?")) if parents.size() > 1 else "?"
		quest_details.text = "%s   /   LVL %d\n\n%s\n\n%s × %s  •  %s" % [str(quest.get("quest_title", "")), int(quest.get("difficulty", 1)), str(quest.get("objective", "")), first, second, str(task.get("trait", "")).replace("_", " ")]
	else:
		quest_details.text = "No experiment assigned yet.\n\nYour answer helps the Professor choose the next investigation."
	if not proposed_quest.is_empty():
		action.text = "ACCEPT QUEST   →"
	elif GameState.status == "awaiting_professor":
		action.text = "PLAN NEXT QUEST   →"
	elif GameState.status == "quest_active":
		action.text = "QUEST ACTIVE  •  GO TO LAB"
	else:
		action.text = "PLAN A QUEST   →"
	action.disabled = GameState.status == "quest_active" and proposed_quest.is_empty()

func _suggest(text: String) -> void:
	input.text = text
	_submit_answer()

func _submit_answer() -> void:
	var answer: String = input.text.strip_edges()
	if answer.is_empty():
		feedback.text = "A short hypothesis is enough. You can also select a suggested answer."
		return
	input.clear()
	var local_reply: String = GameState.answer_diagnostic(answer)
	feedback.text = local_reply
	AIManager.request_chat(GameState.professor_context(), answer, local_reply, _on_chat)
	_render_mastery()
	if GameState.status == "needs_quest" and proposed_quest.is_empty():
		_offer_quest()

func _on_chat(response: Dictionary) -> void:
	feedback.text = str(response.get("reply", feedback.text))

func _on_analysis(response: Dictionary) -> void:
	speech.text = str(response.get("reply", speech.text))

func _offer_quest() -> void:
	if GameState.status == "awaiting_professor":
		GameState.finish_debrief()
	if GameState.status == "quest_active":
		return
	var safe: Dictionary = GameState.suggest_quest()
	proposed_quest = safe
	var next_text: String = MENTOR.next_step(safe, GameState.profile.get("mastery", {}))
	speech.text = next_text
	_render_quest()
	AIManager.request_next_step(GameState.professor_context(), safe, next_text, _on_next_step)
	AIManager.request_quest(GameState.professor_context(), safe, _on_quest)

func _on_next_step(response: Dictionary) -> void:
	if not proposed_quest.is_empty():
		speech.text = str(response.get("reply", speech.text))

func _on_quest(response: Dictionary) -> void:
	if not proposed_quest.is_empty():
		proposed_quest = response
		_render_quest()

func _on_action() -> void:
	if not proposed_quest.is_empty():
		GameState.accept_quest(proposed_quest)
		proposed_quest = {}
		feedback.text = "Quest accepted. Walk to the computer and press E. Your prediction must be locked before the cross can run."
		_refresh()
		return
	if GameState.status != "quest_active":
		_offer_quest()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		closed.emit()
		get_viewport().set_input_as_handled()
