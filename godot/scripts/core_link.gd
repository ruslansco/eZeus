extends Node
signal snapshot_received(state: Dictionary)
signal status_changed(message: String)
signal command_completed(command: String, result: Dictionary)

var simulation: RefCounted

func start_embedded(engine: String, save: String, language: String, save_directory := "") -> void:
	if not ClassDB.class_exists("EZeusSimulation"):
		status_changed.emit("Embedded simulation library is missing. Build the Godot extension.")
		return
	simulation = ClassDB.instantiate("EZeusSimulation")
	if save_directory != "":
		simulation.set_save_directory(save_directory)
	var result: Dictionary = simulation.open_city(engine, save, language)
	if result.has("error"):
		status_changed.emit("Core: " + str(result.error))
		simulation.close_city()
		simulation = null
		return
	connected = true
	status_changed.emit("Connected to embedded C++ simulation")
	snapshot_received.emit(result)
	print("EMBEDDED_CORE ", JSON.stringify(simulation.diagnostics()))

# A new game from a listed adventure (see EZeusSimulation.adventures): the first episode opens paused.
func start_adventure(engine: String, kind: String, ref: String, language: String, save_directory := "") -> void:
	if not ClassDB.class_exists("EZeusSimulation"):
		status_changed.emit("Embedded simulation library is missing. Build the Godot extension.")
		return
	var opened: RefCounted = ClassDB.instantiate("EZeusSimulation")
	if save_directory != "":
		opened.set_save_directory(save_directory)
	var result: Dictionary = opened.open_adventure(engine, kind, ref, language)
	if result.has("error"):
		status_changed.emit("Core: " + str(result.error))
		opened.close_city()
		return
	simulation = opened
	connected = true
	status_changed.emit("Connected to embedded C++ simulation")
	snapshot_received.emit(result)

# Takes over a session the start menu already opened (so the adventure is read once, not twice).
func adopt(opened: RefCounted, save_directory := "") -> void:
	simulation = opened
	if save_directory != "":
		simulation.set_save_directory(save_directory)
	connected = true
	status_changed.emit("Connected to embedded C++ simulation")
	snapshot_received.emit(simulation.snapshot(true))

func _exit_tree() -> void:
	if simulation != null:
		simulation.close_city()

var peer := StreamPeerTCP.new()
var port := 0
var incoming := ""
var commands: Array[String] = []
var waiting := false
var elapsed := 0.0
var wait_age := 0.0
var connected := false
# Accepted city actions wait while the world view holds the city. Native world
# dialogs use direct queries; a queued pause must not release this UI hold.
var commands_held := false

func start(value: int) -> void:
	port = value
	var error := peer.connect_to_host("127.0.0.1", port)
	if error != OK:
		status_changed.emit("Core connection failed: %s" % error)

func send(command: String) -> bool:
	if commands.size() < 16:
		commands.append(command)
		return true
	return false

# Read-only native queries stay out of the mutation queue and never advance time.
func query(command: String) -> Dictionary:
	if simulation == null:
		return {"error": "embedded_query_required"}
	return simulation.command(command)

func _process(dt: float) -> void:
	if simulation != null:
		simulation.advance(dt)
		elapsed += dt
		if (not commands_held and not commands.is_empty()) or elapsed >= .1:
			var command: String = commands.pop_front() if not commands_held and not commands.is_empty() else ""
			var result: Dictionary = simulation.command(command) if not command.is_empty() else simulation.snapshot(false)
			if result.has("protocol"):
				snapshot_received.emit(result)
			elif result.has("error"):
				status_changed.emit("Core: " + str(result.error))
			if not command.is_empty():
				command_completed.emit(command, result)
			elapsed = 0
		return
	if port == 0:
		return
	peer.poll()
	var status := peer.get_status()
	if status != StreamPeerTCP.STATUS_CONNECTED:
		if connected or status == StreamPeerTCP.STATUS_ERROR or status == StreamPeerTCP.STATUS_NONE:
			connected = false
			status_changed.emit("Core disconnected. Relaunch the pilot to reconnect.")
			port = 0
		return
	if not connected:
		connected = true
		status_changed.emit("Connected to native simulation")
	elapsed += dt
	if waiting:
		wait_age += dt
		if wait_age > 10.0:
			peer.disconnect_from_host()
			status_changed.emit("Core reply timed out. Relaunch the pilot.")
			return
	var count := peer.get_available_bytes()
	if count > 0:
		var result := peer.get_data(count)
		if result[0] != OK:
			return
		incoming += result[1].get_string_from_utf8()
		if incoming.length() > 2097152:
			peer.disconnect_from_host()
			return
		var newline := incoming.find("\n")
		if newline >= 0:
			var state = JSON.parse_string(incoming.left(newline))
			incoming = incoming.substr(newline + 1)
			waiting = false
			wait_age = 0.0
			if state is Dictionary:
				if state.has("protocol"):
					snapshot_received.emit(state)
				elif state.has("error"):
					status_changed.emit("Core: " + str(state.error))
	if not waiting and (not commands.is_empty() or elapsed >= .1):
		var command: String = commands.pop_front() if not commands.is_empty() else "snapshot"
		if peer.put_data((command + "\n").to_utf8_buffer()) == OK:
			waiting = true
			wait_age = 0.0
			elapsed = 0.0
