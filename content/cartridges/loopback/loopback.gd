extends Node

var peer = StreamPeerTCP.new()
var connected = false
var time_since_heartbeat = 0.0

func _ready():
    var args = OS.get_cmdline_user_args()
    var port = 50000
    for i in range(args.size()):
        if args[i] == "--ipc" and i + 1 < args.size():
            port = args[i+1].to_int()
            break
            
    print("Loopback connecting to port: ", port)
    peer.connect_to_host("127.0.0.1", port)

func _process(delta):
    peer.poll()
    if peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
        if not connected:
            connected = true
            send_message("ready")
            
        while peer.get_available_bytes() > 0:
            var line = peer.get_string(peer.get_available_bytes())
            print("Loopback received: ", line)
            var messages = line.split("\n", false)
            for msg in messages:
                _handle_message(msg)
                
        time_since_heartbeat += delta
        if time_since_heartbeat >= 1.0:
            time_since_heartbeat = 0.0
            send_message("heartbeat")
    elif connected:
        get_tree().quit()

func _handle_message(msg_str: String):
    var json = JSON.new()
    if json.parse(msg_str) == OK:
        var data = json.data
        if typeof(data) == TYPE_DICTIONARY and data.has("type"):
            var type = data["type"]
            if type == "quit":
                get_tree().quit()
            elif type == "blank":
                $ColorRect.color = Color(0,0,0,1)

func send_message(type: String, data: Dictionary = {}):
    var msg = {"type": type}
    for k in data.keys():
        msg[k] = data[k]
    var str_data = JSON.stringify(msg) + "\n"
    peer.put_data(str_data.to_utf8_buffer())
