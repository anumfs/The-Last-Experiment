# INVENTORY UI SCRIPT
extends Control

@onready var f_label: Label = $VBoxContainer/Sprite2D2
@onready var c_label: Label = $VBoxContainer/Sprite2D
@onready var g_label: Label = $VBoxContainer/Sprite2D3

func _ready():
	# Try multiple possible paths to find game manager
	var game_manager = null
	
	# Try different possible paths
	var possible_paths = [
		"/root/Game",        # If scene is named Game
		"../../",            # If UI is child of Game
		"../../../",         # If UI is nested deeper
		get_tree().current_scene  # Current scene
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node and node.has_signal("inventory_changed"):
			game_manager = node
			print("Found game manager at: ", path)
			break
	
	if game_manager:
		game_manager.inventory_changed.connect(_on_inventory_changed)
		print("Inventory UI connected successfully!")
	else:
		print("ERROR: Could not find game manager!")
	
	# Initialize labels
	update_display("C", 0)
	update_display("F", 0)
	update_display("G", 0)

func _on_inventory_changed(item: String, count: int):
	update_display(item, count)

func update_display(item: String, count: int):
	var text = item + ": " + str(count)
	match item:
		"C":
			c_label.text = text
		"F":
			f_label.text = text
		"G":
			g_label.text = text
