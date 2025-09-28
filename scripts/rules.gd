extends Control

@onready var button: Button = $Button

func _ready():
	button.pressed.connect(_on_back_pressed)
	
func _on_back_pressed():
	print("Going back to start scene...")
	get_tree().change_scene_to_file("res://scenes/main_menu(final).tscn")
