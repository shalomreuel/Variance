extends Control
## World-accessed lab: configure six genes, predict one assigned cross, run local science.

signal closed

const UI = preload("res://scripts/ui_kit.gd")
const RESULTS_SCENE = preload("res://results_ui.tscn")

var genetics: GeneticsEngine
var quest: Dictionary
var configuration: Dictionary
var active_trait: String
var parent_b_genotype: String
var selectors: Dictionary = {}
var parent_b_select: OptionButton
var parent_a_preview: DogPreview
var parent_b_preview: DogPreview
var ai_art: TextureRect
var parent_a_text: Label
var parent_b_text: Label
var phenotype_text: Label
var cross_label: Label
var forecast_label: Label
var mastery_text: Label
var status_text: Label
var prediction_slider: HSlider
var lock_button: Button
var run_button: Button
var image_button: Button
var locked: bool = false
var results_view: Control
var image_snapshot: Dictionary = {}

func _ready() -> void:
	genetics = GameState.genetics
	quest = GameState.current_quest
	active_trait = str(quest.get("lab_task", {}).get("trait", "fur_color"))
	configuration = GameState.profile.get("organism_configurations", genetics.default_configuration()).duplicate(true)
	# The assignment always opens with the assigned parent A, even after an earlier quest.
	var parents: Array = quest.get("lab_task", {}).get("parents", [])
	if parents.size() == 2:
		configuration[active_trait] = str(parents[0].get("genotype", "Bb"))
		parent_b_genotype = str(parents[1].get("genotype", "Bb"))
	else:
		parent_b_genotype = str(configuration.get(active_trait, "Bb"))
	_build()
	_update_display()
	_restore_prediction()
	if GameState.status == "awaiting_professor":
		run_button.text = "REVIEW RESULTS  →"
		run_button.disabled = false
		lock_button.disabled = true

