extends SceneTree

func _initialize() -> void:
	var train: Control = load("res://scripts/gear_train_puzzle.gd").new()
	root.add_child(train)
	train.size = Vector2(724, 724)
	train.reset()
	assert(not train.transmission().valid)
	_place(train, 0, 0)
	_place(train, 2, 1)
	_place(train, 1, 2)
	assert(not train.transmission().valid)
	train.reset()
	_place(train, 0, 0)
	_place(train, 1, 1)
	_place(train, 2, 2)
	var result: Dictionary = train.transmission()
	assert(result.valid)
	assert(is_equal_approx(result.speeds[1], -50.0 / 70.0))
	assert(is_equal_approx(result.speeds[2], 50.0 / 90.0))
	_click(train, Vector2(550, 600), true)
	_click(train, Vector2(550, 600), false)
	assert(train.running)
	train._process(1.0)
	assert(train.angles[0] > 0 and train.angles[1] < 0 and train.angles[2] > 0)
	train.reset()
	assert(not train.running and train.slots == [-1, -1, -1])
	train.free()
	print("GEAR_TRAIN_UI_OK")
	quit()

func _place(train: Control, gear: int, slot: int) -> void:
	_click(train, train.TRAY[gear], true)
	_click(train, train.CENTERS[slot], false)

func _click(train: Control, p: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = p
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	train._gui_input(event)
