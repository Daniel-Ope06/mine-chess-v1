extends Node2D

# TO DO
## Replay system

# Mouse cursors
onready var mouse = $Sprites/MouseCursor
const cursor = preload("res://Assets/Others/item_2_flip.png")
const mine_cursor = preload("res://Assets/Others/item_14.png")
const shield_cursor = preload("res://Assets/Others/shield_gold.png")
var mouse_pos

# Scenes
const gameOver = preload("res://UI/GameOver.tscn")

# Tiles
const tile = preload("res://Chess Pieces/HighlightTile.tscn")
const mine_tile = preload("res://Chess Pieces/HighlightMine.tscn")
const shield_tile = preload("res://Chess Pieces/HighlightShield.tscn")

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

const chess_notation = preload("res://Chess Pieces/NotationSymbol.tscn")

var piece_object = []
var piece_type = []
var tileset = []
var mineset = []
var shieldset = []

# Each tile is 32 by 32
var x_start = -112
var y_start = 112
var offset = 32

# Click variables
var first_click = Vector2(0,0)
var final_click = Vector2(0,0)
var pos; var target
var selected_piece; var target_piece
var selected_type; var target_type
var controlling = false; var movement_occured = false
var mine_control = false
var white_turn = true
var pop_up_books = false
var is_paused = false


# Gold system
var black_gold = 9; var white_gold = 9
var black_mine = 1; var white_mine = 1
var black_shield = 1; var white_shield = 1
var arrow_action; var shield_color = Color(0.878431, 0.733333, 0.388235)
onready var mine_number = $GoldSysten/PopUpBook/Numbers/MineNumber
onready var shield_number = $GoldSysten/PopUpBook/Numbers/ShieldNumber
var piece_value = {'PAWN':1, 'KNIGHT':3, 'BISHOP':3, 'ROOK':5, 'QUEEN':9, 'KING':0, 'MINE':3, 'SHIELD':5}
var button_frame = {'0':27, '1':5, '2':6, '3':7, '4':8, '5':9, '6':15, '7':16, '8':17, '9':18, '10':19} #score:frame

# TODO: Replay system
## Notation rules
# King : K, Queen : Q, Rook : R, Knight : N, Bishop : B, Pawn : '', Mine : M, Shield : S
# Mine placement : Mc3; Shield placemment : SQe4, Se4
# Move piece: Ng1-f3, e4-e5; Kill piece : Nxg1-f3, xe4-d5; Mine kill : Mxc3
# Check: +; Checkmate: #
var piece_notation = {'KING':'K', 'QUEEN':'Q', 'ROOK':'R', 'KNIGHT':'N', 'BISHOP':'B', 'PAWN':'', 'MINE':'M', 'SHIELD':'S'}
var pos_notation = ['a','b','c','d','e','f','g','h']
var journal = []



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
	tileset = build_2D_array()
	mineset = build_2D_array()
	shieldset = build_2D_array()
	build_tileset(tile, tileset)
	build_tileset(mine_tile, mineset)
	build_tileset(shield_tile, shieldset)
	hide_tileset(tileset)
	hide_tileset(mineset)
	hide_tileset(shieldset)
	
	# Hide these
	$PawnPromotion.hide()
	$GoldSysten/PopUpBook.hide()
	
	# Gold, Shield & Mines
	mine_number.set_frame(5)
	shield_number.set_frame(5)
	
	# Test pieces for pawn promotion
#	spawn_piece(9, 'W_PAWN', Vector2(6,5))
#	spawn_piece(3, 'B_PAWN', Vector2(5,2))


func _process(_delta) -> void:
	mouse_pos = get_global_mouse_position()
	show_path(); choose_path()
	place_mine();set_mine()
	place_shield(); set_shield()
	gold_popup(); display_gold()
	display_numbers(); update_numbers()
	disable_btn()
	display_CheckAndCheckmate()


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

func pixel_to_grid(pixel):
	var new_x = round((pixel.x - x_start) / offset)
	var new_y = round((pixel.y - y_start) / -offset)
	return Vector2(new_x, new_y)

func inside_grid(pos):
	if pos.x >= 0 and pos.x <= 7:
		if pos.y >= 0 and pos.y <= 7:
			return true
	return false


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


# Chess piece paths
func show_path():
	movement_occured = false
	if Input.is_action_just_pressed("ui_click") and (mouse.texture == cursor):
		first_click = get_global_mouse_position()
		pos = pixel_to_grid(first_click)
		
		if inside_grid(pos):
			selected_piece = piece_object[pos.x][pos.y]
			selected_type = piece_type[pos.x][pos.y]
			piece_path(selected_type, selected_piece, pos)
			controlling = true

func choose_path():
	if Input.is_action_just_pressed("ui_right_click") and controlling and (mouse.texture == cursor):
		final_click = get_global_mouse_position()
		target = pixel_to_grid(final_click)
		var notation
		
		if inside_grid(target) and controlling:
			controlling = false
			var target_piece = piece_object[target.x][target.y]
			var target_type = piece_type[target.x][target.y]
			if tileset[target.x][target.y].visible:
				var piece = piece_notation[selected_type.substr(2,len(selected_type))]
				
				# move to empty tile
				if target_type == null:
					move_piece(selected_type, selected_piece, pos, target)
					notation = piece + pos_notation[pos.x] + str(pos.y+1) + '-' + pos_notation[target.x] + str(target.y+1)
					
				# kill enemy
				if target_type != null and target_type != 'MINE':
					kill_enemy(selected_type, selected_piece, target_piece, pos, target)
					gold_count(target_type, selected_type)
					notation = piece + 'x' + pos_notation[pos.x] + str(pos.y+1) + '-' + pos_notation[target.x] + str(target.y+1)
					movement_occured = true
				
				if target_type == 'MINE':
					move_piece(selected_type, selected_piece, pos, target)
					var x = ''
					if selected_piece.get_color() != shield_color:
						gold_count(target_type, selected_type)
						x = 'x'
					stepped_on_mine(target, selected_piece, selected_type)
					notation = piece_notation['MINE'] +  x + pos_notation[pos.x] + str(pos.y+1) + '-' + pos_notation[target.x] + str(target.y+1)
					movement_occured = true
		
		if movement_occured:
			white_turn = not(white_turn)
			journal.append(notation)
		hide_tileset(tileset)
		hide_tileset(mineset)

