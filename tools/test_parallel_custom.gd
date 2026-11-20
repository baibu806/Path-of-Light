extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var game: Node2D = load("res://scenes/lighthouse_game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.repair_delay_seconds = 0.01
	game.repair_transition_seconds = 0.01
	game._load_floor(1)
	game._open_challenge(1)
	assert(game.active_task_index == 1 and game.challenge_art_overlay.pipe_network.visible)
	var network: Control = game.challenge_art_overlay.pipe_network
	network.pieces = {Vector2i(0, 1): 9, Vector2i(0, 0): 6, Vector2i(1, 0): 10, Vector2i(2, 0): 12, Vector2i(2, 1): 3}
	network.check_network()
	await create_timer(0.8).timeout
	assert(game._is_task_done(1, 1) and not game._is_task_done(1, 0))
	assert(game.progress[1] == 1)
	var saved: Dictionary = game.export_state()
	game.import_state(saved)
	assert(game._is_task_done(1, 1) and not game._is_task_done(1, 0))
	game._open_challenge(0)
	assert(not game.challenge_art_overlay.pipe_network.visible and game.challenge_art.visible)
	game._close_challenge()
	game.queue_free()
	await process_frame
	print("PARALLEL_CUSTOM_SAVE_OK")
	quit()
