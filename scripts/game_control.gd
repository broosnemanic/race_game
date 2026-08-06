extends Node2D

@onready var board_prefab: PackedScene = preload("res://scenes/board.tscn")
@onready var ship_prefab: PackedScene = preload("res://scenes/ship.tscn")
@onready var board_container: MarginContainer = %BoardContainer

var board: Board
var active_player: int = 0
var ships: Array[Ship] = []
var ship_ready_report: Array[bool] = []
var turn_index: int


func _ready() -> void:
	#board_setup()
	board = board_prefab.instantiate()
	board_container.add_child(board)
	await get_tree().process_frame
	board.square_size = 64.0
	board.grid_size = Vector2i(64, 64)
	board.center_camera()
	board.board_camera.zoom = Vector2(0.5, 0.5)
	board.ship_move_selected.connect(on_ship_move_selected)
	#setup_track()
	new_game(1, 0)
	#activate_board_edit_mode()
	await get_tree().process_frame


# 
func activate_board_edit_mode() -> void:
	new_game(0, 0)
	board.is_edit_mode = true



#
func setup_track() -> void:
	for i_index: int in range(25, 35):
		var t_coord: Vector2i = Vector2i(i_index, 30)
		var t_square: Square = Square.new()
		t_square.normal = Vector2i(0, 1)
		board.squares[t_coord] = t_square
	for i_index: int in range(25, 35):
		var t_coord: Vector2i = Vector2i(i_index + 8, 32)
		var t_square: Square = Square.new()
		t_square.normal = Vector2i(0, -1)
		board.squares[t_coord] = t_square
	board.draw_track()



# TODO: When this is called from `_ready()`, ships do not apear
func board_setup() -> void:
	board = board_prefab.instantiate()
	board_container.add_child(board)
	await get_tree().process_frame
	board.square_size = 64.0
	board.grid_size = Vector2i(64, 64)
	board.center_camera()
	board.board_camera.zoom = Vector2(0.5, 0.5)
	board.ship_move_selected.connect(on_ship_move_selected)


# 
func new_game(a_player_count: int, a_bot_count: int) -> void:
	ships = []
	for i_index: int in range(a_player_count + a_bot_count):
		var t_ship: Ship = ship_prefab.instantiate()
		t_ship.is_bot = i_index >= a_player_count
		ships.append(t_ship)
		t_ship.set_player(i_index)
		board.add_ship(t_ship)
		t_ship.z_index = Constants.SHIP_Z_INDEX
		t_ship.position = start_pos_from_player(t_ship.player)
		#if i_index == 0:
			#t_ship.set_velocity(Vector2i(0, -5))
		#if i_index == 1:
			#t_ship.set_velocity(Vector2i(-4, -7))
		#if i_index == 2:
			#t_ship.set_velocity(Vector2i(0, -7))
	if not ships.is_empty():
		board.on_ship_selected(ships[0])
	ship_ready_report.resize(ships.size())
	turn_index = 0
	board.load_track()


#
func start_turn() -> void:
	board.select_first_ship()


# Placeholder func to distribute starting positions
func start_pos_from_player(a_player: int) -> Vector2:
	var t_coord: Vector2i = Vector2i(1 * a_player + 26, 40)
	if a_player == 0:
		t_coord = Vector2i(32, 39)
		ships[0].set_velocity(Vector2i(1, 0))

	return board.pos_from_coords(t_coord)# + board.board_camera.offset


# Check if all ships are ready; move all ships or select next ship
func on_ship_move_selected(a_ship: Ship) -> void:
	ship_ready_report[a_ship.player] = true
	if is_all_ships_ready():
		board.move_ships()
		reset_ship_ready_report()
		await board.all_moves_completed
		start_turn()
	else:
		board.select_next_ship()


# As it says
func reset_ship_ready_report() -> void:
	for i_index: int in range(ship_ready_report.size()):
		ship_ready_report[i_index] = false


# Have all ships reported a move choice is made?
func is_all_ships_ready() -> bool:
	for i_ready: bool in ship_ready_report:
		if not i_ready:
			return false
	return true
