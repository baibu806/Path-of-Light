extends SceneTree


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var scene: PackedScene = load("res://scenes/lighthouse_game.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	var errors := 0
	for floor_index in range(7):
		game._load_floor(floor_index)
		var geometry: Dictionary = game.spacious_geometry.floors[floor_index]
		var points: Array = [geometry.entry]
		if geometry.exit != null:
			points.append(geometry.exit)
		points.append_array(geometry.service)
		for pair in points:
			var point: Vector2 = game._vector_from_array(pair)
			if not game._walkable(point):
				push_error("Floor %d required foot position blocked: %s" % [floor_index + 1, point])
				errors += 1
	var forbidden := {0: [Vector2(430, 700), Vector2(950, 430)], 5: [Vector2(800, 520)], 6: [Vector2(650, 650)]}
	for floor_number in forbidden:
		game._load_floor(int(floor_number))
		for point in forbidden[floor_number]:
			if game._walkable(point):
				push_error("Floor %d forbidden footprint accepted: %s" % [int(floor_number) + 1, point])
				errors += 1
	game._load_floor(1)
	# The second-floor portal is a real opening, not a picture of a door
	# underneath the platform. Both boots must fit from floor to threshold.
	for point in [Vector2(1180, 680), Vector2(1260, 680), Vector2(1280, 740), Vector2(1330, 820)]:
		if not game._walkable(point):
			push_error("Floor 2 open portal route blocked: %s" % point)
			errors += 1
	print("POLYGON_GEOMETRY_CHECK invalid=%d" % errors)
	game.ambient.stop()
	game.sfx.stop()
	game.ambient.stream = null
	game.sfx.stream = null
	game.free()
	await process_frame
	quit(0 if errors == 0 else 1)
