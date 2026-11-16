extends SceneTree


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var RI: GDScript = load("res://scripts/repair_interaction.gd")

	# 1) Scrambled completion on a sequence task (floor 0, task 1, four steps).
	var sequence: Control = RI.new()
	root.add_child(sequence)
	sequence.configure(0, 1)
	var sequence_mistakes: Array = []
	sequence.mistake.connect(func(message: String) -> void: sequence_mistakes.append(message))
	assert(sequence._kind() == "sequence")
	assert(sequence._step_count() == 4)
	var scrambled := [2, 0, 3, 1]
	for step_index in scrambled:
		assert(not sequence.is_step_done(step_index), "Step unexpectedly done before click")
		sequence.press_art_sequence(step_index)
		assert(sequence.is_step_done(step_index), "Step did not register out of order")
		assert(sequence.completed_count() == sequence.stage)
	assert(sequence.finished, "Scrambled sequence never finished")
	assert(sequence.completed_count() == 4 and sequence.stage == 4)
	# Out-of-order is allowed, so no "wrong order" mistake is emitted.
	assert(sequence_mistakes.is_empty(), "Unexpected mistake on valid order")
	assert(sequence.help_hint().is_empty(), "help_hint should be empty after finish")

	# 2) Scrambled completion on a drag task (floor 1, task 1, three parts).
	var drag: Control = RI.new()
	root.add_child(drag)
	drag.configure(1, 1)
	assert(drag._kind() == "drag")
	drag.drop_art_part(2)
	drag.drop_art_part(0)
	assert(drag.is_step_done(2) and drag.is_step_done(0) and not drag.is_step_done(1))
	assert(drag.completed_count() == 2 and not drag.finished)

	# 3) Three-tier hints on repeated failures, then a success resets the streak.
	var hint_messages: Array = []
	drag.mistake.connect(func(message: String) -> void: hint_messages.append(message))
	drag.fail_art_drop(1)
	drag.fail_art_drop(1)
	drag.fail_art_drop(1)
	assert(drag.mistake_streak == 3, "Streak did not accumulate")
	assert(hint_messages.size() == 3, "Each failure must emit one hint")
	assert(hint_messages[0] != hint_messages[1] and hint_messages[1] != hint_messages[2], "Hint levels must differ")
	assert(drag.help_hint().length() > 0, "help_hint must guide the unfinished step")
	drag.drop_art_part(1)
	assert(drag.mistake_streak == 0, "Success must reset the streak")
	assert(drag.finished and drag.completed_count() == 3)

	# 4) Sequence-drop failure also emits escalating hints.
	var other: Control = RI.new()
	root.add_child(other)
	other.configure(1, 0)  # sequence, three steps
	var other_messages: Array = []
	other.mistake.connect(func(message: String) -> void: other_messages.append(message))
	other.fail_sequence_drop(0)
	other.fail_sequence_drop(0)
	assert(other.mistake_streak == 2 and other_messages.size() == 2)
	assert(other_messages[0] != other_messages[1])

	print("PARALLEL_ORDER_OK scrambled_sequence=4 scrambled_drag=3 hint_tiers=3 streak_reset=ready")
	quit()
