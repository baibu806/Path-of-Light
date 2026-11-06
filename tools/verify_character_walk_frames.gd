extends SceneTree

const ORIGINAL := preload("res://assets/characters/main_character_sprite_frames.tres")
const ALIGNED := preload("res://scripts/scene_aligned_character.gd")


func _initialize() -> void:
	var frames: SpriteFrames = ALIGNED.build_frames(ORIGINAL)
	for name in [&"walk_front", &"walk_side", &"walk_back"]:
		if frames.get_frame_count(name) != 8:
			push_error("Expected exactly eight frames: " + String(name))
			quit(1)
			return
		if not frames.get_animation_loop(name):
			push_error("Walk animation must loop: " + String(name))
			quit(1)
			return
		for index in range(8):
			var texture := frames.get_frame_texture(name, index)
			if texture == null or texture.get_size() != Vector2(512, 768):
				push_error("Wrong cell dimensions: %s frame %d" % [name, index])
				quit(1)
				return
		print("CHARACTER_WALK_OK %s frames=8 fps=%.1f" % [name, frames.get_animation_speed(name)])
	for name in [&"manual_front", &"repair_front", &"success_front", &"failure_front"]:
		if frames.get_frame_count(name) != 4:
			push_error("Expected exactly four scene-aligned action frames: " + String(name))
			quit(1)
			return
		for index in range(4):
			var texture := frames.get_frame_texture(name, index)
			if texture == null or texture.get_size() != Vector2(512, 768):
				push_error("Wrong action cell dimensions: %s frame %d size=%s" % [name, index, texture.get_size() if texture != null else Vector2.ZERO])
				quit(1)
				return
		print("CHARACTER_ACTION_OK %s frames=4 fps=%.1f" % [name, frames.get_animation_speed(name)])
	quit()
