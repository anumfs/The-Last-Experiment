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
	
	print("Flask ", flask_type, " is ready and clickable!")

func _on_body_entered(body):
	print("Something entered flask ", flask_type, ": ", body.name)
	if body.is_in_group("player"):
		print("PLAYER COLLECTED FLASK: ", flask_type)
		flask_touched.emit(flask_type)
	else:
		print("Non-player entered flask: ", body.name, " - Groups: ", body.get_groups())

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		print("CLICKED FLASK: ", flask_type)
		flask_touched.emit(flask_type)
			

		
func _input_event(viewport, event, shape_idx):
	# Backup method
	if event is InputEventMouseButton and event.pressed:
		print("BACKUP CLICK - FLASK: ", flask_type)
		flask_touched.emit(flask_type)
