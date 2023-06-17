extends Control

func _on_twitch_command(type, event):
	if type != Tmi.EventType.SUBSCRIPTION:
		return
	
	if event.is_gift:
		%Label.text = "%s has gifted\n%d subs" % [event.user.display_name, event.gifted]
	elif event.total > 1:
		%Label.text = "%s has renewed their league subscription for %d months" % [event.user.display_name, event.total]
	else:
		%Label.text = "%s has joined the league" % event.user.display_name
	%AnimationPlayer.play("show")
	
