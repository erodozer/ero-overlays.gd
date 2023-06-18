extends EventQueue

func accept_command(type, event):
	return type == Tmi.EventType.FOLLOW
	
func process_event(_type, event):
	%Label.text = "%s is following" % event.user.display_name
	%AnimationPlayer.play("show")
	
