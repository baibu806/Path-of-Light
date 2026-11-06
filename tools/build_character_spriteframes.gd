extends SceneTree

const OUTPUT := "res://assets/characters/main_character_sprite_frames.tres"
const BASE := "res://assets/ui/Characters/MainCharacter/Animations"

const ANIMATIONS := [
	{"name": "idle_front", "path": BASE + "/Idle/Sprites/Front", "fps": 4.0, "loop": true},
	{"name": "idle_side", "path": BASE + "/Idle/Sprites/Side", "fps": 4.0, "loop": true},
	{"name": "idle_back", "path": BASE + "/Idle/Sprites/Back", "fps": 4.0, "loop": true},
	{"name": "walk_front", "path": BASE + "/Walk/Sprites/Front", "fps": 8.0, "loop": true},
	{"name": "walk_side", "path": BASE + "/Walk/Sprites/Side", "fps": 8.0, "loop": true},
	{"name": "walk_back", "path": BASE + "/Walk/Sprites/Back", "fps": 8.0, "loop": true},
	{"name": "interact_front", "path": BASE + "/Interact/Sprites/Front", "fps": 8.0, "loop": false},
	{"name": "interact_side", "path": BASE + "/Interact/Sprites/Side", "fps": 8.0, "loop": false},
	{"name": "interact_back", "path": BASE + "/Interact/Sprites/Back", "fps": 8.0, "loop": false},
	{"name": "repair_front", "path": BASE + "/RepairCrouch/Sprites/Front", "fps": 7.0, "loop": false},
	{"name": "repair_side", "path": BASE + "/RepairCrouch/Sprites/Side", "fps": 7.0, "loop": false},
	{"name": "repair_back", "path": BASE + "/RepairCrouch/Sprites/Back", "fps": 7.0, "loop": false},
	{"name": "manual_front", "path": BASE + "/ManualFlip/Sprites/Front", "fps": 7.0, "loop": false},
	{"name": "manual_side", "path": BASE + "/ManualFlip/Sprites/Side", "fps": 7.0, "loop": false},
	{"name": "manual_back", "path": BASE + "/ManualFlip/Sprites/Back", "fps": 7.0, "loop": false},
	{"name": "success_front", "path": BASE + "/Success/Sprites/Front", "fps": 8.0, "loop": false},
	{"name": "failure_front", "path": BASE + "/Failure/Sprites/Front", "fps": 8.0, "loop": false},
]


func _initialize() -> void:
	var sprite_frames := SpriteFrames.new()
	if sprite_frames.has_animation(&"default"):
		sprite_frames.remove_animation(&"default")

	for definition in ANIMATIONS:
		var animation_name := StringName(definition["name"])
		sprite_frames.add_animation(animation_name)
		sprite_frames.set_animation_speed(animation_name, definition["fps"])
		sprite_frames.set_animation_loop(animation_name, definition["loop"])

		var files := DirAccess.get_files_at(definition["path"])
		files.sort()
		for filename in files:
			if filename.get_extension().to_lower() != "png":
				continue
			var texture := load(definition["path"].path_join(filename)) as Texture2D
			if texture:
				sprite_frames.add_frame(animation_name, texture)

		print(animation_name, ": ", sprite_frames.get_frame_count(animation_name), " frames")

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var error := ResourceSaver.save(sprite_frames, OUTPUT)
	if error != OK:
		printerr("Failed to save SpriteFrames: ", error)
		quit(error)
		return
	print("Saved: ", OUTPUT)
	quit()