func _build() -> void:
	var wash := ColorRect.new()
	wash.color = Color(0.0, 0.045, 0.025, 0.18)
	wash.size = Vector2(1152, 648)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)
	add_child(UI.label("VARIANT ZERO   /   GENETICS CODE EDITOR", Vector2(83, 7), Vector2(800, 32), 18, UI.LIME, "bold"))
	var exit_button := UI.button("EXIT  ×", Vector2(1037, 5), Vector2(103, 32))
	exit_button.pressed.connect(func() -> void: closed.emit())
	add_child(exit_button)

	var library := UI.panel(Vector2(68, 45), Vector2(184, 404), Color(0.028, 0.075, 0.060, 0.98))
	add_child(library)
	library.add_child(UI.label("01 / GENE LIBRARY", Vector2(12, 9), Vector2(165, 26), 11, UI.LIME, "mono"))
	library.add_child(UI.line(Vector2(12, 35), 159))
	for i in range(genetics.order.size()):
		var gene_id: String = genetics.order[i]
		var trait: Dictionary = genetics.trait_for(gene_id)
		var y: float = 43.0 + i * 57.0
		library.add_child(UI.label(str(trait.get("name", gene_id)).to_upper(), Vector2(13, y), Vector2(165, 18), 10, UI.MUTED, "mono"))
		var select := UI.option(Vector2(13, y + 18), Vector2(156, 32))
		for genotype in genetics.possible_genotypes(gene_id):
			select.add_item(genotype.substr(0, 1) + " / " + genotype.substr(1, 1))
			select.set_item_metadata(select.item_count - 1, genotype)
		var choices: Array[String] = genetics.possible_genotypes(gene_id)
		var chosen_index: int = choices.find(str(configuration.get(gene_id, "")))
		select.select(maxi(0, chosen_index))
		select.item_selected.connect(_on_gene_selected.bind(gene_id))
		library.add_child(select)
		selectors[gene_id] = select

	var note := UI.panel(Vector2(68, 461), Vector2(184, 164), Color(0.028, 0.075, 0.060, 0.98))
	add_child(note)
	note.add_child(UI.label("MODEL / 01", Vector2(12, 10), Vector2(160, 22), 11, UI.LIME, "mono"))
	note.add_child(UI.label("This is a simplified single-gene model for learning. Real dog traits are often controlled by multiple genes and environment.", Vector2(12, 36), Vector2(159, 113), 11, UI.MUTED))

	var organisms := UI.panel(Vector2(263, 45), Vector2(566, 402), Color(0.024, 0.068, 0.056, 0.98))
	add_child(organisms)
	organisms.add_child(UI.label("02 / GENOTYPE BUILDER", Vector2(15, 10), Vector2(490, 30), 16, UI.LIME, "bold"))
	organisms.add_child(UI.label("ALLELES → PHENOTYPE → INHERITANCE", Vector2(15, 40), Vector2(465, 21), 10, UI.MUTED, "mono"))
	organisms.add_child(UI.line(Vector2(13, 67), 537))
	organisms.add_child(UI.label("PARENT 01  /  YOUR BUILD", Vector2(20, 75), Vector2(253, 25), 11, UI.CYAN, "mono"))
	organisms.add_child(UI.label("PARENT 02  /  CROSS", Vector2(295, 75), Vector2(260, 25), 11, UI.CYAN, "mono"))
	var p1 := UI.panel(Vector2(17, 102), Vector2(256, 191), Color(0.08, 0.16, 0.13, 0.95))
	var p2 := UI.panel(Vector2(292, 102), Vector2(256, 191), Color(0.08, 0.16, 0.13, 0.95))
	organisms.add_child(p1)
	organisms.add_child(p2)
	parent_a_preview = DogPreview.new()
	parent_a_preview.position = Vector2(5, 5)
	parent_a_preview.size = Vector2(244, 173)
	p1.add_child(parent_a_preview)
	parent_b_preview = DogPreview.new()
	parent_b_preview.position = Vector2(5, 5)
	parent_b_preview.size = Vector2(244, 173)
	p2.add_child(parent_b_preview)
	ai_art = TextureRect.new()
	ai_art.position = Vector2(13, 11)
	ai_art.size = Vector2(230, 168)
	ai_art.expand_mode = 1
	ai_art.stretch_mode = 5
	ai_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ai_art.hide()
	p1.add_child(ai_art)
	parent_a_text = UI.label("", Vector2(20, 299), Vector2(530, 26), 13, UI.LIME, "mono")
	organisms.add_child(parent_a_text)
	parent_b_text = UI.label("", Vector2(20, 327), Vector2(530, 24), 11, UI.MUTED, "mono")
	organisms.add_child(parent_b_text)
	phenotype_text = UI.label("", Vector2(20, 354), Vector2(530, 37), 12, UI.TEXT)
	organisms.add_child(phenotype_text)

	var prediction_panel := UI.panel(Vector2(263, 460), Vector2(566, 165), Color(0.025, 0.071, 0.059, 0.99))
	add_child(prediction_panel)
	prediction_panel.add_child(UI.label("03 / PREDICT BEFORE YOU SIMULATE", Vector2(16, 8), Vector2(527, 26), 13, UI.LIME, "bold"))
	forecast_label = UI.label("", Vector2(18, 35), Vector2(527, 26), 12, UI.TEXT, "mono")
	prediction_panel.add_child(forecast_label)
	prediction_slider = HSlider.new()
	prediction_slider.position = Vector2(20, 68)
	prediction_slider.size = Vector2(524, 28)
	prediction_slider.min_value = 0
	prediction_slider.max_value = 100
	prediction_slider.step = 5
	prediction_slider.value = 50
	prediction_slider.value_changed.connect(_on_prediction_changed)
	prediction_panel.add_child(prediction_slider)
	lock_button = UI.button("LOCK PREDICTION", Vector2(17, 110), Vector2(235, 43))
	lock_button.pressed.connect(_lock_prediction)
	prediction_panel.add_child(lock_button)
	run_button = UI.button("RUN SIMULATION  →", Vector2(270, 110), Vector2(277, 43), true)
	run_button.disabled = true
	run_button.pressed.connect(_run_simulation)
	prediction_panel.add_child(run_button)

	var quest_card := UI.panel(Vector2(844, 45), Vector2(292, 164), Color(0.029, 0.075, 0.061, 0.98))
	add_child(quest_card)
	quest_card.add_child(UI.label("CURRENT QUEST", Vector2(13, 10), Vector2(265, 23), 12, UI.LIME, "mono"))
	quest_card.add_child(UI.label(str(quest.get("quest_title", "Study")), Vector2(13, 34), Vector2(265, 27), 15, UI.TEXT, "bold"))
	quest_card.add_child(UI.label(str(quest.get("objective", "")), Vector2(13, 65), Vector2(265, 88), 12, UI.MUTED))

	var cross_card := UI.panel(Vector2(844, 216), Vector2(292, 169), Color(0.029, 0.075, 0.061, 0.98))
	add_child(cross_card)
	cross_card.add_child(UI.label("CROSS SETUP", Vector2(13, 9), Vector2(263, 25), 12, UI.LIME, "mono"))
	cross_label = UI.label("", Vector2(13, 38), Vector2(263, 39), 12, UI.TEXT)
	cross_card.add_child(cross_label)
	cross_card.add_child(UI.label("PARENT 02 ALLELE PAIR", Vector2(13, 83), Vector2(266, 22), 10, UI.MUTED, "mono"))
	parent_b_select = UI.option(Vector2(13, 108), Vector2(264, 37))
	var choices: Array[String] = genetics.possible_genotypes(active_trait)
	for genotype in choices:
		parent_b_select.add_item(genotype.substr(0, 1) + " / " + genotype.substr(1, 1))
		parent_b_select.set_item_metadata(parent_b_select.item_count - 1, genotype)
	parent_b_select.select(maxi(0, choices.find(parent_b_genotype)))
	parent_b_select.item_selected.connect(_on_parent_b_selected)
	cross_card.add_child(parent_b_select)

	var learning := UI.panel(Vector2(844, 392), Vector2(292, 149), Color(0.029, 0.075, 0.061, 0.98))
	add_child(learning)
	learning.add_child(UI.label("LEARNING STATE", Vector2(13, 10), Vector2(264, 25), 12, UI.LIME, "mono"))
	mastery_text = UI.label("", Vector2(13, 40), Vector2(266, 98), 12, UI.TEXT, "mono")
	learning.add_child(mastery_text)

	var image_panel := UI.panel(Vector2(844, 548), Vector2(292, 78), Color(0.029, 0.075, 0.061, 0.98))
	add_child(image_panel)
	image_button = UI.button("OPTIONAL AI SPRITE", Vector2(12, 8), Vector2(265, 30))
	image_button.pressed.connect(_request_image)
	image_panel.add_child(image_button)
	status_text = UI.label("LOCAL DOG PREVIEW  /  ALWAYS AVAILABLE", Vector2(12, 43), Vector2(270, 22), 10, UI.MUTED, "mono")
	image_panel.add_child(status_text)

