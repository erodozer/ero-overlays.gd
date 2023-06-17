extends Node

const GT2_GDO = preload("res://addons/gt_importer/gdo.gd")

@export var hostname = "https://garage.erodozer.moe"
@export var api_baseurl = "%s/api/" % hostname

func _download(url, save_path):
	var http = HTTPRequest.new()
	add_child(http)
	http.request(url)
	var response = await http.request_completed
	
	if response[1] != 200:
		push_error("asset at %s not found" % url)
		return false
		
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_buffer(response[3])
	file.close()
	
	return true

func _retry(request):
	var response = await request.call()
	
	if response[1] == 404:
		await get_tree().create_timer(1.0).timeout # wait some time and then try again
		response = await request.call()
	
	return response
	
func api_get(url):
	var http = HTTPRequest.new()
	http.accept_gzip = false # disabling gzip because it's broken in html5 for some reason
	add_child(http)
	
	var response = await _retry(
		func ():
			http.request(
				api_baseurl + url, 
				[],
				HTTPClient.METHOD_GET
			)
			var response = await http.request_completed
			return response
	)
	http.queue_free()
	
	if response != null and response[1] == 200:
		return JSON.parse_string(response[3].get_string_from_utf8())
	return null
	
func get_user_car(twitch_id):
	var profile = await api_get("user/%s" % twitch_id)
	if profile == null:
		return
	
	var car = await get_car(profile.driving.car_id)
	GT2_GDO.apply_palette(
		car,
		profile.driving.color
	)
	
	return car

## Fetches a car from remote storage (supabase/s3 object store)
func get_car(id):
	DirAccess.make_dir_recursive_absolute("user://cars")
	DirAccess.make_dir_recursive_absolute("user://.tmp")
	
	var save_path = "user://cars/%s.scn" % id
	
	var try_load = ResourceLoader.load(save_path)
	if try_load != null:
		return try_load.instantiate()
	
	var asset_urls = await api_get("assets/car/%s" % id)
	
	await _download(asset_urls.scn, save_path)
	
	try_load = ResourceLoader.load(save_path)
	if try_load != null:
		return try_load.instantiate()
	
	push_error("failed to import %s" % save_path)
	return null
