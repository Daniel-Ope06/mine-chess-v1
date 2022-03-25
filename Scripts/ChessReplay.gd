extends Node2D

# Mouse cursors
onready var mouse = $Sprites/MouseCursor
const cursor = preload("res://Assets/Others/item_2_flip.png")
var mouse_pos

const mine_tile = preload("res://Chess Pieces/HighlightMine.tscn")
const chess_notation = preload("res://Chess Pieces/NotationSymbol.tscn")

const chess_pieces = [
	preload("res://Chess Pieces/Black/BlackRook.tscn"),
	preload("res://Chess Pieces/Black/BlackKnight.tscn"),
	preload("res://Chess Pieces/Black/BlackBishop.tscn"),
	preload("res://Chess Pieces/Black/BlackPawn.tscn"),
	preload("res://Chess Pieces/Black/BlackKing.tscn"),
	preload("res://Chess Pieces/Black/BlackQueen.tscn"),
	
	preload("res://Chess Pieces/White/WhiteRook.tscn"),
	preload("res://Chess Pieces/White/WhiteKnight.tscn"),
	preload("res://Chess Pieces/White/WhiteBishop.tscn"),
	preload("res://Chess Pieces/White/WhitePawn.tscn"),
	preload("res://Chess Pieces/White/WhiteKing.tscn"),
	preload("res://Chess Pieces/White/WhiteQueen.tscn")
]

const piece_textures = [
	preload("res://Assets/Pieces/Black/black_rook.png"),
	preload("res://Assets/Pieces/Black/black_knight.png"),
	preload("res://Assets/Pieces/Black/black_bishop.png"),
	preload("res://Assets/Pieces/Black/black_queen.png"),
	
	preload("res://Assets/Pieces/White/white_rook.png"),
	preload("res://Assets/Pieces/White/white_knight.png"),
	preload("res://Assets/Pieces/White/white_bishop.png"),
	preload("res://Assets/Pieces/White/white_queen.png")
]

var piece_object = []
var piece_type = []
var mineset = []

# Each tile is 32 by 32
var x_start = -112
var y_start = 112
var offset = 32

var pos; var target
var selected_piece; var target_piece
var selected_type; var target_type
var movement_occured = false; var skull = false
var white_turn = true

var piece_notation = {'K':'KING', 'Q':'QUEEN', 'R':'ROOK', 'N':'KNIGHT', 'B':'BISHOP', '':'PAWN', 'M':'MINE', 'S':'SHIELD'}
var pos_notation = ['a','b','c','d','e','f','g','h']
const replay_path = "user://save.txt"
var journal; var counter = 0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	mouse.switch_cursor(cursor, Vector2(1,1), Vector2(-7,-7))
	
	# Chess Pieces
	piece_object = build_2D_array()
	piece_type = build_2D_array()
	spawn_black_pieces()
	spawn_white_pieces()
	
	# Notations
	spawn_letters()
	spawn_numbers()
	
	# Tile Sets
	mineset = build_2D_array()
	build_tileset(mine_tile, mineset)
	hide_tileset(mineset)
	
	
	load_replay()
	print(journal)



# Grid System
func build_2D_array():
	var array = []
	for i in range(8):
		array.append([])
		for j in range(8):
			array[i].append(null)
	return array

func grid_to_pixel(pos):
	var new_x = x_start + (offset * pos.x)
	var new_y = y_start + (-offset * pos.y)
	return Vector2(new_x, new_y)

# Build tiles
func build_tileset(type, set):
	for i in range(8):
		for j in range(8):
			var square = type.instance()
			add_child(square)
			square.position = grid_to_pixel(Vector2(i,j))
			set[i][j] = square

func hide_tileset(set):
	for i in range(8):
		for j in range(8):
			set[i][j].hide()

func show_mines(show):
	if show:
		for i in range(8):
			for j in range(8):
				if piece_type[i][j] == 'MINE':
					mineset[i][j].show()
	if not(show):
		 hide_tileset(mineset)


