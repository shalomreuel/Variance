extends SceneTree
## Run after import: godot --headless --path . --script tests/genetics_test.gd

const ENGINE = preload("res://scripts/genetics_engine.gd")
const QUESTS = preload("res://scripts/quest_manager.gd")
const LEARNER = preload("res://scripts/learner_model.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var engine: GeneticsEngine = ENGINE.new()
	assert(engine.order.size() == 6)
	assert(engine.possible_genotypes("fur_color") == ["BB", "Bb", "bb"])
	assert(engine.valid_genotype("fur_color", "Bb"))
	assert(not engine.valid_genotype("fur_color", "bB"))
	assert(not engine.valid_genotype("fur_color", "XY"))
	assert(engine.express("fur_color", "Bb") == "Dark fur")
	assert(engine.express("fur_color", "bb") == "Light fur")
	var cross: Dictionary = engine.cross("fur_color", "Bb", "Bb")
	assert(cross["genotype_ratios"] == {"BB": 25, "Bb": 50, "bb": 25})
	assert(cross["phenotype_ratios"] == {"Dark fur": 75, "Light fur": 25})
	assert(cross["offspring"].size() == 4)
	assert(engine.cross("fur_color", "BB", "bb")["genotype_ratios"]["Bb"] == 100)
	assert(engine.cross("fur_color", "Bb", "bb")["phenotype_ratios"]["Light fur"] == 50)
	assert(engine.cross("fur_color", "xx", "Bb").is_empty())
	for gene_id in engine.order:
		for a in engine.possible_genotypes(gene_id):
			for b in engine.possible_genotypes(gene_id):
				var result: Dictionary = engine.cross(gene_id, a, b)
				var sum_genotype := 0
				var sum_phenotype := 0
				for value in result["genotype_ratios"].values():
					sum_genotype += int(value)
				for value in result["phenotype_ratios"].values():
					sum_phenotype += int(value)
				assert(sum_genotype == 100 and sum_phenotype == 100)

	var quests: QuestManager = QUESTS.new()
	var first: Dictionary = quests.next_quest({"experiments": []})
	assert(first["quest_id"] == "dominance_intro")
	var altered: Dictionary = first.duplicate(true)
	altered["lab_task"]["parents"][0]["genotype"] = "BB"
	assert(quests.validate_response(altered, first, engine)["lab_task"] == first["lab_task"])
	var profile: Dictionary = {"experiments": [], "mastery": {}, "concept_stats": {}, "misconceptions": {}}
	var config: Dictionary = engine.default_configuration()
	var prediction := {"Dark fur": 100, "Light fur": 0}
	var evaluation: Dictionary = LEARNER.assess_experiment(profile, first, prediction, cross, config, engine)
	assert(evaluation["prediction_accuracy"] == 75.0)
	assert(evaluation["on_task"])
	assert(evaluation["score"] == 82.5)
	assert(profile["mastery"]["dominance"] == 0.75)
	assert(profile["mastery"]["phenotype"] == 0.75)
	assert(profile["mastery"]["inheritance"] == 0.75)
	assert(ConceptGraph.available(profile["mastery"]).has("inheritance"))
	assert(profile["misconceptions"].has("dominant_phenotype_means_AA"))
	assert(not profile["misconceptions"]["dominant_phenotype_means_AA"]["resolved"])
	assert(quests.next_quest(profile)["quest_id"] == "dominance_revisit")
	var answer: String = LEARNER.assess_answer(profile, "A dominant allele is the stronger gene")
	assert(answer.contains("doesn't mean"))
	assert(profile["misconceptions"].has("dominant_means_stronger"))
	var no_misconception: Dictionary = {"diagnostics": [], "misconceptions": {}}
	LEARNER.assess_answer(no_misconception, "I'm not sure yet")
	assert(no_misconception["misconceptions"].is_empty())
	print("GENETICS TEST: 6 traits × 9 crosses, exact ratios, feedback and remediation OK")
	quit(0)