func piece_path(selected_type, selected_piece, pos):
	hide_tileset(tileset)
	hide_tileset(mineset)
	
	if selected_piece != null:
		pawn_path(selected_type, pos)
		
		if selected_type == 'W_KNIGHT' and white_turn:
			knight_path(selected_type, pos)
		if selected_type == 'B_KNIGHT' and not(white_turn):
			knight_path(selected_type, pos)
		
		if selected_type == 'W_BISHOP' and white_turn:
			bishop_path(selected_type, pos)
		if selected_type == 'B_BISHOP' and not(white_turn):
			bishop_path(selected_type, pos)
			
		if selected_type == 'W_ROOK' and white_turn:
			rook_path(selected_type, pos)
		if selected_type == 'B_ROOK' and not(white_turn):
			rook_path(selected_type, pos)
			
		if selected_type == 'W_QUEEN' and white_turn:
			queen_path(selected_type, pos)
		if selected_type == 'B_QUEEN' and not(white_turn):
			queen_path(selected_type, pos)
			
		if selected_type == 'W_KING' and white_turn:
			king_path(selected_type, pos)
		if selected_type == 'B_KING' and not(white_turn):
			king_path(selected_type, pos)

func pawn_path(selected_type, pos):
	if selected_type == 'W_PAWN' and white_turn:
		# move path
		if pos.y == 1:
			if piece_object[pos.x][pos.y+1] == null:
				tileset[pos.x][pos.y+1].show()
				if piece_object[pos.x][pos.y+2] == null:
					tileset[pos.x][pos.y+2].show()
		
		if pos.y != 1 and inside_grid(Vector2(pos.x, pos.y+1)):
			if (piece_object[pos.x][pos.y+1] == null): 
				tileset[pos.x][pos.y+1].show()
		
		# kill path diagonal
		## right
		if inside_grid(Vector2(pos.x-1,pos.y+1)):
			if piece_type[pos.x-1][pos.y+1] != null:
				if 'B_' in piece_type[pos.x-1][pos.y+1]:
					tileset[pos.x-1][pos.y+1].show()
		## left
		if inside_grid(Vector2(pos.x+1,pos.y+1)):
			if piece_type[pos.x+1][pos.y+1] != null:
				if 'B_' in piece_type[pos.x+1][pos.y+1]:
					tileset[pos.x+1][pos.y+1].show()
	
	if selected_type == 'B_PAWN' and not(white_turn):
		# move path
		if pos.y == 6:
			if piece_object[pos.x][pos.y-1] == null:
				tileset[pos.x][pos.y-1].show()
				if piece_object[pos.x][pos.y-2] == null:
					tileset[pos.x][pos.y-2].show()
		
		if pos.y != 6 and inside_grid(Vector2(pos.x, pos.y-1)):
			if (piece_object[pos.x][pos.y-1] == null): 
				tileset[pos.x][pos.y-1].show()
		
		# kill path diagonal
		## right
		if inside_grid(Vector2(pos.x-1,pos.y-1)):
			if piece_type[pos.x-1][pos.y-1] != null:
				if 'W_' in piece_type[pos.x-1][pos.y-1]:
					tileset[pos.x-1][pos.y-1].show()
		## left
		if inside_grid(Vector2(pos.x+1,pos.y-1)):
			if piece_type[pos.x+1][pos.y-1] != null:
				if 'W_' in piece_type[pos.x+1][pos.y-1]:
					tileset[pos.x+1][pos.y-1].show()

func knight_path(selected_type, pos):
	var pos1 = Vector2(pos.x-2, pos.y+1); var pos2 = Vector2(pos.x+2, pos.y+1)
	var pos3 = Vector2(pos.x-2, pos.y-1); var pos4 = Vector2(pos.x+2, pos.y-1)
	var pos5 = Vector2(pos.x-1, pos.y+2); var pos6 = Vector2(pos.x+1, pos.y+2)
	var pos7 = Vector2(pos.x-1, pos.y-2); var pos8 = Vector2(pos.x+1, pos.y-2)
	var path = [pos1,pos2,pos3,pos4,pos5,pos6,pos7,pos8]
	
	for posI in path:
		if inside_grid(posI):
			if (piece_type[posI.x][posI.y] == null) or (piece_type[posI.x][posI.y] == 'MINE') or (('B_' in piece_type[posI.x][posI.y]) and ('W_' in selected_type)) or (('W_' in piece_type[posI.x][posI.y]) and ('B_' in selected_type)):
				tileset[posI.x][posI.y].show()

