# BANNED ITEM SCRIPT
# Attach this to each banned item scene (bannedflask1.tscn, bannedcomputer.tscn, etc.)

extends Area2D

@export var flask_type: String = "bannedflask1"  # Set in Inspector for each scene
signal flask_touched(type: String)

func _ready():
	print("Banned item ", flask_type, " ready at position: ", global_position)
	add_to_group("banned_items")
	
	# Visual indicator - red tint
	modulate = Color(1, 0.7, 0.7)  # Light red tint
	
	# Connect collision detection
	body_entered.connect(_on_body_entered)
	
	# Also add mouse click detection as backup
	input_event.connect(_on_input_event)
	
	# Make sure monitoring is enabled
	monitoring = true
	monitorable = true

func _on_body_entered(body):
	print("Something entered banned item ", flask_type, ": ", body.name)
	if body.is_in_group("player"):
		print("PLAYER HIT BANNED ITEM: ", flask_type)
		flask_touched.emit(flask_type)
	else:
		print("Non-player entered banned item: ", body.name)

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("MOUSE CLICKED BANNED ITEM: ", flask_type)
			flask_touched.emit(flask_type)
