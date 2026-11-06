extends Control

const UI_FONT := preload("res://assets/fonts/HarmonyOS_Sans_SC_Medium.ttf")
const HINT_FONT := preload("res://assets/fonts/SourceHanSerifSC-SemiBold.otf")
const TOOL_ATLAS := preload("res://assets/ui/interaction_tool_cutouts_v1.png")
const EXTRA_TOOL_ATLAS := preload("res://assets/ui/interaction_tool_cutouts_extra_v1.png")
const FOUNDATION_REPAIRED := preload("res://assets/ui/Floors/Floor01_Foundation/Panels/foundation_inspection_repaired_v1.png")

# Coordinates are in each panel's native pixels. The painted control is the
# hit target; instructions appear only after the player pauses.
const LAYOUTS := [
	[
		{"source": [77, 625], "points": [[160, 210], [555, 270], [150, 445], [345, 375]]},
		{"points": [[160, 250], [190, 470], [275, 470], [540, 475]], "sequence_sources": [[160, 245], [105, 470], [275, 470], [355, 470]], "sequence_targets": [[535, 475], [485, 428], [545, 390], [535, 475]], "sequence_tools": ["石料", "刮刀", "木槌", "砂浆"]},
		{"points": [[500, 255], [510, 425]]}
	],
	[
		{"points": [[625, 315], [430, 325], [245, 325]], "sequence_sources": [[435, 580], [545, 580], [665, 580]], "sequence_targets": [[625, 315], [430, 325], [245, 325]]},
		{"sources": [[245, 235], [245, 345], [245, 450]], "points": [[435, 215], [425, 340], [490, 545]]},
		{"points": [[310, 380], [600, 245]]}
	],
	[
		{"points": [[270, 285], [355, 325], [445, 395]], "sequence_sources": [null, [570, 315], [570, 485]], "sequence_targets": [null, [355, 325], [445, 395]]},
		{"sources": [[205, 240], [365, 555], [165, 555]], "points": [[440, 265], [450, 350], [365, 435]]},
		{"points": [[380, 260], [595, 425]]}
	],
	[
		{"points": [[365, 285], [405, 390], [555, 500]], "sequence_sources": [[265, 440], [265, 440], [265, 440]], "sequence_targets": [[365, 285], [405, 390], [555, 500]]},
		{"sources": [[175, 245], [325, 245], [480, 245]], "points": [[140, 520], [285, 510], [480, 495]]},
		{"points": [[395, 505]], "dial_center": [395, 505], "dial_radius": 120}
	],
	[
		{"source": [110, 600], "points": [[225, 235], [400, 235], [230, 380], [400, 380]]},
		{"points": [[155, 300], [360, 300], [565, 300]], "sequence_sources": [[145, 550], [145, 550], [145, 550]], "sequence_targets": [[155, 300], [360, 300], [565, 300]]},
		{"sources": [[70, 615], [150, 615], [235, 615]], "points": [[195, 300], [360, 300], [525, 300]]}
	],
	[
		{"points": [[365, 410], [360, 480]]},
		{"points": [[280, 585], [600, 585]]},
		{"points": [[100, 375], [600, 385]]}
	],
	[
		{"points": [[285, 210], [435, 210], [585, 210], [285, 360], [435, 360], [585, 360], [435, 55]]},
		{"points": [[110, 385], [185, 385], [300, 385], [405, 385]]},
		{"points": [[325, 250]], "dial_center": [325, 250], "dial_radius": 170},
		{"points": [[415, 310], [575, 285], [185, 260]]}
	]
]

const C_READY := Color("59e5ff")
const C_DONE := Color("9df2b5")
const C_WAIT := Color("edba71")

# Place delayed guidance on artwork that already has an empty inscription plate.
# Other panels keep the guidance just below the equipment so controls stay clear.
const LIGHTHOUSE_HINT_RECTS := [
	Rect2(218, 419, 428, 63),
	Rect2(115, 439, 440, 53),
	Rect2(207, 415, 420, 61),
	Rect2(101, 412, 445, 61)
]