# Spawn Pieces
func spawn_piece(n, type, pos):
	var piece = chess_pieces[n].instance()
	$ChessPieces.add_child(piece)
	piece.position = grid_to_pixel(pos)
	piece_object[pos.x][pos.y] = piece
	piece_type[pos.x][pos.y] = type

func spawn_black_pieces():
	var black = ['B_ROOK', 'B_KNIGHT', 'B_BISHOP']
	var n = 0; var p = 0
	for piece in black:
		spawn_piece(n, piece, Vector2(p,7))
		spawn_piece(n, piece, Vector2(7-p,7))
		n = n + 1; p = p + 1
	
	for i in range(8):
		spawn_piece(3, 'B_PAWN', Vector2(i,6))
	
	spawn_piece(4, 'B_KING', Vector2(4,7))
	spawn_piece(5, 'B_QUEEN', Vector2(3,7))

func spawn_white_pieces():
	var white = ['W_ROOK', 'W_KNIGHT', 'W_BISHOP']
	var n = 6; var p = 0
	for piece in white:
		spawn_piece(n, piece, Vector2(p,0))
		spawn_piece(n, piece, Vector2(7-p,0))
		n = n + 1; p = p + 1
	
	for i in range(8):
		spawn_piece(9, 'W_PAWN', Vector2(i,1))
	
	spawn_piece(10, 'W_KING', Vector2(4,0))
	spawn_piece(11, 'W_QUEEN', Vector2(3,0))

func spawn_notation(frame: int, pixel_position: Vector2):
	var symbol= chess_notation.instance()
	$Sprites/Notation.add_child(symbol)
	symbol.position = pixel_position
	symbol.frame = frame

func spawn_letters():
	var pos = Vector2(-112, 140)
	for i in range(8):
		spawn_notation(i, pos)
		pos = pos + Vector2(32,0)

func spawn_numbers():
	var pos = Vector2(-138, 112)
	for i in range(26,34):
		spawn_notation(i, pos)
		pos = pos + Vector2(0,-32)


# Movement
func update_array(selected_type, selected_piece, pos, target):
	piece_object[target.x][target.y] = selected_piece
	piece_object[pos.x][pos.y] = null
	
	piece_type[target.x][target.y] = selected_type
	piece_type[pos.x][pos.y] = null

func move_piece(selected_type, selected_piece, pos, target):
	update_array(selected_type, selected_piece, pos, target)
	selected_piece.animate(grid_to_pixel(target))
	#promotion_popup(selected_type, target)
	movement_occured = true

func kill_enemy(selected_type, selected_piece, target_piece, pos, target):
	update_array(selected_type, selected_piece, pos, target)
	target_piece.queue_free()
	selected_piece.animate(grid_to_pixel(target))
	#promotion_popup(selected_type, target)


# Replay System
func load_replay():
	var replay = File.new()
	if replay.file_exists(replay_path):
		var error = replay.open(replay_path, File.READ)
		if error == OK:
			journal = replay.get_var()
			replay.close()
		else:
			print('error')

func next_move():
	var move = journal[counter]
	var pos = Vector2(0,0)
	var target = Vector2(0,0)
	
	# Mines
	if move[0] == 'M':
		# Mine placement
		if not('x' in move):
			pos.x = pos_notation.find(move[1]); pos.y = int(move[2])
			piece_type[pos.x][pos.y] = 'MINE'
		
		# Mine kill
		if 'x' in move:
			pos.x = pos_notation.find(move[2]); pos.y = int(move[3])
			target.x = pos_notation.find(move[5]); target.y = int(move[6])
			
			selected_piece = piece_object[pos.x][pos.y]
			selected_type = piece_type[pos.x][pos.y]
			
		


# Buttons
func _on_NextBtn_pressed() -> void:
	next_move()
	counter = counter + 1
	print(counter)

func _on_MineBtn_pressed() -> void:
	skull = not(skull)
	show_mines(skull)
