extends Control

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	
	position.x -= 20
	position.y += 20