var interaction: Control
var layout: Dictionary = {}
var image_size := Vector2(724, 724)
var held_source := false
var held_sequence := false
var scraping := false
var scrape_time := 0.0
var held_dial := false
var active_parameter := -1
var parameter_start := Vector2.ZERO
var parameter_base := 0.0
var hint_text := ""
var hint_is_error := false
var hint_on_parchment := false
var message_rect_native := Rect2()
var pointer := Vector2.ZERO
var panel_texture: Texture2D
var floor_id := 0
var task_id := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false


func configure(floor_number: int, task_number: int, target_interaction: Control, native_size: Vector2, artwork: Texture2D) -> void:
	layout = LAYOUTS[floor_number][task_number]
	interaction = target_interaction
	image_size = native_size
	panel_texture = artwork
	floor_id = floor_number
	task_id = task_number
	held_source = false
	held_sequence = false
	scraping = false
	scrape_time = 0.0
	held_dial = false
	active_parameter = -1
	hint_text = ""
	hint_on_parchment = floor_number == 6
	if floor_number == 0:
		message_rect_native = Rect2(111, 582, 502, 78)
	elif floor_number == 2:
		message_rect_native = Rect2(105, 611, 510, 65)
	elif floor_number == 6:
		message_rect_native = LIGHTHOUSE_HINT_RECTS[task_number]
	else:
		message_rect_native = Rect2(0, image_size.y + 10.0, image_size.x, 60.0)
	queue_redraw()


func _process(delta: float) -> void:
	if not scraping:
		return
	scrape_time += delta
	queue_redraw()
	if scrape_time >= 0.42:
		scraping = false
		interaction.drop_art_part()


func show_hint(message: String, is_error: bool = false) -> void:
	hint_text = message
	hint_is_error = is_error
	queue_redraw()


func hide_hint() -> void:
	if hint_text.is_empty():
		return
	hint_text = ""
	queue_redraw()


func _scale() -> float:
	return minf(size.x / image_size.x, size.y / image_size.y)


func _panel_point(point: Array) -> Vector2:
	return (size - image_size * _scale()) * 0.5 + Vector2(float(point[0]), float(point[1])) * _scale()


func hotspot(index: int) -> Vector2:
	return _panel_point(layout.points[index])


func source_point(index: int) -> Vector2:
	if layout.has("source"):
		return _panel_point(layout.source)
	return _panel_point(layout.sources[index])


