extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://scenes/lighthouse_game.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	var failures := 0
	for floor_index in range(7):
		var broken := Image.load_from_file(ProjectSettings.globalize_path(game.EXPANDED_ART[floor_index]))
		var repaired := Image.load_from_file(ProjectSettings.globalize_path(game.EXPANDED_REPAIRED_ART[floor_index]))
		if broken.is_empty() or repaired.is_empty():
			push_error("Floor %d repair pair missing" % (floor_index + 1))
			failures += 1
			continue
		var canvas_size: Vector2 = game._expanded_canvas_size()
		var source_gap := (Vector2(broken.get_size()) - Vector2(repaired.get_size())).abs()
		if source_gap.x > 1.0 or source_gap.y > 1.0:
			push_error("Floor %d repair pair exceeds one-pixel alignment tolerance" % (floor_index + 1))
			failures += 1
			continue
		# Rendering scales both paintings into this same canvas; normalize source
		# sampling here as well so the floor-five one-pixel export gap is audited.
		if broken.get_size() != Vector2i(canvas_size):
			broken.resize(int(canvas_size.x), int(canvas_size.y), Image.INTERPOLATE_BILINEAR)
		if repaired.get_size() != Vector2i(canvas_size):
			repaired.resize(int(canvas_size.x), int(canvas_size.y), Image.INTERPOLATE_BILINEAR)
		var regions: Array = game.PARTIAL_REPAIR_REGIONS[floor_index]
		var changed := PackedInt32Array()
		changed.resize(regions.size() + 1)
		var totals := PackedInt32Array()
		totals.resize(regions.size() + 1)
		for y in range(0, broken.get_height(), 2):
			for x in range(0, broken.get_width(), 2):
				var bucket := regions.size()
				for index in range(regions.size()):
					var region: Vector4 = regions[index]
					var dx := (float(x) - region.x) / region.z
					var dy := (float(y) - region.y) / region.w
					if dx * dx + dy * dy < 0.74:
						bucket = index
						break
				totals[bucket] += 1
				var a := broken.get_pixel(x, y)
				var b := repaired.get_pixel(x, y)
				if maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b))) > 0.095:
					changed[bucket] += 1
		var rates := PackedStringArray()
		for index in range(changed.size()):
			rates.append("%0.1f%%" % (100.0 * changed[index] / maxf(1.0, totals[index])))
			if index < regions.size() - 1 and changed[index] < 100:
				push_error("Floor %d repair stage %d has no visible art change" % [floor_index + 1, index + 1])
				failures += 1
		print("REPAIR_ART floor=%d size=%s changed_by_stage=%s outside=%s" % [floor_index + 1, broken.get_size(), str(rates.slice(0, regions.size())), rates[regions.size()]])
	game.free()
	quit(1 if failures else 0)
