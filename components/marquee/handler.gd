extends EventQueue

const YIPPEE_ID = "6518c704-4ba6-43b2-85fa-5b69d4fe9c06"
const MIKU_ID = "87560ec9-8491-4461-b5e4-af6681326c06"
const MAX_HISTORY = 5
var notifications = []
var initial_text = ""

signal update_text(notifications)

func _ready():
	super._ready()
	initial_text = %LabelA.text
	_push_notification(initial_text)

func reset():
	notifications = []
	_push_notification(initial_text)

func accept_command(type, event):
	if type == Tmi.EventType.REDEEM and event.reward.id in [YIPPEE_ID, MIKU_ID]:
		return true
	
	return type in [
		Tmi.EventType.FOLLOW,
		Tmi.EventType.SUBSCRIPTION,
	]

func _push_notification(text):
	notifications.append(text)
	if len(notifications) > MAX_HISTORY:
		notifications.pop_front()
	
	var joined_text = " :://:: ".join(notifications)
	update_text.emit(joined_text)
	

func process_event(type, event):
	var text = ""
	
	if type == Tmi.EventType.FOLLOW:
		text = "%s is following" % event.user.display_name
	elif type == Tmi.EventType.SUBSCRIPTION:
		if event.is_gift:
			text = "%s gifted\n%d subs" % [event.user.display_name, event.gifted]
		else:
			text = "%s subscribed" % event.user.display_name
	elif type == Tmi.EventType.REDEEM:
		if event.reward.id == YIPPEE_ID:
			text = "%s Yippee" % event.user.display_name
		elif event.reward.id == MIKU_ID:
			text = "%s summoned a miku" % event.user.display_name
	
	_push_notification(text)
