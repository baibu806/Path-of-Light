extends Node2D

signal state_changed(state: Dictionary)
signal game_completed(state: Dictionary)

const CHARACTER_FRAMES := preload("res://assets/characters/main_character_sprite_frames.tres")
const SCENE_ALIGNED_CHARACTER := preload("res://scripts/scene_aligned_character.gd")
const REPAIR_INTERACTION := preload("res://scripts/repair_interaction.gd")
const REPAIR_ART_OVERLAY := preload("res://scripts/repair_art_overlay.gd")
const PARTIAL_REPAIR_SHADER := preload("res://shaders/partial_floor_repair.gdshader")
const UI := preload("res://scripts/ui_typography.gd")
const UI_ROOT := "res://assets/ui/Global/"
const GAMEPLAY_MUSIC_PATH := "res://assets/audio/music/ruins_light_gameplay_suno_v1.wav"
const VIEW_SIZE := Vector2(1536.0, 1024.0)
const EXPANDED_IMAGE_SCALE := 1.0
const SPACIOUS_GEOMETRY_PATH := "res://assets/data/spacious_floor_geometry_v2.json"
const SPACIOUS_PROP_LAYOUT_PATH := "res://assets/data/spacious_prop_layout.json"
const EXPANDED_ART := [
	"res://assets/levels/revisions/floor_01/broken_direct_stairs_v3.png",
	"res://assets/levels/revisions/floor_02/broken_direct_stairs_v3.png",
	"res://assets/levels/revisions/floor_03/broken_direct_stairs_v3.png",
	"res://assets/levels/revisions/floor_04/broken_direct_stairs_v3.png",
	"res://assets/levels/revisions/floor_05/broken_direct_stairs_v3.png",
	"res://assets/levels/revisions/floor_06/broken_direct_stairs_v3.png",
	"res://assets/levels/revisions/floor_07/broken_direct_stairs_v3.png",
]
const EXPANDED_REPAIRED_ART := [
	"res://assets/levels/revisions/floor_01/repaired_direct_stairs_v3.png",
	"res://assets/levels/revisions/floor_02/repaired_direct_stairs_v3.png",
	"res://assets/levels/revisions/floor_03/repaired_direct_stairs_v3.png",
	"res://assets/levels/revisions/floor_04/repaired_direct_stairs_v3.png",
	"res://assets/levels/revisions/floor_05/repaired_direct_stairs_v3.png",
	"res://assets/levels/revisions/floor_06/repaired_direct_stairs_v3.png",
	"res://assets/levels/revisions/floor_07/repaired_direct_stairs_v3.png",
]
# Intermediate repairs reveal changes only at the matching equipment.
# The final task switches to the entire repaired painting.
const PARTIAL_REPAIR_REGIONS := [
	[Vector4(520, 430, 360, 340), Vector4(850, 510, 320, 350), Vector4(1120, 490, 300, 330)],
	[Vector4(880, 265, 135, 180), Vector4(1040, 380, 160, 210), Vector4(1100, 490, 260, 250)],
	[Vector4(430, 220, 165, 165), Vector4(610, 165, 195, 170), Vector4(1060, 220, 165, 175)],
	[Vector4(570, 210, 145, 155), Vector4(820, 285, 300, 255), Vector4(1050, 300, 160, 170)],
	[Vector4(470, 300, 58, 78), Vector4(710, 270, 105, 115), Vector4(1060, 355, 170, 200)],
	[Vector4(1180, 345, 92, 100), Vector4(790, 335, 165, 160), Vector4(865, 230, 240, 250)],
	[Vector4(650, 615, 245, 125), Vector4(690, 370, 205, 205), Vector4(895, 500, 175, 170), Vector4(710, 365, 305, 300)],
]
const PLAYER_SCALE := 0.37
const PLAYER_SPEED := 230.0
const INTERACT_DISTANCE := 130.0
const STAIR_DISTANCE := 135.0
const MEDAL_IDS := ["foundation", "drainage", "power", "machinery", "reflection", "focus", "dawn_guardian"]
const MEDAL_NAMES := ["地基守护", "疏水修复", "电力恢复", "机械调校", "镜面反射", "焦点校准", "黎明守望"]

var floors := [
	{
		"title": "第一层 · 地基检查",
		"ambient": "res://assets/audio/sfx/ambience/rain_room_loop.wav",
		"tasks": ["清除盐霜并寻找裂缝", "敲击判断空鼓与受潮范围", "填补砂浆并完成承压测试"],
		"sounds": ["floor_01/salt_scrape.wav", "floor_01/stone_tap.wav", "floor_01/pressure_test.wav"]
	},
	{
		"title": "第二层 · 管道拼接",
		"ambient": "res://assets/audio/sfx/ambience/rain_room_loop.wav",
		"tasks": ["沿水迹定位破损管段", "重新拼接管道并锁紧接头", "按顺序转动阀门并启动排水泵"],
		"sounds": ["floor_02/water_leak.wav", "floor_02/pipe_clank.wav", "floor_02/pump_start.wav"]
	},
	{
		"title": "第三层 · 电路装配",
		"ambient": "res://assets/audio/sfx/ambience/machinery_hum_loop.wav",
		"tasks": ["清理受潮线路并查找短路点", "安装保险丝并恢复控制回路", "合上主电闸并校准输出电压"],
		"sounds": ["floor_03/electric_crackle.wav", "floor_03/fuse_insert.wav", "floor_03/power_restore.wav"]
	},
	{
		"title": "第四层 · 齿轮调校",
		"ambient": "res://assets/audio/sfx/ambience/machinery_hum_loop.wav",
		"tasks": ["诊断卡滞齿轮与断齿位置", "更换齿轮并调节啮合间隙", "完成注油与空载运转测试"],
		"sounds": ["floor_04/gear_jam.wav", "floor_04/gear_fit.wav", "floor_04/gear_running.wav"]
	},
	{
		"title": "第五层 · 镜片装配",
		"ambient": "res://assets/audio/sfx/ambience/coastal_wind_loop.wav",
		"tasks": ["擦除盐雾并检查镜片裂损", "按光路顺序安装反射镜", "点亮测试光源确认折射路径"],
		"sounds": ["floor_05/glass_wipe.wav", "floor_05/lens_place.wav", "floor_05/test_beam.wav"]
	},
	{
		"title": "第六层 · 焦距校准",
		"ambient": "res://assets/audio/sfx/ambience/machinery_hum_loop.wav",
		"tasks": ["移动光源到标定位置", "微调环形镜组的角度与焦距", "控制温度并锁定稳定光束"],
		"sounds": ["floor_06/mirror_swivel.wav", "floor_06/focus_adjust.wav", "floor_06/focus_lock.wav"]
	},
	{
		"title": "第七层 · 主灯复明",
		"ambient": "res://assets/audio/sfx/ambience/coastal_wind_loop.wav",
		"tasks": ["检查七层系统回传信号", "按手册顺序通过闪灯校验", "旋转方位盘对准港口航道", "合上主断路器并启动灯塔"],
		"sounds": ["floor_07/control_beep.wav", "floor_07/control_beep.wav", "floor_07/compass_rotate.wav", "floor_07/lighthouse_start.wav"]
	}
]

var floor_index := 0
var progress := [0, 0, 0, 0, 0, 0, 0]
var mistakes := [0, 0, 0, 0, 0, 0, 0]
var medal_levels := [0, 0, 0, 0, 0, 0, 0]
var repair_challenges: Array = []
var spacious_geometry: Dictionary = {}
var spacious_prop_layout: Dictionary = {}
var floor_objects: Array[Sprite2D] = []
var object_base_z: Dictionary = {}
var object_states: Array[Dictionary] = [{}, {}, {}, {}, {}, {}, {}]
var object_origins: Dictionary = {}
var object_images: Dictionary = {}
var dismantle_mode := false
var selected_object_index := 0
var dragging_object: Sprite2D
var object_drag_offset := Vector2.ZERO
var object_drag_start := Vector2.ZERO
var object_drag_moved := false
var dismantle_message := ""
var working := false
var direction := "front"
var footstep_timer := 0.0
var repair_delay_seconds := 0.75
var repair_transition_seconds := 1.0
var floor_transitioning := false
var background_rect := Rect2()

