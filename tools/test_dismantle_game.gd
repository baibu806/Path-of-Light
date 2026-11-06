extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://scenes/lighthouse_game.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/levels/layers/manifest.json"))
	var counted := 0
	for floor_index in range(7):
		game._load_floor(floor_index)
		game._set_dismantle_mode(true)
		game.selected_object_index = 0
		_key(game, KEY_TAB)
		assert(game.selected_object_index == 1)
		game.selected_object_index = 0
		var expected: Array = manifest.floors["floor_%02d" % (floor_index + 1)].objects
		assert(game.floor_objects.size() == expected.size())
		for object_index in range(game.floor_objects.size()):
			var prop: Sprite2D = game.floor_objects[object_index]
			var id := prop.name.trim_prefix("Prop_")
			var origin: Vector2 = game.object_origins[id]
			assert(prop.texture != null)
			assert(prop.get_meta("independent_art", false))
			game.selected_object_index = object_index
			_key(game, KEY_X)
			assert(not prop.visible)
			assert(game.object_states[floor_index].has(id))
			_key(game, KEY_RIGHT)
			assert(prop.visible and prop.position == origin + Vector2(9, 0))
			_key(game, KEY_ENTER)
			assert(prop.visible and prop.position == origin)
			assert(not game.object_states[floor_index].has(id))
			_key(game, KEY_X)
			counted += 1
		assert(game.object_states[floor_index].size() == expected.size())
		game._load_floor_layers(false)
		assert(_all_removed(game))
		game._load_floor_layers(true)
		assert(_all_removed(game))
		_key(game, KEY_R)
		assert(game.object_states[floor_index].is_empty())
		for prop in game.floor_objects:
			assert(prop.visible)
		game._set_dismantle_mode(false)
	assert(counted == 102)
	game._load_floor(0)
	game._set_dismantle_mode(true)
	var mouse_prop: Sprite2D = game.level_root.get_node("Prop_front_barrel")
	var click_point := _find_pick_point(game, mouse_prop)
	assert(click_point.x >= 0.0)
	_mouse_button(game, click_point, MOUSE_BUTTON_LEFT, true)
	_mouse_button(game, click_point, MOUSE_BUTTON_LEFT, false)
	assert(not mouse_prop.visible)
	_mouse_button(game, click_point, MOUSE_BUTTON_RIGHT, true)
	assert(mouse_prop.visible)
	var original: Vector2 = mouse_prop.position
	var drag_target := click_point + Vector2(84, 18)
	_mouse_button(game, click_point, MOUSE_BUTTON_LEFT, true)
	var motion := InputEventMouseMotion.new()
	motion.position = drag_target
	game._unhandled_input(motion)
	_mouse_button(game, drag_target, MOUSE_BUTTON_LEFT, false)
	assert(mouse_prop.visible)
	assert(mouse_prop.position.distance_to(original + Vector2(84, 18) / game.world_camera.zoom) < 0.1)
	game._restore_object(mouse_prop)
	assert(mouse_prop.position == original)
	print("DISMANTLE_TEST_OK removable_objects=102 back_slices=204 broken_repaired_persistence=7")
	game.ambient.stop()
	game.sfx.stop()
	game.ambient.stream = null
	game.sfx.stream = null
	game.free()
	await process_frame
	quit()


func _all_removed(game: Node2D) -> bool:
	for prop in game.floor_objects:
		if prop.visible:
			return false
	return true


func _key(game: Node2D, key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	game._unhandled_input(event)


func _mouse_button(game: Node2D, point: Vector2, button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.position = point
	event.pressed = pressed
	game._unhandled_input(event)


func _find_pick_point(game: Node2D, prop: Sprite2D) -> Vector2:
	var image := prop.texture.get_image()
	for y in range(4, image.get_height(), 3):
		for x in range(4, image.get_width(), 3):
			if image.get_pixel(x, y).a < 0.7:
				continue
			var world_point: Vector2 = game.level_root.to_global(prop.position + Vector2(x, y) * prop.scale)
			var point: Vector2 = game.get_canvas_transform() * world_point
			if game._pick_visible_object(point) == prop:
				return point
	return Vector2(-1, -1)
