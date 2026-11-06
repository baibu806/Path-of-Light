extends SceneTree


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var game_scene: PackedScene = load("res://scenes/lighthouse_game.tscn")
	var game = game_scene.instantiate()
	root.add_child(game)
	await process_frame
	var layer_manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/levels/layers/manifest.json"))
	var total_objects := 0
	for floor_index in range(7):
		game._load_floor(floor_index)
		await process_frame
		var floor_id := "floor_%02d" % (floor_index + 1)
		var expected_count: int = layer_manifest.floors[floor_id].objects.size()
		assert(game.level_root.get_meta("expanded_scene", false))
		assert(game.level_root.get_meta("independent_equipment_count", 0) == expected_count)
		assert(game.floor_objects.size() == expected_count)
		assert(not game.world_hint_frame.visible)
		total_objects += expected_count
		assert(ResourceLoader.exists(game.EXPANDED_REPAIRED_ART[floor_index]))
		# Dismantle references may cluster near one station; repair tasks are
		# driven by their own panel interactions, not by prop-group coverage.
		for prop in game.floor_objects:
			var group := int(prop.get_meta("repair_group"))
			assert(group >= 0 and group < game.floors[floor_index].tasks.size())
		assert(game.partial_repair_overlay != null)
		var partial_material := game.partial_repair_overlay.material as ShaderMaterial
		assert(int(partial_material.get_shader_parameter("completed_stages")) == 0)
		game.progress[floor_index] = 1
		game._load_floor(floor_index)
		partial_material = game.partial_repair_overlay.material as ShaderMaterial
		assert(int(partial_material.get_shader_parameter("completed_stages")) == 1)
		assert(game.background.texture.resource_path == game.EXPANDED_ART[floor_index])
		game.progress[floor_index] = 0
	var state: Dictionary = game.export_state()
	assert(state.progress.size() == 7 and state.medal_levels.size() == 7)
	game.queue_free()
	await process_frame

	var shell_scene: PackedScene = load("res://scenes/game_shell.tscn")
	var shell = shell_scene.instantiate()
	root.add_child(shell)
	await process_frame
	assert(shell.menu_root.visible)
	assert(shell.opening_root != null and shell.pause_root != null and shell.ending_root != null)
	assert(shell.opening_video.stream != null)
	assert(shell.ending_video.stream != null)
	assert(shell.ending_still.texture != null)
	print("COMPLETION_SYSTEMS_OK floors=7 split_objects=%d repaired_states=7 cinematic_videos=2 save_pause_ending=ready" % total_objects)
	shell.queue_free()
	await process_frame
	quit()
