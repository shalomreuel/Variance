class_name LearnerModel
extends RefCounted
## Every score and knowledge claim is traceable to an answer or a prediction.

static func assess_answer(profile: Dictionary, answer: String) -> String:
	var words: String = answer.strip_edges().to_lower()
	if words.is_empty():
		return "Ask a question or try one of the suggested answers. No judgement yet."
	var history: Array = profile.get("diagnostics", [])
	history.append({"at": Time.get_datetime_string_from_system(), "answer": answer.substr(0, 300)})
	if history.size() > 30:
		history.pop_front()
	profile["diagnostics"] = history
	var negates_strength: bool = words.contains("not stronger") or words.contains("not a stronger") or words.contains("not the stronger") or words.contains("isn't stronger") or words.contains("doesn't mean stronger") or words.contains("doesn't mean a stronger") or words.contains("not about strength")
	if (words.contains("stronger") or words.contains("more powerful") or words.contains("better gene")) and not negates_strength:
		observe_misconception(profile, "dominant_means_stronger", "Answer: " + answer.substr(0, 120), 0.75)
		return "That's a common idea, but dominance doesn't mean an allele is stronger. It describes which trait appears in a heterozygote. Let's test it with two Bb parents."
	if words.contains("dominant") and (words.contains("always") or words.contains("must") or words.contains("only")) and (answer.contains("BB") or answer.contains("AA") or words.contains("two dominant alleles")) and not words.contains("not "):
		observe_misconception(profile, "dominant_phenotype_means_AA", "Answer: " + answer.substr(0, 120), 0.75)
		return "In this model, both BB and Bb look dark; a dominant phenotype does not tell us whether both alleles are dominant. Let's cross two Bb parents."
	if words.contains("genotype") and words.contains("phenotype") and (words.contains("same") or words.contains("identical")) and not words.contains("not ") and not words.contains("isn't"):
		observe_misconception(profile, "genotype_equals_phenotype", "Answer: " + answer.substr(0, 120), 0.75)
		return "A genotype is an allele pair; a phenotype is what we can observe. Different genotypes can yield the same appearance. Let's test that."
	if words.contains("need") and (words.contains("variation") or words.contains("mutat")):
		observe_misconception(profile, "variation_is_created_by_need", "Answer: " + answer.substr(0, 120), 0.75)
		return "Variation does not arise because an organism needs it. Alleles already present in parents can combine in different ways."
	if (words.contains("individual") or words.contains("one dog")) and words.contains("evolv") and (words.contains("lifetime") or words.contains("during its life")):
		observe_misconception(profile, "individuals_evolve_during_lifetime", "Answer: " + answer.substr(0, 120), 0.75)
		return "An individual can develop during life, but evolutionary change is measured across generations in populations. For now let's trace inherited variation."
	if words.contains("heterozyg") or words.contains("one dominant") or words.contains("shows with one") or negates_strength:
		resolve_misconception(profile, "dominant_means_stronger", "Explicit correction in student's answer")
		return "Exactly: a dominant allele is expressed with one copy in this simplified model. Now use the lab to see what each Bb parent can pass on."
	if words.contains("not sure") or words.contains("don't know"):
		return "Not knowing is a good starting point. A Bb dog looks dark but still carries b. Let's use the lab to find out what two Bb parents can pass on."
	return "Interesting hypothesis. In this model, Bb looks dark, but b is still present. What do you predict will happen when two Bb parents are crossed?"

static func observe_misconception(profile: Dictionary, identifier: String, evidence: String, confidence: float) -> void:
	var all_records: Dictionary = profile.get("misconceptions", {})
	var record: Dictionary = all_records.get(identifier, {
		"id": identifier, "confidence": 0.0, "evidence": [], "evidence_count": 0,
		"first_detected": Time.get_datetime_string_from_system(), "times_observed": 0, "resolved": false
	})
	var observations: Array = record.get("evidence", [])
	observations.append(evidence)
	if observations.size() > 10:
		observations.pop_front()
	record["evidence"] = observations
	record["evidence_count"] = int(record.get("evidence_count", 0)) + 1
	record["times_observed"] = int(record.get("times_observed", 0)) + 1
	record["confidence"] = minf(0.95, maxf(float(record.get("confidence", 0.0)), confidence) + (0.08 if int(record["times_observed"]) > 1 else 0.0))
	record["resolved"] = false
	all_records[identifier] = record
	profile["misconceptions"] = all_records

static func resolve_misconception(profile: Dictionary, identifier: String, evidence: String) -> void:
	var all_records: Dictionary = profile.get("misconceptions", {})
	if all_records.has(identifier):
		var record: Dictionary = all_records[identifier]
		record["resolved"] = true
		var observations: Array = record.get("evidence", [])
		observations.append(evidence)
		record["evidence"] = observations
		all_records[identifier] = record
		profile["misconceptions"] = all_records

