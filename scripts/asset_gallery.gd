extends Control

const GOLD := Color("#e3ad55")
const GOLD_BRIGHT := Color("#ffd486")
const INK := Color("#07131d")
const PANEL := Color("#102332")
const PANEL_LIGHT := Color("#183647")
const TEXT := Color("#e8f0f2")
const MUTED := Color("#91a9b2")

const CATEGORIES := [
	{"name": "全局界面", "path": "res://assets/ui/Global", "extensions": ["png", "jpg", "jpeg"], "kind": "image"},
	{"name": "七层检修面板", "path": "res://assets/ui/Floors", "extensions": ["png", "jpg", "jpeg"], "kind": "image"},
	{"name": "按钮状态", "path": "res://assets/ui/Common/Buttons", "extensions": ["png"], "kind": "image"},
	{"name": "图标集", "path": "res://assets/ui/Icons/Sprites", "extensions": ["png"], "kind": "image"},
	{"name": "七层奖章", "path": "res://assets/ui/Medals/Sprites", "extensions": ["png"], "kind": "image"},
	{"name": "手册与弹窗", "path": "res://assets/ui/Manual_Popups", "extensions": ["png", "jpg", "jpeg"], "kind": "image"},
	{"name": "对话立绘", "path": "res://assets/ui/Dialogue", "extensions": ["png", "jpg", "jpeg"], "kind": "image"},
	{"name": "关卡场景", "path": "res://assets/ui/Scenes", "extensions": ["png", "jpg", "jpeg"], "kind": "image"},
	{"name": "人物动画", "path": "res://assets/ui/Characters/MainCharacter/Animations", "extensions": ["png"], "kind": "image"},
	{"name": "开篇分镜", "path": "res://assets/cinematic/opening_frames", "extensions": ["png", "jpg", "jpeg"], "kind": "image"},
	{"name": "推门关键帧", "path": "res://assets/cinematic/door_keyframes", "extensions": ["png", "jpg", "jpeg"], "kind": "image"},
	{"name": "音乐", "path": "res://assets/audio", "extensions": ["wav", "ogg", "mp3"], "kind": "audio"},
]

var category_buttons: Array[Button] = []
var current_files: Array[String] = []
var current_category := 0
var current_index := 0

var preview: TextureRect
var empty_label: Label
var title_label: Label
var count_label: Label
var path_label: Label
var detail_label: Label
var index_label: Label
var play_button: Button
var audio_player: AudioStreamPlayer


