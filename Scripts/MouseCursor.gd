extends Sprite

func _process(_delta) -> void:
	position = get_global_mouse_position()

func switch_texture(mat):
	set_texture(mat)
