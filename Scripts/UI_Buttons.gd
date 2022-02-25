extends Node2D

var sprite
var pos

func _ready() -> void:
	sprite = $Sprite
	pos = sprite.get_position()


func on_hover(frame1, frame2):
	if get_global_mouse_position() == pos:
		sprite.set_frame(frame2)
	else:
		sprite.set_frame(frame1)