var level_root: Node2D
var background: Sprite2D
var partial_repair_overlay: Sprite2D
var foreground_occluders: Array[Polygon2D] = []
var player: AnimatedSprite2D
var player_body: CharacterBody2D
var player_shadow: Polygon2D
var ambient: AudioStreamPlayer
var gameplay_music: AudioStreamPlayer
var sfx: AudioStreamPlayer
var title_label: Label
var task_label: Label
var progress_label: Label
var prompt_label: Label
var repair_button: Button
var world_hint_frame: NinePatchRect
var world_hint_content: MarginContainer
var world_idle_seconds := 0.0
var world_has_moved := false
var medal_icons: Array[TextureRect] = []
var challenge_overlay: Control
var challenge_art_mount: Control
var challenge_art: TextureRect
var challenge_art_overlay: Control
var challenge_close_button: TextureButton
var repair_interaction: Control
var challenge_idle_seconds := 0.0
var challenge_error_seconds := 0.0
var medal_overlay: Control
var award_icon: TextureRect
var award_title: Label
var award_detail: Label
var medal_continue_button: Button
var up_stair_label: Label
var down_stair_label: Label
var world_camera: Camera2D
var floor_map_overlay: Control
var floor_map_title: Label
var floor_map_detail: Label


func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/repair_challenges.json"))
	if parsed is Array:
		repair_challenges = parsed
	var geometry_parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPACIOUS_GEOMETRY_PATH))
	assert(geometry_parsed is Dictionary)
	spacious_geometry = geometry_parsed
	var layout_parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPACIOUS_PROP_LAYOUT_PATH))
	assert(layout_parsed is Dictionary)
	spacious_prop_layout = layout_parsed
	_build_world()
	_build_hud()
	_load_floor(0)
	var arguments := OS.get_cmdline_user_args()
	if arguments.has("--capture-repair-audit"):
		_capture_repair_audit.call_deferred()
		return
	for argument in arguments:
		if argument.begins_with("--capture-progress="):
			var requested_parts := argument.trim_prefix("--capture-progress=").split(":")
			assert(requested_parts.size() == 2, "Use floor:completed_tasks")
			var requested_floor := clampi(requested_parts[0].to_int(), 1, 7)
			var requested_progress := clampi(requested_parts[1].to_int(), 0, floors[requested_floor - 1].tasks.size())
			progress[requested_floor - 1] = requested_progress
			_load_floor(requested_floor - 1)
			capture_preview.call_deferred("repair_progress_floor_%02d_stage_%02d.png" % [requested_floor, requested_progress])
			return
		if argument.begins_with("--capture-challenge=") or argument.begins_with("--capture-challenge-hint="):
			var with_hint := argument.begins_with("--capture-challenge-hint=")
			var requested_parts := argument.trim_prefix("--capture-challenge-hint=" if with_hint else "--capture-challenge=").split(":")
			assert(requested_parts.size() == 2)
			var requested_floor := clampi(requested_parts[0].to_int(), 1, 7)
			var requested_task := clampi(requested_parts[1].to_int(), 1, floors[requested_floor - 1].tasks.size())
			progress[requested_floor - 1] = requested_task - 1
			_load_floor(requested_floor - 1)
			player.position = _current_spot()
			_open_challenge()
			if with_hint:
				challenge_art_overlay.show_hint(repair_interaction.art_hint())
			capture_preview.call_deferred("challenge_preview%s_floor_%02d_task_%02d.png" % ["_hint" if with_hint else "", requested_floor, requested_task])
			return
		if argument.begins_with("--capture-position="):
			var coordinates := argument.trim_prefix("--capture-position=").split(":")
			assert(coordinates.size() == 3, "Use floor:x:y")
			var requested_floor := clampi(coordinates[0].to_int(), 1, 7)
			_load_floor(requested_floor - 1)
			player.position = Vector2(coordinates[1].to_float(), coordinates[2].to_float())
			capture_preview.call_deferred("position_preview_floor_%02d_%s_%s.png" % [requested_floor, coordinates[1], coordinates[2]])
			return
		if argument.begins_with("--capture-service="):
			var values := argument.trim_prefix("--capture-service=").split(":")
			assert(values.size() == 2, "Use floor:service, starting at 1")
			var requested_floor := clampi(values[0].to_int(), 1, 7)
			_load_floor(requested_floor - 1)
			var service_points: Array = spacious_geometry.floors[floor_index].service
			var requested_service := clampi(values[1].to_int(), 1, service_points.size())
			player.position = _vector_from_array(service_points[requested_service - 1])
			capture_preview.call_deferred("service_preview_floor_%02d_%02d.png" % [requested_floor, requested_service])
			return
		if argument.begins_with("--capture-floor="):
			var requested := clampi(argument.trim_prefix("--capture-floor=").to_int(), 1, 7)
			_load_floor(requested - 1)
			player.position = _current_spot()
			capture_preview.call_deferred("layer_preview_floor_%02d.png" % requested)
			return
		if argument.begins_with("--capture-repaired-floor="):
			var repaired_requested := clampi(argument.trim_prefix("--capture-repaired-floor=").to_int(), 1, 7)
			var repaired_index := repaired_requested - 1
			progress[repaired_index] = floors[repaired_index].tasks.size()
			medal_levels[repaired_index] = 2
			_load_floor(repaired_index)
			player.position = _current_spot()
			capture_preview.call_deferred("repaired_preview_floor_%02d.png" % repaired_requested)
			return
		if argument.begins_with("--capture-action="):
			var action := argument.trim_prefix("--capture-action=")
			var allowed := ["manual_front", "repair_front", "success_front", "failure_front"]
			assert(action in allowed, "Unknown capture action: " + action)
			_load_floor(2)
			player.position = _current_spot()
			player.play(StringName(action))
			player.frame = 2
			SCENE_ALIGNED_CHARACTER.align_feet(player)
			working = true
			capture_preview.call_deferred("character_action_%s.png" % action)
			return
	if arguments.has("--capture-challenge"):
		player.position = _current_spot()
		_open_challenge()
		capture_preview.call_deferred("challenge_preview.png")
	elif arguments.has("--capture-map"):
		toggle_floor_map(true)
		capture_preview.call_deferred("floor_map_screen.png")
	elif arguments.has("--capture-dismantle"):
		_set_dismantle_mode(true)
		var preview_prop := level_root.get_node("Prop_front_parapet") as Sprite2D
		selected_object_index = floor_objects.find(preview_prop)
		preview_prop.visible = false
		_record_object_state(preview_prop, true)
		capture_preview.call_deferred("dismantle_preview.png")
	elif arguments.has("--capture-medal"):
		progress[0] = 3
		mistakes[0] = 1
		await _complete_floor()
		capture_preview.call_deferred("medal_preview.png")
	elif arguments.has("--capture-repair-transition"):
		progress[0] = 3
		repair_transition_seconds = 1.2
		_complete_floor()
		await get_tree().create_timer(0.6).timeout
		capture_preview.call_deferred("floor_01_repair_transition.png")
	elif arguments.has("--capture"):
		capture_preview.call_deferred()


func capture_preview(filename: String = "gameplay_current.png") -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://docs/" + filename)
	get_tree().quit()


func _capture_repair_audit() -> void:
	var output_directory := ProjectSettings.globalize_path("res://docs/repair_audit")
	DirAccess.make_dir_recursive_absolute(output_directory)
	var captures := 0
	for index in range(floors.size()):
		for stage in range(floors[index].tasks.size() + 1):
			progress[index] = stage
			_load_floor(index)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var filename := "floor_%02d_stage_%02d.png" % [index + 1, stage]
			var error := get_viewport().get_texture().get_image().save_png(output_directory.path_join(filename))
			assert(error == OK, filename)
			captures += 1
	print("REPAIR_AUDIT_CAPTURED count=%d" % captures)
	get_tree().quit()


