extends Node2D

# Textures
const book = [
	preload("res://Assets/Others/book_brown.png"), # white won
	preload("res://Assets/Others/book_blue.png")   # black won
]

func _ready() -> void:
	visible = false

func set_winner(white_won: bool):
	if white_won:
		$Background/Book.set_texture(book[0])
	if not(white_won):
		$Background/Book.set_texture(book[1])

func _on_HomeBtn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene("res://UI/MainMenu.tscn")

func _on_ReplayBtn_pressed() -> void:
	get_tree().change_scene("res://UI/ChessReplay.tscn")
