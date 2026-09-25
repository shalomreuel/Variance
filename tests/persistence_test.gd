extends SceneTree
## Run after smoke_loop.gd with the same isolated XDG_DATA_HOME.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(FileAccess.file_exists(GameState.SAVE_FILE))
	assert(GameState.profile.get("experiments", []).size() == 2)
	assert(GameState.profile.get("quest_history", []).size() == 2)
	assert(GameState.profile["mastery"].has("dominance"))
	assert(GameState.profile["misconceptions"].has("dominant_means_stronger"))
	assert(GameState.last_result["simulation"]["phenotype_ratios"]["Floppy ears"] == 50)
	assert(GameState.status == "needs_quest")
	assert(GameState.suggest_quest()["quest_id"] == "hidden_genotypes")
	print("PERSISTENCE TEST: learner profile, evidence and adaptive next quest restored OK")
	quit(0)
