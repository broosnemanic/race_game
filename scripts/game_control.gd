extends Node2D

@onready var board_prefab: PackedScene = preload("res://scenes/board.tscn")
@onready var ship_prefab: PackedScene = preload("res://scenes/ship.tscn")
@onready var board_container: MarginContainer = %BoardContainer
var board: Board
var test_ship: Ship
var active_player: int = 0
var ships: Array[Ship] = []
var player_count: int = 1
var ship_ready_report: Array[bool] = []
var turn_index: int



func _ready() -> void:
	board = board_prefab.instantiate()
	board_container.add_child(board)
	await get_tree().process_frame
	board.square_size = 64.0
	#board.grid_size = Vector2i(16, 16)
	board.grid_size = Vector2i(64, 64)
	board.center_camera()
	board.board_camera.zoom = Vector2(0.5, 0.5)
	board.ship_move_completed.connect(on_ship_move_completed)
	board.ship_move_selected.connect(on_ship_move_selected)
	new_game(2, 0)
	await get_tree().process_frame


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
	board.on_ship_selected(ships[0])
	ship_ready_report.resize(ships.size())
	turn_index = 0


func start_turn() -> void:
	board.select_first_ship()
	#board.fade_traces()
	#board.fade_dots()



func start_pos_from_player(a_player: int) -> Vector2:
	var t_coord: Vector2i = Vector2i(a_player, 0)
	return board.pos_from_coords(t_coord) + board.board_camera.offset


func on_ship_move_completed(a_ship: Ship) -> void:
	pass
	# Check to see if all ships have registered a move
	# If so, then move all ships
	# Reset



func on_ship_move_selected(a_ship: Ship) -> void:
	ship_ready_report[a_ship.player] = true
	if is_all_ships_ready():
		board.move_ships()
		reset_ship_ready_report()
		await get_tree().create_timer(Constants.MOVE_TIME).timeout
		start_turn()
	else:
		board.select_next_ship()


func reset_ship_ready_report() -> void:
	for i_index: int in range(ship_ready_report.size()):
		ship_ready_report[i_index] = false


# Have all ships reported a move choice is made?
func is_all_ships_ready() -> bool:
	for i_ready: bool in ship_ready_report:
		if not i_ready:
			return false
	return true
