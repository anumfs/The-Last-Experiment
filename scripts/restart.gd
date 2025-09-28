extends Control

@onready var restart: Button = $Button

func _ready():
	restart.pressed.connect(_on_restart_pressed)
	
func _on_restart_pressed():
	print("Restarting game...")
	get_tree().change_scene_to_file("res://scenes/main_menu(final).tscn")
