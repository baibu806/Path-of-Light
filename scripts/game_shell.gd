extends Node

const GAME_SCENE := preload("res://scenes/lighthouse_game.tscn")
const UI := preload("res://scripts/ui_typography.gd")
const SAVE_PATH := "user://savegame.json"
const UI_ROOT := "res://assets/ui/Global/"
const SYSTEM_UI := UI_ROOT + "System_Screens/"
const OPENING_VIDEO_PATH := "res://assets/cinematic/video/opening.ogv"
const ENDING_VIDEO_PATH := "res://assets/cinematic/video/ending.ogv"
const ENDING_STILL_PATH := "res://assets/cinematic/video/ending_final.png"
const OPENING_MUSIC_PATH := "res://assets/audio/cinematic/opening_celtic_storm_v1.mp3"
const ENDING_MUSIC_PATH := "res://assets/audio/cinematic/ending_celtic_dawn_v1.mp3"
const DEFAULT_MASTER_VOLUME_DB := -10.0
const MAX_MASTER_VOLUME_DB := -6.0

var game: Node2D
var menu_layer: CanvasLayer
var menu_root: Control
var continue_button: Button
var opening_root: Control
var opening_video: VideoStreamPlayer
var opening_music: AudioStreamPlayer
var opening_transitioning := false
var pause_root: Control
var settings_root: Control
var save_root: Control
var save_status: Label
var ending_root: Control
var ending_video: VideoStreamPlayer
var ending_music: AudioStreamPlayer
var ending_still: TextureRect
var ending_return_button: Button
var ending_complete := false
var transition_fade: ColorRect
var volume_slider: HSlider


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_menu()
	_build_opening()
	_build_pause()
	_build_settings()
	_build_save_slots()
	_build_ending()
	_build_transition_fade()
	_show_menu()
	for argument in OS.get_cmdline_user_args():
		if argument == "--capture-shell=menu":
			_capture_shell.call_deferred("title_menu.png")
		elif argument == "--capture-shell=pause":
			_start_game({})
			await get_tree().process_frame
			_pause_game()
			_capture_shell.call_deferred("pause_settings.png")
		elif argument == "--capture-shell=ending":
			menu_root.visible = false
			ending_root.visible = true
			_finish_ending_video()
			_capture_shell.call_deferred("ending_screen.png")
		elif argument == "--capture-shell=settings":
			menu_root.visible = false
			settings_root.visible = true
			_capture_shell.call_deferred("settings_screen.png")
		elif argument == "--capture-shell=save":
			menu_root.visible = false
			save_root.visible = true
			_refresh_save_slots()
			_capture_shell.call_deferred("save_slots_screen.png")


func _panel_style(fill: Color, border: Color, radius := 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style


func _button(text: String, parent: Control) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(360, 66)
	UI.button(button, 23)
	button.add_theme_stylebox_override("normal", _panel_style(Color("172a40e8"), Color("87b6d8"), 7))
	button.add_theme_stylebox_override("hover", _panel_style(Color("8b5a22f2"), Color("ffe19a"), 7))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("bd762aff"), Color("fff3c4"), 7))
	parent.add_child(button)
	return button


func _art_button(text: String, parent: Control, position: Vector2, size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = size
	button.flat = true
	UI.button(button, 27)
	button.add_theme_color_override("font_color", Color("f8e9c0"))
	button.add_theme_color_override("font_hover_color", Color("fff3a8"))
	button.add_theme_color_override("font_pressed_color", Color("7ee8ff"))
	button.add_theme_stylebox_override("hover", _panel_style(Color("5d40165f"), Color("72dcff"), 7))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("173d55a8"), Color("d6f8ff"), 7))
	parent.add_child(button)
	return button


func _full_overlay() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_layer.add_child(root)
	return root


func _backdrop(root: Control, path: String, tint := Color.WHITE) -> TextureRect:
	var image := TextureRect.new()
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.texture = load(path)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.modulate = tint
	root.add_child(image)
	return image


func _cinematic_video(root: Control, path: String) -> VideoStreamPlayer:
	var matte := ColorRect.new()
	matte.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	matte.color = Color.BLACK
	root.add_child(matte)
	var player := VideoStreamPlayer.new()
	player.position = Vector2(0, 80)
	player.size = Vector2(1536, 864)
	player.expand = true
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player.stream = load(path)
	# Keep any embedded production audio behind the dedicated score.
	player.volume_db = -14.0
	root.add_child(player)
	return player


