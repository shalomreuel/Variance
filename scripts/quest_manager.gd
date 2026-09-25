class_name QuestManager
extends RefCounted
## Local, deterministic curriculum. AI may reword but cannot change lab parameters.

const QUEST_FILE = "res://data/quests.json"
const GRAPH = preload("res://scripts/concept_graph.gd")
var templates: Dictionary = {}

func _init() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(QUEST_FILE))
	if parsed is Dictionary:
		templates = parsed
	else:
		push_error("Local quest templates could not be loaded")

func get_quest(quest_id: String) -> Dictionary:
	var quest: Dictionary = templates.get(quest_id, {})
	return quest.duplicate(true)

func next_quest(profile: Dictionary) -> Dictionary:
	var experiments: Array = profile.get("experiments", [])
	if experiments.is_empty():
		return get_quest("dominance_intro")
	var last: Dictionary = experiments.back()
	var last_id: String = str(last.get("quest_id", "dominance_intro"))
	var accuracy: float = float(last.get("prediction_accuracy", 0.0))
	var on_task: bool = bool(last.get("on_task", false))
	var next_id := "hidden_genotypes"
	if accuracy < 80.0 or not on_task:
		match last_id:
			"dominance_intro": next_id = "dominance_revisit"
			"dominance_revisit": next_id = "dominance_intro"
			"hidden_genotypes": next_id = "dominance_revisit"
			"punnett_grid": next_id = "hidden_genotypes"
			"variation": next_id = "punnett_grid"
			_: next_id = "variation"
	else:
		match last_id:
			"dominance_intro", "dominance_revisit": next_id = "hidden_genotypes"
			"hidden_genotypes": next_id = "punnett_grid"
			"punnett_grid": next_id = "variation"
			"variation": next_id = "coat_inheritance"
			_: next_id = "variation"
	# A correct memorized ratio does not erase a previously explicit hypothesis.
	var misconceptions: Dictionary = profile.get("misconceptions", {})
	if last_id == "dominance_intro" and misconceptions.has("dominant_means_stronger"):
		var evidence: Dictionary = misconceptions["dominant_means_stronger"]
		if not bool(evidence.get("resolved", false)):
			next_id = "dominance_revisit"
	# Use the concept graph to remediate measured weak prerequisites before
	# introducing a dependent concept. Unknowns are not labeled as failures.
	var intended: Dictionary = get_quest(next_id)
	var prerequisite: String = GRAPH.weak_prerequisite(str(intended.get("concept", "")), profile.get("mastery", {}))
	if prerequisite in ["dominance", "phenotype"]:
		next_id = "dominance_revisit"
	elif prerequisite == "genotype":
		next_id = "hidden_genotypes"
	elif prerequisite == "inheritance":
		next_id = "coat_inheritance"
	return get_quest(next_id)

func validate_response(candidate: Variant, safe_quest: Dictionary, engine: GeneticsEngine) -> Dictionary:
	if not candidate is Dictionary:
		return safe_quest
	for key in ["quest_id", "concept", "quest_title", "objective", "question", "lab_task", "difficulty"]:
		if not candidate.has(key):
			return safe_quest
	if str(candidate["quest_id"]) != str(safe_quest.get("quest_id")) or str(candidate["concept"]) != str(safe_quest.get("concept")):
		return safe_quest
	var task: Variant = candidate["lab_task"]
	var expected: Dictionary = safe_quest.get("lab_task", {})
	if not task is Dictionary or str(task.get("trait", "")) != str(expected.get("trait", "")):
		return safe_quest
	var parents: Variant = task.get("parents", [])
	if not parents is Array or parents.size() != 2:
		return safe_quest
	for index in range(2):
		if not parents[index] is Dictionary:
			return safe_quest
		var genotype: String = str(parents[index].get("genotype", ""))
		if not engine.valid_genotype(str(task["trait"]), genotype):
			return safe_quest
		if genotype != str(expected["parents"][index]["genotype"]):
			return safe_quest
	if not candidate["quest_title"] is String or not candidate["objective"] is String or not candidate["question"] is String:
		return safe_quest
	var result: Dictionary = safe_quest.duplicate(true)
	for key in ["quest_title", "objective", "question"]:
		var wording: String = str(candidate[key]).strip_edges()
		if wording.is_empty() or wording.length() > 320:
			return safe_quest
		result[key] = wording
	return result
