extends SceneTree


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var scene: PackedScene = load("res://scenes/lighthouse_game.tscn")
	assert(scene != null)
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	var master_bus := AudioServer.get_bus_index("Master")
	assert(master_bus >= 0)
	assert(AudioServer.get_bus_effect_count(master_bus) >= 2)
	assert(AudioServer.get_bus_volume_db(master_bus) <= -10.0)
	assert(game.gameplay_music != null)
	assert(game.gameplay_music.stream != null)
	assert(game.gameplay_music.stream.get_length() > 80.0)
	assert(game.gameplay_music.volume_db <= -18.0)
	game.repair_delay_seconds = 0.01
	game.repair_transition_seconds = 0.01

	assert(game.repair_challenges.size() == 7)
	assert(not game._can_ascend())
	assert(game.floor_index == 0)
	var start_position: Vector2 = game.player.position
	var move_right := InputEventKey.new()
	move_right.keycode = KEY_D
	move_right.physical_keycode = KEY_D
	move_right.pressed = true
	Input.parse_input_event(move_right)
	await create_timer(0.10).timeout
	move_right.pressed = false
	Input.parse_input_event(move_right)
	assert(game.player.position.x > start_position.x)
	assert(game.player.flip_h)
	assert(game.player.animation == &"walk_side")
	var side_frame := game.player.sprite_frames.get_frame_texture(&"walk_side", 0) as AtlasTexture
	assert(side_frame != null and side_frame.atlas.resource_path.ends_with("boy_walk_side_34_sheet_v1.png"))
	var idle_side_frame := game.player.sprite_frames.get_frame_texture(&"idle_side", 0) as Texture2D
	assert(idle_side_frame != null and idle_side_frame.resource_path.ends_with("boy_idle_side_34_v1.png"))
	game._set_direction(Vector2.LEFT)
	assert(game.direction == "side" and not game.player.flip_h)
	game._set_direction(Vector2(1, -1))
	assert(game.direction == "back" and game.player.flip_h)
	game._set_direction(Vector2(-1, 1))
	assert(game.direction == "front" and not game.player.flip_h)
	game.player.position = game._up_stair_point()
	game._try_interact()
	assert(game.floor_index == 0)
	for floor_index in range(7):
		game._load_floor(floor_index, "start" if floor_index == 0 else "from_below")
		assert(game._walkable(game.player.position), "Entry footprint blocked on floor %d at %s" % [floor_index + 1, game.player.position])
		for spot in game.spacious_geometry.floors[floor_index].service:
			assert(_reachable(game, game._vector_from_array(spot), 100.0), "Floor %d service unreachable from entry: %s" % [floor_index + 1, spot])
		if floor_index < 6:
			assert(_reachable(game, game._up_stair_point(), 100.0), "Floor %d upper stair unreachable" % [floor_index + 1])
		if floor_index > 0:
			assert(_reachable(game, game._down_stair_point(), 100.0), "Floor %d lower stair unreachable" % [floor_index + 1])
	game._load_floor(0)
	assert(not game.world_hint_frame.visible)

	for floor_index in range(7):
		game._load_floor(floor_index)
		assert(game.background.texture != null)
		assert(game.background.texture.resource_path.contains("/revisions/floor_"))
		assert(game.level_root.get_meta("expanded_scene", false))
		var task_total: int = game.floors[floor_index].tasks.size()
		assert(task_total >= 3)
		assert(game.repair_challenges[floor_index].size() == task_total)
		for task_index in range(task_total):
			game.player.position = game._current_spot()
			assert(game._walkable(game.player.position), "Service foot point outside floor %d task %d: %s" % [floor_index + 1, task_index + 1, game.player.position])
			game._try_interact()
			assert(game.challenge_overlay.visible, "Interaction missed floor %d task %d at %s" % [floor_index + 1, task_index + 1, game.player.position])
			assert(game.challenge_art.texture != null)
			assert(game.challenge_art_overlay.hint_text.is_empty())
			assert(game.challenge_art_overlay.layout.points.size() > 0)
			assert(game.repair_interaction.config.kind in ["sequence", "drag", "align", "dial"])
			if game.repair_interaction.config.kind == "sequence":
				assert(game.challenge_art_overlay.layout.points.size() == game.repair_interaction.config.items.size())
			elif game.repair_interaction.config.kind == "drag":
				assert(game.challenge_art_overlay.layout.points.size() == game.repair_interaction.config.parts.size())
				assert(game.challenge_art_overlay.layout.has("source") or game.challenge_art_overlay.layout.sources.size() == game.repair_interaction.config.parts.size())
			elif game.repair_interaction.config.kind == "align":
				assert(game.challenge_art_overlay.layout.points.size() == 2)
			if floor_index == 0 and task_index == 0:
				var escape := InputEventKey.new()
				escape.keycode = KEY_ESCAPE
				escape.pressed = true
				game._input(escape)
				assert(not game.challenge_overlay.visible and game.progress[floor_index] == 0)
				game._try_interact()
				assert(game.challenge_overlay.visible)
				game._process(7.1)
				assert(not game.challenge_art_overlay.hint_text.is_empty())
				var activity := InputEventMouseMotion.new()
				activity.position = game.challenge_art_overlay.source_point(0)
				game._input(activity)
				assert(game.challenge_art_overlay.hint_text.is_empty())
				_art_drag(game.challenge_art_overlay, game.challenge_art_overlay.source_point(0), Vector2(210, 330))
				assert(game.progress[floor_index] == 0)
				assert(game.mistakes[floor_index] == 1)
			await _solve_interaction(game.repair_interaction, game.challenge_art_overlay)
			for animation_frame in range(100):
				if not game.working or game.medal_overlay.visible:
					break
				await create_timer(0.02).timeout
			assert(not game.working or game.medal_overlay.visible, "Repair transition did not finish on floor %d task %d" % [floor_index + 1, task_index + 1])
			assert(game.progress[floor_index] == task_index + 1)
			if task_index + 1 < task_total:
				assert(game.partial_repair_overlay != null)
				var partial_material := game.partial_repair_overlay.material as ShaderMaterial
				assert(is_equal_approx(float(partial_material.get_shader_parameter("completed_stages")), float(task_index + 1)))
			else:
				assert(game.partial_repair_overlay == null)
		await create_timer(0.12).timeout
		assert(game.medal_overlay.visible)
		assert(game.background.texture.resource_path.contains("/revisions/floor_"))
		assert(game.medal_levels[floor_index] == (1 if floor_index == 0 else 2))
		game._close_medal()
		assert(not game.working)
		if floor_index < 6:
			assert(game.floor_index == floor_index + 1)
			assert(game._can_descend())
			game.player.position = game._down_stair_point()
			game._try_interact()
			assert(game.floor_index == floor_index)
			assert(game._can_ascend())
			game.player.position = game._up_stair_point()
			game._try_interact()
			assert(game.floor_index == floor_index + 1)

	var sfx_payload = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/sfx/SFX_MANIFEST.json"))
	assert(sfx_payload.count == 45)
	assert(game.EXPANDED_ART.size() == 7 and game.EXPANDED_REPAIRED_ART.size() == 7)
	for floor_index in range(7):
		assert(ResourceLoader.exists(game.EXPANDED_ART[floor_index]))
		assert(ResourceLoader.exists(game.EXPANDED_REPAIRED_ART[floor_index]))

	print("SMOKE_TEST_OK floors=7 interactive_tasks=22 medal_grades=earned+illuminated stair_transitions=12 sfx=45")
	game.ambient.stop()
	game.sfx.stop()
	game.ambient.stream = null
	game.sfx.stream = null
	game.free()
	await process_frame
	quit()


