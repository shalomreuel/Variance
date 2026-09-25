extends SceneTree
## Isolate user:// with XDG_DATA_HOME=/tmp/vz-smoke before running this test.
## Headless interaction test: start -> walk -> Professor -> lab -> score -> Professor.

func _initialize() -> void:
	call_deferred("_run")

func _interact(player: PlayerController) -> void:
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	player._unhandled_input(press)

func _run() -> void:
	GameState.reset_study()
	assert(change_scene_to_file("res://start_screen.tscn") == OK)
	await process_frame
	await process_frame
	assert(current_scene != null)
	assert(current_scene.name == "StartScreen")
	current_scene.call("_enter_lab")
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.name == "World")
	var world: Node2D = current_scene
	var player: PlayerController = world.get_node("Player")
	var start_x: float = player.position.x
	Input.action_press("move_right")
	for i in range(8):
		await physics_frame
	Input.action_release("move_right")
	assert(player.position.x > start_x)

	player.global_position = Vector2(822, 478)
	for i in range(3):
		await physics_frame
	assert(player.current_focus != null and player.current_focus.kind == "professor")
	_interact(player)
	await process_frame
	var mentor: Control = world.get("open_overlay")
	assert(mentor != null and not player.can_move)
	var question: LineEdit = mentor.get("input")
	question.text = "The dominant allele is the stronger gene."
	mentor.call("_submit_answer")
	assert(GameState.profile["misconceptions"].has("dominant_means_stronger"))
	var offer: Dictionary = mentor.get("proposed_quest")
	assert(offer.get("quest_id") == "dominance_intro")
	mentor.call("_on_action")
	assert(GameState.status == "quest_active")
	mentor.emit_signal("closed")
	await process_frame
	await process_frame
	assert(player.can_move)

	player.global_position = Vector2(317, 548)
	for i in range(3):
		await physics_frame
	assert(player.current_focus != null and player.current_focus.kind == "computer")
	_interact(player)
	await process_frame
	var editor: Control = world.get("open_overlay")
	assert(editor != null)
	var config: Dictionary = editor.get("configuration")
	assert(GameState.genetics.express("fur_color", str(config["fur_color"])) == "Dark fur")
	var slider: HSlider = editor.get("prediction_slider")
	slider.value = 100
	assert(not editor.get("locked"))
	editor.call("_lock_prediction")
	assert(editor.get("locked"))
	assert(not GameState.profile["pending_prediction"].is_empty())
	editor.call("_run_simulation")
	assert(GameState.status == "awaiting_professor")
	assert(GameState.last_result["simulation"]["genotype_ratios"] == {"BB": 25, "Bb": 50, "bb": 25})
	assert(GameState.last_result["assessment"]["prediction_accuracy"] == 75.0)
	assert(editor.get("results_view") != null)
	var results: Control = editor.get("results_view")
	results.emit_signal("return_to_world")
	await process_frame
	await process_frame
	assert(player.can_move)

	player.global_position = Vector2(822, 478)
	for i in range(3):
		await physics_frame
	_interact(player)
	await process_frame
	mentor = world.get("open_overlay")
	assert(mentor != null)
	assert(str(mentor.get("speech").text).contains("75%"))
	mentor.call("_on_action")
	offer = mentor.get("proposed_quest")
	assert(offer["quest_id"] == "dominance_revisit")
	assert(offer["lab_task"]["trait"] == "ear_type")
	mentor.call("_on_action")
	assert(GameState.current_quest["quest_id"] == "dominance_revisit")
	assert(GameState.profile["mastery"]["dominance"] == 0.75)
	mentor.emit_signal("closed")
	await process_frame

	# Correct follow-up unlocks a deeper, genotype-vs-phenotype question.
	var second_config: Dictionary = GameState.genetics.default_configuration()
	var second_guess := {"Upright ears": 50, "Floppy ears": 50}
	assert(GameState.store_prediction(second_config, "ee", second_guess))
	assert(not GameState.run_experiment(second_config, "ee", second_guess).is_empty())
	GameState.finish_debrief()
	assert(GameState.suggest_quest()["quest_id"] == "hidden_genotypes")
	assert(FileAccess.file_exists(GameState.SAVE_FILE))
	print("SMOKE LOOP: start -> walk -> E Professor -> E lab -> prediction -> result -> adaptive quest OK")
	quit(0)
