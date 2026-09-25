extends Node
## One source of truth for the learner and a versioned, local, persistent save.

signal quest_changed
signal experiment_completed
signal profile_changed

const SAVE_FILE = "user://variant_zero_profile.json"
const VERSION = 1
const QUESTS = preload("res://scripts/quest_manager.gd")
const LEARNER = preload("res://scripts/learner_model.gd")
const GRAPH = preload("res://scripts/concept_graph.gd")

var genetics: GeneticsEngine
var quest_manager: QuestManager
var profile: Dictionary = {}
var current_quest: Dictionary = {}
var last_result: Dictionary = {}
var status: String = "needs_quest"

func _ready() -> void:
	genetics = GeneticsEngine.new()
	quest_manager = QUESTS.new()
	_reset_to_defaults()
	_load_profile()

func _reset_to_defaults() -> void:
	profile = {
		"mastery": {}, "concept_stats": {}, "misconceptions": {},
		"quest_history": [], "experiments": [], "diagnostics": [], "pending_prediction": {},
		"current_concept": "dominance", "unlocked_concepts": ["genes", "alleles", "genotype", "phenotype", "dominance"],
		"organism_configurations": genetics.default_configuration()
	}
	current_quest = {}
	last_result = {}
	status = "needs_quest"

func has_progress() -> bool:
	return not profile.get("quest_history", []).is_empty() or not profile.get("diagnostics", []).is_empty()

func suggest_quest() -> Dictionary:
	return quest_manager.next_quest(profile)

func accept_quest(candidate: Dictionary) -> void:
	var safe: Dictionary = suggest_quest()
	current_quest = quest_manager.validate_response(candidate, safe, genetics)
	if current_quest.is_empty():
		return
	status = "quest_active"
	profile["pending_prediction"] = {}
	profile["current_concept"] = str(current_quest.get("concept", "dominance"))
	var history: Array = profile.get("quest_history", [])
	history.append({"quest_id": current_quest["quest_id"], "accepted_at": Time.get_datetime_string_from_system(), "state": "active"})
	profile["quest_history"] = history
	save_profile()
	quest_changed.emit()

func answer_diagnostic(answer: String) -> String:
	var explanation: String = LEARNER.assess_answer(profile, answer)
	save_profile()
	profile_changed.emit()
	return explanation

func update_configuration(configuration: Dictionary) -> void:
	if not genetics.describe_organism(configuration).is_empty():
		profile["organism_configurations"] = configuration.duplicate(true)
		save_profile()

func store_prediction(configuration: Dictionary, parent_b: String, prediction: Dictionary) -> bool:
	if status != "quest_active" or genetics.describe_organism(configuration).is_empty():
		return false
	var trait_id: String = str(current_quest.get("lab_task", {}).get("trait", ""))
	if genetics.cross(trait_id, str(configuration.get(trait_id, "")), parent_b).is_empty():
		return false
	var total: int = 0
	for value in prediction.values():
		if int(value) < 0 or int(value) > 100:
			return false
		total += int(value)
	if prediction.size() != 2 or total != 100:
		return false
	profile["pending_prediction"] = {"configuration": configuration.duplicate(true), "parent_b": parent_b, "prediction": prediction.duplicate(true)}
	save_profile()
	return true

func clear_prediction() -> void:
	if not profile.get("pending_prediction", {}).is_empty():
		profile["pending_prediction"] = {}
		save_profile()

