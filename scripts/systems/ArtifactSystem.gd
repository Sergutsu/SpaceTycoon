extends Node
class_name ArtifactSystem

# Artifact system signals
@warning_ignore("unused_signal")
signal artifact_discovered(artifact_id: String, system_id: String, lore_fragment: String)
signal artifact_collected(artifact_id: String, effects: Dictionary)
signal precursor_lore_unlocked(civilization: String, lore_text: String)
signal artifact_effects_applied(bonuses: Dictionary)

# Precursor civilizations and their artifacts
var precursor_civilizations: Dictionary = {
	"chronovores": {
		"name": "The Chronovores",
		"lore": "Masters of time who consumed temporal energy until they forgot to exist in the present",
		"discovered": false,
		"artifacts": {
			"temporal_fragment": {
				"name": "Temporal Fragment",
				"rarity": "common",
				"effect_type": "travel_speed",
				"magnitude": 0.15,
				"description": "A crystallized moment that makes journeys feel shorter",
				"lore": "Time itself seems to bend around this strange crystal..."
			},
			"chronos_anchor": {
				"name": "Chronos Anchor",
				"rarity": "rare",
				"effect_type": "global_efficiency",
				"magnitude": 0.25,
				"description": "Accelerates all ship operations by anchoring to stable timestreams",
				"lore": "The Chronovores used these to maintain temporal stability in their cities"
			}
		}
	},
	"silica_gardens": {
		"name": "The Silica Gardens",
		"lore": "Terraformers who grew planets like flowers until their creations gained consciousness and screamed",
		"discovered": false,
		"artifacts": {
			"genesis_seed": {
				"name": "Genesis Seed",
				"rarity": "common",
				"effect_type": "market_bonus",
				"magnitude": 0.20,
				"description": "Enhances planetary resource generation and trade efficiency",
				"lore": "A seed that could grow entire ecosystems in moments"
			},
			"world_shaper": {
				"name": "World Shaper",
				"rarity": "rare",
				"effect_type": "new_routes",
				"magnitude": 1.0,
				"description": "Reveals hidden hyperspace routes between systems",
				"lore": "The Gardens used these tools to sculpt reality itself"
			}
		}
	},
	"void_weavers": {
		"name": "The Void Weavers",
		"lore": "Space-time architects who knitted dark matter into dreams and nightmares",
		"discovered": false,
		"artifacts": {
			"space_fold": {
				"name": "Space Fold Device",
				"rarity": "common",
				"effect_type": "fuel_efficiency",
				"magnitude": 0.20,
				"description": "Bends space to make distant places closer",
				"lore": "The Weavers folded space like origami to travel instantly"
			},
			"reality_loom": {
				"name": "Reality Loom",
				"rarity": "rare",
				"effect_type": "wormhole_access",
				"magnitude": 1.0,
				"description": "Creates temporary wormholes for instant travel",
				"lore": "A device that weaves the fabric of space-time itself"
			}
		}
	}
}

# Active artifacts and their effects
var collected_artifacts: Array = []
var active_bonuses: Dictionary = {
	"travel_speed_bonus": 0.0,
	"fuel_efficiency_bonus": 0.0,
	"trade_bonus": 0.0,
	"global_efficiency": 0.0,
	"detection_bonus": 0.0
}

func attempt_discovery(system_id: String, scanner_level: int) -> Dictionary:
	var base_chance = _get_scanner_detection_chance(scanner_level)
	var system_modifier = _get_system_discovery_modifier(system_id)
	var final_chance = base_chance * system_modifier
	
	if randf() < final_chance:
		return _generate_artifact_discovery(system_id)
	
	return {}

func collect_artifact(artifact_id: String) -> Dictionary:
	var artifact = _find_artifact_by_id(artifact_id)
	if artifact.is_empty():
		return {"success": false, "error": "Artifact not found"}
	
	# Check if artifact is already collected
	if collected_artifacts.has(artifact_id):
		return {"success": false, "error": "Artifact already collected"}
	
	# Add to collected artifacts
	collected_artifacts.append(artifact_id)
	
	# Apply artifact effects
	var effects = _apply_artifact_effects(artifact)
	
	# Check if this unlocks new precursor lore
	var civilization = _get_artifact_civilization(artifact_id)
	if not precursor_civilizations[civilization]["discovered"]:
		precursor_civilizations[civilization]["discovered"] = true
		precursor_lore_unlocked.emit(civilization, precursor_civilizations[civilization]["lore"])
	
	# Emit signals
	artifact_collected.emit(artifact_id, effects)
	artifact_effects_applied.emit(active_bonuses)
	
	return {"success": true, "effects": effects}

func get_active_bonuses() -> Dictionary:
	return active_bonuses

@warning_ignore("unused_parameter")
func get_trade_bonus(good_type: String = "") -> float:
	return active_bonuses.get("trade_bonus", 0.0)

