extends Sprite

func _process(_delta) -> void:
	position = get_global_mouse_position()

func switch_cursor(mat, size : Vector2, pos : Vector2):
	set_texture(mat)
	set_scale(size)
	offset = pos