func _build_world() -> void:
	player_body = CharacterBody2D.new()
	player_body.name = "PlayerFootBody"
	player_body.collision_layer = 1
	player_body.collision_mask = 2
	player_body.safe_margin = 0.1
	var foot_shape := CollisionShape2D.new()
	var feet := ConvexPolygonShape2D.new()
	# Match the full two-boot footprint used by _walkable(), not one center point.
	feet.points = _polygon_from_arrays(spacious_geometry.footprint)
	foot_shape.shape = feet
	player_body.add_child(foot_shape)
	add_child(player_body)

	player = AnimatedSprite2D.new()
	player.sprite_frames = SCENE_ALIGNED_CHARACTER.build_frames(CHARACTER_FRAMES)
	player.animation = &"idle_front"
	player.scale = Vector2.ONE * PLAYER_SCALE
	# Position is the point where the boots touch the floor, not the frame center.
	player.offset = Vector2(0, -352)
	SCENE_ALIGNED_CHARACTER.align_feet(player)
	player.z_index = 1
	add_child(player)
	player_shadow = Polygon2D.new()
	var shadow_points := PackedVector2Array()
	for index in range(24):
		var theta := TAU * float(index) / 24.0
		shadow_points.append(Vector2(cos(theta) * 45.0, sin(theta) * 12.0))
	player_shadow.polygon = shadow_points
	player_shadow.color = Color(0.01, 0.035, 0.075, 0.42)
	player_shadow.z_index = 0
	add_child(player_shadow)
	world_camera = Camera2D.new()
	world_camera.enabled = true
	world_camera.position_smoothing_enabled = true
	world_camera.position_smoothing_speed = 7.0
	add_child(world_camera)

	up_stair_label = _make_stair_label("上层楼梯", 13)
	add_child(up_stair_label)
	down_stair_label = _make_stair_label("下层楼梯")
	add_child(down_stair_label)

	ambient = AudioStreamPlayer.new()
	ambient.volume_db = -24.0
	add_child(ambient)

	gameplay_music = AudioStreamPlayer.new()
	gameplay_music.name = "GameplayMusic"
	gameplay_music.volume_db = -18.0
	var music_stream: AudioStream = load(GAMEPLAY_MUSIC_PATH)
	if music_stream is AudioStreamWAV:
		music_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	gameplay_music.stream = music_stream
	add_child(gameplay_music)
	gameplay_music.play()

	sfx = AudioStreamPlayer.new()
	sfx.volume_db = -5.0
	add_child(sfx)


func _make_stair_label(caption: String, font_size := 19) -> Label:
	var label := Label.new()
	label.text = caption
	label.z_index = 8
	UI.button(label, font_size)
	label.add_theme_color_override("font_color", Color("fff0b3"))
	label.add_theme_color_override("font_shadow_color", Color("0d1725"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _panel_style(color: Color, border: Color, radius := 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var hud_texture: Texture2D = load(UI_ROOT + "gameplay_hud.png")
	# Keep the existing toolbars and right-side indicators, but do not ghost
	# the old central header behind the new task frame.
	for region in [
		Rect2(0, 805, 540, 219),
		Rect2(1040, 805, 496, 219),
		Rect2(1120, 0, 416, 250),
	]:
		var crop := AtlasTexture.new()
		crop.atlas = hud_texture
		crop.region = region
		var fragment := TextureRect.new()
		fragment.position = region.position
		fragment.size = region.size
		fragment.texture = crop
		fragment.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fragment.stretch_mode = TextureRect.STRETCH_SCALE
		fragment.modulate.a = 0.34
		fragment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(fragment)

	# Use the same brass-and-blue-stone frame language as the existing HUD art.
	# Nine-patch stretches its stone center without distorting the lantern/corners.
	var top_frame_art := AtlasTexture.new()
	top_frame_art.atlas = load("res://assets/ui/Common/common_ui_atlas_v2.png")
	top_frame_art.region = Rect2(15, 312, 365, 126)
	var top_panel := NinePatchRect.new()
	top_panel.name = "TaskStatusFrame"
	top_panel.texture = top_frame_art
	top_panel.position = Vector2(18, 14)
	top_panel.size = Vector2(610, 124)
	top_panel.patch_margin_left = 70
	top_panel.patch_margin_right = 42
	top_panel.patch_margin_top = 24
	top_panel.patch_margin_bottom = 27
	top_panel.modulate.a = 0.94
	top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(top_panel)

	var top_inset := MarginContainer.new()
	top_inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_inset.add_theme_constant_override("margin_left", 90)
	top_inset.add_theme_constant_override("margin_right", 34)
	top_inset.add_theme_constant_override("margin_top", 21)
	top_inset.add_theme_constant_override("margin_bottom", 16)
	top_panel.add_child(top_inset)

	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 4)
	top_inset.add_child(top_box)

	title_label = Label.new()
	UI.display(title_label, 29)
	title_label.add_theme_color_override("font_color", Color("ffe4a3"))
	top_box.add_child(title_label)

	task_label = Label.new()
	UI.body(task_label, 20)
	task_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	task_label.visible = false
	top_box.add_child(task_label)

	progress_label = Label.new()
	UI.button(progress_label, 17)
	progress_label.add_theme_color_override("font_color", Color("a9d9ff"))
	top_box.add_child(progress_label)

	var medal_strip := HBoxContainer.new()
	medal_strip.position = Vector2(818, 26)
	medal_strip.add_theme_constant_override("separation", 8)
	layer.add_child(medal_strip)
	for i in range(7):
		var medal := TextureRect.new()
		medal.custom_minimum_size = Vector2(84, 84)
		medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		medal_strip.add_child(medal)
		medal_icons.append(medal)

	world_hint_frame = NinePatchRect.new()
	world_hint_frame.name = "ActionHintFrame"
	world_hint_frame.texture = top_frame_art
	world_hint_frame.position = Vector2(418, 912)
	world_hint_frame.size = Vector2(700, 86)
	world_hint_frame.patch_margin_left = 70
	world_hint_frame.patch_margin_right = 42
	world_hint_frame.patch_margin_top = 24
	world_hint_frame.patch_margin_bottom = 27
	world_hint_frame.modulate.a = 0.9
	world_hint_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(world_hint_frame)

	world_hint_content = MarginContainer.new()
	world_hint_content.position = world_hint_frame.position
	world_hint_content.size = world_hint_frame.size
	world_hint_content.add_theme_constant_override("margin_left", 84)
	world_hint_content.add_theme_constant_override("margin_right", 28)
	world_hint_content.add_theme_constant_override("margin_top", 11)
	world_hint_content.add_theme_constant_override("margin_bottom", 11)
	layer.add_child(world_hint_content)

	var bottom_box := HBoxContainer.new()
	bottom_box.add_theme_constant_override("separation", 12)
	world_hint_content.add_child(bottom_box)

	prompt_label = Label.new()
	prompt_label.text = ""
	UI.body(prompt_label, 18)
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_box.add_child(prompt_label)

	repair_button = Button.new()
	repair_button.text = "开始检修  [E]"
	repair_button.custom_minimum_size = Vector2(160, 54)
	repair_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UI.button(repair_button, 18)
	repair_button.add_theme_stylebox_override("normal", _panel_style(Color("1e3546f2"), Color("d6a64e"), 2))
	repair_button.add_theme_stylebox_override("hover", _panel_style(Color("28506afc"), Color("fff0b8"), 2))
	repair_button.add_theme_stylebox_override("pressed", _panel_style(Color("725023ff"), Color("ffe6a2"), 2))
	repair_button.add_theme_stylebox_override("disabled", _panel_style(Color("172530e8"), Color("637687"), 2))
	repair_button.add_theme_color_override("font_color", Color("f9e5b8"))
	repair_button.add_theme_color_override("font_hover_color", Color("ffffff"))
	repair_button.add_theme_color_override("font_disabled_color", Color("a8bac5"))
	repair_button.pressed.connect(_try_interact)
	bottom_box.add_child(repair_button)
	_set_world_hint_visible(false)

	_build_challenge_overlay(layer)
	_build_medal_overlay(layer)
	_build_floor_map_overlay(layer)


func _make_overlay(layer: CanvasLayer) -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.05, 0.09, 0.83)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	layer.add_child(overlay)
	return overlay


func _set_world_hint_visible(enabled: bool) -> void:
	world_hint_frame.visible = enabled
	world_hint_content.visible = enabled


func _make_ui_button(caption: String, parent: Control) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(340, 68)
	UI.button(button, 21)
	button.add_theme_stylebox_override("normal", _panel_style(Color("263950f2"), Color("8eb7d7"), 6))
	button.add_theme_stylebox_override("hover", _panel_style(Color("405a70fc"), Color("ffd27a"), 6))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("765021ff"), Color("fff0b0"), 6))
	parent.add_child(button)
	return button


