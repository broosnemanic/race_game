extends Node2D

@onready var board_prefab: PackedScene = preload("res://scenes/board.tscn")
@onready var ship_prefab: PackedScene = preload("res://scenes/ship.tscn")
@onready var board_container: MarginContainer = %BoardContainer

var board: Board
var active_player: int = 0
var ships: Array[Ship] = []
var ship_ready_report: Array[bool] = []
var turn_index: int
const PLAYER_COUNT: int = 3


# Ship inits for testing
var ship_inits: Array[ShipInit] = [ShipInit.new(Vector2i(26, 40), Vector2i(0, 0)),
									ShipInit.new(Vector2i(28, 40), Vector2i(0, 0)),
									ShipInit.new(Vector2i(30, 40), Vector2i(0, 0)),
									ShipInit.new(Vector2i(32, 40), Vector2i(0, 0))]

# Object to hold ship starting data
class ShipInit:
	func _init(a_position: Vector2i, a_velocity: Vector2i) -> void:
		position = a_position
		velocity = a_velocity
	var position: Vector2i
	var velocity: Vector2i


# 
func _ready() -> void:
	#board_setup()
	board = board_prefab.instantiate()
	board_container.add_child(board)
	await get_tree().process_frame
	board.square_size = Constants.SQUARE_SIZE
	board.grid_size = Vector2i(64, 64)
	board.center_camera()
	board.board_camera.zoom = Vector2(0.25, 0.25)
	board.ship_move_selected.connect(on_ship_move_selected)
	#setup_track()
	new_game(PLAYER_COUNT, 0)
	#activate_board_edit_mode()
	await get_tree().process_frame
	#Engine.time_scale = 0.25


# As it says
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
		var t_init: ShipInit = ship_inits[i_index]
		t_ship.is_bot = i_index >= a_player_count
		ships.append(t_ship)
		t_ship.set_player(i_index)
		board.add_ship(t_ship)
		t_ship.shadow.modulate = Constants.player_color[i_index]
		t_ship.shadow.modulate.a = 0.25
		t_ship.z_index = Constants.SHIP_Z_INDEX
		t_ship.square_size = board.square_size
		t_ship.setup_arrowhead()
		t_ship.position = t_init.position * board.square_size
		t_ship.set_velocity(t_init.velocity)
	if not ships.is_empty():
		start_turn()
	ship_ready_report.resize(ships.size())
	turn_index = 0
	board.load_track()
	board.set_player_order(0)


# 1st -> last; 2nd -> 1st; etc
func increment_player_order() -> void:
	board.increment_first_mover()
 

# As it says
func start_turn() -> void:
	board.select_first_ship()


# Check if all ships are ready; move all ships or select next ship
func on_ship_move_selected(a_ship: Ship) -> void:
	ship_ready_report[a_ship.player] = true
	if is_all_ships_ready():
		board.move_ships()
		reset_ship_ready_report()
		await board.all_moves_completed
		increment_player_order()
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
