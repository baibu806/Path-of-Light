extends SceneTree

func _initialize() -> void:
	var circuit: Control = load("res://scripts/circuit_network.gd").new()
	root.add_child(circuit)
	circuit.size = Vector2(724, 724)
	circuit.reset()
	_wire(circuit, 0, 1)
	_click(circuit, Vector2(280, 350), MOUSE_BUTTON_LEFT)
	assert(not circuit.switch_on and not circuit.complete, "A direct short must trip the switch")
	_click(circuit, circuit.POINTS[0], MOUSE_BUTTON_RIGHT)
	assert(circuit.wires.is_empty())
	_click(circuit, Vector2(420, 350), MOUSE_BUTTON_LEFT)
	assert(circuit.fuse_installed)
	_wire(circuit, 0, 2)
	_wire(circuit, 3, 4)
	_wire(circuit, 5, 6)
	_wire(circuit, 7, 1)
	assert(not circuit._reachable(false), "Open switch must break the circuit")
	_click(circuit, Vector2(280, 350), MOUSE_BUTTON_LEFT)
	assert(circuit.complete and circuit.switch_on)
	circuit.reset()
	assert(circuit.wires.is_empty() and not circuit.fuse_installed and not circuit.complete)
	circuit.free()
	print("CIRCUIT_NETWORK_UI_OK")
	quit()

func _wire(circuit: Control, from: int, to: int) -> void:
	_button(circuit, circuit.POINTS[from], MOUSE_BUTTON_LEFT, true)
	_button(circuit, circuit.POINTS[to], MOUSE_BUTTON_LEFT, false)

func _click(circuit: Control, p: Vector2, button: int) -> void:
	_button(circuit, p, button, true)
	_button(circuit, p, button, false)

func _button(circuit: Control, p: Vector2, button: int, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = p
	event.button_index = button as MouseButton
	event.pressed = pressed
	circuit._gui_input(event)