func _build_challenge_overlay(layer: CanvasLayer) -> void:
	challenge_overlay = _make_overlay(layer)
	challenge_overlay.color = Color(0.02, 0.05, 0.09, 1.0)
	challenge_art_mount = Control.new()
	challenge_overlay.add_child(challenge_art_mount)
	challenge_art = TextureRect.new()
	challenge_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	challenge_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	challenge_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	challenge_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	challenge_art_mount.add_child(challenge_art)
	challenge_art_overlay = REPAIR_ART_OVERLAY.new()
	challenge_art_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	challenge_art_mount.add_child(challenge_art_overlay)
	repair_interaction = REPAIR_INTERACTION.new()
	repair_interaction.visible = false
	challenge_overlay.add_child(repair_interaction)
	repair_interaction.solved.connect(_complete_challenge)
	repair_interaction.mistake.connect(_on_interaction_mistake)
	repair_interaction.step_completed.connect(_on_interaction_step)
	var close_icon := AtlasTexture.new()
	close_icon.atlas = load("res://assets/ui/Common/common_ui_atlas_v2.png")
	close_icon.region = Rect2(800, 438, 76, 76)
	challenge_close_button = TextureButton.new()
	challenge_close_button.texture_normal = close_icon
	challenge_close_button.texture_hover = close_icon
	challenge_close_button.texture_pressed = close_icon
	challenge_close_button.ignore_texture_size = true
	challenge_close_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	challenge_close_button.size = Vector2(70, 70)
	challenge_close_button.tooltip_text = "返回场景（Esc）"
	challenge_close_button.pressed.connect(_close_challenge)
	challenge_overlay.add_child(challenge_close_button)


func _build_medal_overlay(layer: CanvasLayer) -> void:
	medal_overlay = _make_overlay(layer)
	var result_art := TextureRect.new()
	result_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_art.texture = load(UI_ROOT + "System_Screens/chapter_results.png")
	result_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	result_art.modulate = Color(1, 1, 1, 0.82)
	result_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	medal_overlay.add_child(result_art)
	var panel := PanelContainer.new()
	panel.position = Vector2(375, 114)
	panel.size = Vector2(786, 796)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("16273bf3"), Color("ffd57b"), 14))
	medal_overlay.add_child(panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 18)
	panel.add_child(stack)
	award_title = Label.new()
	award_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.display(award_title, 36)
	award_title.add_theme_color_override("font_color", Color("ffe1a0"))
	stack.add_child(award_title)
	award_icon = TextureRect.new()
	award_icon.custom_minimum_size = Vector2(360, 360)
	award_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	award_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stack.add_child(award_icon)
	award_detail = Label.new()
	award_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	award_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	award_detail.custom_minimum_size = Vector2(690, 96)
	UI.story(award_detail, 24)
	stack.add_child(award_detail)
	medal_continue_button = _make_ui_button("进入下一层", stack)
	medal_continue_button.custom_minimum_size = Vector2(500, 68)
	medal_continue_button.pressed.connect(_close_medal)


func _build_floor_map_overlay(layer: CanvasLayer) -> void:
	floor_map_overlay = _make_overlay(layer)
	var map_art := TextureRect.new()
	map_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_art.texture = load(UI_ROOT + "floor_map.png")
	map_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	floor_map_overlay.add_child(map_art)
	floor_map_title = Label.new()
	floor_map_title.position = Vector2(943, 112)
	floor_map_title.size = Vector2(530, 62)
	floor_map_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.display(floor_map_title, 31)
	floor_map_title.add_theme_color_override("font_color", Color("ffe3a0"))
	floor_map_overlay.add_child(floor_map_title)
	floor_map_detail = Label.new()
	floor_map_detail.position = Vector2(952, 470)
	floor_map_detail.size = Vector2(515, 250)
	floor_map_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.story(floor_map_detail, 22)
	floor_map_detail.add_theme_color_override("font_color", Color("e3edf5"))
	floor_map_overlay.add_child(floor_map_detail)
	var close := _make_ui_button("关闭楼层图  [F]", floor_map_overlay)
	close.position = Vector2(1100, 846)
	close.size = Vector2(330, 66)
	close.pressed.connect(toggle_floor_map.bind(false))


func toggle_floor_map(force_open: Variant = null) -> void:
	if working and not floor_map_overlay.visible:
		return
	var should_open := not floor_map_overlay.visible if force_open == null else bool(force_open)
	floor_map_overlay.visible = should_open
	working = should_open
	if should_open:
		floor_map_title.text = "灯塔楼层图 · 第 %d 层" % (floor_index + 1)
		var completed := 0
		for value in medal_levels:
			completed += 1 if int(value) > 0 else 0
		floor_map_detail.text = "%s\n\n当前检修：%d / %d\n已获得徽章：%d / 7\n\n蓝色光环标记当前楼层；完成检修后可由楼梯继续上行。" % [floors[floor_index].title, progress[floor_index], floors[floor_index].tasks.size(), completed]


func _load_floor(index: int, entry: String = "start") -> void:
	floor_index = clampi(index, 0, floors.size() - 1)
	var floor_data: Dictionary = floors[floor_index]
	var repaired: bool = _floor_complete(floor_index)
	_load_floor_layers(repaired)
	if entry == "from_below":
		player.position = _down_stair_point()
	elif entry == "from_above":
		player.position = _up_stair_point()
	else:
		player.position = _down_stair_point()
	player.animation = &"idle_front"
	player.play()
	direction = "front"
	player.flip_h = false
	player.modulate = Color("ffe9d9") if floor_index == 6 else Color("dceeff")
	player_body.position = player.position
	world_camera.position = background_rect.get_center()
	_update_character_depth()
	challenge_overlay.hide()
	medal_overlay.hide()
	floor_map_overlay.hide()
	working = false
	world_idle_seconds = 0.0
	world_has_moved = false
	_set_world_hint_visible(false)
	_update_stair_labels()
	set_ambient(floor_data.ambient)
	_update_hud()
	state_changed.emit(export_state())
	queue_redraw()


func _load_floor_layers(repaired: bool) -> void:
	dragging_object = null
	if is_instance_valid(level_root):
		level_root.free()
	floor_objects.clear()
	foreground_occluders.clear()
	object_base_z.clear()
	object_origins.clear()
	object_images.clear()
	partial_repair_overlay = null
	_load_expanded_floor(repaired)


