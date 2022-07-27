extends Control

onready var mouse = $MouseCursor
const cursor = preload("res://Assets/Others/item_2_flip.png")
var mouse_pos

const chess_notation = preload("res://Chess Pieces/NotationSymbol.tscn")
const notation_table = {'A':0, 'B':1, 'C':2, 'D':3, 'E':4, 'F':5, 'G':6, 'H':7, 'I':8, 'J':9,
'K':10, 'L':11, 'M':12, 'N':13, 'O':14, 'P':15, 'Q':16, 'R':17, 'S':18, 'T':19, 'U':20, 'V':21,
'W':22, 'X':23, 'Y':24, 'Z':25,
'a':36, 'b':37, 'c':38, 'd':39, 'e':40, 'f':41, 'g':42, 'h':43, 'i':44, 'j':45, 'k':46, 'l':47,
'm':48, 'n':49, 'o':50, 'p':51, 'q':52, 'r':53, 's':54, 't':55, 'u':56, 'v':57, 'w':58, 'x':59,
'y':60, 'z':61, ' ':62}


var show = false
var instruction_1 = "LEFT CLICK TO SELECT"
var instruction_2 = "RIGHT CLICK TO SET"
var line1 = Vector2(16, 210)
var line2 = Vector2(line1.x, line1.y+16)


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	mouse.switch_cursor(cursor, Vector2(2,2), Vector2(-7,-7))
	$AnimationPlayer.play("Loop")
	
	spawn_sentence(instruction_1, line1)
	spawn_sentence(instruction_2, line2)

func _on_RestartBtn_pressed() -> void:
	$AudioStreamPlayer.play()
	yield(get_tree().create_timer(0.2), "timeout")
	get_tree().change_scene("res://UI/ChessDisplay.tscn")

func _on_ControlsBtn_pressed() -> void:
	$AudioStreamPlayer.play()
	show = not(show)
	$Instructions.visible = show

func _on_QuitBtn_pressed() -> void:
	$AudioStreamPlayer.play()
	yield(get_tree().create_timer(0.5), "timeout")
	get_tree().quit()


func spawn_character(letter, pixel_pos):
	var frame = notation_table[letter]
	var symbol= chess_notation.instance()
	$Instructions.add_child(symbol)
	symbol.frame = frame
	symbol.position = pixel_pos

func spawn_sentence(sentence, start_pos):
	for character in sentence:
		spawn_character(character, start_pos)
		start_pos += Vector2(12, 0)