func bishop_path(selected_type, pos):
	var i_UpLeft = 1
	var i_UpRight = 1
	var i_DownLeft = 1
	var i_DownRight = 1
	
	# UpLeft
	while inside_grid(Vector2(pos.x-i_UpLeft, pos.y+i_UpLeft)) and piece_object[pos.x-i_UpLeft][pos.y+i_UpLeft] == null:
		tileset[pos.x-i_UpLeft][pos.y+i_UpLeft].show()
		i_UpLeft = i_UpLeft + 1
	if inside_grid(Vector2(pos.x-i_UpLeft, pos.y+i_UpLeft)) and ((('W_' in selected_type) and ('B_' in piece_type[pos.x-i_UpLeft][pos.y+i_UpLeft])) or (('B_' in selected_type) and ('W_' in piece_type[pos.x-i_UpLeft][pos.y+i_UpLeft]))):
		tileset[pos.x-i_UpLeft][pos.y+i_UpLeft].show()
	
	# UpRight
	while inside_grid(Vector2(pos.x+i_UpRight, pos.y+i_UpRight)) and piece_object[pos.x+i_UpRight][pos.y+i_UpRight] == null:
		tileset[pos.x+i_UpRight][pos.y+i_UpRight].show()
		i_UpRight = i_UpRight + 1
	if inside_grid(Vector2(pos.x+i_UpRight, pos.y+i_UpRight)) and (('W_' in selected_type) and ('B_' in piece_type[pos.x+i_UpRight][pos.y+i_UpRight]) or (('B_' in selected_type) and ('W_' in piece_type[pos.x+i_UpRight][pos.y+i_UpRight]))):
		tileset[pos.x+i_UpRight][pos.y+i_UpRight].show()
	
	# DownLeft
	while inside_grid(Vector2(pos.x-i_DownLeft, pos.y-i_DownLeft)) and piece_object[pos.x-i_DownLeft][pos.y-i_DownLeft] == null:
		tileset[pos.x-i_DownLeft][pos.y-i_DownLeft].show()
		i_DownLeft = i_DownLeft + 1
	if inside_grid(Vector2(pos.x-i_DownLeft, pos.y-i_DownLeft)) and ((('W_' in selected_type) and ('B_' in piece_type[pos.x-i_DownLeft][pos.y-i_DownLeft])) or (('B_' in selected_type) and ('W_' in piece_type[pos.x-i_DownLeft][pos.y-i_DownLeft]))):
		tileset[pos.x-i_DownLeft][pos.y-i_DownLeft].show()
	
	# DownRight
	while inside_grid(Vector2(pos.x+i_DownRight, pos.y-i_DownRight)) and piece_object[pos.x+i_DownRight][pos.y-i_DownRight] == null:
		tileset[pos.x+i_DownRight][pos.y-i_DownRight].show()
		i_DownRight = i_DownRight + 1
	if inside_grid(Vector2(pos.x+i_DownRight, pos.y-i_DownRight)) and ((('W_' in selected_type) and ('B_' in piece_type[pos.x+i_DownRight][pos.y-i_DownRight])) or (('B_' in selected_type) and ('W_' in piece_type[pos.x+i_DownRight][pos.y-i_DownRight]))):
		tileset[pos.x+i_DownRight][pos.y-i_DownRight].show()

func rook_path(selected_type, pos):
	var i_Up = 1
	var i_Right = 1
	var i_Down = 1
	var i_Left = 1
	
	# Up
	while inside_grid(Vector2(pos.x, pos.y+i_Up)) and piece_object[pos.x][pos.y+i_Up] == null:
		tileset[pos.x][pos.y+i_Up].show()
		i_Up = i_Up + 1
	if inside_grid(Vector2(pos.x, pos.y+i_Up)) and ((('W_' in selected_type) and ('B_' in piece_type[pos.x][pos.y+i_Up])) or (('B_' in selected_type) and ('W_' in piece_type[pos.x][pos.y+i_Up]))):
		tileset[pos.x][pos.y+i_Up].show()
		
	# Right
	while inside_grid(Vector2(pos.x+i_Right, pos.y)) and piece_object[pos.x+i_Right][pos.y] == null:
		tileset[pos.x+i_Right][pos.y].show()
		i_Right = i_Right + 1
	if inside_grid(Vector2(pos.x+i_Right, pos.y)) and ((('W_' in selected_type) and ('B_' in piece_type[pos.x+i_Right][pos.y])) or (('B_' in selected_type) and ('W_' in piece_type[pos.x+i_Right][pos.y]))):
		tileset[pos.x+i_Right][pos.y].show()
		
	# Down
	while inside_grid(Vector2(pos.x, pos.y-i_Down)) and piece_object[pos.x][pos.y-i_Down] == null:
		tileset[pos.x][pos.y-i_Down].show()
		i_Down = i_Down + 1
	if inside_grid(Vector2(pos.x, pos.y-i_Down)) and ((('W_' in selected_type) and ('B_' in piece_type[pos.x][pos.y-i_Down])) or (('B_' in selected_type) and ('W_' in piece_type[pos.x][pos.y-i_Down]))):
		tileset[pos.x][pos.y-i_Down].show()
		
	# Left
	while inside_grid(Vector2(pos.x-i_Left, pos.y)) and piece_object[pos.x-i_Left][pos.y] == null:
		tileset[pos.x-i_Left][pos.y].show()
		i_Left = i_Left + 1
	if inside_grid(Vector2(pos.x-i_Left, pos.y)) and ((('W_' in selected_type) and ('B_' in piece_type[pos.x-i_Left][pos.y])) or (('B_' in selected_type) and ('W_' in piece_type[pos.x-i_Left][pos.y]))):
		tileset[pos.x-i_Left][pos.y].show()

func queen_path(selected_type, pos):
	bishop_path(selected_type, pos)
	rook_path(selected_type, pos)

func king_path(selected_type, pos):
	var pos1 = Vector2(pos.x-1, pos.y);   var pos2 = Vector2(pos.x+1, pos.y)
	var pos3 = Vector2(pos.x-1, pos.y-1); var pos4 = Vector2(pos.x+1, pos.y-1)
	var pos5 = Vector2(pos.x-1, pos.y+1); var pos6 = Vector2(pos.x+1, pos.y+1)
	var pos7 = Vector2(pos.x, pos.y-1); var pos8 = Vector2(pos.x, pos.y+1)
	var path = [pos1,pos2,pos3,pos4,pos5,pos6,pos7,pos8]
	
	var turn
	if white_turn:
		turn = 'W_'
	if not(white_turn):
		turn = 'B_'
	
	for posI in path:
		if inside_grid(posI) and not(in_check(posI, turn)):
			if (piece_type[posI.x][posI.y] == null) or (('B_' in piece_type[posI.x][posI.y]) and ('W_' in selected_type)) or (('W_' in piece_type[posI.x][posI.y]) and ('B_' in selected_type)):
				tileset[posI.x][posI.y].show()
		if inside_grid(posI) and (piece_type[posI.x][posI.y] == 'MINE'):
			mineset[posI.x][posI.y].show()


# Movement
func update_array(selected_type, selected_piece, pos, target):
	piece_object[target.x][target.y] = selected_piece
	piece_object[pos.x][pos.y] = null
	
	piece_type[target.x][target.y] = selected_type
	piece_type[pos.x][pos.y] = null

