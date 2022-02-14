extends Node2D

var cursor = load("res://Assets/item_2_flip.png")
const tile = preload("res://Chess Pieces/HighlightTile.tscn")

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
var tileset = []

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
var white_turn = true

# Gold system
var black_gold = 0
var white_gold = 0
var chess_notation = {'A':0, 'B':1, 'C':2, 'D':3, 'E':4, 'F':5, 'G':6, 'H':7}
var piece_value = {'PAWN':1, 'KNIGHT':3, 'BISHOP':3, 'ROOK':5, 'QUEEN':9, 'KING':0}

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2())
	
	piece_object = build_2D_array()
	piece_type = build_2D_array()
	tileset = build_2D_array()
	spawn_black_pieces()
	spawn_white_pieces()
	build_tileset()
	hide_tileset()
	
	# Hide these
	$PawnPromotion.hide()
	
	# Test pieces
	spawn_piece(9, 'W_PAWN', Vector2(6,5))
	spawn_piece(3, 'B_PAWN', Vector2(5,2))
	spawn_piece(2, 'B_BISHOP', Vector2(5,3))
	spawn_piece(11, 'W_QUEEN', Vector2(3,3))

func _process(_delta) -> void:
	show_path()
	choose_path()


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
	if pos.x >= 0 and pos.x < 8:
		if pos.y >= 0 and pos.y < 8:
			return true
	return false


# Spawn Pieces
func spawn_piece(n, type, pos):
	var piece = chess_pieces[n].instance()
	add_child(piece)
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


# Build tiles
func build_tileset():
	for i in range(8):
		for j in range(8):
			var square = tile.instance()
			add_child(square)
			square.position = grid_to_pixel(Vector2(i,j))
			tileset[i][j] = square

func hide_tileset():
	for i in range(8):
		for j in range(8):
			tileset[i][j].hide()


# Chess piece paths
func show_path():
	movement_occured = false
	if Input.is_action_just_pressed("ui_click"):
		first_click = get_global_mouse_position()
		pos = pixel_to_grid(first_click)
		
		if inside_grid(pos):
			selected_piece = piece_object[pos.x][pos.y]
			selected_type = piece_type[pos.x][pos.y]
			piece_path(selected_type, selected_piece, pos)
			controlling = true

func choose_path():
	if Input.is_action_just_pressed("ui_right_click") and controlling:
		final_click = get_global_mouse_position()
		target = pixel_to_grid(final_click)
		
		if inside_grid(target) and controlling:
			controlling = false
			var target_piece = piece_object[target.x][target.y]
			var target_type = piece_type[target.x][target.y]
			if tileset[target.x][target.y].visible:
				# move to empty tile
				if target_type == null or target_type == 'MINE':
					move_piece(selected_type, selected_piece, pos, target)
					movement_occured = true
				# kill enemy
				if target_type != null and target_type != 'MINE':
					kill_enemy(selected_type, selected_piece, target_piece, pos, target)
					movement_occured = true
			
		if movement_occured:
			white_turn = not(white_turn)
		hide_tileset()

func piece_path(selected_type, selected_piece, pos):
	hide_tileset()
	
	if selected_piece != null:
		pawn_path(selected_type, pos)
		
		if 'W_' in selected_type and white_turn:
			knight_path(selected_type, pos)
		if 'B_' in selected_type and not(white_turn):
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
	if 'KNIGHT' in selected_type:
		var pos1 = Vector2(pos.x-2, pos.y+1); var pos2 = Vector2(pos.x+2, pos.y+1)
		var pos3 = Vector2(pos.x-2, pos.y-1); var pos4 = Vector2(pos.x+2, pos.y-1)
		var pos5 = Vector2(pos.x-1, pos.y+2); var pos6 = Vector2(pos.x+1, pos.y+2)
		var pos7 = Vector2(pos.x-1, pos.y-2); var pos8 = Vector2(pos.x+1, pos.y-2)
		var path = [pos1,pos2,pos3,pos4,pos5,pos6,pos7,pos8]
		
		for posI in path:
			if inside_grid(posI):
				if (piece_type[posI.x][posI.y] == null) or (('B_' in piece_type[posI.x][posI.y]) and ('W_' in selected_type)) or (('W_' in piece_type[posI.x][posI.y]) and ('B_' in selected_type)):
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


# Movement
func update_array(selected_type, selected_piece, pos, target):
	piece_object[target.x][target.y] = selected_piece
	piece_object[pos.x][pos.y] = null
	
	piece_type[target.x][target.y] = selected_type
	piece_type[pos.x][pos.y] = null

func move_piece(selected_type, selected_piece, pos, target):
	update_array(selected_type, selected_piece, pos, target)
	selected_piece.animate(grid_to_pixel(target))
	promotion_popup(selected_type, target)

func kill_enemy(selected_type, selected_piece, target_piece, pos, target):
	update_array(selected_type, selected_piece, pos, target)
	target_piece.queue_free()
	selected_piece.animate(grid_to_pixel(target))
	promotion_popup(selected_type, target)


# Special functions
func promotion_popup(selected_type, target):
	if 'PAWN' in selected_type:
		if target.y == 7:
			$PawnPromotion.show()
			$PawnPromotion/PopUp/WhiteButtons.show()
			$PawnPromotion/PopUp/BlackButtons.hide()
		if target.y == 0:
			#get_tree().paused = true
			$PawnPromotion.show()
			$PawnPromotion/PopUp/WhiteButtons.hide()
			$PawnPromotion/PopUp/BlackButtons.show()

func promote_to(promotion, chess_piece,  pos, sprite):
	piece_object[pos.x][pos.y].switch_texture(null)
	var piece = chess_pieces[chess_piece].instance()
	add_child(piece)
	piece.position = grid_to_pixel(pos)
	piece_object[pos.x][pos.y] = piece
	piece_type[pos.x][pos.y] = promotion
	piece_object[pos.x][pos.y].switch_texture(piece_textures[sprite])

func in_check(color, pos):
	var path_up = check_PathUp(pos)
	var path_down = check_PathDown(pos)
	var path_right = check_PathRight(pos)
	var path_left = check_PathLeft(pos)
	
	if ('ROOK' in path_up):
		pass



# Check Paths
func check_PathUp(pos):
	var path_up = [null]
	var i = 1
	while ((path_up[i-1] == null) or (path_up[i-1] == 'MINE')) and (pos.y + i <7):
		path_up.append(piece_type[pos.x][pos.y + i])
		i = i + 1
	return path_up

func check_PathDown(pos):
	var path_down = [null]
	var i = 1
	while ((path_down[i-1] == null) or (path_down[i-1] == 'MINE')) and (pos.y - i > 0):
		path_down.append(piece_type[pos.x][pos.y - i])
		i = i + 1
	return path_down
	
func check_PathRight(pos):
	var path_right = [null]
	var i = 1
	while ((path_right[i-1] == null) or (path_right[i-1] == 'MINE')) and (pos.x + i <7):
		path_right.append(piece_type[pos.x + i][pos.y])
		i = i + 1
	return path_right

func check_PathLeft(pos):
	var path_left = [null]
	var i = 1
	while ((path_left[i-1] == null) or (path_left[i-1] == 'MINE')) and (pos.x - i > 0):
		path_left.append(piece_type[pos.x - i][pos.y])
		i = i + 1
	return path_left



# Buttons
func _on_W_QueenBtn_pressed() -> void:
	var last_row = []; var target = Vector2(0,0)
	for i in range(8):
		last_row.append(piece_type[i][7])
	target.x = last_row.find('W_PAWN'); target.y = 7
	promote_to('W_QUEEN', 6,  target, 7)
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
