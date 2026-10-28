class_name HunterConstants
extends RefCounted

## Game Constants, Species Database, & Scoring Formulas
## 100% Procedural data tables for species, ballistics, and trophy scoring.

enum SpeciesType { WHITETAIL_DEER, RED_FOX, MALLARD_DUCK, GHOST_BUCK, WEREWOLF, WENDIGO }
enum OrganType { BRAIN, UPPER_SPINE, HEART, LUNGS, LIVER, INTESTINES, FLESH }
enum WeaponType { BOLT_ACTION_308, SHOTGUN_12GA, WATERFOWL_CALL, DEER_GRUNT_CALL, BINOCULARS }
enum SurfaceType { DRY_LEAVES, MUD, TURF, WATER, WOOD }

const ORGAN_SCORE_MULTIPLIERS = {
	OrganType.BRAIN: 1.0,
	OrganType.UPPER_SPINE: 0.95,
	OrganType.HEART: 1.0,
	OrganType.LUNGS: 0.9,
	OrganType.LIVER: 0.6,
	OrganType.INTESTINES: 0.2,
	OrganType.FLESH: 0.1
}

const SPECIES_DATA = {
	"Whitetail Deer": {
		"speed": 8.0,
		"run_speed": 13.0,
		"bleed_heart": 45.0,
		"detect_visual": 65.0,
		"detect_audio_db": 75.0,
		"scent_range": 220.0,
		"min_weight": 55.0,
		"max_weight": 115.0,
		"trophy_name": "Boone & Crockett Antler Score",
		"min_trophy": 110.0,
		"max_trophy": 195.0
	},
	"Red Fox": {
		"speed": 1.8,
		"run_speed": 13.5,
		"bleed_heart": 35.0,
		"detect_visual": 95.0,
		"detect_audio_db": 85.0,
		"scent_range": 210.0,
		"min_weight": 4.5,
		"max_weight": 8.2,
		"trophy_name": "Pelt Quality Score",
		"min_trophy": 15.0,
		"max_trophy": 32.0
	},
	"Mallard": {
		"speed": 0.5,
		"run_speed": 14.0,
		"bleed_heart": 20.0,
		"detect_visual": 45.0,
		"detect_audio_db": 65.0,
		"scent_range": 40.0,
		"min_weight": 0.9,
		"max_weight": 1.6,
		"trophy_name": "Plumage & Wingspan",
		"min_trophy": 12.0,
		"max_trophy": 25.0
	},
	"Ghost Buck (Mythical)": {
		"speed": 8.5,
		"run_speed": 15.5,
		"bleed_heart": 60.0,
		"detect_visual": 90.0,
		"detect_audio_db": 90.0,
		"scent_range": 280.0,
		"min_weight": 95.0,
		"max_weight": 135.0,
		"trophy_name": "Ethereal Antler Crown",
		"min_trophy": 190.0,
		"max_trophy": 240.0
	},
	"Werewolf": {
		"speed": 3.5,
		"run_speed": 17.0,
		"bleed_heart": 90.0,
		"detect_visual": 110.0,
		"detect_audio_db": 95.0,
		"scent_range": 320.0,
		"min_weight": 120.0,
		"max_weight": 165.0,
		"trophy_name": "Apex Predator Pelt & Skull",
		"min_trophy": 250.0,
		"max_trophy": 320.0
	},
	"Wendigo (Cryptid)": {
		"speed": 2.8,
		"run_speed": 18.0,
		"bleed_heart": 120.0,
		"detect_visual": 130.0,
		"detect_audio_db": 100.0,
		"scent_range": 350.0,
		"min_weight": 150.0,
		"max_weight": 210.0,
		"trophy_name": "Cursed Void Antler Skull",
		"min_trophy": 280.0,
		"max_trophy": 360.0
	}
}

static func get_species_cfg(species_name: String) -> Dictionary:
	return SPECIES_DATA.get(species_name, SPECIES_DATA["Whitetail Deer"])