func _load_expanded_floor(repaired: bool) -> void:
	level_root = Node2D.new()
	level_root.name = "ExpandedFloor%02d" % (floor_index + 1)
	add_child(level_root)
	background = Sprite2D.new()
	background.name = "Base"
	background.centered = false
	# The enlarged painting is authoritative. Legacy cutouts remain only as
	# dismantling references; they are not part of the normal room composition.
	var background_path: String = str(EXPANDED_REPAIRED_ART[floor_index] if repaired else EXPANDED_ART[floor_index])
	background.texture = load(background_path)
	assert(background.texture != null, background_path)
	var canvas_size := _expanded_canvas_size()
	background.scale = canvas_size / Vector2(background.texture.get_size()) * EXPANDED_IMAGE_SCALE
	background.z_index = -20
	level_root.add_child(background)
	if not repaired:
		_add_partial_repair_overlay()
	_add_foreground_occlusion()
	var floor_id := "floor_%02d" % (floor_index + 1)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/levels/layers/manifest.json"))
	assert(parsed is Dictionary)
	var entries: Array = parsed.floors[floor_id].objects
	var placements: Array = spacious_prop_layout.floors[floor_id]
	assert(placements.size() == entries.size(), "Every independent prop needs a spacious-map placement")
	var service_points: Array = spacious_geometry.floors[floor_index].service
	for entry_index in range(entries.size()):
		var entry: Dictionary = entries[entry_index]
		var object_id := str(entry.id)
		var texture_path := _independent_prop_path(floor_id, object_id)
		var source_image := Image.load_from_file(ProjectSettings.globalize_path(texture_path))
		assert(not source_image.is_empty(), texture_path)
		var texture := ImageTexture.create_from_image(source_image)
		var rect: Array = placements[entry_index]
		var target_rect := Rect2(
			Vector2(float(rect[0]), float(rect[1])),
			Vector2(float(rect[2]), float(rect[3]))
		)
		var prop := Sprite2D.new()
		prop.name = "Prop_" + object_id
		prop.texture = texture
		prop.centered = false
		var fit_scale := minf(target_rect.size.x / texture.get_width(), target_rect.size.y / texture.get_height())
		prop.scale = Vector2.ONE * fit_scale
		var drawn_size := texture.get_size() * fit_scale
		prop.position = target_rect.position + (target_rect.size - drawn_size) * 0.5
		prop.z_index = int(entry.z)
		prop.set_meta("selection_rect", Rect2(prop.position, drawn_size))
		prop.set_meta("source_rect", Rect2i(int(rect[0]), int(rect[1]), int(rect[2]), int(rect[3])))
		prop.set_meta("asset_role", str(entry.role))
		prop.set_meta("independent_art", true)
		var prop_center := prop.position + drawn_size * 0.5
		var repair_group := 0
		var nearest_distance := INF
		for service_index in range(service_points.size()):
			var distance := prop_center.distance_squared_to(_vector_from_array(service_points[service_index]))
			if distance < nearest_distance:
				nearest_distance = distance
				repair_group = service_index
		prop.set_meta("repair_group", repair_group)
		level_root.add_child(prop)
		floor_objects.append(prop)
		object_base_z[object_id] = prop.z_index
		object_origins[object_id] = prop.position
		var saved: Dictionary = object_states[floor_index].get(object_id, {})
		if not saved.is_empty():
			prop.position += saved.get("offset", Vector2.ZERO)
		# Repairing a station changes its damage state; it must not remove the
		# station or its neighboring dismantle pieces from the room.
		prop.visible = not bool(saved.get("hidden", false))
	var world_size: Vector2 = canvas_size * EXPANDED_IMAGE_SCALE
	background_rect = Rect2(Vector2.ZERO, world_size)
	world_camera.limit_left = 0
	world_camera.limit_top = 0
	world_camera.limit_right = roundi(world_size.x)
	world_camera.limit_bottom = roundi(world_size.y)
	var overview_zoom := minf(VIEW_SIZE.x / world_size.x, VIEW_SIZE.y / world_size.y)
	world_camera.zoom = Vector2.ONE * overview_zoom
	world_camera.position = world_size * 0.5
	level_root.set_meta("expanded_scene", true)
	level_root.set_meta("art_status", "spacious_painted_map_polygon_footprints_v2")
	level_root.set_meta("independent_equipment_count", floor_objects.size())
	_update_character_depth()


func _add_partial_repair_overlay() -> void:
	partial_repair_overlay = Sprite2D.new()
	partial_repair_overlay.name = "PartialRepair"
	partial_repair_overlay.centered = false
	partial_repair_overlay.texture = load(EXPANDED_REPAIRED_ART[floor_index])
	partial_repair_overlay.scale = _expanded_canvas_size() / Vector2(partial_repair_overlay.texture.get_size()) * EXPANDED_IMAGE_SCALE
	partial_repair_overlay.z_index = -19
	var material := ShaderMaterial.new()
	material.shader = PARTIAL_REPAIR_SHADER
	material.set_shader_parameter("broken_texture", background.texture)
	var regions := PackedVector4Array()
	for region in PARTIAL_REPAIR_REGIONS[floor_index]:
		regions.append(region)
	while regions.size() < 4:
		regions.append(Vector4.ZERO)
	material.set_shader_parameter("repair_regions", regions)
	material.set_shader_parameter("repair_count", floors[floor_index].tasks.size())
	material.set_shader_parameter("completed_stages", float(progress[floor_index]))
	material.set_shader_parameter("reserve_beam_for_final", floor_index >= 4)
	material.set_shader_parameter("floor_number", floor_index + 1)
	material.set_shader_parameter("canvas_size", _expanded_canvas_size())
	partial_repair_overlay.material = material
	level_root.add_child(partial_repair_overlay)


func _expanded_canvas_size() -> Vector2:
	var dimensions: Array = spacious_geometry.image_size
	return Vector2(float(dimensions[0]), float(dimensions[1]))


func _add_foreground_occlusion() -> void:
	# Each patch uses pixels from this exact map, so its artwork cannot drift.
	for vertices in spacious_geometry.floors[floor_index].foreground:
		var outline := _polygon_from_arrays(vertices)
		var occluder := Polygon2D.new()
		occluder.name = "ForegroundOcclusion"
		occluder.polygon = outline
		occluder.uv = outline
		occluder.texture = background.texture
		occluder.z_index = 3
		level_root.add_child(occluder)
		foreground_occluders.append(occluder)


func _independent_prop_path(floor_id: String, object_id: String) -> String:
	var refined := "res://assets/levels/independent_props/%s/v2/%s.png" % [floor_id, object_id]
	if ResourceLoader.exists(refined):
		return refined
	return "res://assets/levels/independent_props/%s/v1/%s.png" % [floor_id, object_id]


func _up_stair_point() -> Vector2:
	var exit_point: Variant = spacious_geometry.floors[floor_index].exit
	return _vector_from_array(exit_point) if exit_point != null else Vector2(-1000, -1000)


func _down_stair_point() -> Vector2:
	return _vector_from_array(spacious_geometry.floors[floor_index].entry)


func _floor_complete(index: int) -> bool:
	return progress[index] >= floors[index].tasks.size()


func _can_ascend() -> bool:
	return floor_index < floors.size() - 1 and _floor_complete(floor_index)


func _can_descend() -> bool:
	return floor_index > 0


func _near_up_stair() -> bool:
	return floor_index < floors.size() - 1 and player.position.distance_to(_up_stair_point()) <= STAIR_DISTANCE


func _near_down_stair() -> bool:
	return _can_descend() and player.position.distance_to(_down_stair_point()) <= STAIR_DISTANCE


func _update_stair_labels() -> void:
	up_stair_label.visible = floor_index < floors.size() - 1
	if up_stair_label.visible:
		up_stair_label.position = _up_stair_point() + Vector2(-125, -145)
		up_stair_label.modulate = Color.WHITE if _can_ascend() else Color(0.82, 0.86, 0.92, 0.82)
		up_stair_label.text = "上层通道" if _can_ascend() else "上层未开放"
	down_stair_label.visible = _can_descend()
	if down_stair_label.visible:
		down_stair_label.position = _down_stair_point() + Vector2(-48, 45)


func _current_spot() -> Vector2:
	var points: Array = spacious_geometry.floors[floor_index].service
	var physical_index := mini(progress[floor_index], points.size() - 1)
	if progress[floor_index] >= floors[floor_index].tasks.size():
		return Vector2(-1000, -1000)
	return _vector_from_array(points[physical_index])


func _walkable(point: Vector2) -> bool:
	var geometry: Dictionary = spacious_geometry.floors[floor_index]
	var outline := _polygon_from_arrays(geometry.walk)
	var foot := PackedVector2Array()
	for offset in spacious_geometry.footprint:
		foot.append(point + _vector_from_array(offset))
	# Test both boots, not only their center.
	for index in range(foot.size()):
		if not Geometry2D.is_point_in_polygon(foot[index], outline):
			return false
		var edge_center := (foot[index] + foot[(index + 1) % foot.size()]) * 0.5
		if not Geometry2D.is_point_in_polygon(edge_center, outline):
			return false
	for vertices in geometry.blocked_polygons:
		if not Geometry2D.intersect_polygons(foot, _polygon_from_arrays(vertices)).is_empty():
			return false
	return true