static func assess_experiment(profile: Dictionary, quest: Dictionary, prediction: Dictionary, result: Dictionary, configuration: Dictionary, engine: GeneticsEngine) -> Dictionary:
	var trait_id: String = str(result.get("trait", ""))
	var ratios: Dictionary = result.get("phenotype_ratios", {})
	var dominant_label: String = str(result.get("dominant_label", ""))
	var recessive_label: String = str(result.get("recessive_label", ""))
	var error: float = absf(float(prediction.get(dominant_label, -1)) - float(ratios.get(dominant_label, -1)))
	error += absf(float(prediction.get(recessive_label, -1)) - float(ratios.get(recessive_label, -1)))
	var accuracy: float = clampf(100.0 - error / 2.0, 0.0, 100.0)
	var task: Dictionary = quest.get("lab_task", {})
	var parents: Array = task.get("parents", [])
	var on_task: bool = parents.size() == 2 and trait_id == str(task.get("trait", ""))
	if on_task:
		on_task = str(result["parents"][0]) == str(parents[0].get("genotype", "")) and str(result["parents"][1]) == str(parents[1].get("genotype", ""))
	var genetic_validity: bool = not engine.describe_organism(configuration).is_empty() and engine.valid_genotype(trait_id, str(result["parents"][1]))
	# Transparent rubric: 70% prediction, 20% testing the assigned cross, 10% valid alleles.
	var score: float = accuracy * 0.7 + (20.0 if on_task else 0.0) + (10.0 if genetic_validity else 0.0)
	var concept: String = str(quest.get("concept", "inheritance"))
	var gap: String = "No specific misconception is supported by this prediction."
	if accuracy < 90.0 and not on_task:
		gap = "You tested a different cross. Compare the assigned parents before drawing a conclusion."
	elif accuracy < 90.0 and on_task and int(prediction.get(recessive_label, -1)) == 0 and int(ratios.get(recessive_label, 0)) > 0:
		gap = "Possible gap: a dominant-looking parent may still carry a recessive allele. This prediction alone cannot prove why you expected 0%."
		observe_misconception(profile, "dominant_phenotype_means_AA", "Predicted 0% %s for %s x %s, actual %d%%" % [recessive_label, result["parents"][0], result["parents"][1], ratios[recessive_label]], 0.45)
	elif accuracy < 90.0:
		gap = "The prediction differed from the four allele combinations. Recheck the Punnett grid; the reason for the error is not yet known."
	else:
		gap = "Your prediction matches the exact four-cell cross. Test another pairing to check that the idea transfers."

	var experiment: Dictionary = {
		"at": Time.get_datetime_string_from_system(), "quest_id": str(quest.get("quest_id", "")),
		"concept": concept, "trait": trait_id, "parent_a": str(result["parents"][0]),
		"parent_b": str(result["parents"][1]), "configuration": configuration.duplicate(true),
		"prediction": prediction.duplicate(true), "actual": ratios.duplicate(true),
		"genotypes": result.get("genotype_ratios", {}).duplicate(true),
		"offspring": result.get("offspring", []).duplicate(true), "prediction_accuracy": accuracy,
		"experimental_reasoning": 100 if on_task else 0, "genetic_validity": 100 if genetic_validity else 0,
		"concept_understanding": accuracy if on_task else null,
		"score": score, "on_task": on_task, "gap": gap
	}
	var experiments: Array = profile.get("experiments", [])
	experiments.append(experiment)
	if experiments.size() > 100:
		experiments.pop_front()
	profile["experiments"] = experiments
	profile["organism_configurations"] = configuration.duplicate(true)

	# Only assigned crosses count toward mastery. Every prediction also tests
	# phenotype reading and inheritance reasoning; the same observation may
	# support these prerequisites without inventing a separate quiz score.
	if on_task:
		var evidenced: Array[String] = [concept]
		for prerequisite in ["phenotype", "inheritance"]:
			if not evidenced.has(prerequisite):
				evidenced.append(prerequisite)
		for observed_concept in evidenced:
			_record_concept(profile, observed_concept, accuracy)
		if accuracy >= 90.0 and int(ratios.get(recessive_label, 0)) > 0:
			var clean_attempts := 0
			for item in experiments:
				if bool(item.get("on_task", false)) and float(item.get("prediction_accuracy", 0)) >= 90.0:
					if int(item.get("actual", {}).get(recessive_label, 0)) > 0:
						clean_attempts += 1
			if clean_attempts >= 2:
				resolve_misconception(profile, "dominant_phenotype_means_AA", "Two accurate crosses allowed recessive offspring")
	return experiment

static func _record_concept(profile: Dictionary, concept: String, accuracy: float) -> void:
	var stats: Dictionary = profile.get("concept_stats", {})
	var entry: Dictionary = stats.get(concept, {"attempts": 0, "total_accuracy": 0.0})
	entry["attempts"] = int(entry["attempts"]) + 1
	entry["total_accuracy"] = float(entry["total_accuracy"]) + accuracy
	stats[concept] = entry
	profile["concept_stats"] = stats
	var mastery: Dictionary = profile.get("mastery", {})
	mastery[concept] = float(entry["total_accuracy"]) / float(entry["attempts"]) / 100.0
	profile["mastery"] = mastery
