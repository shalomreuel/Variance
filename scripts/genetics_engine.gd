class_name GeneticsEngine
extends RefCounted
## Deterministic science. The Professor and image provider never calculate inheritance.

const GENE_FILE = "res://data/genes.json"
var traits: Dictionary = {}
var order: Array[String] = []
var model_note: String = ""

func _init() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GENE_FILE))
	if not parsed is Dictionary:
		push_error("Genetics data could not be loaded")
		return
	model_note = str(parsed.get("model_note", ""))
	for entry in parsed.get("traits", []):
		if entry is Dictionary and entry.has("id"):
			var gene_id: String = str(entry["id"])
			traits[gene_id] = entry
			order.append(gene_id)

func trait_for(gene_id: String) -> Dictionary:
	return traits.get(gene_id, {})

func possible_genotypes(gene_id: String) -> Array[String]:
	var trait: Dictionary = trait_for(gene_id)
	if trait.is_empty():
		return []
	var upper: String = str(trait.get("symbol", ""))
	var lower: String = upper.to_lower()
	return [upper + upper, upper + lower, lower + lower]

func valid_genotype(gene_id: String, genotype: String) -> bool:
	return genotype in possible_genotypes(gene_id)

func default_configuration() -> Dictionary:
	var configuration: Dictionary = {}
	for gene_id in order:
		configuration[gene_id] = str(traits[gene_id].get("default_genotype", ""))
	return configuration

func express(gene_id: String, genotype: String) -> String:
	var trait: Dictionary = trait_for(gene_id)
	if not valid_genotype(gene_id, genotype):
		return ""
	var expression: String = "dominant" if genotype.contains(str(trait["symbol"])) else "recessive"
	return str(trait["phenotypes"].get(expression, ""))

func dominant_expressed(gene_id: String, genotype: String) -> bool:
	var trait: Dictionary = trait_for(gene_id)
	return valid_genotype(gene_id, genotype) and genotype.contains(str(trait["symbol"]))

func describe_organism(configuration: Dictionary) -> Dictionary:
	var phenotypes: Dictionary = {}
	var genotypes: Dictionary = {}
	for gene_id in order:
		var genotype: String = str(configuration.get(gene_id, ""))
		if not valid_genotype(gene_id, genotype):
			return {}
		genotypes[gene_id] = genotype
		phenotypes[gene_id] = express(gene_id, genotype)
	return {"genotypes": genotypes, "phenotypes": phenotypes}

func _canonical_pair(gene_id: String, first: String, second: String) -> String:
	var upper: String = str(trait_for(gene_id).get("symbol", ""))
	if first == upper:
		return first + second
	if second == upper:
		return second + first
	return first + second

func cross(gene_id: String, parent_a: String, parent_b: String) -> Dictionary:
	if not valid_genotype(gene_id, parent_a) or not valid_genotype(gene_id, parent_b):
		return {}
	var trait: Dictionary = trait_for(gene_id)
	var genotype_count: Dictionary = {}
	for genotype in possible_genotypes(gene_id):
		genotype_count[genotype] = 0
	var dominant_label: String = str(trait["phenotypes"]["dominant"])
	var recessive_label: String = str(trait["phenotypes"]["recessive"])
	var phenotype_count: Dictionary = {}
	phenotype_count[dominant_label] = 0
	phenotype_count[recessive_label] = 0
	var offspring: Array[Dictionary] = []
	# Each parent supplies either of its two alleles with probability 1/2.
	# Enumerating all four slots preserves multiplicity (Bb occurs twice).
	for i in range(2):
		for j in range(2):
			var allele_a: String = parent_a.substr(i, 1)
			var allele_b: String = parent_b.substr(j, 1)
			var genotype: String = _canonical_pair(gene_id, allele_a, allele_b)
			var phenotype: String = express(gene_id, genotype)
			genotype_count[genotype] += 1
			phenotype_count[phenotype] += 1
			offspring.append({"allele_a": allele_a, "allele_b": allele_b, "genotype": genotype, "phenotype": phenotype})
	var genotype_ratios: Dictionary = {}
	var phenotype_ratios: Dictionary = {}
	for genotype in genotype_count:
		genotype_ratios[genotype] = int(genotype_count[genotype]) * 25
	for phenotype in phenotype_count:
		phenotype_ratios[phenotype] = int(phenotype_count[phenotype]) * 25
	return {
		"trait": gene_id,
		"parents": [parent_a, parent_b],
		"offspring": offspring,
		"genotype_ratios": genotype_ratios,
		"phenotype_ratios": phenotype_ratios,
		"dominant_label": dominant_label,
		"recessive_label": recessive_label
	}