func move_piece(selected_type, selected_piece, pos, target):
	update_array(selected_type, selected_piece, pos, target)
	if is_valid():
		selected_piece.animate(grid_to_pixel(target))
		promotion_popup(selected_type, target)
		movement_occured = true
	else:
		update_array(selected_type, selected_piece, target, pos)

func kill_enemy(selected_type, selected_piece, target_piece, pos, target):
	update_array(selected_type, selected_piece, pos, target)
	target_piece.queue_free()
	selected_piece.animate(grid_to_pixel(target))
	promotion_popup(selected_type, target)

func stepped_on_mine(target, selected_piece, selected_type):
	if selected_piece.get_color() == Color(1,1,1,1):
		yield(get_tree().create_timer(0.6), "timeout")
		selected_piece.explode()
		yield(get_tree().create_timer(1.0), "timeout")
		selected_piece.queue_free()
		piece_type[target.x][target.y] = null
		piece_object[target.x][target.y] = null
	
	if selected_piece.get_color() == shield_color:
		yield(get_tree().create_timer(0.6), "timeout")
		selected_piece.explode()
		yield(get_tree().create_timer(1.0), "timeout")
		piece_type[target.x][target.y] = selected_type
		piece_object[target.x][target.y] = selected_piece

func is_valid():
	var king_pos; var turn
	if white_turn == true:
		king_pos = find_index('W_KING')
		turn = 'W_'
	if white_turn == false:
		king_pos = find_index('B_KING')
		turn = 'B_'
	
	if in_check(king_pos, turn):
		return false
	if not(in_check(king_pos, turn)):
		return true


# Special functions
func promotion_popup(selected_type, target):
	if 'PAWN' in selected_type:
		if target.y == 7:
			$PawnPromotion.show()
			$PawnPromotion/PopUp/WhiteButtons.show()
			$PawnPromotion/PopUp/BlackButtons.hide()
		if target.y == 0:
			$PawnPromotion.show()
			$PawnPromotion/PopUp/WhiteButtons.hide()
			$PawnPromotion/PopUp/BlackButtons.show()

func promote_to(promotion, chess_piece,  pos, sprite):
	piece_object[pos.x][pos.y].switch_texture(null)
	var piece = chess_pieces[chess_piece].instance()
	$ChessPieces.add_child(piece)
	piece.position = grid_to_pixel(pos)
	piece_object[pos.x][pos.y] = piece
	piece_type[pos.x][pos.y] = promotion
	piece_object[pos.x][pos.y].switch_texture(piece_textures[sprite])

func in_check(pos, turn):
	var path_up = check_path(pos, Vector2(0, 1)); var path_down = check_path(pos, Vector2(0, -1))
	var path_right = check_path(pos, Vector2(1, 0)); var path_left = check_path(pos, Vector2(-1, 0))
	
	var path_up_right = check_path(pos, Vector2(1, 1)); var path_up_left = check_path(pos, Vector2(-1, 1))
	var path_down_right = check_path(pos, Vector2(1, -1)); var path_down_left = check_path(pos, Vector2(-1, -1))
	
	var cross_path = path_up + path_down + path_right + path_left
	var diagonal_path = path_up_right + path_up_left + path_down_right + path_down_left
	
	var path_knight = check_knight(pos)
	
	var T
	if turn == 'W_':
		T = 'B_'
	if turn == 'B_':
		T = 'W_'
	
	if (T+'ROOK' in cross_path) or (T+'QUEEN' in cross_path):
		return true
	
	if (T+'BISHOP' in diagonal_path) or (T+'QUEEN' in diagonal_path):
		return true
	
	for i in path_knight:
		if (i != null) and (T+'KNIGHT' in i):
			return true
	
	var all_paths = [path_up, path_down, path_right, path_left, path_up_right, path_up_left, path_down_right, path_down_left]

	if not(white_turn):
		for i in range(4,6):
			var path = all_paths[i]
			if (len(path)>1) and (path[1] != null) and (T+'PAWN' in path[1]):
				return true
	if white_turn:
		for i in range(6,8):
			var path = all_paths[i]
			if (len(path)>1) and (path[1] != null) and (T+'PAWN' in path[1]):
				return true

	for path in all_paths:
		if (len(path)>1) and (path[1] != null) and (T+'KING' in path[1]):
			return true

