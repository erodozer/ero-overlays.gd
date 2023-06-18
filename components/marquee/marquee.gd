extends HBoxContainer

@export_range(0, 999) var scroll_speed = 10

func _ready():
	build_marquee(%LabelA.text)

func _process(delta):
	position.x -= scroll_speed * delta
	if %Spacer.global_position.x + %Spacer.size.x < 0:
		position.x = 0

func build_marquee(text):
	var width = $LabelA.get_theme_default_font().get_string_size(text)
	var repeat_number = floor(size.x / float(width.x)) + 1
	var message = []
	for i in repeat_number:
		message.append(text)
	text = " :://:: ".join(message)
	
	$LabelA.text = text
	$LabelB.text = text
