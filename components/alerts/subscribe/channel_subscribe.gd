extends EventQueue

func accept_command(type, event):
	return type == Tmi.EventType.SUBSCRIPTION
	
func process_event(_type, event):
	if event.is_gift:
		%Label.text = "%s has gifted\n%d subs" % [event.user.display_name, event.gifted]
	elif event.total > 1:
		%Label.text = "%s has renewed their league subscription for %d months" % [event.user.display_name, event.total]
	else:
		%Label.text = "%s has joined the league" % event.user.display_name
	%AnimationPlayer.play("show")
	await %AnimationPlayer.animation_finished
	
