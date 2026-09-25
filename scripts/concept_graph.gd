class_name ConceptGraph
extends RefCounted
## Curriculum dependencies; unlocking is not the same as claiming mastery.

const ORDER = ["genes", "alleles", "genotype", "phenotype", "dominance", "inheritance", "punnett_squares", "genetic_variation", "mutation", "natural_selection", "adaptation", "evolution"]
const LABELS = {
	"genes": "Genes", "alleles": "Alleles", "genotype": "Genotype", "phenotype": "Phenotype",
	"dominance": "Dominance", "inheritance": "Inheritance", "punnett_squares": "Punnett squares",
	"genetic_variation": "Genetic variation", "mutation": "Mutation", "natural_selection": "Natural selection",
	"adaptation": "Adaptation", "evolution": "Evolution"
}
const REQUIRES = {
	"alleles": ["genes"], "genotype": ["alleles"], "phenotype": ["genotype"],
	"dominance": ["alleles", "phenotype"], "inheritance": ["dominance"],
	"punnett_squares": ["genotype", "inheritance"],
	"genetic_variation": ["inheritance"], "mutation": ["genetic_variation"],
	"natural_selection": ["genetic_variation"], "adaptation": ["natural_selection"],
	"evolution": ["natural_selection", "adaptation"]
}

static func label_for(concept: String) -> String:
	return str(LABELS.get(concept, concept.capitalize()))

static func weak_prerequisite(concept: String, mastery: Dictionary) -> String:
	for prerequisite in REQUIRES.get(concept, []):
		# An unobserved prerequisite is unknown, not evidence of weakness.
		if mastery.has(prerequisite) and float(mastery[prerequisite]) < 0.65:
			return str(prerequisite)
	return ""

static func available(mastery: Dictionary) -> Array[String]:
	var result: Array[String] = ["genes", "alleles", "genotype", "phenotype", "dominance"]
	for concept in ORDER:
		if result.has(concept):
			continue
		var ready := true
		for requirement in REQUIRES.get(concept, []):
			if not mastery.has(requirement) or float(mastery[requirement]) < 0.65:
				ready = false
				break
		if ready:
			result.append(concept)
	return result