func in_checkmate(pos, turn):
	var InCheck = []
	if inCheck_king(pos, 0,1, turn):
		InCheck.append(true)
	if inCheck_king(pos, 0,-1, turn):
		InCheck.append(true)
	if inCheck_king(pos, 1,0, turn):
		InCheck.append(true)
	if inCheck_king(pos, 1,1, turn):
		InCheck.append(true)
	if inCheck_king(pos, 1,-1, turn):
		InCheck.append(true)
	if inCheck_king(pos, -1,0, turn):
		InCheck.append(true)
	if inCheck_king(pos, -1,1, turn):
		InCheck.append(true)
	if inCheck_king(pos, -1,-1, turn):
		InCheck.append(true)
	
	
	var path_up = check_path(pos, Vector2(0, 1)); var path_down = check_path(pos, Vector2(0, -1))
	var path_right = check_path(pos, Vector2(1, 0)); var path_left = check_path(pos, Vector2(-1, 0))

	var path_up_right = check_path(pos, Vector2(1, 1)); var path_up_left = check_path(pos, Vector2(-1, 1))
	var path_down_right = check_path(pos, Vector2(1, -1)); var path_down_left = check_path(pos, Vector2(-1, -1))

	var path_knight = check_knight(pos)

	var T
	if turn == 'W_':
		T = 'B_'
	if turn == 'B_':
		T = 'W_'

	if (T+'ROOK' in path_up):
		InCheck.append(not(in_check(Vector2(pos.x, pos.y + path_up.find(T+'ROOK')), T)))
		var i = 1
		while path_up.find(T+'ROOK') - i > 0:
			InCheck.append(not(block_path(Vector2(pos.x, pos.y + (path_up.find(T+'ROOK') - i)))))
			i = i + 1

	if (T+'QUEEN' in path_up):
		InCheck.append(not(in_check(Vector2(pos.x, pos.y + path_up.find(T+'QUEEN')), T)))
		var i = 1
		while path_up.find(T+'QUEEN') - i > 0:
			InCheck.append(not(block_path(Vector2(pos.x, pos.y + (path_up.find(T+'QUEEN') - i)))))
			i = i + 1

	if (T+'ROOK' in path_down):
		InCheck.append(not(in_check(Vector2(pos.x, pos.y - path_down.find(T+'ROOK')), T)))
		var i = 1
		while path_down.find(T+'ROOK') - i > 0:
			InCheck.append(not(block_path(Vector2(pos.x, pos.y - (path_up.find(T+'ROOK') - i)))))
			i = i + 1

	if (T+'QUEEN' in path_down):
		InCheck.append(not(in_check(Vector2(pos.x, pos.y - path_down.find(T+'QUEEN')), T)))
		var i = 1
		while path_down.find(T+'QUEEN') - i > 0:
			InCheck.append(not(block_path(Vector2(pos.x, pos.y - (path_down.find(T+'QUEEN') - i)))))
			i = i + 1

	if (T+'ROOK' in path_right):
		InCheck.append(not(in_check(Vector2(pos.x  + path_right.find(T+'ROOK'), pos.y), T)))
		var i = 1
		while path_right.find(T+'ROOK') - i > 0:
			InCheck.append(not(block_path(Vector2(pos.x + (path_right.find(T+'ROOK') - i), pos.y))))
			i = i + 1

	if (T+'QUEEN' in path_right):
		InCheck.append(not(in_check(Vector2(pos.x  + path_right.find(T+'QUEEN'), pos.y), T)))
		var i = 1
		while path_right.find(T+'QUEEN') - i > 0:
			InCheck.append(not(block_path(Vector2(pos.x + (path_right.find(T+'QUEEN') - i), pos.y))))
			i = i + 1

	if (T+'ROOK' in path_left):
		InCheck.append(not(in_check(Vector2(pos.x  - path_left.find(T+'ROOK'), pos.y), T)))
		var i = 1
		while path_left.find(T+'ROOK') - i > 0:
			InCheck.append(not(block_path(Vector2(pos.x - (path_left.find(T+'ROOK') - i), pos.y))))
			i = i + 1

	if (T+'QUEEN' in path_left):
		InCheck.append(not(in_check(Vector2(pos.x  - path_left.find(T+'QUEEN'), pos.y), T)))
		var i = 1
		while path_left.find(T+'QUEEN') - i > 0:
			InCheck.append(not(block_path(Vector2(pos.x - (path_left.find(T+'QUEEN') - i), pos.y))))
			i = i + 1

	if (T+'BISHOP' in path_up_right):
		InCheck.append(not(in_check(Vector2(pos.x  + path_up_right.find(T+'BISHOP'), pos.y + path_up_right.find(T+'BISHOP')), T)))
		var i = 1
		while path_up_right.find(T+'BISHOP') - i > 0:
			InCheck.append(not(block_path(Vector2(pos.x + (path_up_right.find(T+'BISHOP') - i), pos.y + (path_up_right.find(T+'BISHOP') - i)))))
			i = i + 1

	if (T+'QUEEN' in path_up_right):
		InCheck.append(not(in_check(Vector2(pos.x  + path_up_right.find(T+'QUEEN'), pos.y + path_up_right.find(T+'QUEEN')), T)))
		var i = 1
		while path_up_right.find(T+'QUEEN') - i > 0:
			InCheck.append(not(block_path(Vector2(pos.x + (path_up_right.find(T+'QUEEN') - i), pos.y + (path_up_right.find(T+'QUEEN') - i)))))
			i = i + 1

	if (T+'BISHOP' in path_up_left):
		InCheck.append(not(in_check(Vector2(pos.x  - path_up_left.find(T+'BISHOP'), pos.y + path_up_left.find(T+'BISHOP')), T)))
		var i = 1
		while path_up_left.find(T+'BISHOP') - i > 0:
			InCheck.append(not(block_path(Vector2(pos.x - (path_up_left.find(T+'BISHOP') - i), pos.y + (path_up_left.find(T+'BISHOP') - i)))))
			i = i + 1

	if (T+'QUEEN' in path_up_left):
		InCheck.append(not(in_check(Vector2(pos.x  - path_up_left.find(T+'QUEEN'), pos.y + path_up_left.find(T+'QUEEN')), T)))
		var i = 1
		while path_up_left.find(T+'QUEEN') - i > 0:
			InCheck.append(not(block_path(Vector2(pos.x - (path_up_left.find(T+'QUEEN') - i), pos.y + (path_up_left.find(T+'QUEEN') - i)))))
			i = i + 1

	if (T+'BISHOP' in path_down_right):
		InCheck.append(not(in_check(Vector2(pos.x  + path_down_right.find(T+'BISHOP'), pos.y - path_down_right.find(T+'BISHOP')), T)))
		var i = 1
		while path_down_right.find(T+'BISHOP') - i > 0:
			InCheck.append(not(block_path(Vector2(pos.x + (path_down_right.find(T+'BISHOP') - i), pos.y - (path_down_right.find(T+'BISHOP') - i)))))
			i = i + 1

	if (T+'QUEEN' in path_down_right):
		InCheck.append(not(in_check(Vector2(pos.x  + path_down_right.find(T+'QUEEN'), pos.y - path_down_right.find(T+'QUEEN')), T)))
		var i = 1
		while path_down_right.find(T+'QUEEN') - i > 0:
			InCheck.append(not(block_path(Vector2(pos.x + (path_down_right.find(T+'QUEEN') - i), pos.y - (path_down_right.find(T+'QUEEN') - i)))))
			i = i + 1

	if (T+'BISHOP' in path_down_left):
		InCheck.append(not(in_check(Vector2(pos.x  - path_down_left.find(T+'BISHOP'), pos.y - path_down_left.find(T+'BISHOP')), T)))
		var i = 1
		while path_down_left.find(T+'BISHOP') - i > 0:
			InCheck.append(not(block_path(Vector2(pos.x - (path_down_left.find(T+'BISHOP') - i), pos.y - (path_down_left.find(T+'BISHOP') - i)))))
			i = i + 1

	if (T+'QUEEN' in path_down_left):
		InCheck.append(not(in_check(Vector2(pos.x  - path_down_left.find(T+'QUEEN'), pos.y - path_down_left.find(T+'QUEEN')), T)))
		var i = 1
		while path_down_left.find(T+'QUEEN') - i > 0:
			InCheck.append(not(block_path(Vector2(pos.x - (path_down_left.find(T+'QUEEN') - i), pos.y - (path_down_left.find(T+'QUEEN') - i)))))
			i = i + 1
	
	if (T+'KNIGHT' in path_knight):
		var p = path_knight.find(T+'KNIGHT')
		var v
		if p == 0 : v = Vector2(2,1);  if p == 1 : v = Vector2(2,-1)
		if p == 2 : v = Vector2(-2,1); if p == 3 : v = Vector2(-2,-1)
		if p == 4 : v = Vector2(1,2);  if p == 5 : v = Vector2(1,-2)
		if p == 6 : v = Vector2(1,-2); if p == 7 : v = Vector2(-1,-2)
		InCheck.append(not(in_check(pos + v, T)))
	
	if InCheck.count(true) == len(InCheck) and len(InCheck) > 0:
		return true
	else:
		return false

