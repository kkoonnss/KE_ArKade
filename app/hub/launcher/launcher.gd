extends Node
class_name HubLauncher

signal cartridge_ready
signal cartridge_error(err_msg)
signal cartridge_score(score_data)
signal cartridge_player_joined(player_id)
signal cartridge_exited(clean)
signal ipc_log(msg)

const HEARTBEAT_INTERVAL = 1.0 # 1000ms
const MAX_MISSED_HEARTBEATS = 3

var tcp_server: TCPServer
var peer: StreamPeerTCP
var active_pid: int = -1
var time_since_last_heartbeat: float = 0.0
var missed_beats: int = 0
var running: bool = false
var port: int = 0

func _ready():
	tcp_server = TCPServer.new()
	# Find open port
	for p in range(50000, 60000):
		if tcp_server.listen(p, "127.0.0.1") == OK:
			port = p
			break
	print("Hub IPC Server listening on port: ", port)

func _process(delta):
	if not running:
		return
		
	# Check if the process has closed externally
	if active_pid > 0 and not OS.is_process_running(active_pid):
		active_pid = -1
		running = false
		if peer:
			peer.disconnect_from_host()
			peer = null
		emit_signal("ipc_log", "Process exited externally (clean exit)")
		emit_signal("cartridge_exited", true)
		return
		
	if tcp_server.is_connection_available():
		if peer == null or not peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			peer = tcp_server.take_connection()
			time_since_last_heartbeat = 0.0
			missed_beats = 0
			emit_signal("ipc_log", "Cartridge connected to socket")
			
	if peer != null and peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		peer.poll()
		while peer.get_available_bytes() > 0:
			var line = peer.get_string(peer.get_available_bytes())
			var messages = line.split("\n", false)
			for msg in messages:
				_handle_message(msg)
				
		time_since_last_heartbeat += delta
		if time_since_last_heartbeat >= HEARTBEAT_INTERVAL:
			time_since_last_heartbeat = 0.0
			missed_beats += 1
			if missed_beats >= MAX_MISSED_HEARTBEATS:
				emit_signal("ipc_log", "Cartridge missed 3 heartbeats. Terminating.")
				kill_cartridge()
	else:
		# Startup connection timeout
		time_since_last_heartbeat += delta
		if time_since_last_heartbeat >= 10.0:
			emit_signal("ipc_log", "Cartridge failed to connect within 10 seconds. Terminating.")
			kill_cartridge()

func _handle_message(msg_str: String):
	var json = JSON.new()
	if json.parse(msg_str) == OK:
		var msg = json.data
		if not typeof(msg) == TYPE_DICTIONARY or not msg.has("type"):
			return
			
		var type = msg["type"]
		emit_signal("ipc_log", "Received: " + msg_str.strip_edges())
		if type == "heartbeat":
			missed_beats = 0
		elif type == "ready":
			emit_signal("cartridge_ready")
		elif type == "score":
			emit_signal("cartridge_score", msg.get("data", {}))
		elif type == "player_joined":
			emit_signal("cartridge_player_joined", msg.get("player_id", 0))
		elif type == "error":
			emit_signal("cartridge_error", msg.get("message", "Unknown error"))
			
func launch(launch_cmd: String, args_template: String, scene_dir: String, level_dir: String):
	if running:
		emit_signal("ipc_log", "Stopping current running cartridge for new launch")
		stop_cartridge()
		
	var args_str = args_template.replace("<scene_dir>", scene_dir).replace("<level_dir>", level_dir).replace("<socket>", str(port))
	var final_cmd = launch_cmd + " " + args_str
	
	# Split command into executable and arguments for OS.create_process, respecting quotes
	var parts = []
	var current_part = ""
	var in_quotes = false
	var idx = 0
	while idx < final_cmd.length():
		var ch = final_cmd[idx]
		if ch == '"':
			in_quotes = not in_quotes
		elif ch == ' ' and not in_quotes:
			if current_part != "":
				parts.append(current_part)
				current_part = ""
		else:
			current_part += ch
		idx += 1
	if current_part != "":
		parts.append(current_part)
		
	var exe = parts[0]
	var args = []
	for k in range(1, parts.size()):
		args.append(parts[k])
		
	emit_signal("ipc_log", "Launching: " + final_cmd)
	
	emit_signal("ipc_log", "DEBUG EXE: " + exe)
	emit_signal("ipc_log", "DEBUG ARGS: " + str(args))
	emit_signal("ipc_log", "DEBUG CWD: " + OS.get_executable_path().get_base_dir())
	active_pid = OS.create_process(exe, args)
	if active_pid > 0:
		running = true
		missed_beats = 0
		time_since_last_heartbeat = 0.0
		if peer:
			peer.disconnect_from_host()
			peer = null
	else:
		emit_signal("ipc_log", "Failed to start process")
		emit_signal("cartridge_error", "Failed to start process")

func send_message(type: String, data: Dictionary = {}):
	if peer != null and peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var msg = {"type": type}
		for k in data.keys():
			msg[k] = data[k]
		var str_data = JSON.stringify(msg) + "\n"
		emit_signal("ipc_log", "Sending: " + str_data.strip_edges())
		peer.put_data(str_data.to_utf8_buffer())

func stop_cartridge():
	if active_pid > 0:
		OS.kill(active_pid)
		active_pid = -1
	running = false
	if peer:
		peer.disconnect_from_host()
		peer = null
	emit_signal("ipc_log", "Cartridge stopped cleanly by hub")
	emit_signal("cartridge_exited", true)

func kill_cartridge():
	if active_pid <= 0 and not running and peer == null:
		emit_signal("ipc_log", "Force kill requested, but no cartridge process is active")
		return
	if active_pid > 0:
		OS.kill(active_pid)
		active_pid = -1
	running = false
	if peer:
		peer.disconnect_from_host()
		peer = null
	emit_signal("ipc_log", "Cartridge force killed (abnormal exit)")
	emit_signal("cartridge_exited", false)
