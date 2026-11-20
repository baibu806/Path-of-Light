extends Control

signal solved
const FONT := preload("res://assets/fonts/HarmonyOS_Sans_SC_Medium.ttf")
const CENTERS := [Vector2(180, 330), Vector2(300, 330), Vector2(460, 330)]
const RADII := [50.0, 70.0, 90.0]
const TEETH := [10, 14, 18]
const TRAY := [Vector2(145, 565), Vector2(285, 565), Vector2(455, 565)]
const BOARD_PATH := "res://assets/ui/mechanical_workbench_v1.png"
var board: Texture2D
var metal_texture: Texture2D
var slots := [-1, -1, -1]
var picked := -1
var cursor := Vector2.ZERO
var running := false
var elapsed := 0.0
var speeds := [0.0, 0.0, 0.0]
var angles := [0.0, 0.0, 0.0]
var message := "把齿轮拖到轴上，啮合后试转。"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	board = load(BOARD_PATH)
	metal_texture = load("res://assets/ui/pipe_straight_v1.png")

func reset() -> void:
	slots = [-1, -1, -1]
	picked = -1
	running = false
	elapsed = 0.0
	speeds = [0.0, 0.0, 0.0]
	angles = [0.0, 0.0, 0.0]
	message = "把齿轮拖到轴上，啮合后试转。"
	queue_redraw()

func _scale_factor() -> float:
	return minf(size.x / 724.0, size.y / 724.0)

func _native(p: Vector2) -> Vector2:
	return (p - (size - Vector2(724, 724) * _scale_factor()) * 0.5) / _scale_factor()

func _gui_input(event: InputEvent) -> void:
	if running:
		return
	if event is InputEventMouseMotion and picked >= 0:
		cursor = _native(event.position)
		queue_redraw()
		return
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var p := _native(event.position)
	if event.pressed:
		if p.distance_to(Vector2(625, 170)) < 24:
			message = "比较轴距和齿轮大小，让相邻齿轮边缘接触。"
			queue_redraw()
			return
		if Rect2(492, 575, 166, 62).has_point(p):
			start_test()
			return
		for i in range(3):
			if slots[i] >= 0 and p.distance_to(CENTERS[i]) <= RADII[slots[i]]:
				picked = slots[i]
				slots[i] = -1
				cursor = p
				queue_redraw()
				return
		for i in range(3):
			if i not in slots and p.distance_to(TRAY[i]) <= 40:
				picked = i
				cursor = p
				queue_redraw()
				return
	elif picked >= 0:
		for i in range(3):
			if p.distance_to(CENTERS[i]) <= 45:
				slots[i] = picked
				break
		picked = -1
		queue_redraw()

func transmission() -> Dictionary:
	if slots.has(-1):
		return {"valid": false, "reason": "还有空轴，先安装齿轮。"}
	var links := [[], [], []]
	for i in range(3):
		for j in range(i + 1, 3):
			var distance: float = CENTERS[i].distance_to(CENTERS[j])
			var expected: float = RADII[slots[i]] + RADII[slots[j]]
			if distance < expected - 2.0:
				return {"valid": false, "reason": "齿轮互相挤压，无法转动。"}
			if absf(distance - expected) <= 2.0:
				links[i].append(j)
				links[j].append(i)
	var velocity := [0.0, 0.0, 0.0]
	var visited := {0: true}
	var queue: Array[int] = [0]
	velocity[0] = 1.0
	while not queue.is_empty():
		var node: int = queue.pop_front()
		for next in links[node]:
			var next_speed: float = -velocity[node] * RADII[slots[node]] / RADII[slots[next]]
			if visited.has(next):
				if absf(velocity[next] - next_speed) > 0.01:
					return {"valid": false, "reason": "传动方向冲突，机构卡住了。"}
			else:
				visited[next] = true
				velocity[next] = next_speed
				queue.append(next)
	if visited.size() < 3:
		return {"valid": false, "reason": "部分齿轮没有啮合，动力无法传到末端。"}
	return {"valid": true, "speeds": velocity}