func _on_gene_selected(index: int, gene_id: String) -> void:
	var selector: OptionButton = selectors[gene_id]
	configuration[gene_id] = str(selector.get_item_metadata(index))
	_invalidate()
	GameState.update_configuration(configuration)
	_update_display()

func _on_parent_b_selected(index: int) -> void:
	parent_b_genotype = str(parent_b_select.get_item_metadata(index))
	_invalidate()
	_update_display()

func _on_prediction_changed(_value: float) -> void:
	_invalidate()
	_update_forecast()

func _invalidate() -> void:
	locked = false
	if run_button != null and GameState.status == "quest_active":
		run_button.disabled = true
	if lock_button != null:
		lock_button.text = "LOCK PREDICTION"
	if ai_art != null:
		ai_art.hide()
	GameState.clear_prediction()

func _update_display() -> void:
	parent_a_preview.set_configuration(configuration)
	var second: Dictionary = configuration.duplicate(true)
	second[active_trait] = parent_b_genotype
	parent_b_preview.set_configuration(second)
	var genotypes := PackedStringArray()
	for gene_id in genetics.order:
		genotypes.append(str(configuration.get(gene_id, "??")))
	parent_a_text.text = "GENOTYPE  /  " + " ".join(genotypes)
	parent_b_text.text = "ACTIVE CROSS  /  %s × %s  •  %s" % [str(configuration.get(active_trait, "??")), parent_b_genotype, str(genetics.trait_for(active_trait).get("name", ""))]
	var organism: Dictionary = genetics.describe_organism(configuration)
	var appearance: Dictionary = organism.get("phenotypes", {})
	phenotype_text.text = "PHENOTYPE  /  %s  ·  %s  ·  %s" % [appearance.get("fur_color", ""), appearance.get("ear_type", ""), appearance.get("tail_type", "")]
	cross_label.text = "%s\nYOUR BUILD: %s" % [str(genetics.trait_for(active_trait).get("name", "")).to_upper(), str(configuration.get(active_trait, "??"))]
	var mastery: Dictionary = GameState.profile.get("mastery", {})
	var concept: String = str(quest.get("concept", "dominance"))
	var mastery_line: String = "UNTESTED" if not mastery.has(concept) else "%d%% OBSERVED" % roundi(float(mastery[concept]) * 100.0)
	mastery_text.text = "%s  /  %s\n\n%s\n\n%d EXPERIMENT(S) ON RECORD" % [ConceptGraph.label_for(concept).to_upper(), mastery_line, str(quest.get("question", "")), GameState.profile.get("experiments", []).size()]
	_update_forecast()

