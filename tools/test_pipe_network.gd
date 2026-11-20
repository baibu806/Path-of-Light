extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var puzzle: Control = load("res://scripts/pipe_network.gd").new()
	root.add_child(puzzle)
	puzzle.size = Vector2(724, 724)
	puzzle.reset()
	assert(puzzle.pipe_textures.size() == 4)
	assert(not puzzle.inspect_network().success)
	_place(puzzle, 1, Vector2i(0, 0), 1)
	_place(puzzle, 1, Vector2i(2, 0), 2)
	assert(puzzle.inspect_network().success)
	_click(puzzle, Vector2(660, 660), MOUSE_BUTTON_RIGHT)
	assert(puzzle.inspect_network().success)
	_click(puzzle, Vector2(322, 257), MOUSE_BUTTON_RIGHT)
	assert(not puzzle.inspect_network().success)
	for i in range(3):
		_click(puzzle, Vector2(322, 257), MOUSE_BUTTON_RIGHT)
	assert(puzzle.inspect_network().success)
	_click(puzzle, Vector2(410, 608), MOUSE_BUTTON_LEFT)
	assert(puzzle.complete)
	puzzle.reset()
	assert(puzzle.pieces.size() == 3 and not puzzle.complete)
	puzzle.free()
	print("PIPE_NETWORK_UI_OK")
	quit()

func _place(puzzle: Control, kind: int, cell: Vector2i, rotations: int) -> void:
	var source := Vector2(150, 216 + kind * 93)
	var destination := Vector2(270, 205) + Vector2(cell) * 105 + Vector2(52, 52)
	_button(puzzle, source, MOUSE_BUTTON_LEFT, true)
	_button(puzzle, destination, MOUSE_BUTTON_LEFT, false)
	for i in range(rotations):
		_click(puzzle, destination, MOUSE_BUTTON_RIGHT)

func _click(puzzle: Control, p: Vector2, button: int) -> void:
	_button(puzzle, p, button, true)
	_button(puzzle, p, button, false)

func _button(puzzle: Control, p: Vector2, button: int, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = p
	event.button_index = button as MouseButton
	event.pressed = pressed
	puzzle._gui_input(event)