func start_test() -> void:
	var result := transmission()
	if not result.valid:
		message = result.reason
		queue_redraw()
		return
	speeds = result.speeds
	angles = [0.0, PI / float(TEETH[slots[1]]), 0.0]
	running = true
	elapsed = 0.0
	message = "传动接通：相邻齿轮反向转动。"
	queue_redraw()

func _process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	for i in range(3):
		angles[i] += float(speeds[i]) * delta
	queue_redraw()
	if elapsed >= 3.0:
		running = false
		solved.emit()

func _draw() -> void:
	var f := _scale_factor()
	draw_set_transform((size - Vector2(724, 724) * f) * 0.5, 0.0, Vector2.ONE * f)
	if board:
		draw_texture_rect(board, Rect2(0, 0, 724, 724), false)
	draw_string(FONT, Vector2(185, 155), "修复齿轮传动", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("f1d39a"))
	draw_string(FONT, Vector2(185, 184), "连接三根轴，将动力从左侧传到右侧。", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("d5e5e4"))
	draw_circle(Vector2(625, 170), 19, Color("78562e"))
	draw_string(FONT, Vector2(619, 178), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("fff1ce"))
	for i in range(3):
		draw_circle(CENTERS[i], 13, Color("886c47"))
		if slots[i] >= 0:
			_draw_gear(CENTERS[i], slots[i], angles[i], 1.0)
	for i in range(3):
		if i not in slots and i != picked:
			_draw_gear(TRAY[i], i, 0, 0.43)
	if picked >= 0:
		_draw_gear(cursor, picked, 0, 0.65)
	draw_rect(Rect2(492, 575, 166, 62), Color("78562e"))
	draw_rect(Rect2(492, 575, 166, 62), Color("d3ad70"), false, 2)
	draw_string(FONT, Vector2(525, 615), "试转", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	draw_string(FONT, Vector2(105, 653), message, HORIZONTAL_ALIGNMENT_LEFT, 530, 16, Color("e8d8b4"))
	draw_set_transform(Vector2.ZERO)

func _draw_gear(center: Vector2, gear: int, angle: float, scale_value: float) -> void:
	var r: float = RADII[gear] * scale_value
	var count: int = TEETH[gear]
	var points := PackedVector2Array()
	for i in range(count * 4):
		var theta := TAU * float(i) / float(count * 4) + angle
		var radius := r * (1.08 if i % 4 in [1, 2] else 0.92)
		points.append(center + Vector2.from_angle(theta) * radius)
	var shadow := PackedVector2Array()
	for point in points:
		shadow.append(point + Vector2(3, 5) * scale_value)
	draw_colored_polygon(shadow, Color(0.01, 0.03, 0.04, 0.65))
	if metal_texture:
		var uv := PackedVector2Array()
		for point in points:
			var local := (point - center) / (2.2 * r) + Vector2(0.5, 0.5)
			uv.append((Vector2(870, 240) + local * Vector2(420, 230)) / metal_texture.get_size())
		draw_polygon(points, PackedColorArray([Color.WHITE]), uv, metal_texture)
	else:
		draw_colored_polygon(points, Color("91602b"))
	draw_arc(center, r * 0.82, 0, TAU, 64, Color("b4823c"), 5 * scale_value, true)
	draw_arc(center, r * 0.82, PI * 1.05, PI * 1.9, 32, Color("ffe09a"), 3 * scale_value, true)
	draw_arc(center, r * 0.72, 0, TAU, 64, Color("e7c17a"), 4 * scale_value, true)
	for i in range(4):
		var a := angle + float(i) * PI / 2.0
		draw_line(center + Vector2.from_angle(a) * r * 0.37, center + Vector2.from_angle(a) * r * 0.67, Color("805326"), 6 * scale_value, true)
	draw_circle(center, r * 0.30, Color("25343a"))
	draw_arc(center, r * 0.30, 0, TAU, 48, Color("e7c17a"), 3 * scale_value, true)
