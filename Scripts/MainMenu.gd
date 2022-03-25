extends Control

onready var mouse = $MouseCursor
const cursor = preload("res://Assets/Others/item_2_flip.png")
var mouse_pos

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	mouse.switch_cursor(cursor, Vector2(2,2), Vector2(-7,-7))
	$AnimationPlayer.play("Loop")

func _on_RestartBtn_pressed() -> void:
	get_tree().change_scene("res://UI/ChessDisplay.tscn")

func _on_QuitBtn_pressed() -> void:
	get_tree().quit()
