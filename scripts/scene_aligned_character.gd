extends RefCounted

# Scene-camera-compatible locomotion art. Other action clips remain in the
# original SpriteFrames until matching three-quarter action art is approved.
const ROOT := "res://assets/characters/scene_aligned/"
const IDLE_SCALE := 0.15
const WALK_SCALE := 0.30
const ACTION_SCALE := 0.30


static func build_frames(original: SpriteFrames) -> SpriteFrames:
	var frames := original.duplicate(true) as SpriteFrames
	var idle_front: Texture2D = load(ROOT + "boy_idle_front_34_v1.png")
	var idle_side: Texture2D = load(ROOT + "boy_idle_side_34_v1.png")
	var idle_back: Texture2D = load(ROOT + "boy_idle_back_34_v1.png")
	var walk_front: Texture2D = load(ROOT + "boy_walk_front_34_sheet_v1.png")
	var walk_back: Texture2D = load(ROOT + "boy_walk_back_34_sheet_v1.png")
	var walk_side: Texture2D = load(ROOT + "boy_walk_side_34_sheet_v1.png")
	var between_front: Texture2D = load(ROOT + "boy_walk_front_34_inbetween_v2.png")
	var between_back: Texture2D = load(ROOT + "boy_walk_back_34_inbetween_v2.png")
	var action_sheets := {
		&"manual_front": load(ROOT + "boy_manual_front_34_sheet_v1.png"),
		&"repair_front": load(ROOT + "boy_repair_front_34_sheet_v2.png"),
		&"success_front": load(ROOT + "boy_success_front_34_sheet_v1.png"),
		&"failure_front": load(ROOT + "boy_failure_front_34_sheet_v1.png"),
	}
	for name in [&"idle_front", &"idle_side", &"idle_back", &"walk_front", &"walk_side", &"walk_back"]:
		if frames.has_animation(name):
			frames.clear(name)
	var idle_map := {&"idle_front": idle_front, &"idle_side": idle_side, &"idle_back": idle_back}
	for name in idle_map:
		frames.add_frame(name, idle_map[name])
		frames.set_animation_speed(name, 2.0)
	var walk_map := {&"walk_front": walk_front, &"walk_side": walk_side, &"walk_back": walk_back}
	for name in walk_map:
		var main_sheet: Texture2D = walk_map[name]
		if name == &"walk_side":
			for index in range(4):
				frames.add_frame(name, _sheet_cell(main_sheet, index))
			frames.set_animation_speed(name, 8.0)
			frames.set_animation_loop(name, true)
			continue
		var between_sheet: Texture2D = between_back if name == &"walk_back" else between_front
		for index in range(4):
			frames.add_frame(name, _sheet_cell(main_sheet, index))
			frames.add_frame(name, _sheet_cell(between_sheet, index))
		frames.set_animation_speed(name, 10.0)
		frames.set_animation_loop(name, true)
	for name in action_sheets:
		if frames.has_animation(name):
			frames.clear(name)
		var sheet: Texture2D = action_sheets[name]
		for index in range(4):
			frames.add_frame(name, _sheet_cell(sheet, index))
		frames.set_animation_speed(name, 6.0)
		frames.set_animation_loop(name, name == &"manual_front")
	return frames


static func _sheet_cell(sheet: Texture2D, index: int) -> AtlasTexture:
	var cell := sheet.get_size() / 2.0
	var slice := AtlasTexture.new()
	slice.atlas = sheet
	slice.region = Rect2(Vector2(index % 2, floori(float(index) / 2.0)) * cell, cell)
	return slice


static func align_feet(sprite: AnimatedSprite2D) -> void:
	var name := String(sprite.animation)
	if name.begins_with("walk_"):
		sprite.scale = Vector2.ONE * WALK_SCALE
		sprite.offset = Vector2(0, -332)
	elif name.begins_with("idle_"):
		sprite.scale = Vector2.ONE * IDLE_SCALE
		sprite.offset = Vector2(0, -640)
	elif name in ["manual_front", "repair_front", "success_front", "failure_front"]:
		sprite.scale = Vector2.ONE * ACTION_SCALE
		sprite.offset = Vector2(0, -332)
	else:
		sprite.scale = Vector2.ONE * 0.37
		sprite.offset = Vector2(0, -352)
