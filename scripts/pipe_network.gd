extends Control

signal solved

const FONT := preload("res://assets/fonts/HarmonyOS_Sans_SC_Medium.ttf")
const DIRECTIONS := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const MASKS := [10, 3, 11, 1]
const FIXED := {Vector2i(0, 1): 9, Vector2i(1, 0): 10, Vector2i(2, 1): 3}
const GAPS := [Vector2i(0, 0), Vector2i(2, 0)]
const NAMES := ["直管", "弯管", "三通", "堵头"]
const GRID := Vector2(270, 205)
const CELL := 105.0
const PALETTE := Vector2(150, 216)
const BOARD_PATH := "res://assets/ui/mechanical_workbench_v1.png"
const PIPE_PATHS := ["res://assets/ui/pipe_straight_v1.png", "res://assets/ui/pipe_elbow_v1.png", "res://assets/ui/pipe_tee_v1.png", "res://assets/ui/pipe_cap_v1.png"]
const PIPE_REGIONS := [Rect2(568, 172, 1036, 380), Rect2(288, 216, 692, 704), Rect2(272, 184, 904, 688), Rect2(564, 272, 320, 520)]
var board: Texture2D
var pipe_textures: Array[Texture2D] = []
var pipe_regions: Array[Rect2] = []
var pieces: Dictionary = {}
var selected := -1
var dragging := false
var cursor := Vector2.ZERO
var message := "挑选管件补上两处断口；右键旋转管件。"
var complete := false
var testing := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	board = load(BOARD_PATH)
	pipe_textures.clear()
	pipe_regions.clear()
	for index in range(PIPE_PATHS.size()):
		var path: String = PIPE_PATHS[index]
		var texture: Texture2D = load(path)
		pipe_textures.append(texture)
		pipe_regions.append(PIPE_REGIONS[index])

func reset() -> void:
	pieces.clear()
	pieces.merge(FIXED)
	selected = -1
	dragging = false
	complete = false
	testing = false
	message = "挑选管件补上两处断口；右键旋转管件。"
	queue_redraw()

func _scale_factor() -> float:
	return minf(size.x / 724.0, size.y / 724.0)

func _native(p: Vector2) -> Vector2:
	return (p - (size - Vector2(724, 724) * _scale_factor()) * 0.5) / _scale_factor()

func _cell(p: Vector2) -> Vector2i:
	var grid_pos := (p - GRID) / CELL
	var c := Vector2i(floori(grid_pos.x), floori(grid_pos.y))
	return c if c in GAPS else Vector2i(-1, -1)

func _rotate(mask: int) -> int:
	return ((mask << 1) | (mask >> 3)) & 15

func _gui_input(event: InputEvent) -> void:
	if complete:
		return
	if event is InputEventMouseMotion and dragging:
		cursor = _native(event.position)
		queue_redraw()
		return
	if not event is InputEventMouseButton:
		return
	var p := _native(event.position)
	var c := _cell(p)
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and pieces.has(c):
		pieces[c] = _rotate(pieces[c])
		testing = false
		message = "管段已旋转。检查接口是否接通。"
		queue_redraw()
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		if p.distance_to(Vector2(625, 170)) < 24:
			message = "比较两侧管口，拖入弯管并右键调整方向。"
			queue_redraw()
			return
		for index in range(MASKS.size()):
			if p.distance_to(PALETTE + Vector2(0, index * 93)) < 40:
				selected = MASKS[index]
				dragging = true
				cursor = p
				queue_redraw()
				return
		if pieces.has(c):
			selected = pieces[c]
			pieces.erase(c)
			testing = false
			dragging = true
			cursor = p
			queue_redraw()
	elif dragging:
		dragging = false
		if c.x >= 0:
			pieces[c] = selected
			testing = false
		selected = -1
		queue_redraw()
	if not event.pressed and Rect2(256, 579, 310, 60).has_point(p):
		check_network()

func check_network() -> void:
	testing = true
	var result := inspect_network()
	if result.success:
		complete = true
		message = "管路接通，水流抵达排水口。"
		queue_redraw()
		solved.emit()
	else:
		message = "水流未到出口或接口漏水，再检查管路。"
		queue_redraw()

func inspect_network() -> Dictionary:
	var start := Vector2i(0, 1)
	if not pieces.has(start) or (int(pieces[start]) & 8) == 0:
		return {"success": false, "wet": {}}
	var queue: Array[Vector2i] = [start]
	var wet := {start: true}
	var reaches_exit := false
	var leaks := false
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		var mask := int(pieces[c])
		for d in range(4):
			if (mask & (1 << d)) == 0:
				continue
			var next: Vector2i = c + DIRECTIONS[d]
			if c == start and d == 3:
				continue
			if c == Vector2i(2, 1) and d == 1:
				reaches_exit = true
				continue
			if not pieces.has(next) or (int(pieces[next]) & (1 << ((d + 2) % 4))) == 0:
				leaks = true
			elif not wet.has(next):
				wet[next] = true
				queue.append(next)
	return {"success": reaches_exit and not leaks, "wet": wet}

