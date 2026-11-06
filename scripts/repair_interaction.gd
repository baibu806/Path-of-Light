extends Control

const UI_FONT := preload("res://assets/fonts/HarmonyOS_Sans_SC_Medium.ttf")

signal solved
signal mistake(message: String)
signal step_completed

# Each entry is a physical operation, not a multiple-choice answer. The left
# illustration remains the original floor panel; this control is its operable part.
const TASKS := [
	[
		{"kind": "drag", "instruction": "按住画面中的刮刀，依次刮净四处盐霜。", "parts": ["刮刀", "刮刀", "刮刀", "刮刀"], "targets": ["左上盐霜", "右侧盐霜", "左下盐霜", "中央盐霜"]},
		{"kind": "sequence", "interaction": "drag_sequence", "instruction": "拖动石料与工具到修复处，依次选材、清缝、轻敲、填补。", "items": ["选稳固石料", "清理接缝", "轻敲空鼓", "填补砂浆"]},
		{"kind": "align", "instruction": "调节砂浆配比与承压负载，再锁定测试。", "labels": ["砂浆配比", "承压负载"], "targets": [62, 74], "tolerance": 8}
	],
	[
		{"kind": "sequence", "drag_steps": [0, 1, 2], "instruction": "拖动检修工具，沿水迹逆流追查三处管道。", "items": ["排水口", "弯管", "裂口"]},
		{"kind": "drag", "instruction": "从左侧零件架取直管、弯管、三通，接入右侧对应管路。", "parts": ["直管", "弯管", "三通"], "targets": ["上方缺口", "中段转角", "排水端"]},
		{"kind": "align", "instruction": "控制阀门开度和泵压，落入安全范围后启动。", "labels": ["阀门开度", "排水泵压"], "targets": [68, 54], "tolerance": 7}
	],
	[
		{"kind": "sequence", "drag_steps": [1, 2], "instruction": "先断电，再拖动软布和刷子清理受潮接点。", "items": ["断开电闸", "清理左端", "清理右端"]},
		{"kind": "drag", "instruction": "先安放保险丝，再把蓝、红导线接回对应端子。", "parts": ["保险丝", "蓝色导线", "红色导线"], "targets": ["保险座", "蓝线端子", "红线端子"]},
		{"kind": "align", "instruction": "把输出电压和负载调入绿色标定区。", "labels": ["输出电压", "回路负载"], "targets": [72, 46], "tolerance": 6}
	],
	[
		{"kind": "sequence", "drag_steps": [0, 1, 2], "instruction": "移动放大镜，依次检查异物、断齿和轴承。", "items": ["异物", "断齿", "轴承"]},
		{"kind": "drag", "instruction": "按尺寸将三只齿轮装上对应传动轴。", "parts": ["小齿轮", "中齿轮", "大齿轮"], "targets": ["左传动轴", "中传动轴", "右传动轴"]},
		{"kind": "dial", "instruction": "转动图中的调速仪表，指向左侧绿色区后锁定。", "label": "调速旋钮", "target": 270, "tolerance": 11}
	],
	[
		{"kind": "drag", "instruction": "用软布依次擦拭镜面上的四处盐雾。", "parts": ["软布", "软布", "软布", "软布"], "targets": ["左上", "右上", "左下", "右下"]},
		{"kind": "sequence", "drag_steps": [0, 1, 2], "instruction": "移动放大镜，从左到右检查镜片裂纹。", "items": ["左镜", "中镜", "右镜"]},
		{"kind": "drag", "instruction": "从下方托盘取三片镜片，依次装入空镜位。", "parts": ["第一镜片", "第二镜片", "第三镜片"], "targets": ["入射位", "转折位", "出射位"]}
	],
	[
		{"kind": "align", "instruction": "移动光源的横向、纵向位置到刻线。", "labels": ["水平位置", "垂直位置"], "targets": [36, 67], "tolerance": 5},
		{"kind": "align", "instruction": "微调镜组角度与焦距，使两项都落入绿色区。", "labels": ["镜组角度", "焦距"], "targets": [58, 79], "tolerance": 5},
		{"kind": "align", "instruction": "降低温度并稳住光束，再锁定焦点。", "labels": ["工作温度", "光束稳定度"], "targets": [31, 84], "tolerance": 6}
	],
	[
		{"kind": "sequence", "instruction": "依次确认七层系统的回传灯。", "items": ["地基", "排水", "电路", "机械", "镜片", "焦距", "主灯"]},
		{"kind": "sequence", "instruction": "按手册完成短、短、长、短的闪灯校验。", "items": ["短闪 1", "短闪 2", "长闪", "短闪 3"]},
		{"kind": "dial", "instruction": "转动图中的方位盘，对准右上方绿色安全航道。", "label": "灯塔方位盘", "target": 45, "tolerance": 8},
		{"kind": "sequence", "instruction": "依次合上断路器、预热、启动主灯。", "items": ["合闸", "预热", "启动"]}
	]
]

