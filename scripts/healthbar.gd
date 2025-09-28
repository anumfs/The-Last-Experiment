# HEALTH UI SCRIPT
extends Control

@onready var heart1: Sprite2D = $HBoxContainer/Sprite2D
@onready var heart2: Sprite2D = $HBoxContainer/Sprite2D2
@onready var heart3: Sprite2D = $HBoxContainer/Sprite2D3

var hearts = []

func _ready():
	hearts = [heart1, heart2, heart3]
	
	# Try multiple possible paths to find game manager
	var game_manager = null
	
	var possible_paths = [
		"/root/Game",
		"../../", 
		"../../../",
		get_tree().current_scene
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node and node.has_signal("health_changed"):
			game_manager = node
			print("Found game manager at: ", path)
			break
	
	if game_manager:
		game_manager.health_changed.connect(_on_health_changed)
		print("Health UI connected successfully!")
	else:
		print("ERROR: Could not find game manager for health!")

func _on_health_changed(new_health: int):
	print("Hearts remaining: ", new_health)
	
	# Show/hide hearts
	for i in range(hearts.size()):
		hearts[i].visible = (i < new_health)