func _draw() -> void:
	var factor := _scale_factor()
	draw_set_transform((size - Vector2(724, 724) * factor) * 0.5, 0.0, Vector2.ONE * factor)
	if board:
		draw_texture_rect(board, Rect2(0, 0, 724, 724), false)
	draw_string(FONT, Vector2(185, 155), "修复破损管路", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("f1d39a"))
	draw_string(FONT, Vector2(185, 184), "检查断口，选管件接通两侧。", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("d5e5e4"))
	draw_circle(Vector2(625, 170), 19, Color("78562e"))
	draw_string(FONT, Vector2(619, 178), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("fff1ce"))
	var wet: Dictionary = inspect_network().wet if testing else {}
	# Permanently mounted inlet and outlet pipes frame the damaged assembly.
	_draw_pipe(GRID + Vector2(-0.325, 1.5) * CELL, 10, testing, 0.65)
	_draw_pipe(GRID + Vector2(3.325, 1.5) * CELL, 10, complete, 0.65)
	for x in range(3):
		for y in range(3):
			var c := Vector2i(x, y)
			var rect := Rect2(GRID + Vector2(x, y) * CELL, Vector2.ONE * CELL)
			if c in GAPS and not pieces.has(c):
				draw_arc(rect.get_center(), 22, 0, TAU, 32, Color(0.77, 0.62, 0.40, 0.6), 2, true)
				draw_string(FONT, rect.get_center() + Vector2(-18, 40), "断口", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("d6b77c"))
			if pieces.has(c):
				_draw_pipe(rect.get_center(), int(pieces[c]), wet.has(c))
	for index in range(MASKS.size()):
		var center := PALETTE + Vector2(0, index * 93)
		draw_rect(Rect2(center - Vector2(42, 38), Vector2(84, 76)), Color(0.12, 0.19, 0.20, 0.86))
		draw_rect(Rect2(center - Vector2(42, 38), Vector2(84, 76)), Color("a67d4e"), false, 2)
		_draw_pipe(center, MASKS[index], false, 0.62)
		draw_string(FONT, center + Vector2(-22, 55), NAMES[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("e4c791"))
	draw_rect(Rect2(256, 579, 310, 60), Color("594126"))
	draw_rect(Rect2(260, 583, 302, 52), Color("172f38"))
	draw_rect(Rect2(256, 579, 310, 60), Color("d5ad6e"), false, 3)
	for point in [Vector2(266, 589), Vector2(556, 589), Vector2(266, 629), Vector2(556, 629)]:
		draw_circle(point, 3, Color("e5c280"))
	draw_string(FONT, Vector2(340, 618), "打开水阀测试", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("fff1ce"))
	draw_string(FONT, Vector2(105, 653), message, HORIZONTAL_ALIGNMENT_LEFT, 530, 16, Color("e8d8b4"))
	if dragging and selected >= 0:
		_draw_pipe(cursor, selected, false, 0.8)
	draw_set_transform(Vector2.ZERO)

func _draw_pipe(center: Vector2, mask: int, wet: bool, scale_factor := 1.0) -> void:
	var kind := -1
	var rotation := 0
	for i in range(MASKS.size()):
		var candidate: int = MASKS[i]
		for turn in range(4):
			if candidate == mask:
				kind = i
				rotation = turn
				break
			candidate = _rotate(candidate)
		if kind >= 0:
			break
	if kind < 0 or pipe_textures.size() != MASKS.size():
		return
	var dst := Rect2(-52.5, -22, 105, 44)
	if kind == 1:
		dst = Rect2(-17.5, -52.5, 70, 70)
	elif kind == 2:
		dst = Rect2(-52.5, -52.5, 105, 70)
	elif kind == 3:
		dst = Rect2(-22, -52.5, 44, 70)
	var f := _scale_factor()
	var base_origin := (size - Vector2(724, 724) * f) * 0.5
	draw_set_transform(base_origin + center * f, rotation * PI / 2.0, Vector2.ONE * f * scale_factor)
	draw_texture_rect_region(pipe_textures[kind], dst, pipe_regions[kind])
	draw_set_transform(base_origin, 0.0, Vector2.ONE * f)
	if wet:
		for d in range(4):
			if (mask & (1 << d)) != 0:
				draw_line(center, center + Vector2(DIRECTIONS[d]) * 39.0 * scale_factor, Color(0.40, 0.83, 0.94, 0.72), 3.0 * scale_factor, true)
