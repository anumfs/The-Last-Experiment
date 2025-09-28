# START SCENE
extends Control


@onready var start_button: Button = $VBoxContainer/Button
@onready var rules_button: Button = $VBoxContainer/Button2

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	rules_button.pressed.connect(_on_rules_pressed)

func _on_start_pressed():
	print("Going to main game...")
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_rules_pressed():
	print("Going to rules page...")
	get_tree().change_scene_to_file("res://scenes/rules_page.tscn")

#RULES
extends Control

@onready var button: Button = $Button

func _ready():
	button.pressed.connect(_on_back_pressed)
	
func _on_back_pressed():
	print("Going back to start scene...")
	get_tree().change_scene_to_file("res://scenes/main_menu(final).tscn")

#RESTART
extends Control

@onready var restart: Button = $Button

func _ready():
	restart.pressed.connect(_on_restart_pressed)
	
func _on_restart_pressed():
	print("Restarting game...")
	get_tree().change_scene_to_file("res://scenes/main_menu(final).tscn")

#GAME
# === GAME MANAGER SCRIPT (Main Scene) ===
# Updated for separate flask scenes (FlaskA.tscn, FlaskB.tscn, etc.)
extends Node2D

# Define your mixing recipes (order matters!)
var recipes = {
	["A", "B"]: "C",
	["B", "A"]: "C",  # Same result, different order
	["D", "E"]: "F",
	["E", "D"]: "F"   # Same result, different order
}

var current_sequence = []
var blocked_flasks = []

# inventory tracking - Only C, F, G
var inventory = {
	"C": 0,
	"F": 0,
	"G": 0
}

# health system
@export var max_health: int = 3
var current_health: int = 3

#banned items
var banned_items = ["bannedflask1", "bannedflask2", "bannedjar", "bannedcomputer"]

signal inventory_changed(item: String, count: int)
signal health_changed(new_health: int)

func _ready():
	# Initialize health
	current_health = max_health
	
	# Connect all flask and banned item signals
	print("=== GAME MANAGER STARTING ===")
	connect_all_objects()
	
	# Debug: Check what's in the scene
	var all_flasks = get_tree().get_nodes_in_group("flasks")
	print("Total flasks found: ", all_flasks.size())
	for flask in all_flasks:
		if flask.has_method("get") and flask.get("flask_type"):
			print("Flask found: ", flask.flask_type, " at ", flask.position)
		else:
			print("Flask found but no flask_type property")

func connect_all_objects():
	# Connect regular flasks (A, B, C, D, E, F, G)
	connect_flask_type("A")
	connect_flask_type("B")
	connect_flask_type("C")
	connect_flask_type("D")
	connect_flask_type("E")
	connect_flask_type("F")
	connect_flask_type("G")
	
	# Connect banned items
	connect_banned_type("bannedflask1")
	connect_banned_type("bannedflask2")
	connect_banned_type("bannedjar")
	connect_banned_type("bannedcomputer")

func connect_flask_type(flask_type: String):
	# Find all instances of this flask type
	var flask_nodes = get_tree().get_nodes_in_group("flask_" + flask_type.to_lower())
	if flask_nodes.is_empty():
		# Fallback: try generic "flasks" group
		flask_nodes = get_tree().get_nodes_in_group("flasks")
		flask_nodes = flask_nodes.filter(func(node): return node.has_method("get") and node.get("flask_type") == flask_type)
	
	print("Looking for flask type: ", flask_type, " - Found: ", flask_nodes.size(), " instances")
	
	for flask in flask_nodes:
		if flask.has_signal("flask_touched"):
			if not flask.flask_touched.is_connected(_on_flask_touched):
				flask.flask_touched.connect(_on_flask_touched)
				print("✅ Connected flask: ", flask_type)
			else:
				print("⚠ Flask already connected: ", flask_type)
		else:
			print("❌ Flask missing 'flask_touched' signal: ", flask_type)

func connect_banned_type(banned_type: String):
	# Find all instances of this banned type
	var banned_nodes = get_tree().get_nodes_in_group("banned_" + banned_type.to_lower())
	if banned_nodes.is_empty():
		# Fallback: try generic "banned_items" group
		banned_nodes = get_tree().get_nodes_in_group("banned_items")
		banned_nodes = banned_nodes.filter(func(node): return node.flask_type == banned_type)
	
	for banned in banned_nodes:
		if banned.has_signal("flask_touched") and not banned.flask_touched.is_connected(_on_flask_touched):
			banned.flask_touched.connect(_on_flask_touched)
			print("Connected banned item: ", banned_type)

