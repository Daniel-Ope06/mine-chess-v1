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
	$AnimationPlayer.play("Promotion")
	sprite.hide()
	yield(get_tree().create_timer(0.63), "timeout")
	sprite.set_texture(mat)
	sprite.show()

func show_shield():
	sprite.modulate = Color(1,1,0.4,1)