func _update_forecast() -> void:
	if forecast_label == null:
		return
	var trait: Dictionary = genetics.trait_for(active_trait)
	var phenotypes: Dictionary = trait.get("phenotypes", {})
	var dominant: String = str(phenotypes.get("dominant", "Dominant"))
	var recessive: String = str(phenotypes.get("recessive", "Recessive"))
	forecast_label.text = "%s  %d%%    /    %s  %d%%" % [dominant, roundi(prediction_slider.value), recessive, 100 - roundi(prediction_slider.value)]

func _prediction() -> Dictionary:
	var simulation: Dictionary = genetics.cross(active_trait, str(configuration.get(active_trait, "")), parent_b_genotype)
	if simulation.is_empty():
		return {}
	var guess: Dictionary = {}
	guess[str(simulation["dominant_label"])] = roundi(prediction_slider.value)
	guess[str(simulation["recessive_label"])] = 100 - roundi(prediction_slider.value)
	return guess

func _restore_prediction() -> void:
	var pending: Dictionary = GameState.profile.get("pending_prediction", {})
	if pending.get("configuration") != configuration or str(pending.get("parent_b", "")) != parent_b_genotype:
		return
	var guess: Dictionary = pending.get("prediction", {})
	var trait: Dictionary = genetics.trait_for(active_trait)
	var dominant: String = str(trait.get("phenotypes", {}).get("dominant", ""))
	if guess.has(dominant):
		prediction_slider.set_value_no_signal(float(guess[dominant]))
		_update_forecast()
		locked = true
		lock_button.text = "PREDICTION LOCKED  ✓"
		run_button.disabled = false

func _lock_prediction() -> void:
	if GameState.status != "quest_active":
		return
	if GameState.store_prediction(configuration, parent_b_genotype, _prediction()):
		locked = true
		lock_button.text = "PREDICTION LOCKED  ✓"
		run_button.disabled = false
		status_text.text = "PREDICTION SAVED  /  READY TO TEST"
	else:
		status_text.text = "INVALID CONFIGURATION  /  CHECK ALLELES"

func _run_simulation() -> void:
	if GameState.status == "awaiting_professor" and not GameState.last_result.is_empty():
		_show_results(GameState.last_result)
		return
	if not locked:
		return
	var response: Dictionary = GameState.run_experiment(configuration, parent_b_genotype, _prediction())
	if response.is_empty():
		status_text.text = "PREDICTION CHANGED  /  LOCK IT AGAIN"
		return
	run_button.text = "REVIEW RESULTS  →"
	lock_button.disabled = true
	_show_results(response)

func _show_results(result: Dictionary) -> void:
	if results_view != null:
		return
	results_view = RESULTS_SCENE.instantiate() as Control
	add_child(results_view)
	results_view.call("configure", result)
	results_view.connect("return_to_world", func() -> void: closed.emit())
	results_view.connect("back_to_lab", func() -> void:
		results_view.queue_free()
		results_view = null
	)

func _request_image() -> void:
	image_button.disabled = true
	image_snapshot = configuration.duplicate(true)
	status_text.text = "REQUESTING IMAGE  /  LOCAL DOG VISIBLE"
	var organism: Dictionary = genetics.describe_organism(configuration)
	AIManager.request_image(organism.get("phenotypes", {}), _on_image)

func _on_image(response: Dictionary) -> void:
	image_button.disabled = false
	if image_snapshot != configuration:
		status_text.text = "GENES CHANGED  /  LOCAL DOG PREVIEW ACTIVE"
		return
	if response.get("status") != "generated":
		status_text.text = "OFFLINE  /  LOCAL DOG PREVIEW ACTIVE"
		return
	var data: PackedByteArray = Marshalls.base64_to_raw(str(response.get("image_base64", "")))
	var image := Image.new()
	if image.load_png_from_buffer(data) != OK or image.get_width() == 0:
		status_text.text = "IMAGE ERROR  /  LOCAL DOG PREVIEW ACTIVE"
		return
	ai_art.texture = ImageTexture.create_from_image(image)
	ai_art.show()
	status_text.text = "AI VISUAL ONLY  /  GENETICS UNCHANGED"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if results_view == null:
			closed.emit()
		get_viewport().set_input_as_handled()
