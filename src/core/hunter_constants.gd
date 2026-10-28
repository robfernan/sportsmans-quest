class_name HunterConstants
extends RefCounted

## Game Constants & Scoring Formulas (Inspired by theHunter Classic)
## Fully open-source data tables for species, ballistics, and trophy scoring.

enum SpeciesType { WHITETAIL_DEER, MALLARD_DUCK, CANADIAN_GOOSE, BLACK_BEAR, ELK }
enum OrganType { BRAIN, UPPER_SPINE, HEART, LUNGS, LIVER, INTESTINES, FLESH }
enum WeaponType { BOLT_ACTION_308, SHOTGUN_12GA, WATERFOWL_CALL, DEER_GRUNT_CALL, BINOCULARS }

const ORGAN_SCORE_MULTIPLIERS = {
	OrganType.BRAIN: 1.0,
	OrganType.UPPER_SPINE: 0.95,
	OrganType.HEART: 1.0,
	OrganType.LUNGS: 0.9,
	OrganType.LIVER: 0.6,
	OrganType.INTESTINES: 0.2,
	OrganType.FLESH: 0.1
}

const SPECIES_CONFIG = {
	SpeciesType.WHITETAIL_DEER: {
		"name": "Whitetail Deer",
		"min_weight": 55.0,
		"max_weight": 115.0, # kg
		"trophy_name": "Boone & Crockett Antler Score",
		"min_trophy": 110.0,
		"max_trophy": 195.0
	},
	SpeciesType.MALLARD_DUCK: {
		"name": "Mallard Duck",
		"min_weight": 0.9,
		"max_weight": 1.6,
		"trophy_name": "Plumage Quality & Weight",
		"min_trophy": 12.0,
		"max_trophy": 25.0
	}
}

## Generates a realistic trophy harvest record for a downed animal
static func generate_harvest_record(species: SpeciesType, organ: OrganType, shot_distance: float, weapon_name: String) -> Dictionary:
	var cfg = SPECIES_CONFIG[species]
	var weight = snapped(randf_range(cfg.min_weight, cfg.max_weight), 0.1)
	var raw_trophy = randf_range(cfg.min_trophy, cfg.max_trophy)
	
	# Ethical shot multiplier: messy flesh shots reduce score
	var ethical_mult = ORGAN_SCORE_MULTIPLIERS.get(organ, 0.5)
	var final_score = snapped(raw_trophy * (0.8 + 0.2 * ethical_mult), 0.1)

	var organ_str = "Heart"
	match organ:
		OrganType.BRAIN: organ_str = "Brain"
		OrganType.UPPER_SPINE: organ_str = "Upper Spine"
		OrganType.HEART: organ_str = "Heart"
		OrganType.LUNGS: organ_str = "Double Lungs"
		OrganType.LIVER: organ_str = "Liver"
		OrganType.FLESH: organ_str = "Flesh (Non-Vital)"

	return {
		"species_name": cfg.name,
		"weight_kg": weight,
		"trophy_name": cfg.trophy_name,
		"trophy_score": final_score,
		"organ_hit": organ_str,
		"shot_distance_m": snapped(shot_distance, 0.1),
		"weapon_used": weapon_name,
		"harvest_time": Time.get_time_string_from_system()
	}