func _solve_interaction(interaction: Control, art: Control) -> void:
	match str(interaction.config.kind):
		"sequence":
			for index in range(interaction.config.items.size()):
				if art.layout.has("sequence_sources") and art.layout.sequence_sources[index] != null:
					_art_drag(art, art._panel_point(art.layout.sequence_sources[index]), art._panel_point(art.layout.sequence_targets[index]))
				else:
					_art_click(art, art.hotspot(index))
		"drag":
			for index in range(interaction.config.parts.size()):
				_art_drag(art, art.source_point(index), art.hotspot(index))
				if art.scraping:
					await create_timer(0.45).timeout
		"align":
			for index in range(2):
				var start: Vector2 = art.hotspot(index)
				var delta: float = float(interaction.config.targets[index]) * 1.6 * art._scale()
				_art_drag(art, start, start + Vector2(0, -delta))
		"dial":
			var radians := deg_to_rad(float(interaction.config.target) - 90.0)
			var center: Vector2 = art._panel_point(art.layout.dial_center)
			var point: Vector2 = center + Vector2(cos(radians), sin(radians)) * 30.0
			_art_drag(art, center, point)
	assert(interaction.finished)


func _click(interaction: Control, point: Vector2) -> void:
	_mouse_button(interaction, point, true)
	_mouse_button(interaction, point, false)


func _drag(interaction: Control, start: Vector2, target: Vector2) -> void:
	_mouse_button(interaction, start, true)
	var motion := InputEventMouseMotion.new()
	motion.position = target
	interaction._gui_input(motion)
	_mouse_button(interaction, target, false)


func _art_click(art: Control, point: Vector2) -> void:
	_mouse_button(art, point, true)
	_mouse_button(art, point, false)


func _art_drag(art: Control, start: Vector2, target: Vector2) -> void:
	_mouse_button(art, start, true)
	var motion := InputEventMouseMotion.new()
	motion.position = target
	art._gui_input(motion)
	_mouse_button(art, target, false)


func _mouse_button(interaction: Control, point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = pressed
	interaction._gui_input(event)


func _reachable(game: Node2D, target: Vector2, threshold: float) -> bool:
	var origin: Vector2 = game.player.position
	var step := 16.0
	var queue: Array[Vector2i] = [Vector2i.ZERO]
	var seen := {Vector2i.ZERO: true}
	var cursor := 0
	var directions := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	while cursor < queue.size() and queue.size() < 20000:
		var cell: Vector2i = queue[cursor]
		cursor += 1
		var point := origin + Vector2(cell) * step
		if point.distance_to(target) <= threshold:
			return true
		for direction in directions:
			var next: Vector2i = cell + direction
			if seen.has(next):
				continue
			var next_point := origin + Vector2(next) * step
			if not game._walkable(next_point):
				continue
			seen[next] = true
			queue.append(next)
	return false
