extends Node2D

var move_tween
var sprite

func _ready() -> void:
	move_tween = $Tween
	sprite = $Sprite

func animate(target):
	move_tween.interpolate_property(self, "position", position, target, 0.3,
	Tween.TRANS_SINE, Tween.EASE_OUT)
	move_tween.start()

func switch_texture(mat):
	sprite.set_texture(mat)

func show_shield():
	sprite.modulate = Color(1,1,0.4,1)