func _vector_from_array(pair: Variant) -> Vector2:
	assert(pair is Array and pair.size() >= 2)
	return Vector2(float(pair[0]), float(pair[1]))


func _polygon_from_arrays(vertices: Array) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for vertex in vertices:
		polygon.append(_vector_from_array(vertex))
	return polygon


func _process(delta: float) -> void:
	SCENE_ALIGNED_CHARACTER.align_feet(player)
	_update_prop_visuals()
	if not ambient.playing and ambient.stream != null:
		ambient.play()
	if not gameplay_music.playing and gameplay_music.stream != null:
		gameplay_music.play()
	if challenge_overlay.visible:
		challenge_idle_seconds += delta
		if challenge_error_seconds > 0.0:
			challenge_error_seconds -= delta
			if challenge_error_seconds <= 0.0:
				challenge_art_overlay.hide_hint()
		elif challenge_idle_seconds >= 7.0 and challenge_art_overlay.hint_text.is_empty():
			challenge_art_overlay.show_hint(repair_interaction.art_hint())
	if working:
		_set_world_hint_visible(false)
		return
	if dismantle_mode:
		_update_character_depth()
		prompt_label.text = "M退出｜Tab选件｜左拖/X取下｜方向键移｜右键/回车复位｜R全复位"
		repair_button.disabled = true
		repair_button.visible = false
		_set_world_hint_visible(true)
		var selected_id := floor_objects[selected_object_index].name.trim_prefix("Prop_") if not floor_objects.is_empty() else "无"
		task_label.text = "拆件候选：%s  (%d/%d)  %s" % [selected_id, object_states[floor_index].size(), floor_objects.size(), dismantle_message]
		queue_redraw()
		return

	var movement := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		movement.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		movement.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		movement.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		movement.y += 1

	var old_position := player.position
	if movement.length() > 0:
		movement = movement.normalized()
		var motion := movement * PLAYER_SPEED * delta
		var next := player.position + motion
		if _walkable(next):
			_move_player(motion)
		else:
			var horizontal_motion := Vector2(motion.x, 0)
			var vertical_motion := Vector2(0, motion.y)
			var horizontal := player.position + horizontal_motion
			var vertical := player.position + vertical_motion
			if _walkable(horizontal):
				_move_player(horizontal_motion)
			elif _walkable(vertical):
				_move_player(vertical_motion)
	var actual_motion := player.position - old_position
	if actual_motion.length_squared() > 0.01:
		world_idle_seconds = 0.0
		world_has_moved = true
		_set_direction(actual_motion)
		_play_character_animation("walk")
		footstep_timer -= delta
		if footstep_timer <= 0:
			_play_sfx("player/footstep_wet_01.wav" if floor_index < 2 else "player/footstep_stone_01.wav", -12.0)
			footstep_timer = 0.42
	else:
		world_idle_seconds += delta
		_play_character_animation("idle")
		footstep_timer = 0.0
	_update_character_depth()

	var near_repair := player.position.distance_to(_current_spot()) <= INTERACT_DISTANCE
	var near_up := _near_up_stair()
	var near_down := _near_down_stair()
	var action_available := near_repair or near_down or (near_up and _can_ascend())
	repair_button.disabled = not action_available
	repair_button.visible = action_available
	if near_repair:
		prompt_label.text = "找到它了，来检查一下。"
	elif near_up:
		prompt_label.text = "往上一层走吧。" if _can_ascend() else "先修好这一层，楼梯才会开放。"
	elif near_down:
		prompt_label.text = "要回到下一层看看吗？"
	elif _floor_complete(floor_index):
		prompt_label.text = "这一层已经亮起来了，去楼梯口看看吧。"
	else:
		prompt_label.text = "别着急，沿着柔光找找：%s。" % floors[floor_index].tasks[progress[floor_index]]
	repair_button.text = "检修 [E]" if near_repair else "走楼梯 [E]"
	_set_world_hint_visible((action_available and world_has_moved) or (world_idle_seconds >= 7.0 and not challenge_overlay.visible))
	queue_redraw()


func _update_prop_visuals() -> void:
	if floor_transitioning:
		return
	for index in range(floor_objects.size()):
		var prop := floor_objects[index]
		var id := prop.name.trim_prefix("Prop_")
		var moved := object_states[floor_index].has(id) and not bool(object_states[floor_index][id].get("hidden", false))
		prop.modulate.a = (0.8 if moved else 0.38) if dismantle_mode and (moved or index == selected_object_index) else 0.0


func _move_player(motion: Vector2) -> void:
	player_body.position = player.position
	player_body.move_and_collide(motion)
	player.position = player_body.position


func _update_character_depth() -> void:
	if not is_instance_valid(level_root):
		return
	# The sprite frame retains a few transparent pixels below both boots.
	# Keep the contact shadow under the sole, not behind the ankle.
	player_shadow.position = player.position + Vector2(0, 9)
	var foot_y := level_root.to_local(player.position).y
	for prop in floor_objects:
		var id := prop.name.trim_prefix("Prop_")
		var original_z: int = object_base_z[id]
		if original_z < 0:
			continue
		var object_foot_y := prop.position.y + prop.texture.get_height() * prop.scale.y
		prop.z_index = 2 if foot_y < object_foot_y else 0


func _set_direction(movement: Vector2) -> void:
	# The art faces left. Mirror every three-quarter view for rightward travel.
	# Choose from actual displacement, so sliding along an obstacle faces the
	# direction the boots are moving rather than the blocked input direction.
	if absf(movement.x) > absf(movement.y) * 1.2:
		direction = "side"
	else:
		direction = "back" if movement.y < 0.0 else "front"
	if absf(movement.x) > 0.01:
		player.flip_h = movement.x > 0.0


func _play_character_animation(prefix: String) -> void:
	var animation := StringName(prefix + "_" + direction)
	if player.animation != animation:
		player.play(animation)
	SCENE_ALIGNED_CHARACTER.align_feet(player)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F:
			toggle_floor_map()
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_M and not working:
			_set_dismantle_mode(not dismantle_mode)
			return
		if dismantle_mode:
			_handle_dismantle_key(event)
			return
		if event.physical_keycode == KEY_E or event.physical_keycode == KEY_SPACE:
			if not working:
				_try_interact()
	if dismantle_mode and event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
		_handle_object_mouse_button(event)
	if dismantle_mode and event is InputEventMouseMotion and is_instance_valid(dragging_object):
		var local_point := _screen_to_level(event.position)
		if local_point.distance_to(object_drag_start) > 5.0:
			object_drag_moved = true
			dragging_object.position = local_point - object_drag_offset
			_record_object_state(dragging_object, false)
			queue_redraw()


func _input(event: InputEvent) -> void:
	if challenge_overlay.visible:
		if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE):
			_close_challenge()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventKey:
			challenge_idle_seconds = 0.0
			if challenge_error_seconds <= 0.0:
				challenge_art_overlay.hide_hint()
	# A drag may end over a HUD panel, which consumes _unhandled_input.
	if dismantle_mode and is_instance_valid(dragging_object) and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_handle_object_mouse_button(event)


func _set_dismantle_mode(enabled: bool) -> void:
	dismantle_mode = enabled
	dragging_object = null
	dismantle_message = ""
	selected_object_index = clampi(selected_object_index, 0, maxi(0, floor_objects.size() - 1))
	if enabled:
		player.play(&"idle_front")
		_play_sfx("ui/manual_page.wav", -10.0)
	else:
		_update_hud()
		_play_sfx("ui/ui_cancel.wav", -10.0)