const WIDTH := 420.0
const TRACK_LEFT := 58.0
const TRACK_RIGHT := 360.0
const DIAL_CENTER := Vector2(210, 163)
const DIAL_RADIUS := 91.0
const LOCK_RECT := Rect2(116, 282, 188, 49)
const C_BG := Color("101e2b")
const C_EDGE := Color("b08a50")
const C_BLUE := Color("3e5966")
const C_GOLD := Color("f2c675")
const C_GREEN := Color("87d4ad")
const C_RED := Color("ed9789")

var config: Dictionary = {}
var stage := 0
var values := [0.0, 0.0]
var angle := 0.0
var dragging := false
var drag_index := -1
var drag_position := Vector2.ZERO
var active_slider := -1
var hover_point := Vector2(-1000, -1000)
var finished := false


func _ready() -> void:
	custom_minimum_size = Vector2(WIDTH, 350)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL


func configure(floor_number: int, task_number: int) -> void:
	assert(floor_number >= 0 and floor_number < TASKS.size())
	assert(task_number >= 0 and task_number < TASKS[floor_number].size())
	config = TASKS[floor_number][task_number].duplicate(true)
	stage = 0
	values = [0.0, 0.0]
	angle = 0.0
	dragging = false
	drag_index = -1
	active_slider = -1
	finished = false
	queue_redraw()


func instruction() -> String:
	return str(config.get("instruction", ""))


func current_step_text() -> String:
	if config.is_empty() or finished:
		return ""
	match str(config.kind):
		"sequence":
			if config.get("interaction", "") == "drag_sequence" or stage in config.get("drag_steps", []):
				return "下一步：拖动「%s」到画面亮起的位置" % str(config.items[stage])
			return "下一步：点击画面中的「%s」" % str(config.items[stage])
		"drag":
			return "下一步：将「%s」拖到「%s」" % [str(config.parts[stage]), str(config.targets[stage])]
		"align":
			return "在画面标记处向上拖动调参；两项进入绿色区后锁定。"
		"dial":
			return "转动方位盘至绿色刻线，再按锁定 / 测试。"
	return ""


func art_hint() -> String:
	if config.is_empty() or finished:
		return ""
	match str(config.kind):
		"sequence":
			if config.get("interaction", "") == "drag_sequence" or stage in config.get("drag_steps", []):
				return "拿起「%s」，移到亮起的修复处。" % str(config.items[stage])
			return "先看看「%s」，慢慢来。" % str(config.items[stage])
		"drag":
			var part := str(config.parts[stage])
			var target := str(config.targets[stage])
			if part in ["刮刀", "软布"]:
				return "慢慢来，用「%s」清理「%s」。" % [part, target]
			return "试试把「%s」放到「%s」。" % [part, target]
		"align": return "慢慢调，让两处刻度亮起绿色。"
		"dial": return "轻轻转，等指针停在绿色区。"
	return ""


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(WIDTH, 350)), C_BG, true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(WIDTH, 350)), C_EDGE, false, 2)
	draw_rect(Rect2(8, 8, WIDTH - 16, 334), C_EDGE.darkened(0.48), false, 1)
	for rivet in [Vector2(13, 13), Vector2(WIDTH - 13, 13), Vector2(13, 337), Vector2(WIDTH - 13, 337)]:
		draw_circle(rivet, 3, C_GOLD)
	if config.is_empty():
		return
	match str(config.kind):
		"sequence": _draw_sequence()
		"drag": _draw_drag()
		"align": _draw_align()
		"dial": _draw_dial()


func _draw_sequence() -> void:
	var items: Array = config.items
	_text(Vector2(20, 39), "逐项检查  %d / %d" % [stage, items.size()], C_GOLD, 20)
	for index in range(items.size()):
		var rect := _sequence_rect(index)
		var color := C_GREEN if index < stage else (C_GOLD if index == stage else C_BLUE)
		_draw_tile(rect, color, index == stage)
		_text(rect.position + Vector2(12, 32), str(items[index]), Color.WHITE, 18)
		_text(rect.position + Vector2(6, -6), "%d" % (index + 1), color, 16)


