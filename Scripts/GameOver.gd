extends Control

const cursor = preload("res://Assets/Others/item_2_flip.png")

# Textures
const book = [
	preload("res://Assets/Others/book_brown.png"), # white won
	preload("res://Assets/Others/book_blue.png")   # black won
]

const background = [
	preload("res://Assets/Transition Pics/Riding-Knight.jpg"), # white won
	preload("res://Assets/Transition Pics/Queen-Pawn.png")     # black won
]

func set_winner(white_won: bool):
	if white_won:
		$Book.set_texture(book[0])
		$Background.set_texture(background[0])
	if not(white_won):
		$Book.set_texture(book[1])
		$Background.set_texture(background[1])

func _on_RestartBtn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene("res://UI/ChessDisplay.tscn")

func _on_HomeBtn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene("res://UI/MainMenu.tscn")