func _on_flask_touched(flask_type: String):
	print("Touched: ", flask_type)
	
	# Check if banned item
	if flask_type in banned_items:
		handle_banned_item(flask_type)
		return
	
	# Check if inventory item (C, F, G) - collect immediately
	if flask_type in inventory.keys():
		collect_inventory_item(flask_type)
		return
	
	# Check if blocked
	if flask_type in blocked_flasks:
		print(flask_type, " is blocked! Complete current recipe first.")
		return
	
	# Add to sequence for mixing
	current_sequence.append(flask_type)
	print("Current sequence: ", current_sequence)
	
	# Remove clicked flask immediately
	remove_flask_from_scene(flask_type)
	
	# Check for recipe completion
	check_for_recipe()

func remove_flask_from_scene(flask_type: String):
	# Try specific group first
	var flasks = get_tree().get_nodes_in_group("flask_" + flask_type.to_lower())
	if flasks.is_empty():
		# Fallback to generic group
		flasks = get_tree().get_nodes_in_group("flasks")
		flasks = flasks.filter(func(node): return node.flask_type == flask_type)
	
	# Remove the first instance found
	for flask in flasks:
		if flask.flask_type == flask_type:
			# Visual feedback
			flask.modulate = Color.GREEN
			var tween = create_tween()
			tween.tween_property(flask, "scale", Vector2.ZERO, 0.3)
			tween.tween_callback(flask.queue_free)
			break

func remove_banned_from_scene(item_type: String):
	# Try specific group first
	var banned_objects = get_tree().get_nodes_in_group("banned_" + item_type.to_lower())
	if banned_objects.is_empty():
		# Fallback to generic group
		banned_objects = get_tree().get_nodes_in_group("banned_items")
		banned_objects = banned_objects.filter(func(node): return node.flask_type == item_type)
	
	# Remove the first instance found
	for banned in banned_objects:
		if banned.flask_type == item_type:
			banned.modulate = Color.RED
			var tween = create_tween()
			tween.tween_property(banned, "modulate:a", 0.0, 0.5)
			tween.tween_callback(banned.queue_free)
			break

func collect_inventory_item(item_type: String):
	# Add to inventory
	inventory[item_type] += 1
	print("Collected ", item_type, "! Total: ", inventory[item_type])
	
	# Remove from scene
	remove_flask_from_scene(item_type)
	
	# Update UI
	inventory_changed.emit(item_type, inventory[item_type])
	print_inventory()
	
	# Check win condition
	check_win_condition()

func handle_banned_item(item_type: String):
	print("Hit banned item: ", item_type, "! Losing 1 heart!")
	
	# Decrease health
	current_health -= 1
	current_health = max(current_health, 0)
	
	# Update UI
	health_changed.emit(current_health)
	print("Hearts remaining: ", current_health)
	
	# Remove banned item with red effect
	remove_banned_from_scene(item_type)
	
	# Check game over
	if current_health <= 0:
		game_over()

func check_for_recipe():
	# Check if we have a complete recipe
	for recipe_ingredients in recipes.keys():
		if arrays_equal(current_sequence, recipe_ingredients):
			var result = recipes[recipe_ingredients]
			print("Recipe complete! Created: ", result)
			spawn_result(result)
			reset_sequence()
			return
		
		# Check if current sequence is start of this recipe
		if is_sequence_start(current_sequence, recipe_ingredients):
			block_other_flasks(recipe_ingredients)
			return
	
	# No matching recipe found
	print("No recipe matches, resetting...")
	reset_sequence()

func is_sequence_start(current: Array, recipe: Array) -> bool:
	if current.size() > recipe.size():
		return false
	
	for i in range(current.size()):
		if current[i] != recipe[i]:
			return false
	return true

func arrays_equal(arr1: Array, arr2: Array) -> bool:
	if arr1.size() != arr2.size():
		return false
	for i in range(arr1.size()):
		if arr1[i] != arr2[i]:
			return false
	return true

func block_other_flasks(recipe_ingredients: Array):
	blocked_flasks.clear()
	
	# Block all flasks not in current recipe
	var all_types = ["A", "B", "C", "D", "E", "F", "G"]
	for flask_type in all_types:
		if not flask_type in recipe_ingredients:
			blocked_flasks.append(flask_type)
	
	print("Blocked flasks: ", blocked_flasks)

