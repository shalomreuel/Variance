extends Control
## Four exact gamete combinations + comparisons, never LLM-generated results.

signal return_to_world
signal back_to_lab

const UI = preload("res://scripts/ui_kit.gd")

func configure(payload: Dictionary) -> void:
	var simulation: Dictionary = payload.get("simulation", {})
	var assessment: Dictionary = payload.get("assessment", {})
	var quest: Dictionary = payload.get("quest", {})
	var configuration: Dictionary = assessment.get("configuration", {}).duplicate(true)
	var veil := ColorRect.new()
	veil.size = Vector2(1152, 648)
	veil.color = Color(0.0, 0.023, 0.022, 0.94)
	add_child(veil)
	var frame := UI.panel(Vector2(42, 20), Vector2(1068, 609), Color(0.025, 0.068, 0.059, 0.99))
	add_child(frame)
	frame.add_child(UI.label("04 / EXPERIMENT COMPLETE", Vector2(24, 16), Vector2(560, 33), 21, UI.LIME, "bold"))
	frame.add_child(UI.label(str(quest.get("quest_title", "Inheritance study")), Vector2(25, 51), Vector2(530, 23), 12, UI.MUTED, "mono"))
	frame.add_child(UI.label("LEARNING SCORE   %d / 100" % roundi(float(assessment.get("score", 0))), Vector2(706, 23), Vector2(338, 30), 15, UI.CYAN, "bold"))
	frame.add_child(UI.line(Vector2(23, 83), 1020))

	var left := UI.panel(Vector2(22, 98), Vector2(495, 357), Color(0.04, 0.105, 0.09))
	frame.add_child(left)
	left.add_child(UI.label("THE CROSS   /   PARENT ORGANISMS", Vector2(14, 9), Vector2(472, 27), 12, UI.LIME, "mono"))
	var parents: Array = simulation.get("parents", ["?", "?"])
	var trait_id: String = str(simulation.get("trait", "fur_color"))
	for i in range(2):
		var parent_config: Dictionary = configuration.duplicate(true)
		parent_config[trait_id] = str(parents[i])
		var preview := DogPreview.new()
		preview.position = Vector2(22 + i * 234, 34)
		preview.size = Vector2(201, 122)
		preview.set_configuration(parent_config)
		left.add_child(preview)
		left.add_child(UI.label("PARENT %d   %s" % [i + 1, str(parents[i])], Vector2(30 + i * 234, 153), Vector2(198, 23), 12, UI.CYAN, "mono"))
	left.add_child(UI.line(Vector2(15, 186), 461))
	left.add_child(UI.label("PUNNETT GRID   /   FOUR EQUALLY LIKELY SLOTS", Vector2(16, 190), Vector2(467, 25), 10, UI.MUTED, "mono"))
	var children: Array = simulation.get("offspring", [])
	for index in range(mini(4, children.size())):
		var child: Dictionary = children[index]
		var slot := UI.panel(Vector2(13 + (index % 2) * 238, 222 + int(index / 2.0) * 61), Vector2(229, 54), Color(0.075, 0.15, 0.12))
		left.add_child(slot)
		var child_config: Dictionary = configuration.duplicate(true)
		child_config[trait_id] = str(child.get("genotype", ""))
		var puppy := DogPreview.new()
		puppy.position = Vector2(3, 3)
		puppy.size = Vector2(77, 47)
		puppy.set_configuration(child_config)
		slot.add_child(puppy)
		slot.add_child(UI.label("%s  /  %s" % [str(child.get("allele_a", "")), str(child.get("allele_b", ""))], Vector2(84, 5), Vector2(136, 21), 11, UI.CYAN, "mono"))
		slot.add_child(UI.label("%s   %s" % [str(child.get("genotype", "")), str(child.get("phenotype", ""))], Vector2(84, 26), Vector2(137, 23), 11, UI.TEXT))

	var right := UI.panel(Vector2(529, 98), Vector2(515, 357), Color(0.04, 0.105, 0.09))
	frame.add_child(right)
	right.add_child(UI.label("ACTUAL RESULT   /   GENOTYPE", Vector2(17, 9), Vector2(475, 26), 12, UI.LIME, "mono"))
	var genotype_ratios: Dictionary = simulation.get("genotype_ratios", {})
	var possible: Array[String] = GameState.genetics.possible_genotypes(trait_id)
	for i in range(possible.size()):
		var genotype: String = possible[i]
		var percent: int = int(genotype_ratios.get(genotype, 0))
		right.add_child(UI.label("%s    %d%%" % [genotype, percent], Vector2(20, 37 + i * 27), Vector2(122, 26), 13, UI.TEXT, "mono"))
		_draw_bar(right, Vector2(145, 46 + i * 27), 339.0, percent, UI.CYAN)
	right.add_child(UI.line(Vector2(17, 133), 479))
	right.add_child(UI.label("PHENOTYPE      ACTUAL    YOUR PREDICTION", Vector2(20, 143), Vector2(480, 25), 11, UI.MUTED, "mono"))
	var ratios: Dictionary = simulation.get("phenotype_ratios", {})
	var guesses: Dictionary = assessment.get("prediction", {})
	for i in range(2):
		var phenotype: String = str(simulation.get("dominant_label" if i == 0 else "recessive_label", ""))
		right.add_child(UI.label("%-16s   %3d%%        %3d%%" % [phenotype, int(ratios.get(phenotype, 0)), int(guesses.get(phenotype, 0))], Vector2(20, 174 + i * 35), Vector2(477, 29), 12, UI.TEXT, "mono"))
	right.add_child(UI.line(Vector2(17, 254), 479))
	right.add_child(UI.label("PREDICTION ACCURACY", Vector2(20, 268), Vector2(255, 23), 12, UI.MUTED, "mono"))
	right.add_child(UI.label("%d%%" % roundi(float(assessment.get("prediction_accuracy", 0))), Vector2(410, 263), Vector2(86, 32), 21, UI.LIME, "bold"))
	right.add_child(UI.label("REASONING  %d%%    VALIDITY  %d%%" % [int(assessment.get("experimental_reasoning", 0)), int(assessment.get("genetic_validity", 0))], Vector2(20, 303), Vector2(470, 23), 11, UI.CYAN, "mono"))
	right.add_child(UI.label("Only the quest trait is crossed; other preview traits stay fixed.", Vector2(20, 331), Vector2(473, 22), 10, UI.MUTED))

	var insight := UI.panel(Vector2(22, 465), Vector2(1022, 83), Color(0.058, 0.12, 0.095))
	frame.add_child(insight)
	insight.add_child(UI.label("CONCEPT GAP  /  EVIDENCE, NOT A GUESS ABOUT YOU", Vector2(15, 8), Vector2(990, 25), 12, UI.LIME, "mono"))
	insight.add_child(UI.label(str(assessment.get("gap", "")), Vector2(15, 32), Vector2(986, 45), 13, UI.TEXT))
	frame.add_child(UI.label("SCORE = 70% PREDICTION + 20% ASSIGNED CROSS + 10% VALID ALLELES", Vector2(25, 565), Vector2(720, 24), 10, UI.MUTED, "mono"))
	var floor_button := UI.button("RETURN TO PROFESSOR  →", Vector2(787, 558), Vector2(259, 39), true)
	floor_button.pressed.connect(func() -> void: return_to_world.emit())
	frame.add_child(floor_button)
	var lab_button := UI.button("VIEW LAB", Vector2(657, 558), Vector2(120, 39))
	lab_button.pressed.connect(func() -> void: back_to_lab.emit())
	frame.add_child(lab_button)

func _draw_bar(parent: Control, pos: Vector2, width: float, percentage: int, color: Color) -> void:
	var background := ColorRect.new()
	background.position = pos
	background.size = Vector2(width, 8)
	background.color = Color(0.1, 0.19, 0.15)
	parent.add_child(background)
	var filled := ColorRect.new()
	filled.position = pos
	filled.size = Vector2(width * clampf(float(percentage) / 100.0, 0.0, 1.0), 8)
	filled.color = color
	parent.add_child(filled)
