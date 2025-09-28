# FLASK COLLECTION SCRIPT
# Attach this to each collectible flask scene (blueflask.tscn, reddropper.tscn, etc.)

extends Area2D

@export var flask_type: String = "A"  # Set in Inspector for each scene
signal flask_touched(type: String)

func _ready():
	print("Flask ", flask_type, " ready at position: ", global_position)
	add_to_group("flasks")
	
	# Connect collision detection
	body_entered.connect(_on_body_entered)
	
	# Also add mouse click detection as backup
	input_event.connect(_on_input_event)
	
	# Make sure monitoring is enabled
	monitoring = true
	monitorable = true

func _on_body_entered(body):
	print("Something entered flask ", flask_type, ": ", body.name)
	if body.is_in_group("player"):
		print("PLAYER COLLECTED FLASK: ", flask_type)
		flask_touched.emit(flask_type)
	else:
		print("Non-player entered flask: ", body.name, " - Groups: ", body.get_groups())

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("MOUSE CLICKED FLASK: ", flask_type)
			flask_touched.emit(flask_type)