func _handle_dismantle_key(event: InputEventKey) -> void:
	var key := event.physical_keycode if event.physical_keycode != 0 else event.keycode
	match key:
		KEY_R:
			_reset_removed_objects()
		KEY_ESCAPE:
			_set_dismantle_mode(false)
		KEY_TAB:
			var step := -1 if event.shift_pressed else 1
			selected_object_index = posmod(selected_object_index + step, floor_objects.size())
			dismantle_message = ""
			_play_sfx("ui/ui_confirm.wav", -16.0)
		KEY_X, KEY_DELETE:
			var selected := floor_objects[selected_object_index]
			selected.visible = false
			_record_object_state(selected, true)
			dismantle_message = "已取下"
			_play_sfx("ui/ui_confirm.wav", -12.0)
		KEY_ENTER, KEY_KP_ENTER:
			_restore_object(floor_objects[selected_object_index])
		KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN:
			var prop := floor_objects[selected_object_index]
			prop.visible = true
			var step := 26.0 if event.shift_pressed else 9.0
			var direction_vector := Vector2.ZERO
			match key:
				KEY_LEFT: direction_vector.x = -1.0
				KEY_RIGHT: direction_vector.x = 1.0
				KEY_UP: direction_vector.y = -1.0
				KEY_DOWN: direction_vector.y = 1.0
			prop.position += direction_vector * step
			_record_object_state(prop, false)
			dismantle_message = "已移动"
	queue_redraw()


func _handle_object_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var restore_prop := _pick_visible_object(event.position)
		if restore_prop == null or not object_states[floor_index].has(restore_prop.name.trim_prefix("Prop_")):
			var removed_prop := _pick_removed_object(event.position)
			if removed_prop != null:
				restore_prop = removed_prop
		if restore_prop != null:
			_restore_object(restore_prop)
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		var prop := _pick_visible_object(event.position)
		if prop == null:
			return
		selected_object_index = floor_objects.find(prop)
		dragging_object = prop
		object_drag_start = _screen_to_level(event.position)
		object_drag_offset = object_drag_start - prop.position
		object_drag_moved = false
	else:
		if not is_instance_valid(dragging_object):
			return
		if not object_drag_moved:
			dragging_object.visible = false
			_record_object_state(dragging_object, true)
			dismantle_message = "已取下：" + dragging_object.name.trim_prefix("Prop_")
		else:
			_record_object_state(dragging_object, false)
			dismantle_message = "已移走：" + dragging_object.name.trim_prefix("Prop_")
		_play_sfx("ui/ui_confirm.wav", -12.0)
		dragging_object = null
		queue_redraw()


func _pick_visible_object(screen_point: Vector2) -> Sprite2D:
	var local_point := _screen_to_level(screen_point)
	var best: Sprite2D = null
	var best_z := -100000
	for prop in floor_objects:
		if not prop.visible or not _texture_hit(prop, local_point, prop.name):
			continue
		if prop.z_index >= best_z:
			best = prop
			best_z = prop.z_index
	return best


func _pick_removed_object(screen_point: Vector2) -> Sprite2D:
	var local_point := _screen_to_level(screen_point)
	var best: Sprite2D = null
	var best_z := -100000
	for prop in floor_objects:
		if not object_states[floor_index].has(prop.name.trim_prefix("Prop_")):
			continue
		var bounds: Rect2 = prop.get_meta("selection_rect")
		if not bounds.has_point(local_point):
			continue
		if prop.z_index >= best_z:
			best = prop
			best_z = prop.z_index
	return best


func _screen_to_level(screen_point: Vector2) -> Vector2:
	return level_root.to_local(get_canvas_transform().affine_inverse() * screen_point)


func _texture_hit(sprite: Sprite2D, point: Vector2, cache_key: String) -> bool:
	var local := sprite.to_local(point)
	var x := floori(local.x)
	var y := floori(local.y)
	if not object_images.has(cache_key):
		object_images[cache_key] = sprite.texture.get_image()
	var source: Image = object_images[cache_key]
	if x < 0 or y < 0 or x >= source.get_width() or y >= source.get_height():
		return false
	return source.get_pixel(x, y).a >= 0.5


func _record_object_state(prop: Sprite2D, hidden: bool) -> void:
	var id := prop.name.trim_prefix("Prop_")
	object_states[floor_index][id] = {
		"hidden": hidden,
		"offset": prop.position - (object_origins[id] as Vector2)
	}


func _restore_object(prop: Sprite2D, audible := true) -> void:
	var id := prop.name.trim_prefix("Prop_")
	prop.position = object_origins[id]
	prop.visible = true
	object_states[floor_index].erase(id)
	dismantle_message = "已复位：" + id
	if audible:
		_play_sfx("ui/ui_cancel.wav", -12.0)
	queue_redraw()


func _reset_removed_objects() -> void:
	for prop in floor_objects:
		_restore_object(prop, false)
	dismantle_message = "本层拆件已全部复位"
	_play_sfx("ui/ui_cancel.wav", -10.0)


func _try_interact() -> void:
	if working:
		return
	# A service station may be close to the stair landing. The active repair
	# takes precedence until it is complete, so E cannot change floors mid-task.
	if player.position.distance_to(_current_spot()) <= INTERACT_DISTANCE:
		_open_challenge()
		return
	if _near_up_stair():
		if _can_ascend():
			_play_sfx("ui/ui_confirm.wav")
			_load_floor(floor_index + 1, "from_below")
		else:
			_play_sfx("ui/ui_error.wav", -9.0)
		return
	if _near_down_stair():
		_play_sfx("ui/ui_confirm.wav")
		_load_floor(floor_index - 1, "from_above")
		return
	_play_sfx("ui/ui_error.wav", -9.0)


func _open_challenge() -> void:
	working = true
	repair_button.disabled = true
	player.play(&"manual_front")
	var challenge: Dictionary = repair_challenges[floor_index][progress[floor_index]]
	var panel_path := "res://assets/ui/Floors/" + str(challenge.panel).replace("/", "/Panels/")
	challenge_art.texture = load(panel_path)
	var native_size := Vector2(challenge_art.texture.get_size())
	var art_scale := minf(930.0 / native_size.x, 800.0 / native_size.y)
	challenge_art_mount.size = native_size * art_scale
	challenge_art_mount.position = (VIEW_SIZE - challenge_art_mount.size) * 0.5
	var painted_bounds := challenge_art.texture.get_image().get_used_rect()
	challenge_close_button.position = challenge_art_mount.position + Vector2(
		float(painted_bounds.position.x + painted_bounds.size.x) * art_scale - 30.0,
		float(painted_bounds.position.y) * art_scale - 36.0
	)
	if floor_index == 6:
		challenge_close_button.position.x -= 120.0
	repair_interaction.configure(floor_index, progress[floor_index])
	challenge_art_overlay.configure(floor_index, progress[floor_index], repair_interaction, native_size, challenge_art.texture)
	challenge_idle_seconds = 0.0
	challenge_error_seconds = 0.0
	challenge_overlay.show()
	_play_sfx("ui/manual_page.wav", -10.0)


func _close_challenge() -> void:
	challenge_overlay.hide()
	challenge_art_overlay.hide_hint()
	working = false
	player.play(&"idle_front")
	_play_sfx("ui/ui_cancel.wav", -9.0)


func _on_interaction_mistake(message: String) -> void:
	if not challenge_overlay.visible:
		return
	mistakes[floor_index] += 1
	player.play(&"failure_front")
	challenge_idle_seconds = 0.0
	challenge_error_seconds = 2.8
	challenge_art_overlay.show_hint(message, true)
	_play_sfx("ui/ui_error.wav", -8.0)


func _on_interaction_step() -> void:
	player.play(&"manual_front")
	challenge_idle_seconds = 0.0
	challenge_error_seconds = 0.0
	challenge_art_overlay.hide_hint()
	_play_sfx("ui/ui_confirm.wav", -20.0, 0.78)


