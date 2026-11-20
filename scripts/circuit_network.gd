extends Control

signal solved
const FONT := preload("res://assets/fonts/HarmonyOS_Sans_SC_Medium.ttf")
const SWITCH_ICON := preload("res://assets/ui/Icons/Sprites/icon_switch.png")
const FUSE_ICON := preload("res://assets/ui/Icons/Sprites/icon_fuse.png")
const LAMP_ICON := preload("res://assets/ui/Icons/Sprites/icon_lamp_beam.png")
const POINTS := [Vector2(135, 250), Vector2(135, 465), Vector2(260, 250), Vector2(340, 250), Vector2(435, 250), Vector2(515, 250), Vector2(570, 360), Vector2(570, 465)]
const BOARD_PATH := "res://assets/ui/mechanical_workbench_v1.png"
var board: Texture2D
var wires: Array = []
var fuse_installed := false
var switch_on := false
var dragging := -1
var cursor := Vector2.ZERO
var message := "先断开开关，安装保险丝，再连接接线端。"
var complete := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	board = load(BOARD_PATH)

func reset() -> void:
	wires.clear()
	fuse_installed = false
	switch_on = false
	dragging = -1
	complete = false
	message = "先断开开关，安装保险丝，再连接接线端。"
	queue_redraw()

func _scale_factor() -> float:
	return minf(size.x / 724.0, size.y / 724.0)

func _native(p: Vector2) -> Vector2:
	return (p - (size - Vector2(724, 724) * _scale_factor()) * 0.5) / _scale_factor()

func _terminal(p: Vector2) -> int:
	for i in range(POINTS.size()):
		if p.distance_to(POINTS[i]) <= 22:
			return i
	return -1

func _gui_input(event: InputEvent) -> void:
	if complete:
		return
	if event is InputEventMouseMotion and dragging >= 0:
		cursor = _native(event.position)
		queue_redraw()
		return
	if not event is InputEventMouseButton:
		return
	var p := _native(event.position)
	var terminal := _terminal(p)
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and terminal >= 0 and not switch_on:
		for i in range(wires.size() - 1, -1, -1):
			if terminal in wires[i]:
				wires.remove_at(i)
		queue_redraw()
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		if p.distance_to(Vector2(625, 170)) < 24:
			message = "依次连通电源、开关、保险丝与灯泡，再回到电源。"
		elif Rect2(390, 325, 155, 58).has_point(p) and not switch_on:
			fuse_installed = true
			message = "保险丝已装入。拖动端子之间的导线。"
		elif Rect2(235, 325, 135, 58).has_point(p):
			switch_on = not switch_on
			if switch_on:
				_test_circuit()
			else:
				message = "电源已断开，可调整接线。"
		elif terminal >= 0:
			if switch_on:
				message = "先断开开关，再调整线路。"
			else:
				dragging = terminal
				cursor = p
	elif dragging >= 0:
		if terminal >= 0 and terminal != dragging:
			_connect(dragging, terminal)
		dragging = -1
	queue_redraw()

func _connect(a: int, b: int) -> void:
	for wire in wires:
		if a in wire or b in wire:
			message = "端子已接线；断电后右键端子可拆除。"
			return
	wires.append([a, b])
	message = "已连接。右键端子可拆除导线。"

func _reachable(avoid_lamp: bool, omit_switch := false, omit_fuse := false) -> bool:
	var links: Array = wires.duplicate(true)
	if switch_on and not omit_switch:
		links.append([2, 3])
	if fuse_installed and not omit_fuse:
		links.append([4, 5])
	if not avoid_lamp:
		links.append([6, 7])
	var seen := {0: true}
	var queue: Array[int] = [0]
	while not queue.is_empty():
		var node: int = queue.pop_front()
		for link in links:
			if node not in link:
				continue
			var next: int = link[1] if link[0] == node else link[0]
			if not seen.has(next):
				seen[next] = true
				queue.append(next)
	return seen.has(1)

func _test_circuit() -> void:
	if _reachable(true):
		switch_on = false
		message = "检测到短路，开关已断开；检查导线。"
	elif _reachable(false) and not _reachable(false, true, false) and not _reachable(false, false, true):
		complete = true
		message = "回路闭合，灯亮了。"
		queue_redraw()
		solved.emit()
	else:
		message = "回路尚未闭合；断电后检查保险丝和导线。"

func _draw() -> void:
	var f := _scale_factor()
	draw_set_transform((size - Vector2(724, 724) * f) * 0.5, 0.0, Vector2.ONE * f)
	if board:
		draw_texture_rect(board, Rect2(0, 0, 724, 724), false)
	draw_string(FONT, Vector2(185, 155), "恢复电路", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("f1d39a"))
	draw_string(FONT, Vector2(185, 184), "断电接线，安装保险丝，再合闸测试。", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("d5e5e4"))
	draw_circle(Vector2(625, 170), 19, Color("78562e"))
	draw_string(FONT, Vector2(619, 178), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("fff1ce"))
	for wire in wires:
		draw_line(POINTS[wire[0]], POINTS[wire[1]], Color("b77c45"), 8, true)
		draw_line(POINTS[wire[0]], POINTS[wire[1]], Color("f1c77e"), 3, true)
	if dragging >= 0:
		draw_line(POINTS[dragging], cursor, Color("f1c77e"), 4, true)
	for point in POINTS:
		draw_circle(point, 15, Color("a97b40"))
		draw_circle(point, 8, Color("20343a"))
	draw_string(FONT, Vector2(95, 205), "电源 +", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("e5d3ad"))
	draw_string(FONT, Vector2(95, 510), "电源 −", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("e5d3ad"))
	draw_string(FONT, Vector2(275, 205), "开关", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("e5d3ad"))
	draw_string(FONT, Vector2(440, 205), "保险丝", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("e5d3ad"))
	draw_string(FONT, Vector2(555, 510), "灯泡", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("e5d3ad"))
	draw_rect(Rect2(235, 325, 135, 58), Color("172f38"))
	draw_rect(Rect2(235, 325, 135, 58), Color("c99b5b"), false, 3)
	draw_texture_rect(SWITCH_ICON, Rect2(239, 330, 48, 48), false)
	draw_string(FONT, Vector2(290, 362), "断开" if switch_on else "合闸", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("fff1ce"))
	draw_rect(Rect2(390, 325, 155, 58), Color("172f38"))
	draw_rect(Rect2(390, 325, 155, 58), Color("c99b5b"), false, 3)
	draw_texture_rect(FUSE_ICON, Rect2(394, 330, 48, 48), false, Color.WHITE if fuse_installed else Color(0.65, 0.65, 0.65))
	draw_string(FONT, Vector2(444, 350), "已安装" if fuse_installed else "安装", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("fff1ce"))
	draw_string(FONT, Vector2(444, 370), "保险丝", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("fff1ce"))
	draw_line(POINTS[2], POINTS[3], Color("f4cd7a") if switch_on else Color("566767"), 4)
	if fuse_installed:
		draw_line(POINTS[4], POINTS[5], Color("f4cd7a"), 4)
	draw_texture_rect(LAMP_ICON, Rect2(547, 389, 46, 46), false, Color.WHITE if complete else Color(0.5, 0.5, 0.5))
	draw_string(FONT, Vector2(95, 615), "拖动端子接线；断电时右键端子可拆线。", HORIZONTAL_ALIGNMENT_LEFT, 540, 16, Color("e8d8b4"))
	draw_string(FONT, Vector2(95, 648), message, HORIZONTAL_ALIGNMENT_LEFT, 540, 16, Color("e8d8b4"))
	draw_set_transform(Vector2.ZERO)
