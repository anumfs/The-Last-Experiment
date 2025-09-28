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
