extends EventQueue

const YIPPEE_ID = "6518c704-4ba6-43b2-85fa-5b69d4fe9c06"

func accept_command(type, event):
	if type != Tmi.EventType.REDEEM:
		return false
		
	var id = event.reward.id
	
	if id != YIPPEE_ID:
		return false
	
	return true

func process_event(type, event):
	%Label.text = "%s YIPPEE" % event.user.display_name
	%AnimationPlayer.play("show")
	