func _cinematic_music(root: Control, path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	player.volume_db = -8.0
	root.add_child(player)
	return player


func _build_transition_fade() -> void:
	transition_fade = ColorRect.new()
	transition_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_fade.color = Color(0, 0, 0, 0)
	transition_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_fade.visible = false
	menu_layer.add_child(transition_fade)


func _build_menu() -> void:
	menu_layer = CanvasLayer.new()
	menu_layer.layer = 100
	add_child(menu_layer)
	menu_root = _full_overlay()
	_backdrop(menu_root, UI_ROOT + "main_menu.png")
	var title := Label.new()
	title.text = "遗迹光路"
	title.position = Vector2(470, 128)
	title.size = Vector2(596, 92)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI.display(title, 58)
	title.add_theme_color_override("font_color", Color("ffe4a0"))
	title.add_theme_color_override("font_shadow_color", Color("241304"))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	menu_root.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "海雾归航 · 灯塔检修纪事"
	subtitle.position = Vector2(550, 235)
	subtitle.size = Vector2(436, 44)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.story(subtitle, 22)
	subtitle.add_theme_color_override("font_color", Color("d8ecf7"))
	menu_root.add_child(subtitle)
	var start := _art_button("开始新游戏", menu_root, Vector2(542, 292), Vector2(452, 86))
	start.pressed.connect(_start_opening)
	continue_button = _art_button("继续游戏", menu_root, Vector2(542, 398), Vector2(452, 86))
	continue_button.pressed.connect(_continue_game)
	var saves := _art_button("存档管理", menu_root, Vector2(542, 504), Vector2(452, 86))
	saves.pressed.connect(_show_save_slots)
	var settings := _art_button("设置", menu_root, Vector2(542, 610), Vector2(452, 86))
	settings.pressed.connect(_show_settings)
	var quit := _art_button("退出游戏", menu_root, Vector2(542, 716), Vector2(452, 86))
	quit.pressed.connect(get_tree().quit)
	var hint := Label.new()
	hint.text = "WASD 移动 · E 交互 · F 楼层图 · Esc 暂停"
	hint.position = Vector2(510, 930)
	hint.size = Vector2(516, 40)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.body(hint, 17)
	hint.add_theme_color_override("font_color", Color("b8d5e8"))
	menu_root.add_child(hint)


func _build_opening() -> void:
	opening_root = _full_overlay()
	opening_root.visible = false
	opening_video = _cinematic_video(opening_root, OPENING_VIDEO_PATH)
	opening_video.finished.connect(_finish_opening)
	opening_music = _cinematic_music(opening_root, OPENING_MUSIC_PATH)
	var skip := _art_button("跳过  [Esc]", opening_root, Vector2(1270, 14), Vector2(230, 52))
	skip.pressed.connect(_finish_opening)


func _build_pause() -> void:
	pause_root = _full_overlay()
	pause_root.visible = false
	_backdrop(pause_root, SYSTEM_UI + "pause_menu.png")
	var title := Label.new()
	title.text = "暂停"
	title.position = Vector2(410, 105)
	title.size = Vector2(716, 104)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI.display(title, 42)
	title.add_theme_color_override("font_color", Color("fff0c6"))
	title.add_theme_color_override("font_shadow_color", Color("3a1f08"))
	title.add_theme_constant_override("shadow_offset_y", 2)
	pause_root.add_child(title)
	var resume := _art_button("返回游戏", pause_root, Vector2(406, 254), Vector2(724, 88))
	resume.pressed.connect(_resume)
	var save := _art_button("保存进度", pause_root, Vector2(406, 386), Vector2(724, 88))
	save.pressed.connect(_show_save_slots)
	var settings := _art_button("设置", pause_root, Vector2(406, 518), Vector2(724, 88))
	settings.pressed.connect(_show_settings)
	var map := _art_button("楼层地图", pause_root, Vector2(406, 650), Vector2(724, 88))
	map.pressed.connect(_show_map_from_pause)
	var menu := _art_button("保存并返回标题", pause_root, Vector2(406, 782), Vector2(724, 88))
	menu.pressed.connect(_save_and_menu)


func _build_settings() -> void:
	settings_root = _full_overlay()
	settings_root.visible = false
	_backdrop(settings_root, SYSTEM_UI + "settings_menu.png")
	var title := Label.new()
	title.text = "设置"
	title.position = Vector2(410, 105)
	title.size = Vector2(716, 104)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI.display(title, 42)
	title.add_theme_color_override("font_color", Color("fff0c6"))
	title.add_theme_color_override("font_shadow_color", Color("3a1f08"))
	title.add_theme_constant_override("shadow_offset_y", 2)
	settings_root.add_child(title)
	var volume_label := Label.new()
	volume_label.text = "总音量"
	volume_label.position = Vector2(354, 232)
	volume_label.size = Vector2(180, 60)
	UI.heading(volume_label, 25)
	settings_root.add_child(volume_label)
	volume_slider = HSlider.new()
	volume_slider.position = Vector2(520, 230)
	volume_slider.size = Vector2(530, 64)
	volume_slider.min_value = -45
	volume_slider.max_value = MAX_MASTER_VOLUME_DB
	volume_slider.step = 1
	volume_slider.value = DEFAULT_MASTER_VOLUME_DB
	volume_slider.value_changed.connect(_set_volume)
	settings_root.add_child(volume_slider)
	var note := Label.new()
	note.text = "音乐、环境声与检修音效将同步调整"
	note.position = Vector2(520, 330)
	note.size = Vector2(530, 40)
	UI.body(note, 18)
	note.add_theme_color_override("font_color", Color("b8d5e8"))
	settings_root.add_child(note)
	var back := _art_button("保存设置并返回", settings_root, Vector2(410, 794), Vector2(716, 82))
	back.pressed.connect(_close_subscreen)


func _build_save_slots() -> void:
	save_root = _full_overlay()
	save_root.visible = false
	_backdrop(save_root, SYSTEM_UI + "save_slots.png")
	var title := Label.new()
	title.text = "航路档案"
	title.position = Vector2(410, 66)
	title.size = Vector2(716, 104)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI.display(title, 46)
	title.add_theme_color_override("font_color", Color("3a2616"))
	save_root.add_child(title)
	for index in range(3):
		var slot := Button.new()
		slot.position = Vector2(143 + index * 480, 247)
		slot.size = Vector2(390, 510)
		slot.flat = true
		slot.text = "自动存档" if index == 0 else "空档位"
		UI.heading(slot, 24)
		slot.add_theme_color_override("font_color", Color("f4e6c5"))
		slot.add_theme_stylebox_override("hover", _panel_style(Color("15385166"), Color("63ddff"), 10))
		if index == 0:
			slot.pressed.connect(_save_primary_slot)
		else:
			slot.disabled = true
		save_root.add_child(slot)
	save_status = Label.new()
	save_status.position = Vector2(450, 770)
	save_status.size = Vector2(636, 70)
	save_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI.body(save_status, 20)
	save_root.add_child(save_status)
	var back := _art_button("返回", save_root, Vector2(644, 866), Vector2(248, 70))
	back.pressed.connect(_close_subscreen)


func _refresh_save_slots() -> void:
	if not is_instance_valid(save_status):
		return
	if FileAccess.file_exists(SAVE_PATH):
		var state := _read_save()
		var floor_number := clampi(int(state.get("floor_index", 0)) + 1, 1, 7)
		save_status.text = "已有进度 · 第 %d 层 · 点击第一档覆盖保存" % floor_number
	else:
		save_status.text = "尚无存档 · 开始游戏后可在此保存"


func _save_primary_slot() -> void:
	_save_game()
	_refresh_save_slots()
	save_status.text = "保存完成 · " + save_status.text


func _show_settings() -> void:
	menu_root.visible = false
	pause_root.visible = false
	save_root.visible = false
	settings_root.visible = true


func _show_save_slots() -> void:
	menu_root.visible = false
	pause_root.visible = false
	settings_root.visible = false
	save_root.visible = true
	_refresh_save_slots()


func _close_subscreen() -> void:
	settings_root.visible = false
	save_root.visible = false
	if is_instance_valid(game):
		pause_root.visible = true
	else:
		_show_menu()


func _show_map_from_pause() -> void:
	pause_root.visible = false
	get_tree().paused = false
	if is_instance_valid(game) and game.has_method("toggle_floor_map"):
		game.toggle_floor_map(true)


func _build_ending() -> void:
	ending_root = _full_overlay()
	ending_root.visible = false
	ending_video = _cinematic_video(ending_root, ENDING_VIDEO_PATH)
	ending_video.finished.connect(_finish_ending_video)
	ending_music = _cinematic_music(ending_root, ENDING_MUSIC_PATH)
	ending_still = TextureRect.new()
	ending_still.position = Vector2(0, 80)
	ending_still.size = Vector2(1536, 864)
	ending_still.texture = load(ENDING_STILL_PATH)
	ending_still.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ending_still.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ending_still.visible = false
	ending_root.add_child(ending_still)
	ending_return_button = _art_button("跳过结尾  [Esc]", ending_root, Vector2(1210, 14), Vector2(290, 52))
	ending_return_button.pressed.connect(_skip_or_leave_ending)


func _show_menu() -> void:
	get_tree().paused = false
	if opening_video.is_playing():
		opening_video.stop()
	if ending_video.is_playing():
		ending_video.stop()
	opening_music.stop()
	ending_music.stop()
	menu_root.visible = true
	opening_root.visible = false
	pause_root.visible = false
	settings_root.visible = false
	save_root.visible = false
	ending_root.visible = false
	ending_still.visible = false
	ending_complete = false
	transition_fade.visible = false
	opening_transitioning = false
	continue_button.disabled = not FileAccess.file_exists(SAVE_PATH)


func _start_opening() -> void:
	menu_root.visible = false
	opening_root.visible = true
	opening_transitioning = false
	opening_video.play()
	opening_music.play()


func _finish_opening() -> void:
	if not opening_root.visible or opening_transitioning:
		return
	opening_transitioning = true
	transition_fade.visible = true
	transition_fade.color = Color(0, 0, 0, 0)
	var fade_to_black := create_tween()
	fade_to_black.tween_property(transition_fade, "color:a", 1.0, 0.35)
	await fade_to_black.finished
	opening_video.stop()
	opening_music.stop()
	opening_root.visible = false
	await _start_game({})
	var fade_to_game := create_tween()
	fade_to_game.tween_property(transition_fade, "color:a", 0.0, 0.4)
	await fade_to_game.finished
	transition_fade.visible = false
	opening_transitioning = false


func _continue_game() -> void:
	_start_game(_read_save())


func _start_game(state: Dictionary) -> void:
	if is_instance_valid(game):
		game.queue_free()
	game = GAME_SCENE.instantiate()
	add_child(game)
	move_child(game, 0)
	game.state_changed.connect(_write_save)
	game.game_completed.connect(_show_ending)
	menu_root.visible = false
	await get_tree().process_frame
	if not state.is_empty():
		game.import_state(state)
	else:
		_write_save(game.export_state())


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE):
		return
	if opening_root.visible:
		_finish_opening()
	elif ending_root.visible:
		_skip_or_leave_ending()
	elif settings_root.visible or save_root.visible:
		_close_subscreen()
	elif is_instance_valid(game) and not ending_root.visible:
		if pause_root.visible:
			_resume()
		else:
			_pause_game()