func display_CheckAndCheckmate():
	var king_pos; var turn
	if white_turn == true:
		king_pos = find_index('W_KING')
		turn = 'W_'
	if white_turn == false:
		king_pos = find_index('B_KING')
		turn = 'B_'
	
	if (king_pos != null):
		if in_check(king_pos, turn) and not(in_checkmate(king_pos, turn)):
			mineset[king_pos.x][king_pos.y].show()
			if journal[-1] != '+':
				journal.append('+')
		if in_check(king_pos, turn) and in_checkmate(king_pos, turn):
			shieldset[king_pos.x][king_pos.y].show()
			if journal[-1] != '#':
				journal.append('#')
			yield(get_tree().create_timer(2.0), "timeout")
			var game_over = gameOver.instance()
			add_child(game_over)
			get_tree().paused = true
			$CameraLarge.current = true
			mouse.switch_cursor(cursor, Vector2(2,2), Vector2(-7,-7))
#			game_over.set_winner(not(white_turn))
#			var disable = [
#				$Sprites/Background, $Sprites/ChessBoard,
#				$PawnPromotion, $GoldSysten, $ChessPieces,
#				$CameraSmall
#			]
#
#			for node in disable:
#				disable(node)
		
		if movement_occured:
			hide_tileset(mineset)

func find_index(piece):
	for i in range(piece_type.size()):
		for j in range(piece_type.size()):
			if piece_type[i][j] == piece:
				return(Vector2(i,j))

func check_path(pos : Vector2, direction : Vector2):
	var path = [null]
	var i = 1
	var d = direction
	if inside_grid(pos + d):
		while ((path[i-1] == null) or (path[i-1] == 'MINE')) and inside_grid(pos + d):
			path.append(piece_type[pos.x + d.x][pos.y + d.y])
			i = i + 1
			
			if d.x == 0 and d.y > 0:
				d = d + Vector2(0, 1)
			if d.x == 0  and d.y < 0:
				d = d + Vector2(0, -1)
			
			if d.x > 0  and d.y == 0:
				d = d + Vector2(1, 0)
			if d.x > 0  and d.y > 0:
				d = d + Vector2(1, 1)
			if d.x > 0  and d.y < 0:
				d = d + Vector2(1, -1)
				
			if d.x < 0  and d.y == 0:
				d = d + Vector2(-1, 0)
			if d.x < 0  and d.y > 0:
				d = d + Vector2(-1, 1)
			if d.x < 0  and d.y < 0:
				d = d + Vector2(-1, -1)
	return path

func check_knight(pos : Vector2):
	var path = []
	if inside_grid(pos + Vector2(2,1)):
		path.append(piece_type[pos.x + 2][pos.y + 1])
	if inside_grid(pos + Vector2(2,-1)):
		path.append(piece_type[pos.x + 2][pos.y - 1])
	if inside_grid(pos + Vector2(-2,1)):
		path.append(piece_type[pos.x - 2][pos.y + 1])
	if inside_grid(pos + Vector2(-2, -1)):
		path.append(piece_type[pos.x - 2][pos.y - 1])
	if inside_grid(pos + Vector2(1, 2)):
		path.append(piece_type[pos.x + 1][pos.y + 2])
	if inside_grid(pos + Vector2(1, -2)):
		path.append(piece_type[pos.x + 1][pos.y - 2])
	if inside_grid(pos + Vector2(-1, 2)):
		path.append(piece_type[pos.x - 1][pos.y + 2])
	if inside_grid(pos + Vector2(-1, -2)):
		path.append(piece_type[pos.x - 1][pos.y - 2])
	return path

func block_path(pos : Vector2):
	var path_up = check_path(pos, Vector2(0, 1)); var path_down = check_path(pos, Vector2(0, -1))
	var path_right = check_path(pos, Vector2(1, 0)); var path_left = check_path(pos, Vector2(-1, 0))
	
	var path_up_right = check_path(pos, Vector2(1, 1)); var path_up_left = check_path(pos, Vector2(-1, 1))
	var path_down_right = check_path(pos, Vector2(1, -1)); var path_down_left = check_path(pos, Vector2(-1, -1))
	
	var cross_path = path_up + path_down + path_right + path_left
	var diagonal_path = path_up_right + path_up_left + path_down_right + path_down_left
	
	var path_knight = check_knight(pos)
	
	var T
	if white_turn == true:
		T = "W_"
	if white_turn == false:
		T = "B_"
	
	if (T+'ROOK' in cross_path) or (T+'QUEEN' in cross_path):
		return true
	
	if (T+'BISHOP' in diagonal_path) or (T+'QUEEN' in diagonal_path):
		return true
	
	for i in path_knight:
		if (i != null) and (T+'KNIGHT' in i):
			return true
	
	var cross = [path_up, path_down]
	
	if white_turn:
		var path = cross[1]
		if (len(path)>1) and (path[1] != null) and (path[1] == T+'PAWN'):
			return true
		if (len(path)>2) and (path[2] != null) and (path[2] == T+'PAWN'):
			return true
	if not(white_turn):
		var path = cross[0]
		if (len(path)>1) and (path[1] != null) and (path[1] == T+'PAWN'):
			return true
		if (len(path)>2) and (path[2] != null) and (path[2] == T+'PAWN'):
			return true