func _draw() -> void:
	if interaction == null or layout.is_empty():
		return
	var kind := str(interaction.config.kind)
	var stage_now: int = interaction.stage
	var points: Array = layout.points
	_draw_physical_state(stage_now)
	if floor_id == 3 and task_id == 1:
		_draw_gear_installation_state(stage_now)
	if floor_id == 4 and task_id == 2:
		_draw_lens_installation_state(stage_now)
	if floor_id == 0 and task_id == 0:
		for repaired_index in range(mini(stage_now, points.size())):
			_draw_repaired_foundation_region(repaired_index)
	if floor_id == 0 and task_id == 1:
		_draw_sequence_material_changes(stage_now)
	for index in range(points.size()):
		var draggable := layout.has("sequence_sources") and layout.sequence_sources[index] != null
		var place := _panel_point(layout.sequence_sources[index]) if draggable else hotspot(index)
		var done := index < stage_now and kind in ["sequence", "drag"]
		var ready := index == stage_now or kind in ["align", "dial"]
		if done:
			continue
		if not done and not ready:
			continue
		var color := C_DONE if done else C_READY
		var radius := 31.0 if ready else 20.0
		draw_circle(place, radius + 5.0, Color(0.02, 0.08, 0.12, 0.62))
		draw_circle(place, radius, Color(color.r, color.g, color.b, 0.23 if ready else 0.13))
		draw_arc(place, radius, 0, TAU, 40, Color.WHITE, 5.0)
		draw_arc(place, radius - 3.0, 0, TAU, 40, color, 3.0)
		if kind in ["sequence", "drag"]:
			draw_string(UI_FONT, place + Vector2(-7, 7), str(index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
		elif kind == "align":
			_draw_align_marker(place, index)
			draw_string(UI_FONT, place + Vector2(-6, 7), str(index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
		if draggable and layout.has("sequence_targets") and ready:
			var destination := _panel_point(layout.sequence_targets[index])
			draw_arc(destination, 40 * _scale(), 0, TAU, 32, C_READY, 4)
	if kind == "drag" and stage_now < points.size():
		var source := source_point(stage_now)
		draw_circle(source, 34, Color(0.02, 0.08, 0.12, 0.68))
		if floor_id == 0 and task_id == 0:
			_draw_scraper(source)
		draw_arc(source, 31, 0, TAU, 36, Color.WHITE, 5)
		draw_arc(source, 27, 0, TAU, 36, C_WAIT, 3)
		draw_circle(source, 6, C_WAIT)
		if held_source:
			_draw_dragged_art(stage_now, pointer)
		if scraping:
			_draw_scrape_action(hotspot(stage_now), scrape_time / 0.42)
	if held_sequence and stage_now < layout.sequence_sources.size():
		_draw_sequence_tool(stage_now, pointer)
	# Completion is communicated by the repaired apparatus, never by a checkmark.
	if kind == "dial" and layout.has("dial_center"):
		var center := _panel_point(layout.dial_center)
		var radians := deg_to_rad(interaction.angle - 90.0)
		var end := center + Vector2(cos(radians), sin(radians)) * 44.0
		draw_line(center, end, C_READY, 4)
		draw_circle(end, 7, C_READY)
	if not hint_text.is_empty():
		_draw_hint()


func _native_rect_around(point: Array, extent := 42.0) -> Rect2:
	var center := Vector2(float(point[0]), float(point[1]))
	return Rect2(center - Vector2.ONE * extent, Vector2.ONE * extent * 2.0)


func _draw_art_crop(index: int, at: Vector2, alpha := 1.0) -> void:
	if panel_texture == null:
		return
	var part := str(interaction.config.parts[index])
	if _draw_tool_cutout(part, at, alpha):
		return
	var source_array: Array = layout.source if layout.has("source") else layout.sources[index]
	var native_rect := _native_rect_around(source_array)
	var side := native_rect.size.x * _scale()
	var destination := Rect2(at - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	draw_texture_rect_region(panel_texture, destination, native_rect, Color(1, 1, 1, alpha))


func _draw_scraper(at: Vector2) -> void:
	_draw_tool_cutout("刮刀", at)


func _tool_atlas_location(tool: String) -> Vector3i:
	match tool:
		"刮刀", "抹刀": return Vector3i(0, 0, 0)
		"软布": return Vector3i(0, 1, 0)
		"刷子": return Vector3i(0, 2, 0)
		"放大镜": return Vector3i(0, 3, 0)
		"直管": return Vector3i(0, 0, 1)
		"弯管": return Vector3i(0, 1, 1)
		"三通": return Vector3i(0, 2, 1)
		"保险丝": return Vector3i(0, 3, 1)
		"小齿轮": return Vector3i(0, 0, 2)
		"中齿轮": return Vector3i(0, 1, 2)
		"大齿轮": return Vector3i(0, 2, 2)
		"镜片": return Vector3i(0, 3, 2)
		"石料": return Vector3i(1, 0, 0)
		"木槌": return Vector3i(1, 1, 0)
		"砂浆": return Vector3i(1, 2, 0)
		"扳手": return Vector3i(1, 3, 0)
		"蓝色导线": return Vector3i(1, 0, 1)
		"红色导线": return Vector3i(1, 1, 1)
		"反射镜", "第一镜", "第二镜", "第三镜": return Vector3i(1, 2, 1)
		"第一镜片", "第二镜片", "第三镜片": return Vector3i(0, 3, 2)
	return Vector3i(-1, -1, -1)


func _draw_tool_cutout(tool: String, at: Vector2, alpha := 1.0, native_side := 91.0) -> bool:
	var place := _tool_atlas_location(tool)
	if place.x < 0:
		return false
	var atlas: Texture2D = TOOL_ATLAS if place.x == 0 else EXTRA_TOOL_ATLAS
	var rows := 3 if place.x == 0 else 2
	var cell := Vector2(atlas.get_width() / 4.0, atlas.get_height() / float(rows))
	var source := Rect2(Vector2(place.y, place.z) * cell, cell)
	var side := native_side * _scale()
	var destination := Rect2(at - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	draw_texture_rect_region(atlas, Rect2(destination.position + Vector2(2, 3), destination.size), source, Color(0.02, 0.03, 0.04, 0.38 * alpha))
	draw_texture_rect_region(atlas, destination, source, Color(1, 1, 1, alpha))
	return true


func _native_box(center: Vector2, dimensions: Vector2, color: Color) -> void:
	var position := _panel_point([center.x, center.y])
	draw_rect(Rect2(position - dimensions * _scale() * 0.5, dimensions * _scale()), color, true)


func _draw_native_beam(start: Vector2, finish: Vector2, strength := 1.0) -> void:
	var a := _panel_point([start.x, start.y])
	var b := _panel_point([finish.x, finish.y])
	draw_line(a, b, Color(1.0, 0.67, 0.23, 0.20 * strength), 18.0 * _scale())
	draw_line(a, b, Color(1.0, 0.91, 0.62, 0.85 * strength), 3.0 * _scale())


func _draw_physical_state(completed: int) -> void:
	# The source paintings are flat. Cover only the parts that are not yet
	# functional, then let the original painted hardware reappear step by step.
	match floor_id:
		1:
			if task_id == 0:
				var leaks := [Vector2(625, 315), Vector2(430, 325), Vector2(245, 325)]
				for index in range(mini(completed, leaks.size())):
					_native_box(leaks[index], Vector2(57, 26), Color("253c48"))
			elif task_id == 1:
				var pipe_gaps := [Vector2(435, 215), Vector2(425, 340), Vector2(490, 545)]
				var pipe_sizes := [Vector2(111, 56), Vector2(100, 92), Vector2(113, 62)]
				for index in range(completed, 3):
					_native_box(pipe_gaps[index], pipe_sizes[index], Color("102231"))
				for index in range(mini(completed, 3)):
					_native_box(Vector2(245, 235 + index * 110), Vector2(108, 90), Color("142a3c"))
			elif task_id == 2:
				_draw_gauge_state(Vector2(600, 245), float(interaction.values[1]), 68.0)
		2:
			if task_id == 0:
				for index in range(1, mini(completed + 1, 3)):
					_native_box(Vector2(layout.points[index][0], layout.points[index][1]), Vector2(44, 38), Color("293947"))
			elif task_id == 1:
				var electrical_parts := [Vector2(440, 265), Vector2(450, 350), Vector2(365, 435)]
				for index in range(completed, 3):
					_native_box(electrical_parts[index], Vector2(62, 88), Color("112638"))
				for index in range(mini(completed, 3)):
					var source := source_point(index)
					draw_circle(source, 36.0 * _scale(), Color("102333"))
			elif task_id == 2:
				_draw_gauge_state(Vector2(380, 260), float(interaction.values[0]), 72.0)
		3:
			if task_id == 0:
				for index in range(mini(completed, 3)):
					var place := hotspot(index)
					draw_circle(place, 30.0 * _scale(), Color("36494f"))
			elif task_id == 2:
				_draw_gauge_state(Vector2(395, 505), interaction.angle / 3.6, 75.0)
		4:
			if task_id == 0:
				for index in range(mini(completed, 4)):
					var place := hotspot(index)
					draw_circle(place, 48.0 * _scale(), Color(0.48, 0.70, 0.80, 0.75))
					draw_arc(place, 40.0 * _scale(), -2.2, 0.6, 24, Color("e3f8ff"), 3.0 * _scale())
			elif task_id == 1:
				for index in range(mini(completed, 3)):
					var place := hotspot(index)
					draw_line(place + Vector2(-21, 19) * _scale(), place + Vector2(18, -19) * _scale(), Color("9ed8eb"), 3.0 * _scale())
		5:
			_draw_focus_state(completed)
		6:
			_draw_lighthouse_state(completed)


func _draw_gauge_state(center_native: Vector2, value: float, target: float) -> void:
	var center := _panel_point([center_native.x, center_native.y])
	var amount := clampf(value / 100.0, 0.0, 1.0)
	var sweep := lerpf(PI * 0.85, PI * 2.15, amount)
	var tip := center + Vector2(cos(sweep), sin(sweep)) * 39.0 * _scale()
	draw_line(center, tip, Color("edbb6a") if absf(value - target) > 8.0 else Color("a2e7ad"), 4.0 * _scale())
	draw_circle(center, 5.0 * _scale(), Color("dcaa60"))


func _draw_focus_state(_completed: int) -> void:
	if task_id == 0:
		_native_box(Vector2(365, 267), Vector2(380, 18), Color("182939"))
		var horizontal := float(interaction.values[0])
		var vertical := float(interaction.values[1])
		_draw_native_beam(Vector2(150, 267), Vector2(545, 267 + (67.0 - vertical) * 0.58), 0.35 + horizontal / 150.0)
	elif task_id == 1:
		_native_box(Vector2(365, 290), Vector2(540, 18), Color("182939"))
		var deviation := (58.0 - float(interaction.values[0])) * 0.7
		_draw_native_beam(Vector2(105, 290), Vector2(355, 290 + deviation), 0.7)
		_draw_native_beam(Vector2(355, 290 + deviation), Vector2(625, 290 + deviation * 0.2), 0.45 + float(interaction.values[1]) / 180.0)
	else:
		_draw_gauge_state(Vector2(600, 385), float(interaction.values[0]), 31.0)


func _draw_lighthouse_state(completed: int) -> void:
	if task_id == 0:
		for index in range(7):
			var place := hotspot(index)
			draw_circle(place, 11.0 * _scale(), Color("252f33"))
			if index < completed:
				draw_circle(place, 7.0 * _scale(), Color("f6d272"))
	elif task_id == 1:
		var lamp := _panel_point([300, 205])
		draw_circle(lamp, (16.0 + completed * 6.0) * _scale(), Color(1.0, 0.75, 0.33, 0.11 + completed * 0.06))
	elif task_id == 2:
		_draw_gauge_state(Vector2(325, 250), interaction.angle / 3.6, 12.5)
	else:
		for index in range(3):
			var place := hotspot(index)
			draw_circle(place, 19.0 * _scale(), Color("192e37") if index >= completed else Color("f6c873"))


func _draw_gear_installation_state(completed: int) -> void:
	var gear_names := ["小齿轮", "中齿轮", "大齿轮"]
	var cover_sides := [84.0, 105.0, 125.0]
	var placed_sides := [104.0, 126.0, 160.0]
	for index in range(mini(completed, 3)):
		var source := source_point(index)
		var cover_side: float = cover_sides[index] * _scale()
		var cover := Rect2(source - Vector2.ONE * cover_side * 0.5, Vector2.ONE * cover_side)
		draw_rect(cover, Color("132639"), true)
		var destination := hotspot(index)
		_draw_tool_cutout(gear_names[index], destination, 1.0, placed_sides[index])
		# The lower shaft and the installed gear now read as one mechanism.
		draw_circle(destination, 9.0 * _scale(), Color("80511e"))
		draw_circle(destination, 4.0 * _scale(), Color("f3c77b"))


func _draw_lens_installation_state(completed: int) -> void:
	var lens_widths := [45.0, 32.0, 54.0]
	var lens_height := 150.0
	var dark_stone := Color("102333")
	for index in range(3):
		var destination := hotspot(index)
		if index >= completed:
			var half_width: float = lens_widths[index] * _scale() * 0.5
			var half_height := lens_height * _scale() * 0.5
			var cavity := Rect2(destination - Vector2(half_width, half_height), Vector2(half_width * 2.0, half_height * 2.0))
			draw_rect(cavity, dark_stone, true)
			draw_line(destination + Vector2(-half_width, -half_height), destination + Vector2(-half_width, half_height), Color("7f5b27"), 3.0 * _scale())
			draw_line(destination + Vector2(half_width, -half_height), destination + Vector2(half_width, half_height), Color("a87730"), 3.0 * _scale())
		else:
			var tray := source_point(index)
			var tray_cover := Rect2(tray - Vector2(21, 51) * _scale(), Vector2(42, 102) * _scale())
			draw_rect(tray_cover, Color("102333"), true)
	var beam_y := _panel_point([0, 300]).y
	var beam_start := _panel_point([145, 300]).x
	var beam_end := _panel_point([650, 300]).x
	draw_line(Vector2(beam_start, beam_y), Vector2(beam_end, beam_y), Color("102333"), 10.0 * _scale())
	var reached: float = [175.0, 340.0, 510.0, 650.0][clampi(completed, 0, 3)]
	var light_end := _panel_point([reached, 300.0]).x
	draw_line(Vector2(beam_start, beam_y), Vector2(light_end, beam_y), Color("f9ce72"), 5.0 * _scale())
	draw_line(Vector2(beam_start, beam_y), Vector2(light_end, beam_y), Color("fff4bd"), 2.0 * _scale())


func _draw_scrape_action(at: Vector2, progress: float) -> void:
	var radius := 34.0 * _scale()
	var cleared := clampf(progress, 0.0, 1.0)
	draw_circle(at, radius * cleared, Color(0.13, 0.23, 0.29, 0.86 * cleared))
	for line_index in range(3):
		var y := (float(line_index) - 1.0) * radius * 0.55
		draw_line(at + Vector2(-radius * 0.8, y), at + Vector2(lerpf(-radius * 0.8, radius * 0.8, cleared), y), Color("d4c6a8"), 3.0 * _scale())
	_draw_scraper(at + Vector2(lerpf(-radius, radius, cleared), -radius * 0.45))


func _draw_repaired_foundation_region(index: int) -> void:
	var repaired_centers := [Vector2(305, 350), Vector2(1010, 455), Vector2(260, 785), Vector2(620, 620)]
	var sample_center: Vector2 = repaired_centers[index]
	var visible_radius := 45.0 if index < 3 else 62.0
	var feather_radius := visible_radius + 12.0
	var screen_center := _panel_point(layout.points[index])
	var scale_factor := _scale()
	var texture_scale := FOUNDATION_REPAIRED.get_width() / image_size.x
	var texture_size := Vector2(FOUNDATION_REPAIRED.get_size())
	for step in range(32):
		var theta_a := TAU * float(step) / 32.0
		var theta_b := TAU * float(step + 1) / 32.0
		var direction_a := Vector2(cos(theta_a), sin(theta_a))
		var direction_b := Vector2(cos(theta_b), sin(theta_b))
		var inner_a := direction_a * visible_radius
		var inner_b := direction_b * visible_radius
		var outer_a := direction_a * feather_radius
		var outer_b := direction_b * feather_radius
		var white := Color.WHITE
		var clear := Color(1, 1, 1, 0)
		draw_primitive(PackedVector2Array([screen_center, screen_center + inner_a * scale_factor, screen_center + inner_b * scale_factor]), PackedColorArray([white, white, white]), PackedVector2Array([sample_center / texture_size, (sample_center + inner_a * texture_scale) / texture_size, (sample_center + inner_b * texture_scale) / texture_size]), FOUNDATION_REPAIRED)
		draw_primitive(PackedVector2Array([screen_center + inner_a * scale_factor, screen_center + outer_a * scale_factor, screen_center + inner_b * scale_factor]), PackedColorArray([white, clear, white]), PackedVector2Array([(sample_center + inner_a * texture_scale) / texture_size, (sample_center + outer_a * texture_scale) / texture_size, (sample_center + inner_b * texture_scale) / texture_size]), FOUNDATION_REPAIRED)
		draw_primitive(PackedVector2Array([screen_center + inner_b * scale_factor, screen_center + outer_a * scale_factor, screen_center + outer_b * scale_factor]), PackedColorArray([white, clear, clear]), PackedVector2Array([(sample_center + inner_b * texture_scale) / texture_size, (sample_center + outer_a * texture_scale) / texture_size, (sample_center + outer_b * texture_scale) / texture_size]), FOUNDATION_REPAIRED)


func _draw_dragged_art(index: int, at: Vector2) -> void:
	_draw_art_crop(index, at)


func _draw_sequence_tool(index: int, at: Vector2) -> void:
	var tool := ""
	match floor_id:
		0: tool = ["石料", "刮刀", "木槌", "砂浆"][index]
		1: tool = ["放大镜", "刷子", "扳手"][index]
		2: tool = ["", "软布", "刷子"][index]
		3: tool = "放大镜"
		4: tool = "放大镜"
	if _draw_tool_cutout(tool, at):
		return
	var native_center := Vector2(layout.sequence_sources[index][0], layout.sequence_sources[index][1])
	var native_rect := Rect2(native_center - Vector2(42, 45), Vector2(84, 90))
	var side := native_rect.size * _scale()
	draw_circle(at + Vector2(5, 8), side.x * 0.48, Color(0.01, 0.03, 0.05, 0.55))
	draw_texture_rect_region(panel_texture, Rect2(at - side * 0.5, side), native_rect)


func _draw_sequence_material_changes(completed: int) -> void:
	if completed <= 0:
		return
	var gap := _panel_point([535, 475])
	var unit := _scale()
	if completed >= 1:
		draw_rect(Rect2(gap + Vector2(-33, -27) * unit, Vector2(66, 54) * unit), Color("536473"), true)
		draw_line(gap + Vector2(-30, 5) * unit, gap + Vector2(28, 5) * unit, Color("adb9b8"), 3 * unit)
	if completed >= 2:
		var scrape := _panel_point([485, 428])
		draw_arc(scrape, 34 * unit, PI * 0.15, PI * 1.55, 22, Color("d8c6a4"), 5 * unit)
		draw_line(scrape + Vector2(-26, 11) * unit, scrape + Vector2(26, -14) * unit, Color("8dabb2"), 4 * unit)
	if completed >= 3:
		draw_rect(Rect2(gap + Vector2(-30, -24) * unit, Vector2(60, 48) * unit), Color("768180"), true)
	if completed >= 4:
		draw_rect(Rect2(gap + Vector2(-31, -25) * unit, Vector2(62, 50) * unit), Color("a69670"), false, 6 * unit)


func _draw_align_marker(place: Vector2, index: int) -> void:
	var value := float(interaction.values[index])
	var target := float(interaction.config.targets[index])
	var tolerance := float(interaction.config.tolerance)
	var start_angle := deg_to_rad(135.0)
	var sweep := deg_to_rad(270.0)
	var band_start := start_angle + sweep * clampf((target - tolerance) / 100.0, 0.0, 1.0)
	var band_end := start_angle + sweep * clampf((target + tolerance) / 100.0, 0.0, 1.0)
	draw_arc(place, 31.0, band_start, band_end, 12, C_DONE, 5.0)
	var needle_angle := start_angle + sweep * value / 100.0
	var needle_end := place + Vector2(cos(needle_angle), sin(needle_angle)) * 22.0
	draw_line(place, needle_end, C_WAIT, 4.0)
	if absf(value - target) <= tolerance:
		draw_arc(place, 25.0, 0, TAU, 32, C_DONE, 3.0)


func _draw_hint() -> void:
	var origin := (size - image_size * _scale()) * 0.5
	var rect := Rect2(origin + message_rect_native.position * _scale(), message_rect_native.size * _scale())
	var font_size := roundi(23.0 * _scale())
	var max_width := rect.size.x - 18.0
	while font_size > 13 and HINT_FONT.get_string_size(hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width:
		font_size -= 1
	var baseline := rect.position.y + (rect.size.y + HINT_FONT.get_ascent(font_size) - HINT_FONT.get_descent(font_size)) * 0.5
	var color := Color("ffb8a0") if hint_is_error else Color("f8e1ae")
	var shadow := Color("182432")
	if hint_on_parchment:
		color = Color("8e342a") if hint_is_error else Color("483126")
		shadow = Color("ffe8b7")
	draw_string(HINT_FONT, Vector2(rect.position.x + 9, baseline + 1), hint_text, HORIZONTAL_ALIGNMENT_CENTER, max_width, font_size, shadow)
	draw_string(HINT_FONT, Vector2(rect.position.x + 9, baseline), hint_text, HORIZONTAL_ALIGNMENT_CENTER, max_width, font_size, color)


func _gui_input(event: InputEvent) -> void:
	if interaction == null or interaction.finished or scraping:
		return
	var kind := str(interaction.config.kind)
	if kind not in ["sequence", "drag", "align", "dial"]:
		return
	if event is InputEventMouseMotion:
		if held_source:
			pointer = event.position
			queue_redraw()
		if held_sequence:
			pointer = event.position
			queue_redraw()
		if held_dial:
			_update_dial(event.position)
		if active_parameter >= 0:
			_update_parameter(event.position)
		return
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		if kind == "align":
			for index in range(2):
				if event.position.distance_to(hotspot(index)) <= 36.0:
					active_parameter = index
					parameter_start = event.position
					parameter_base = float(interaction.values[index])
					break
		elif kind == "dial":
			var center := _panel_point(layout.dial_center)
			if event.position.distance_to(center) <= float(layout.dial_radius) * _scale():
				held_dial = true
				_update_dial(event.position)
		elif kind == "sequence":
			if layout.has("sequence_sources") and interaction.stage < layout.sequence_sources.size() and layout.sequence_sources[interaction.stage] != null:
				var current: int = interaction.stage
				if current < layout.sequence_sources.size() and event.position.distance_to(_panel_point(layout.sequence_sources[current])) <= 45.0 * _scale():
					held_sequence = true
					pointer = event.position
					queue_redraw()
			else:
				for index in range(layout.points.size()):
					if event.position.distance_to(hotspot(index)) <= 34.0:
						interaction.press_art_sequence(index)
						queue_redraw()
						break
		else:
			var stage_now: int = interaction.stage
			if stage_now < layout.points.size() and event.position.distance_to(source_point(stage_now)) <= 36.0:
				held_source = true
				pointer = event.position
				queue_redraw()
	elif held_sequence:
		held_sequence = false
		var current: int = interaction.stage
		if current < layout.sequence_targets.size() and event.position.distance_to(_panel_point(layout.sequence_targets[current])) <= 57.0 * _scale():
			interaction.press_art_sequence(current)
		else:
			interaction.mistake.emit("把工具移到需要处理的部位，再松开。")
		queue_redraw()
	elif active_parameter >= 0:
		active_parameter = -1
		interaction.try_finish_from_art()
	elif held_dial:
		held_dial = false
		interaction.try_finish_from_art()
	elif held_source:
		held_source = false
		var stage_now: int = interaction.stage
		if stage_now < layout.points.size() and event.position.distance_to(hotspot(stage_now)) <= 38.0:
			if floor_id == 0 and task_id == 0:
				scraping = true
				scrape_time = 0.0
			else:
				interaction.drop_art_part()
		else:
			interaction.fail_art_drop()
		queue_redraw()


func _update_dial(point: Vector2) -> void:
	var center := _panel_point(layout.dial_center)
	interaction.set_art_angle(rad_to_deg(atan2(point.y - center.y, point.x - center.x)) + 90.0)
	queue_redraw()


func _update_parameter(point: Vector2) -> void:
	interaction.set_art_value(active_parameter, parameter_base + (parameter_start.y - point.y) / (1.6 * _scale()))
	queue_redraw()