func get_fuel_efficiency_bonus() -> float:
	return active_bonuses.get("fuel_efficiency_bonus", 0.0)

func get_travel_speed_bonus() -> float:
	return active_bonuses.get("travel_speed_bonus", 0.0)

func get_collected_artifacts() -> Array:
	var artifacts_data = []
	for artifact_id in collected_artifacts:
		var artifact = _find_artifact_by_id(artifact_id)
		if not artifact.is_empty():
			artifacts_data.append(artifact)
	return artifacts_data

func get_precursor_lore() -> Dictionary:
	var lore_data = {}
	for civ_id in precursor_civilizations.keys():
		var civ = precursor_civilizations[civ_id]
		lore_data[civ_id] = {
			"name": civ["name"],
			"discovered": civ["discovered"],
			"lore": civ["lore"] if civ["discovered"] else "",
			"artifacts_found": _count_artifacts_from_civilization(civ_id)
		}
	return lore_data

func _get_scanner_detection_chance(scanner_level: int) -> float:
	var detection_chances = [0.05, 0.10, 0.15, 0.22, 0.30, 0.40]
	return detection_chances[clamp(scanner_level, 0, detection_chances.size() - 1)]

func _get_system_discovery_modifier(system_id: String) -> float:
	# Different systems have different artifact discovery rates
	match system_id:
		"frontier_outpost":
			return 2.0  # High chance in frontier systems
		"nexus_station":
			return 0.5  # Low chance in hub systems
		_:
			return 1.0  # Normal chance elsewhere

func _generate_artifact_discovery(system_id: String) -> Dictionary:
	# Select random civilization and artifact
	var civilizations = precursor_civilizations.keys()
	var selected_civ = civilizations[randi() % civilizations.size()]
	var artifacts = precursor_civilizations[selected_civ]["artifacts"].keys()
	var selected_artifact = artifacts[randi() % artifacts.size()]
	
	var artifact_data = precursor_civilizations[selected_civ]["artifacts"][selected_artifact]
	
	return {
		"artifact_id": selected_artifact,
		"civilization": selected_civ,
		"name": artifact_data["name"],
		"description": artifact_data["description"],
		"lore": artifact_data["lore"],
		"rarity": artifact_data["rarity"],
		"system_id": system_id
	}

func _find_artifact_by_id(artifact_id: String) -> Dictionary:
	for civ_id in precursor_civilizations.keys():
		var artifacts = precursor_civilizations[civ_id]["artifacts"]
		if artifacts.has(artifact_id):
			var artifact = artifacts[artifact_id].duplicate()
			artifact["id"] = artifact_id
			artifact["civilization"] = civ_id
			return artifact
	return {}

func _get_artifact_civilization(artifact_id: String) -> String:
	for civ_id in precursor_civilizations.keys():
		if precursor_civilizations[civ_id]["artifacts"].has(artifact_id):
			return civ_id
	return ""

func _apply_artifact_effects(artifact: Dictionary) -> Dictionary:
	var effects = {}
	
	match artifact["effect_type"]:
		"travel_speed":
			active_bonuses["travel_speed_bonus"] += artifact["magnitude"]
			effects["travel_speed_bonus"] = artifact["magnitude"]
		"global_efficiency":
			active_bonuses["global_efficiency"] += artifact["magnitude"]
			effects["global_efficiency"] = artifact["magnitude"]
		"market_bonus":
			active_bonuses["trade_bonus"] += artifact["magnitude"]
			effects["trade_bonus"] = artifact["magnitude"]
		"fuel_efficiency":
			active_bonuses["fuel_efficiency_bonus"] += artifact["magnitude"]
			effects["fuel_efficiency_bonus"] = artifact["magnitude"]
		"new_routes":
			# Special effect - could unlock new travel routes
			effects["new_routes"] = true
		"wormhole_access":
			# Special effect - instant travel capability
			effects["wormhole_access"] = true
	
	return effects

func restore_artifact_effects(artifact_ids: Array):
	# Restore artifacts without duplicating them in collected_artifacts
	# This is used when loading saved game data
	collected_artifacts.clear()
	active_bonuses = {
		"travel_speed_bonus": 0.0,
		"fuel_efficiency_bonus": 0.0,
		"trade_bonus": 0.0,
		"global_efficiency": 0.0,
		"detection_bonus": 0.0
	}
	
	for artifact_id in artifact_ids:
		var artifact = _find_artifact_by_id(artifact_id)
		if not artifact.is_empty():
			collected_artifacts.append(artifact_id)
			_apply_artifact_effects(artifact)
			
			# Update precursor lore discovery status
			var civilization = _get_artifact_civilization(artifact_id)
			if not precursor_civilizations[civilization]["discovered"]:
				precursor_civilizations[civilization]["discovered"] = true

func _count_artifacts_from_civilization(civ_id: String) -> int:
	var count = 0
	for artifact_id in collected_artifacts:
		if _get_artifact_civilization(artifact_id) == civ_id:
			count += 1
	return count