func inCheck_king(pos, i,j, turn):
	if inside_grid(pos + Vector2(i, j)):
		if (piece_type[pos.x + i][pos.y + j] == null):
			if in_check(pos +  Vector2(i, j), turn):
				return true
			return false

func disable(node):
		node.hide()
		node.set_process(false)
		node.set_process_input(false)

# Mine & Gold System
func gold_popup():	
	if white_turn == true and pop_up_books == true:
		$GoldSysten/PopUpBook.show()
	
	if white_turn == false  and pop_up_books == true:
		$GoldSysten/PopUpBook.show()
		
	if pop_up_books == false:
		$GoldSysten/PopUpBook.hide()

func place_mine():
	if Input.is_action_just_pressed("ui_click") and (mouse.texture == mine_cursor):
		var mine_click = get_global_mouse_position()
		var mine_pos = pixel_to_grid(mine_click)
		
		if inside_grid(mine_pos) and (piece_type[mine_pos.x][mine_pos.y] == null):
			hide_tileset(mineset)
			mineset[mine_pos.x][mine_pos.y].show()
		else:
			hide_tileset(mineset)
			mouse.switch_cursor(cursor, Vector2(1,1), Vector2(-7, -7))

func set_mine():
	if Input.is_action_just_pressed("ui_right_click") and (mouse.texture == mine_cursor):
		var mine_click = get_global_mouse_position()
		var mine_pos = pixel_to_grid(mine_click)
		
		var mine
		if white_turn == true:
			mine = white_mine
		if white_turn == false:
			mine = black_mine
		
		if inside_grid(mine_pos) and mine > 0:
			if mineset[mine_pos.x][mine_pos.y].visible == true:
				mouse.switch_cursor(cursor, Vector2(1,1), Vector2(-7, -7))
				hide_tileset(mineset)
				piece_type[mine_pos.x][mine_pos.y] = 'MINE'
				var notation = piece_notation['MINE'] + pos_notation[mine_pos.x] + str(mine_pos.y+1)
				journal.append(notation)
			
			mine = mine - 1
			var frame = button_frame[str(mine)]
			mine_number.set_frame(frame)
			
			if white_turn == true:
				white_mine = mine
			if white_turn == false:
				black_mine = mine

func place_shield():
	if  Input.is_action_just_pressed("ui_click") and (mouse.texture == shield_cursor):
		var shield_click = get_global_mouse_position()
		var shield_pos = pixel_to_grid(shield_click)
		
		if inside_grid(shield_pos) and (piece_object[shield_pos.x][shield_pos.y] != null):
			if white_turn == true and "W_" in piece_type[shield_pos.x][shield_pos.y]:
				hide_tileset(shieldset)
				shieldset[shield_pos.x][shield_pos.y].show()
			if white_turn == false and "B_" in piece_type[shield_pos.x][shield_pos.y]:
				hide_tileset(shieldset)
				shieldset[shield_pos.x][shield_pos.y].show()
		else:
			hide_tileset(shieldset)
			mouse.switch_cursor(cursor, Vector2(1,1), Vector2(-7, -7))

func set_shield():
	if Input.is_action_just_pressed("ui_right_click") and (mouse.texture == shield_cursor):
		var shield_click = get_global_mouse_position()
		var shield_pos = pixel_to_grid(shield_click)
		
		var shield
		if white_turn == true:
			shield = white_shield
		if white_turn == false:
			shield = black_shield
		
		if inside_grid(shield_pos) and shield > 0:
			if shieldset[shield_pos.x][shield_pos.y].visible == true:
				mouse.switch_cursor(cursor, Vector2(1,1), Vector2(-7, -7))
				hide_tileset(shieldset)
				piece_object[shield_pos.x][shield_pos.y].show_shield()
				var notation = piece_notation['SHIELD'] + pos_notation[shield_pos.x] + str(shield_pos.y+1)
				journal.append(notation)
			
			shield = shield - 1
			var frame = button_frame[str(shield)]
			shield_number.set_frame(frame)
			
			if white_turn == true:
				white_shield = shield
			if white_turn == false:
				black_shield = shield

func disable_btn():
	if white_turn == true:
		$GoldSysten/WhiteBookBtn.disabled = false
		$GoldSysten/BlackBookBtn.disabled = true
		$GoldSysten/WhiteBookBtn.modulate = Color(1, 1, 1, 1)
		$GoldSysten/BlackBookBtn.modulate = Color(0.5, 0.5, 0.5, 1)
	
	if white_turn == false:
		$GoldSysten/WhiteBookBtn.disabled = true
		$GoldSysten/BlackBookBtn.disabled = false
		$GoldSysten/WhiteBookBtn.modulate = Color(0.5, 0.5, 0.5, 1)
		$GoldSysten/BlackBookBtn.modulate = Color(1, 1, 1, 1)

func gold_count(target_type, selected_type):
	if target_type != 'MINE':
		if white_turn == true:
			var piece = target_type.substr(2,len(target_type))
			white_gold = white_gold + piece_value[piece]
		
		if white_turn == false:
			var piece = target_type.substr(2,len(target_type))
			black_gold = black_gold + piece_value[piece]
	
	if target_type == 'MINE':
		if 'B_' in selected_type:
			var piece = selected_type.substr(2,len(selected_type))
			white_gold = white_gold + piece_value[piece]
		
		if 'W_' in selected_type:
			var piece = selected_type.substr(2,len(selected_type))
			black_gold = black_gold + piece_value[piece]

