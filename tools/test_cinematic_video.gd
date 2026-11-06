extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for music_path in [
		"res://assets/audio/cinematic/opening_celtic_storm_v1.mp3",
		"res://assets/audio/cinematic/ending_celtic_dawn_v1.mp3"
	]:
		var music: AudioStream = load(music_path)
		if music == null or music.get_length() < 60.0:
			push_error("Cinematic score missing or too short: " + music_path)
			quit(1)
			return
	for name in ["opening", "ending"]:
		var path: String = "res://assets/cinematic/video/%s.ogv" % name
		var stream: VideoStream = load(path)
		if stream == null:
			push_error("Cannot load cinematic: " + path)
			quit(1)
			return
		var player := VideoStreamPlayer.new()
		player.size = Vector2(1536, 864)
		player.expand = true
		player.stream = stream
		root.add_child(player)
		player.play()
		for frame in range(90):
			await process_frame
		if not player.is_playing() or player.stream_position <= 0.0:
			push_error("Cinematic did not advance: " + path)
			quit(1)
			return
		print("CINEMATIC_OK ", name, " position=", player.stream_position)
		player.stop()
		player.queue_free()
		await process_frame
	var shell = load("res://scenes/game_shell.tscn").instantiate()
	root.add_child(shell)
	await process_frame
	shell._start_opening()
	await process_frame
	if not shell.opening_root.visible or not shell.opening_video.is_playing() or not shell.opening_music.playing:
		push_error("Opening UI did not start video and score together")
		quit(1)
		return
	shell._finish_opening()
	for frame in range(180):
		await process_frame
		if not shell.opening_root.visible and is_instance_valid(shell.game):
			break
	if shell.opening_root.visible or not is_instance_valid(shell.game):
		push_error("Opening skip did not enter the game")
		quit(1)
		return
	if shell.opening_music.playing:
		push_error("Opening score continued after the cinematic")
		quit(1)
		return
	for frame in range(180):
		await process_frame
		if not shell.transition_fade.visible:
			break
	if shell.transition_fade.visible:
		push_error("Opening transition did not finish")
		quit(1)
		return
	shell._show_ending({})
	await process_frame
	if not shell.ending_root.visible or not shell.ending_video.is_playing() or not shell.ending_music.playing or shell.game.ambient.playing:
		push_error("Ending UI did not start video and score together")
		quit(1)
		return
	shell._skip_or_leave_ending()
	if not shell.ending_complete or not shell.ending_still.visible:
		push_error("Ending skip did not show the final frame")
		quit(1)
		return
	if shell.ending_music.playing:
		push_error("Ending score continued after skipping the cinematic")
		quit(1)
		return
	shell._skip_or_leave_ending()
	await process_frame
	if not shell.menu_root.visible or shell.ending_root.visible:
		push_error("Ending did not return to the title menu")
		quit(1)
		return
	print("CINEMATIC_FLOW_OK")
	shell.queue_free()
	await process_frame
	quit(0)