func spawn_result(result_type: String):
	print("Spawning ", result_type)
	
	# Map your actual scene file names
	var scene_mapping = {
		"C": "res://scenes/greenfinaltube.tscn",  # Based on your scene file
		"F": "res://scenes/bluefinalflask.tscn",  # Based on your scene file  
		"G": "res://scenes/redfinalflask.tscn"    # Based on your scene file
	}
	
	var flask_scene_path = scene_mapping.get(result_type, "res://scenes/" + result_type.to_lower() + "flask.tscn")
	var flask_scene = load(flask_scene_path)
	
	if flask_scene == null:
		print("Error: Could not load ", flask_scene_path)
		print("Available scenes should be: ", scene_mapping)
		return
	
	# Create new flask instance
	var new_flask = flask_scene.instantiate()
	
	# Position it somewhere visible
	new_flask.position = Vector2(400, 300)  # Adjust as needed
	
	add_child(new_flask)
	
	# Connect the signal
	if new_flask.has_signal("flask_touched"):
		new_flask.flask_touched.connect(_on_flask_touched)
		print("✅ Connected spawned flask: ", result_type)
	else:
		print("❌ Spawned flask missing signal: ", result_type)
	
	# Visual spawn effect
	new_flask.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(new_flask, "scale", Vector2.ONE, 0.5)

func reset_sequence():
	current_sequence.clear()
	blocked_flasks.clear()
	print("Sequence reset - all flasks available again")

func print_inventory():
	print("=== INVENTORY ===")
	for item in inventory.keys():
		if inventory[item] > 0:
			print(item, ": ", inventory[item])
	print("================")

func check_win_condition():
	# Check if player has collected at least one of each: C, F, G
	if inventory["C"] > 0 and inventory["F"] > 0 and inventory["G"] > 0:
		print("YOU WIN! Collected all required items!")
		game_win()

func game_win():
	print("VICTORY! All flasks collected!")
	get_tree().change_scene_to_file("res://scenes/game win.tscn")

func game_over():
	print("GAME OVER! No hearts left!")
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")

#FLASK
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

#PLAYER
extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@export var speed := 300

# In your player script _ready() function:
func _ready():
	add_to_group("player")
	print("Player added to group") 

func _physics_process(delta: float) -> void:
	# Get input direction for 8-directional movement
	var input_vector = Vector2.ZERO
	
	# Check for input and set animations
	if Input.is_action_pressed("MoveUp"):
		input_vector.y -= 1
	if Input.is_action_pressed("Move Down"):
		input_vector.y += 1
	if Input.is_action_pressed("Move Right"):
		input_vector.x += 1
	if Input.is_action_pressed("Move Left"):
		input_vector.x -= 1
	
	# Normalize for consistent diagonal movement speed
	input_vector = input_vector.normalized()
	
	# Set velocity
	velocity = input_vector * speed
	
	# Handle animations based on movement direction
	if input_vector != Vector2.ZERO:
		# Moving - determine primary direction for animation
		if abs(input_vector.x) > abs(input_vector.y):
			# Horizontal movement is stronger
			if input_vector.x > 0:
				anim.play("move_right")
			else:
				anim.play("move_left")
		else:
			# Vertical movement is stronger
			if input_vector.y < 0:
				anim.play("move_up")
			else:
				anim.play("move_down")
	else:
		# Not moving
		anim.play("idle")
	
	# Apply movement with collision detection
	move_and_slide()

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

#ZOMBIE
extends CharacterBody2D

@export var speed: float = 100
@export var change_interval: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var timer: float = 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	pick_new_direction()
	timer = change_interval

func _physics_process(delta):
	timer -= delta
	if timer <= 0:
		pick_new_direction()
		timer = change_interval

	velocity = direction * speed
	move_and_slide()

	# Agar collision hua, direction change kar do
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and not collider.is_in_group("player"):
			pick_new_direction()
			timer = change_interval
			break

func pick_new_direction():
	var choices = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	direction = choices[randi() % choices.size()]

func _on_AttackArea_body_entered(body):
	if body.is_in_group("player"):
		anim.play("attack")
		$AttackArea/AudioStreamPlayer2D.play()  # <-- if you added an AudioStreamPlayer2D node
