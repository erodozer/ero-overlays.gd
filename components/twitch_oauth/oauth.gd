extends Node

@onready var tmi = get_parent() as Tmi
		
func auth_url(client_id, scopes):
	randomize()
	return ("https://id.twitch.tv/oauth2/authorize?response_type=token&redirect_uri=%s&state=%s&client_id=%s&scope=%s" % [
		"http://localhost:3000".uri_encode(),
		randi(),
		client_id,
		" ".join(scopes).uri_encode()
	])

func poll_local(channel, client_id, client_secret = "", scopes = []):
	var server = HttpServer.new()
	var auth_handler = preload("./local_oauth.gd").new()
	server.register_router("/", HttpFileRouter.new("res://components/twitch_oauth"))
	server.register_router("/auth", auth_handler)
	server.port = 3000
	add_child(server)
	server.start()
	
	var cleanup = func (_credentials):
		if server == null:
			return
		if server.is_processing():
			server.stop()
			server.queue_free()
			server = null
	
	await get_tree().process_frame
	
	auth_handler.success.connect(
		func (newCredentials: TwitchCredentials):
			newCredentials.channel = channel
			newCredentials.client_id = client_id
			newCredentials.client_secret = client_secret
			
			# get user info for token provider
			var user = await tmi.twitch_api.http("users", newCredentials)
			if user:
				newCredentials.user_id = user.data[0].id
				newCredentials.bot_id = user.data[0].login
			var broadcaster = await tmi.twitch_api.http("users?login=%s" % newCredentials.channel, newCredentials)
			if broadcaster:
				newCredentials.broadcaster_user_id = broadcaster.data[0].id
				
			tmi._set_credentials(newCredentials)
	)
	
	var kill_timer = get_tree().create_timer(60.0)
	kill_timer.timeout.connect(cleanup)
	tmi.credentials_updated.connect(cleanup, CONNECT_ONE_SHOT)
	
	OS.shell_open(auth_url(client_id, scopes))