func run_experiment(configuration: Dictionary, parent_b: String, prediction: Dictionary) -> Dictionary:
	if status != "quest_active" or current_quest.is_empty():
		return {}
	var trait_id: String = str(current_quest.get("lab_task", {}).get("trait", ""))
	if genetics.describe_organism(configuration).is_empty():
		return {}
	var pending: Dictionary = profile.get("pending_prediction", {})
	if pending.is_empty() or pending.get("configuration") != configuration or str(pending.get("parent_b", "")) != parent_b or pending.get("prediction") != prediction:
		return {}
	var parent_a: String = str(configuration.get(trait_id, ""))
	var simulation: Dictionary = genetics.cross(trait_id, parent_a, parent_b)
	if simulation.is_empty():
		return {}
	var d: String = str(simulation["dominant_label"])
	var r: String = str(simulation["recessive_label"])
	if not prediction.has(d) or not prediction.has(r):
		return {}
	var predicted_d: int = int(prediction[d])
	var predicted_r: int = int(prediction[r])
	if predicted_d < 0 or predicted_d > 100 or predicted_r < 0 or predicted_d + predicted_r != 100:
		return {}
	var clean_prediction: Dictionary = {}
	clean_prediction[d] = predicted_d
	clean_prediction[r] = predicted_r
	var assessment: Dictionary = LEARNER.assess_experiment(profile, current_quest, clean_prediction, simulation, configuration, genetics)
	last_result = {"simulation": simulation, "assessment": assessment, "quest": current_quest.duplicate(true)}
	profile["pending_prediction"] = {}
	status = "awaiting_professor"
	var history: Array = profile.get("quest_history", [])
	if not history.is_empty():
		var latest: Dictionary = history.back()
		latest["state"] = "completed"
		latest["score"] = assessment["score"]
		history[history.size() - 1] = latest
	profile["quest_history"] = history
	profile["unlocked_concepts"] = GRAPH.available(profile.get("mastery", {}))
	save_profile()
	experiment_completed.emit()
	profile_changed.emit()
	return last_result

func finish_debrief() -> void:
	if status == "awaiting_professor":
		status = "needs_quest"
		current_quest = {}
		save_profile()
		quest_changed.emit()

func professor_context() -> Dictionary:
	var diagnostics: Array = profile.get("diagnostics", [])
	var experiments: Array = profile.get("experiments", [])
	return {
		"current_concept": str(profile.get("current_concept", "dominance")),
		"quest": current_quest.duplicate(true),
		"last_experiment": last_result.duplicate(true),
		"mastery": profile.get("mastery", {}).duplicate(true),
		"misconceptions": profile.get("misconceptions", {}).duplicate(true),
		"selected_genotypes": profile.get("organism_configurations", {}).duplicate(true),
		"pending_prediction": profile.get("pending_prediction", {}).duplicate(true),
		"unlocked_concepts": profile.get("unlocked_concepts", []).duplicate(true),
		"recent_diagnostics": diagnostics.slice(maxi(0, diagnostics.size() - 3)),
		"recent_experiments": experiments.slice(maxi(0, experiments.size() - 3)),
		"experiment_count": experiments.size()
	}

func save_profile() -> void:
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file == null:
		push_error("Cannot save learner profile: " + str(FileAccess.get_open_error()))
		return
	var snapshot := {"version": VERSION, "profile": profile, "current_quest": current_quest, "last_result": last_result, "status": status}
	file.store_string(JSON.stringify(snapshot, "  "))
	file.close()

func _load_profile() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_FILE))
	if not parsed is Dictionary or int(parsed.get("version", -1)) != VERSION or not parsed.get("profile") is Dictionary:
		push_warning("Ignoring invalid/incompatible learner save")
		return
	var incoming: Dictionary = parsed["profile"]
	for key in ["mastery", "concept_stats", "misconceptions", "quest_history", "experiments", "diagnostics", "organism_configurations", "pending_prediction"]:
		if incoming.has(key) and typeof(incoming[key]) == typeof(profile[key]):
			profile[key] = incoming[key]
	for key in ["current_concept", "unlocked_concepts"]:
		if incoming.has(key) and typeof(incoming[key]) == typeof(profile[key]):
			profile[key] = incoming[key]
	if parsed.get("current_quest") is Dictionary:
		var saved_quest: Dictionary = parsed["current_quest"]
		if not saved_quest.is_empty():
			var safe: Dictionary = quest_manager.get_quest(str(saved_quest.get("quest_id", "")))
			if not safe.is_empty():
				current_quest = quest_manager.validate_response(saved_quest, safe, genetics)
	if parsed.get("last_result") is Dictionary:
		last_result = parsed["last_result"]
	var saved_status: String = str(parsed.get("status", "needs_quest"))
	if saved_status in ["quest_active", "awaiting_professor"] and not current_quest.is_empty():
		status = saved_status

func reset_study() -> void:
	_reset_to_defaults()
	save_profile()
	quest_changed.emit()
	profile_changed.emit()