func _draw_drag() -> void:
	var parts: Array = config.parts
	_text(Vector2(20, 39), "现场装配  %d / %d" % [stage, parts.size()], C_GOLD, 20)
	_text(Vector2(25, 64), "工具 / 零件", C_EDGE, 16)
	_text(Vector2(270, 64), "对应位置", C_EDGE, 16)
	for index in range(parts.size()):
		var source := _source_rect(index)
		var target := _target_rect(index)
		var done := index < stage
		_draw_tile(source, C_GREEN if done else (C_GOLD if index == stage else C_BLUE), index == stage)
		_text(source.position + Vector2(11, 28), str(parts[index]), Color.WHITE, 17)
		_draw_tile(target, C_GREEN if done else C_BLUE, false)
		_text(target.position + Vector2(11, 28), str(config.targets[index]), Color.WHITE, 17)
		# Installed parts remain in the artwork; no success tick is drawn here.
	if dragging and drag_index >= 0:
		draw_line(_source_rect(drag_index).get_center(), drag_position, C_GOLD, 4)
		draw_circle(drag_position, 12, C_GOLD)


func _draw_align() -> void:
	var target_values: Array = config.targets
	var tolerance: int = int(config.tolerance)
	_text(Vector2(20, 39), "仪表校准  ·  安全区测试", C_GOLD, 20)
	for index in range(2):
		var y := _slider_y(index)
		_text(Vector2(30, y - 28), "%d / %s  %d" % [index + 1, str(config.labels[index]), roundi(values[index])], Color.WHITE, 18)
		_text(Vector2(306, y - 28), "目标 %d" % int(target_values[index]), C_GREEN, 17)
		draw_line(Vector2(TRACK_LEFT, y), Vector2(TRACK_RIGHT, y), C_BLUE, 12)
		var band_left := _slider_x(float(target_values[index] - tolerance))
		var band_right := _slider_x(float(target_values[index] + tolerance))
		draw_line(Vector2(band_left, y), Vector2(band_right, y), C_GREEN, 13)
		var knob := Vector2(_slider_x(values[index]), y)
		draw_circle(knob, 15, C_GOLD)
		draw_arc(knob, 15, 0, TAU, 24, Color.WHITE, 2)
	_draw_lock_button()


func _draw_dial() -> void:
	_text(Vector2(20, 39), "%s  ·  目标 %d°" % [str(config.label), int(config.target)], C_GOLD, 20)
	draw_arc(DIAL_CENTER, DIAL_RADIUS, 0, TAU, 72, C_EDGE, 6)
	var target_angle := deg_to_rad(float(config.target) - 90.0)
	var target_point := DIAL_CENTER + Vector2(cos(target_angle), sin(target_angle)) * DIAL_RADIUS
	draw_circle(target_point, 13, C_GREEN)
	var needle_angle := deg_to_rad(angle - 90.0)
	var needle_end := DIAL_CENTER + Vector2(cos(needle_angle), sin(needle_angle)) * (DIAL_RADIUS - 17.0)
	draw_line(DIAL_CENTER, needle_end, C_GOLD, 7)
	draw_circle(DIAL_CENTER, 10, C_GOLD)
	_text(Vector2(184, 170), "%d°" % roundi(angle), Color.WHITE, 22)
	_draw_lock_button()


func _draw_lock_button() -> void:
	_draw_tile(LOCK_RECT, C_GOLD, LOCK_RECT.has_point(hover_point))
	_text(LOCK_RECT.position + Vector2(52, 32), "锁定 / 测试", Color.WHITE, 19)


func _draw_tile(rect: Rect2, accent: Color, highlighted: bool) -> void:
	draw_rect(rect, accent.darkened(0.69) if not highlighted else accent.darkened(0.45), true)
	draw_rect(rect, accent, false, 2)