func _complete_challenge() -> void:
	if not challenge_overlay.visible:
		return
	challenge_art_overlay.queue_redraw()
	await get_tree().create_timer(0.42).timeout
	challenge_overlay.hide()
	player.play(&"repair_front")
	var floor_data: Dictionary = floors[floor_index]
	var task_index: int = progress[floor_index]
	_play_sfx(floor_data.sounds[task_index], -9.0, 0.88)
	await get_tree().create_timer(repair_delay_seconds).timeout
	progress[floor_index] += 1
	state_changed.emit(export_state())
	if _floor_complete(floor_index):
		await _complete_floor()
	else:
		if is_instance_valid(partial_repair_overlay):
			var material := partial_repair_overlay.material as ShaderMaterial
			var reveal := create_tween()
			reveal.tween_method(func(value: float) -> void:
				material.set_shader_parameter("completed_stages", value),
				float(task_index), float(progress[floor_index]), minf(0.7, repair_transition_seconds))
			await reveal.finished
		working = false
		player.play(&"idle_front")
		_update_hud()
	queue_redraw()


func _complete_floor() -> void:
	floor_transitioning = true
	working = true
	var repaired_overlay := Sprite2D.new()
	repaired_overlay.name = "RepairTransition"
	repaired_overlay.centered = false
	repaired_overlay.texture = load(EXPANDED_REPAIRED_ART[floor_index])
	repaired_overlay.scale = _expanded_canvas_size() / Vector2(repaired_overlay.texture.get_size()) * EXPANDED_IMAGE_SCALE
	repaired_overlay.z_index = -19
	repaired_overlay.modulate.a = 0.0
	level_root.add_child(repaired_overlay)
	var transition := create_tween().set_parallel(true)
	transition.tween_property(repaired_overlay, "modulate:a", 1.0, repair_transition_seconds)
	for occluder in foreground_occluders:
		transition.tween_property(occluder, "modulate:a", 0.0, repair_transition_seconds)
	for prop in floor_objects:
		if prop.modulate.a > 0.0:
			transition.tween_property(prop, "modulate:a", 0.0, repair_transition_seconds)
	await transition.finished
	_load_floor_layers(true)
	floor_transitioning = false
	medal_levels[floor_index] = 2 if mistakes[floor_index] == 0 else 1
	player.play(&"success_front")
	_play_sfx("floor_07/full_success.wav" if floor_index == 6 else "ui/medal_unlock.wav")
	_update_stair_labels()
	_update_hud()
	_show_medal()
	state_changed.emit(export_state())


func _medal_texture(index: int, level: int) -> Texture2D:
	var state := "locked"
	if level == 1:
		state = "earned"
	elif level >= 2:
		state = "illuminated"
	var path := "res://assets/ui/Medals/Sprites/medal_%s_%s.png" % [MEDAL_IDS[index], state]
	var texture: Texture2D = load(path)
	if level >= 2:
		return texture
	var crop := AtlasTexture.new()
	crop.atlas = texture
	crop.region = Rect2(0, 0, texture.get_width(), 228)
	return crop


func _show_medal() -> void:
	var level: int = medal_levels[floor_index]
	award_icon.texture = _medal_texture(floor_index, level)
	award_title.text = "获得徽章 · " + MEDAL_NAMES[floor_index]
	var result := "完美检修 · 发光徽章" if level == 2 else "修复完成 · 已取得徽章"
	var detail := "本层所有操作均无失误。" if level == 2 else "本层完成修复；共修正 %d 次操作。" % mistakes[floor_index]
	var route := "继续后直接进入下一层，也可以回头查看本层。" if floor_index < floors.size() - 1 else "主灯复明，可以返回各层查看维修成果。"
	award_detail.text = result + "\n" + detail + "\n" + route
	medal_continue_button.text = "进入下一层" if floor_index < floors.size() - 1 else "返回第七层场景"
	medal_overlay.show()


func _close_medal() -> void:
	medal_overlay.hide()
	working = false
	if floor_index < floors.size() - 1:
		_load_floor(floor_index + 1, "from_below")
		return
	player.play(&"idle_front")
	_update_hud()
	if floor_index == floors.size() - 1 and _floor_complete(floor_index):
		game_completed.emit(export_state())


func _reset_floor() -> void:
	progress[floor_index] = 0
	mistakes[floor_index] = 0
	medal_levels[floor_index] = 0
	object_states[floor_index].clear()
	_load_floor(floor_index)
	_play_sfx("ui/ui_cancel.wav", -8.0)
	state_changed.emit(export_state())


func export_state() -> Dictionary:
	return {
		"version": 1,
		"floor_index": floor_index,
		"progress": progress.duplicate(),
		"mistakes": mistakes.duplicate(),
		"medal_levels": medal_levels.duplicate()
	}


func import_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	for key in ["progress", "mistakes", "medal_levels"]:
		var incoming: Variant = state.get(key, [])
		if incoming is Array and incoming.size() == floors.size():
			set(key, incoming.duplicate())
	_load_floor(clampi(int(state.get("floor_index", 0)), 0, floors.size() - 1))


func _update_hud() -> void:
	var floor_data: Dictionary = floors[floor_index]
	var current: int = progress[floor_index]
	var total: int = floor_data.tasks.size()
	title_label.text = floor_data.title
	if current < total:
		task_label.text = "当前任务：" + floor_data.tasks[current]
	else:
		task_label.text = "修复完成：走到楼梯口继续探索"
	progress_label.text = "检修进度  %d / %d　｜　徽章 %s" % [current, total, "发光" if medal_levels[floor_index] == 2 else "已取得" if medal_levels[floor_index] == 1 else "未取得"]
	for i in range(medal_icons.size()):
		medal_icons[i].texture = _medal_texture(i, medal_levels[i])
		medal_icons[i].modulate = Color.WHITE if i == floor_index else Color(0.85, 0.89, 0.94, 0.8)


func set_ambient(path: String) -> void:
	ambient.stop()
	ambient.stream = load(path)
	ambient.play()


func suspend_for_cinematic() -> void:
	ambient.stop()
	gameplay_music.stop()
	sfx.stop()
	process_mode = Node.PROCESS_MODE_DISABLED


func _play_sfx(relative_path: String, volume := -5.0, pitch := 1.0) -> void:
	sfx.stop()
	# All authored effects share a conservative headroom offset. Individual
	# call sites still control their relative balance without touching sources.
	sfx.volume_db = volume - 6.0
	sfx.pitch_scale = pitch
	sfx.stream = load("res://assets/audio/sfx/" + relative_path)
	sfx.play()


func _draw() -> void:
	if floors.is_empty():
		return
	var floor_data: Dictionary = floors[floor_index]
	var current: int = progress[floor_index]
	var pulse := 1.0 + 0.12 * sin(Time.get_ticks_msec() / 180.0)
	if current < floor_data.tasks.size():
		var spot := _current_spot()
		var bob := sin(Time.get_ticks_msec() / 270.0) * 3.0
		var cursor := spot + Vector2(0, -22.0 + bob)
		var shape := PackedVector2Array([
			cursor + Vector2(-8, -10), cursor + Vector2(0, -5),
			cursor + Vector2(8, -10), cursor + Vector2(5, 2),
			cursor + Vector2(0, 11), cursor + Vector2(-5, 2)
		])
		var shadow := PackedVector2Array()
		for vertex in shape:
			shadow.append(vertex + Vector2(1, 2))
		draw_colored_polygon(shadow, Color(0.04, 0.08, 0.10, 0.75))
		draw_colored_polygon(shape, Color("f5cc79"))
		var outline := PackedVector2Array(shape)
		outline.append(shape[0])
		draw_polyline(outline, Color("fff0bd"), 1.4, true)
	if _can_ascend():
		_draw_stair_marker(_up_stair_point(), true, true, pulse)
	if _can_descend():
		_draw_stair_marker(_down_stair_point(), true, false, pulse)


func _draw_stair_marker(at: Vector2, active: bool, upward: bool, pulse: float) -> void:
	var ink := Color("ffd570") if active else Color(0.65, 0.72, 0.82, 0.58)
	draw_circle(at, 33.0 * pulse, Color(ink.r, ink.g, ink.b, 0.15))
	draw_arc(at, 33.0 * pulse, 0, TAU, 40, ink, 3.0)
	var tip := -16.0 if upward else 16.0
	var triangle := PackedVector2Array([
		at + Vector2(0, tip),
		at + Vector2(-13, -tip * 0.2),
		at + Vector2(13, -tip * 0.2)
	])
	draw_colored_polygon(triangle, ink)
