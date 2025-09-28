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
