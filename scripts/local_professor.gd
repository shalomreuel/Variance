class_name LocalProfessor
extends RefCounted
## Offline mentor. Does not calculate genetics: it discusses precomputed engine results.

static func greeting(state: String, quest: Dictionary, last_result: Dictionary) -> String:
	if state == "awaiting_professor" and not last_result.is_empty():
		return "You're back with evidence. Let's compare your prediction with the four allele combinations before we plan the next investigation."
	if state == "quest_active" and not quest.is_empty():
		return "Your investigation is active: %s. Head to the terminal, configure the dogs and lock in a prediction before running the cross." % str(quest.get("quest_title", ""))
	return "Welcome, researcher. Let's start with a question: what does it mean for an allele to be dominant? You can type your idea or use a suggested answer."

static func analyze(last_result: Dictionary) -> String:
	if last_result.is_empty():
		return "First run an experiment so we have evidence to discuss."
	var simulation: Dictionary = last_result.get("simulation", {})
	var assessment: Dictionary = last_result.get("assessment", {})
	var actual: Dictionary = simulation.get("phenotype_ratios", {})
	var dominant: String = str(simulation.get("dominant_label", "the dominant trait"))
	var recessive: String = str(simulation.get("recessive_label", "the recessive trait"))
	var expected_dark: int = int(actual.get(dominant, 0))
	var expected_light: int = int(actual.get(recessive, 0))
	var a: String = str(simulation.get("parents", ["?", "?"])[0])
	var b: String = str(simulation.get("parents", ["?", "?"])[1])
	var intro: String = "%s × %s gives %d%% %s and %d%% %s. " % [a, b, expected_dark, dominant.to_lower(), expected_light, recessive.to_lower()]
	if not bool(assessment.get("on_task", true)):
		return intro + "That was a valid exploration, but it was not the cross the quest asked you to test. Let's try the assigned parents next."
	if float(assessment.get("prediction_accuracy", 0.0)) >= 90.0:
		return intro + "Your prediction followed the evidence. The four cells describe probabilities, not a guarantee for any individual puppy. Ready to apply this to another trait?"
	if int(assessment.get("prediction", {}).get(recessive, -1)) == 0 and expected_light > 0:
		return intro + "Your 0%% prediction overlooked a possible recessive pairing. A dominant-looking heterozygote can carry and pass on the recessive allele; this is a possible reasoning gap, not a diagnosis of your intent."
	return intro + "Your prediction differed. In a Punnett square, list each parent's two alleles along an edge and combine all four pairs. Let's try a targeted follow-up."

static func next_step(quest: Dictionary, mastery: Dictionary) -> String:
	var concept: String = str(quest.get("concept", "genotype"))
	var title: String = ConceptGraph.label_for(concept)
	if mastery.has(concept) and float(mastery[concept]) < 0.65:
		return "We have more to investigate about %s. The next cross isolates one idea so we can revisit it using fresh evidence." % title.to_lower()
	return "Next we will explore %s. We'll build on what you observed rather than simply memorizing the ratios." % title.to_lower()
