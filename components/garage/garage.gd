extends Control

var socket: WebSocketPeer
var socket_id: String
var hello_sent = false

@export var tmi: Tmi

var notification_queue = []

func msgid():
	var ch = "abcdefghijklmnopqrstuvwxyz0123456789"
	var id = ""
	for i in range(32):
		id += ch[randi() % len(ch)]
	return id

# Called when the node enters the scene tree for the first time.
func _ready():
	connect_to_server()
	
	var connection_check = Timer.new()
	connection_check.timeout.connect(
		func ():
			if socket == null:
				connect_to_server()
	)
	add_child(connection_check)
	connection_check.start(5.0)
	
	%Raid.tmi = tmi
	%Raid.remote = %RemoteStorage
	
func connect_to_server():
	var ws = WebSocketPeer.new()
	ws.connect_to_url("wss://garage.erodozer.moe/api/events")
	
	socket = ws
	hello_sent = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if socket == null:
		return
	
	socket.poll()
	
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if not hello_sent:
			socket.send_text(JSON.stringify({
				"type": "hello",
				"id": msgid(),
				"version": "2",
				"subs": ["/all"]
			}))
			hello_sent = true
		
		# read current received packets until end of buffer
		while socket.get_available_packet_count():
			_handle_packet(socket.get_packet())
			
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("Garage WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		socket = null

func _handle_packet(packet):
		# parse packet as list of json messages
	var event = packet.get_string_from_utf8()
	
	for message in event.strip_edges().split("\n", false):
		var data = JSON.parse_string(message)
		
		if "statusCode" in data:
			# handle error
			push_warning(data.payload)
			continue
		
		# nes protocol
		match data.type:
			"ping":
				# respond back with a pong
				socket.send_text(JSON.stringify({
					"type": "ping",
					"id": msgid()
				}))
			"hello":
				socket_id = data.socket
			"pub":
				_handle_message(data.message)
				
func _handle_message(payload):
	match payload.head.type:
		"car.acquired":
			var profile = await tmi.twitch.fetch_user(payload.event.twitch_id)
			
			%Username.text = profile.display_name
			%Message.text = "Acquired %s" % payload.event.car.metadata.display_name
			
			var car_model = await $RemoteStorage.get_car(payload.event.car.id)
			if car_model == null:
				return
			
			var car_scn = car_model.instantiate()
			preload("res://addons/gt_importer/gdo.gd").apply_palette(
				car_scn,
				payload.event.car.color
			)
			
			# remove old car
			for c in %Car.get_children():
				c.queue_free()
				
			%Car.add_child(car_scn)
			
			$AnimationPlayer.play("notification")
			