func _pause_game() -> void:
	get_tree().paused = true
	pause_root.visible = true


func _resume() -> void:
	pause_root.visible = false
	get_tree().paused = false
	if not is_instance_valid(game):
		_show_menu()


func _set_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)


func _save_game() -> void:
	if is_instance_valid(game):
		_write_save(game.export_state())


func _save_and_menu() -> void:
	_save_game()
	get_tree().paused = false
	pause_root.visible = false
	if is_instance_valid(game):
		game.queue_free()
	_show_menu()


func _write_save(state: Dictionary) -> void:
	state = state.duplicate(true)
	state["master_volume_db"] = volume_slider.value
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(state, "  "))


func _read_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary:
		var saved_volume := clampf(float(parsed.get("master_volume_db", DEFAULT_MASTER_VOLUME_DB)), -45.0, MAX_MASTER_VOLUME_DB)
		volume_slider.value = saved_volume
		_set_volume(saved_volume)
		return parsed
	return {}


func _show_ending(state: Dictionary) -> void:
	_write_save(state)
	if is_instance_valid(game):
		game.call("suspend_for_cinematic")
	ending_root.visible = true
	ending_complete = false
	ending_still.visible = false
	ending_return_button.text = "跳过结尾  [Esc]"
	ending_return_button.position = Vector2(1210, 14)
	ending_video.play()
	ending_music.play()


func _finish_ending_video() -> void:
	if not ending_root.visible or ending_complete:
		return
	ending_video.stop()
	ending_music.stop()
	ending_still.visible = true
	ending_complete = true
	ending_return_button.text = "返回标题  [Esc]"
	ending_return_button.position = Vector2(1210, 955)


func _skip_or_leave_ending() -> void:
	if not ending_complete:
		_finish_ending_video()
	else:
		_ending_to_menu()


func _ending_to_menu() -> void:
	ending_video.stop()
	ending_music.stop()
	ending_root.visible = false
	if is_instance_valid(game):
		game.queue_free()
	_show_menu()


func _capture_shell(filename: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://docs/" + filename)
	get_tree().quit()