func _ready() -> void:
	_build_interface()
	_select_category(0)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.keycode in [KEY_RIGHT, KEY_D]:
		_step(1)
	elif event.keycode in [KEY_LEFT, KEY_A]:
		_step(-1)
	elif event.keycode == KEY_SPACE and CATEGORIES[current_category]["kind"] == "audio":
		_toggle_audio()


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = INK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var glow := ColorRect.new()
	glow.color = Color(0.06, 0.16, 0.22, 0.72)
	glow.position = Vector2(0, 0)
	glow.size = Vector2(1536, 230)
	background.add_child(glow)

	var page_margin := MarginContainer.new()
	page_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_margin.add_theme_constant_override("margin_left", 42)
	page_margin.add_theme_constant_override("margin_top", 28)
	page_margin.add_theme_constant_override("margin_right", 42)
	page_margin.add_theme_constant_override("margin_bottom", 30)
	add_child(page_margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 22)
	page_margin.add_child(page)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 78
	page.add_child(header)

	var heading_box := VBoxContainer.new()
	heading_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading_box)

	var eyebrow := _label("GODOT ASSET LIBRARY  /  遗迹光路", 18, GOLD)
	heading_box.add_child(eyebrow)
	title_label = _label("素材导入总览", 34, TEXT)
	heading_box.add_child(title_label)

	count_label = _label("", 18, MUTED)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.custom_minimum_size.x = 260
	header.add_child(count_label)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 22)
	page.add_child(body)

	var sidebar_panel := PanelContainer.new()
	sidebar_panel.custom_minimum_size.x = 285
	sidebar_panel.add_theme_stylebox_override("panel", _panel_style(PANEL, Color("#244657"), 18))
	body.add_child(sidebar_panel)

	var sidebar_margin := MarginContainer.new()
	sidebar_margin.add_theme_constant_override("margin_left", 16)
	sidebar_margin.add_theme_constant_override("margin_top", 18)
	sidebar_margin.add_theme_constant_override("margin_right", 16)
	sidebar_margin.add_theme_constant_override("margin_bottom", 18)
	sidebar_panel.add_child(sidebar_margin)

	var category_list := VBoxContainer.new()
	category_list.add_theme_constant_override("separation", 8)
	sidebar_margin.add_child(category_list)

	category_list.add_child(_label("素材分类", 19, GOLD_BRIGHT))
	var separator := HSeparator.new()
	separator.modulate = Color(1, 1, 1, 0.14)
	category_list.add_child(separator)

	for i in range(CATEGORIES.size()):
		var button := Button.new()
		button.text = CATEGORIES[i]["name"]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.custom_minimum_size.y = 43
		button.add_theme_font_size_override("font_size", 17)
		button.add_theme_color_override("font_color", TEXT)
		button.add_theme_color_override("font_hover_color", GOLD_BRIGHT)
		button.add_theme_color_override("font_pressed_color", INK)
		button.add_theme_stylebox_override("normal", _button_style(Color("#122a39"), Color("#26495a")))
		button.add_theme_stylebox_override("hover", _button_style(Color("#1b3d4d"), GOLD))
		button.add_theme_stylebox_override("pressed", _button_style(GOLD, GOLD_BRIGHT))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.pressed.connect(_select_category.bind(i))
		category_list.add_child(button)
		category_buttons.append(button)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 14)
	body.add_child(right)

	var preview_panel := PanelContainer.new()
	preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_panel.add_theme_stylebox_override("panel", _panel_style(Color("#091822"), Color("#31566a"), 18))
	right.add_child(preview_panel)

	var preview_margin := MarginContainer.new()
	preview_margin.add_theme_constant_override("margin_left", 20)
	preview_margin.add_theme_constant_override("margin_top", 20)
	preview_margin.add_theme_constant_override("margin_right", 20)
	preview_margin.add_theme_constant_override("margin_bottom", 20)
	preview_panel.add_child(preview_margin)

	var preview_stack := Control.new()
	preview_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_margin.add_child(preview_stack)

	preview = TextureRect.new()
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	preview_stack.add_child(preview)

	empty_label = _label("该分类没有可预览的资源", 22, MUTED)
	empty_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_stack.add_child(empty_label)

	var metadata_panel := PanelContainer.new()
	metadata_panel.custom_minimum_size.y = 116
	metadata_panel.add_theme_stylebox_override("panel", _panel_style(PANEL_LIGHT, Color("#31566a"), 14))
	right.add_child(metadata_panel)

	var metadata_margin := MarginContainer.new()
	metadata_margin.add_theme_constant_override("margin_left", 20)
	metadata_margin.add_theme_constant_override("margin_top", 14)
	metadata_margin.add_theme_constant_override("margin_right", 20)
	metadata_margin.add_theme_constant_override("margin_bottom", 14)
	metadata_panel.add_child(metadata_margin)

	var metadata := VBoxContainer.new()
	metadata.add_theme_constant_override("separation", 5)
	metadata_margin.add_child(metadata)

	path_label = _label("", 18, TEXT)
	path_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	metadata.add_child(path_label)
	detail_label = _label("", 15, MUTED)
	metadata.add_child(detail_label)

	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 14)
	metadata.add_child(controls)

	var previous := _control_button("◀  上一个")
	previous.pressed.connect(_step.bind(-1))
	controls.add_child(previous)

	index_label = _label("0 / 0", 17, GOLD_BRIGHT)
	index_label.custom_minimum_size.x = 125
	index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_child(index_label)

	var next := _control_button("下一个  ▶")
	next.pressed.connect(_step.bind(1))
	controls.add_child(next)

	play_button = _control_button("播放音乐")
	play_button.pressed.connect(_toggle_audio)
	play_button.visible = false
	controls.add_child(play_button)

	var hint := _label("方向键 / A、D 浏览　　空格播放或暂停音乐", 14, Color("#6f8994"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(hint)

	audio_player = AudioStreamPlayer.new()
	audio_player.finished.connect(_audio_finished)
	add_child(audio_player)


func _select_category(index: int) -> void:
	current_category = clampi(index, 0, CATEGORIES.size() - 1)
	current_index = 0
	audio_player.stop()
	play_button.text = "播放音乐"

	for i in range(category_buttons.size()):
		category_buttons[i].button_pressed = i == current_category

	var category: Dictionary = CATEGORIES[current_category]
	current_files = _collect_files(category["path"], category["extensions"])
	current_files.sort()
	title_label.text = category["name"]
	count_label.text = "%d 项资源已导入" % current_files.size()
	play_button.visible = category["kind"] == "audio"
	_show_current()


func _collect_files(directory_path: String, extensions: Array) -> Array[String]:
	var result: Array[String] = []
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return result

	directory.list_dir_begin()
	var item_name := directory.get_next()
	while item_name != "":
		if not item_name.begins_with("."):
			var item_path := directory_path.path_join(item_name)
			if directory.current_is_dir():
				result.append_array(_collect_files(item_path, extensions))
			elif item_name.get_extension().to_lower() in extensions:
				result.append(item_path)
		item_name = directory.get_next()
	directory.list_dir_end()
	return result


func _step(direction: int) -> void:
	if current_files.is_empty():
		return
	audio_player.stop()
	play_button.text = "播放音乐"
	current_index = wrapi(current_index + direction, 0, current_files.size())
	_show_current()


func _show_current() -> void:
	if current_files.is_empty():
		preview.texture = null
		empty_label.visible = true
		path_label.text = "未找到资源"
		detail_label.text = "请检查对应 assets 目录。"
		index_label.text = "0 / 0"
		return

	empty_label.visible = false
	var path := current_files[current_index]
	path_label.text = path.trim_prefix("res://")
	index_label.text = "%d / %d" % [current_index + 1, current_files.size()]

	if CATEGORIES[current_category]["kind"] == "audio":
		preview.texture = load("res://assets/ui/Icons/Sprites/icon_lighthouse.png")
		detail_label.text = "音频资源 · 按空格或“播放音乐”试听"
	else:
		var texture := load(path) as Texture2D
		preview.texture = texture
		if texture:
			detail_label.text = "图像资源 · %d × %d px" % [texture.get_width(), texture.get_height()]
		else:
			detail_label.text = "资源载入失败"


func _toggle_audio() -> void:
	if current_files.is_empty() or CATEGORIES[current_category]["kind"] != "audio":
		return
	if audio_player.playing:
		audio_player.stop()
		play_button.text = "播放音乐"
		return
	var stream := load(current_files[current_index]) as AudioStream
	if stream:
		audio_player.stream = stream
		audio_player.play()
		play_button.text = "暂停音乐"


func _audio_finished() -> void:
	play_button.text = "播放音乐"


func _label(label_text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _control_button(button_text: String) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(150, 38)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", GOLD_BRIGHT)
	button.add_theme_stylebox_override("normal", _button_style(Color("#102837"), Color("#31566a")))
	button.add_theme_stylebox_override("hover", _button_style(Color("#1d4050"), GOLD))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#0b1b25"), GOLD_BRIGHT))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _panel_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := _panel_style(fill, border, 8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