func display_gold():
	if white_gold < 10:
		$GoldSysten/WhiteGold.text = '0' + str(white_gold)
	if white_gold >= 10:
		$GoldSysten/WhiteGold.text = str(white_gold)
	
	if black_gold < 10:
		$GoldSysten/BlackGold.text = '0' + str(black_gold)
	if black_gold >= 10:
		$GoldSysten/BlackGold.text = str(black_gold)

func display_numbers():
	if white_turn == true:
		var frame_m = button_frame[str(white_mine)]
		var frame_s = button_frame[str(white_shield)]
		mine_number.set_frame(frame_m)
		shield_number.set_frame(frame_s)
	if white_turn == false:
		var frame_m = button_frame[str(black_mine)]
		var frame_s = button_frame[str(black_shield)]
		mine_number.set_frame(frame_m)
		shield_number.set_frame(frame_s)

func update_numbers():
	var gold
	var mine
	var shield
	
	if white_turn == true:
		gold = white_gold
		mine = white_mine
		shield = white_shield
	if white_turn == false:
		gold = black_gold
		mine = black_mine
		shield = black_shield
	
	if arrow_action == '+MINE':
		if mine < 10 and gold >= piece_value['MINE']:
			mine = mine + 1
			gold = gold - piece_value['MINE']
			var frame = button_frame[str(mine)]
			mine_number.set_frame(frame)
		arrow_action = 'NONE'
	
	if arrow_action == '-MINE':
		if mine > 0:
			mine = mine - 1
			gold = gold + piece_value['MINE']
			var frame = button_frame[str(mine)]
			mine_number.set_frame(frame)
		arrow_action = 'NONE'
		
	if arrow_action == '+SHIELD':
		if shield < 10 and gold >= piece_value['SHIELD']:
			shield = shield + 1
			gold = gold - piece_value['SHIELD']
			var frame = button_frame[str(shield)]
			shield_number.set_frame(frame)
		arrow_action = 'NONE'
	
	if arrow_action == '-SHIELD':
		if shield > 0:
			shield = shield - 1
			gold = gold + piece_value['SHIELD']
			var frame = button_frame[str(shield)]
			shield_number.set_frame(frame)
		arrow_action = 'NONE'
	
	if white_turn == true:
		white_gold = gold 
		white_mine = mine
		white_shield = shield
	if white_turn == false:
		black_gold = gold
		black_mine = mine
		black_shield = shield




# Buttons
## Promotionn Buttons
func _on_W_QueenBtn_pressed() -> void:
	var last_row = []; var target = Vector2(0,0)
	for i in range(8):
		last_row.append(piece_type[i][7])
	target.x = last_row.find('W_PAWN'); target.y = 7
	promote_to('W_QUEEN', 11,  target, 7)
	$PawnPromotion.hide()

func _on_W_KnightBtn_pressed() -> void:
	var last_row = []; var target = Vector2(0,0)
	for i in range(8):
		last_row.append(piece_type[i][7])
	target.x = last_row.find('W_PAWN'); target.y = 7
	promote_to('W_KNIGHT', 7,  target, 5)
	$PawnPromotion.hide()

func _on_W_RookBtn_pressed() -> void:
	var last_row = []; var target = Vector2(0,0)
	for i in range(8):
		last_row.append(piece_type[i][7])
	target.x = last_row.find('W_PAWN'); target.y = 7
	promote_to('W_ROOK', 6,  target, 4)
	$PawnPromotion.hide()

func _on_W_BishopBtn_pressed() -> void:
	var last_row = []; var target = Vector2(0,0)
	for i in range(8):
		last_row.append(piece_type[i][7])
	target.x = last_row.find('W_PAWN'); target.y = 7
	promote_to('W_BISHOP', 8,  target, 6)
	$PawnPromotion.hide()

func _on_B_QueenBtn_pressed() -> void:
	var last_row = []; var target = Vector2(0,0)
	for i in range(8):
		last_row.append(piece_type[i][0])
	target.x = last_row.find('B_PAWN'); target.y = 0
	promote_to('B_QUEEN', 5,  target, 3)
	$PawnPromotion.hide()

func _on_B_KnightBtn_pressed() -> void:
	var last_row = []; var target = Vector2(0,0)
	for i in range(8):
		last_row.append(piece_type[i][0])
	target.x = last_row.find('B_PAWN'); target.y = 0
	promote_to('B_KNIGHT', 1,  target, 1)
	$PawnPromotion.hide()

func _on_B_RookBtn_pressed() -> void:
	var last_row = []; var target = Vector2(0,0)
	for i in range(8):
		last_row.append(piece_type[i][0])
	target.x = last_row.find('B_PAWN'); target.y = 0
	promote_to('B_ROOK', 0,  target, 0)
	$PawnPromotion.hide()

func _on_B_BishopBtn_pressed() -> void:
	var last_row = []; var target = Vector2(0,0)
	for i in range(8):
		last_row.append(piece_type[i][0])
	target.x = last_row.find('B_PAWN'); target.y = 0
	promote_to('B_BISHOP', 2,  target, 2)
	$PawnPromotion.hide()


## Mine & Gold Buttons
func _on_BlackBookBtn_pressed() -> void:
	pop_up_books = not(pop_up_books)

func _on_WhiteBookBtn_pressed() -> void:
	pop_up_books = not(pop_up_books)

func _on_MineBtn_pressed() -> void:
	mouse.switch_cursor(mine_cursor, Vector2(1,1), Vector2(-16,-16))

func _on_ShieldBtn_pressed() -> void:
	mouse.switch_cursor(shield_cursor, Vector2(0.6,0.6), Vector2(-16, -16))

func _on_RightMineBtn_pressed() -> void:
	arrow_action = '+MINE'

func _on_LeftMineBtn_pressed() -> void:
	arrow_action = '-MINE'

func _on_RightShieldBtn_pressed() -> void:
	arrow_action = '+SHIELD'

func _on_LeftShieldBtn_pressed() -> void:
	arrow_action = '-SHIELD'

