extends Node

## Global EventBus autoload for Sportsman's Quest
## Decouples audio, ballistics, AI, missions, and world systems via signals.

signal gunshot_fired(position: Vector3, direction: Vector3, is_heavy: bool)
signal shot_resolved(organ: String, distance_m: float, fatal: bool)
signal animal_spooked(animal_id: int, animal_pos: Vector3, alert_level: float)
signal animal_harvested(species: String, organ: String, distance_m: float, record: Dictionary)
signal player_downed
signal player_landed_water()
signal player_stepped(surface_type: int, stance: int, position: Vector3)
signal time_changed(hour: float)
signal fog_density_changed(density: float)
