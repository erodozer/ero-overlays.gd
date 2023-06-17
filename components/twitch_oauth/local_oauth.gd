extends HttpRouter

signal success(credentials)

# Handle a GET request
func handle_get(request: HttpRequest, response: HttpResponse) -> void:
	if not request.query.has("access_token"):
		response.send(400, "missing access token")
		return
	
	var newCredentials = TwitchCredentials.new()
	newCredentials.token = request.query.get("access_token")
	newCredentials.refresh_token = ""
	
	response.send(200, "Session recorded, you can now close this window.")
	
	success.emit(newCredentials)
	