func _text(point: Vector2, value: String, color: Color, font_size: int) -> void:
	draw_string(UI_FONT, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _sequence_rect(index: int) -> Rect2:
	return Rect2(17 + (index % 3) * 135, 84 + (index / 3) * 82, 118, 54)


func _source_rect(index: int) -> Rect2:
	return Rect2(22, 82 + index * 62, 132, 43)


func _target_rect(index: int) -> Rect2:
	return Rect2(262, 82 + index * 62, 138, 43)


func _slider_y(index: int) -> float:
	return 122.0 + index * 91.0


func _slider_x(value: float) -> float:
	return lerpf(TRACK_LEFT, TRACK_RIGHT, clampf(value, 0.0, 100.0) / 100.0)


func _gui_input(event: InputEvent) -> void:
	if finished or config.is_empty():
		return
	if event is InputEventMouseMotion:
		hover_point = event.position
		if dragging:
			_update_pointer(event.position)
		queue_redraw()
		return
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var point: Vector2 = event.position
	if event.pressed:
		match str(config.kind):
			"sequence":
				for index in range(config.items.size()):
					if _sequence_rect(index).has_point(point):
						_press_sequence(index)
						break
			"drag":
				if stage < config.parts.size() and _source_rect(stage).has_point(point):
					dragging = true
					drag_index = stage
					drag_position = point
			"align":
				if LOCK_RECT.has_point(point):
					_lock()
				else:
					for index in range(2):
						if absf(point.y - _slider_y(index)) <= 24.0 and point.x >= TRACK_LEFT - 20.0 and point.x <= TRACK_RIGHT + 20.0:
							active_slider = index
							dragging = true
							_update_pointer(point)
							break
			"dial":
				if LOCK_RECT.has_point(point):
					_lock()
				elif point.distance_to(DIAL_CENTER) <= DIAL_RADIUS + 22.0:
					dragging = true
					_update_pointer(point)
	else:
		if dragging and str(config.kind) == "drag":
			_drop_drag(point)
		dragging = false
		drag_index = -1
		active_slider = -1
	queue_redraw()


func _update_pointer(point: Vector2) -> void:
	match str(config.kind):
		"drag": drag_position = point
		"align":
			if active_slider >= 0:
				values[active_slider] = clampf((point.x - TRACK_LEFT) / (TRACK_RIGHT - TRACK_LEFT) * 100.0, 0.0, 100.0)
		"dial":
			angle = fposmod(rad_to_deg(atan2(point.y - DIAL_CENTER.y, point.x - DIAL_CENTER.x)) + 90.0, 360.0)
	queue_redraw()


func _press_sequence(index: int) -> void:
	if index < stage:
		return
	if index != stage:
		mistake.emit("顺序不对；请先检查「%s」。" % str(config.items[stage]))
		return
	stage += 1
	queue_redraw()
	if stage == config.items.size():
		_finish()
	else:
		step_completed.emit()


func _drop_drag(point: Vector2) -> void:
	if drag_index != stage:
		return
	if not _target_rect(stage).grow(9).has_point(point):
		fail_art_drop()
		return
	drop_art_part()


func press_art_sequence(index: int) -> void:
	if not finished and str(config.get("kind", "")) == "sequence":
		_press_sequence(index)


func drop_art_part() -> void:
	if finished or str(config.get("kind", "")) != "drag":
		return
	stage += 1
	queue_redraw()
	if stage == config.parts.size():
		_finish()
	else:
		step_completed.emit()


func fail_art_drop() -> void:
	if not finished and str(config.get("kind", "")) == "drag":
		mistake.emit("安装位不匹配；把「%s」放到「%s」。" % [str(config.parts[stage]), str(config.targets[stage])])


func set_art_angle(new_angle: float) -> void:
	if not finished and str(config.get("kind", "")) == "dial":
		angle = fposmod(new_angle, 360.0)
		queue_redraw()


func set_art_value(index: int, new_value: float) -> void:
	if not finished and str(config.get("kind", "")) == "align" and index >= 0 and index < 2:
		values[index] = clampf(new_value, 0.0, 100.0)
		queue_redraw()


func try_finish_from_art() -> void:
	if finished:
		return
	match str(config.get("kind", "")):
		"align":
			for index in range(2):
				if absf(values[index] - float(config.targets[index])) > float(config.tolerance):
					return
			_finish()
		"dial":
			var difference := absf(wrapf(angle - float(config.target) + 180.0, 0.0, 360.0) - 180.0)
			if difference <= float(config.tolerance):
				_finish()


func _lock() -> void:
	if str(config.kind) == "align":
		for index in range(2):
			if absf(values[index] - float(config.targets[index])) > float(config.tolerance):
				mistake.emit("「%s」尚未进入绿色安全区。" % str(config.labels[index]))
				return
	elif str(config.kind) == "dial":
		var difference := absf(wrapf(angle - float(config.target) + 180.0, 0.0, 360.0) - 180.0)
		if difference > float(config.tolerance):
			mistake.emit("「%s」尚未对准绿色刻线。" % str(config.label))
			return
	_finish()


func _finish() -> void:
	if finished:
		return
	finished = true
	queue_redraw()
	solved.emit()
