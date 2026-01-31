extends SubViewportContainer
class_name Board

signal ship_move_completed(a_ship: Ship)
signal ship_move_selected(a_ship: Ship)
signal all_moves_completed()

@onready var board_camera: Camera2D = %BoardCamera
@onready var grid_rect: TextureRect = %GridRect
@onready var board_viewport: SubViewport = $BoardViewport

const TILE_0680: Texture2D = preload("uid://c413je2hltv8q")
const LIGHT_TILE: Texture2D = preload("uid://crkmjka1gcgkc")
const CROSSHAIR_TEX_00: Texture2D = preload("uid://b01dx1v65uhom")
const TARGET_MARKER: Texture2D = preload("uid://cf85b3rajkbrk")
const DOT: Texture2D = preload("uid://dup115kj27cgg")

var crosshair: Sprite2D
var ships: Array[Ship]
var selected_ship: Ship
var mouse_pos: Vector2		# Relative to SubViewportContainer not viewport position
var trace_register: Array[Line2D]
var dot_register: Array[Sprite2D]
var descrete_path_register: Array[DescretePath] = []

func _ready() -> void:
	crosshair = Sprite2D.new()
	crosshair.texture = CROSSHAIR_TEX_00
	crosshair.modulate = Color("000000ff")
	grid_rect.add_child(crosshair)
	crosshair.visible = true


func _process(_delta: float) -> void:
	var t_pos: Vector2 = grid_rect.get_local_mouse_position()
	if t_pos != mouse_pos:
		mouse_pos = t_pos


func get_mouse_pos() -> Vector2:
	return grid_rect.get_local_mouse_position()


func ship_at_mouse_pos() -> Ship:
	var t_mouse_coords: Vector2i = coords_from_pos(get_mouse_pos())
	for i_ship: Ship in ships:
		var t_ship_coord: Vector2i = coords_from_pos(i_ship.position)
		if t_mouse_coords == t_ship_coord:
			return i_ship
	return null


# Size of one square in pixels
var square_size: float:
	set(a_size):
		square_size = a_size
		var t_scale: float = a_size / Constants.ORIGINAL_SQUARE_SIZE
		grid_rect.scale = Vector2(t_scale, t_scale)


# Size in squares
var grid_size: Vector2i:
	set(a_size):
		var t_x: float = a_size.x as float * square_size
		var t_y: float = a_size.y as float * square_size
		grid_rect.size = Vector2(t_x, t_y)


func center_camera() -> void:
	board_camera.offset = Vector2(0.5 * grid_rect.size.x, 0.5 * grid_rect.size.y)


# Position snapped to center of nearest square
func snapped_pos(a_pos: Vector2) -> Vector2:
	return pos_from_coords(coords_from_pos(a_pos))


func pos_from_coords(a_coords: Vector2i) -> Vector2:
	var t_x: float = a_coords.x as float * square_size
	var t_y: float = a_coords.y as float * square_size
	return Vector2(t_x, t_y)


# Square coords from a position
func coords_from_pos(a_pos: Vector2) -> Vector2i:
	var t_x: float = a_pos.x + 0.5 * square_size	# Grid texture ends at 1/2 square for better tiling
	var t_y: float = a_pos.y + 0.5 * square_size
	return Vector2i(floori(t_x / square_size), floori(t_y / square_size))


func add_ship(a_ship: Ship) -> void:
	ships.append(a_ship)
	grid_rect.add_child(a_ship)
	a_ship.z_index = Constants.SHIP_Z_INDEX + a_ship.player
	a_ship.move_selected.connect(on_move_selected)


func select_ship(a_ship: Ship) -> void:
	on_ship_selected(a_ship)


func select_first_ship() -> void:
	select_ship(ships[0])


func select_next_ship() -> void:
	var t_index: int = 0 if selected_ship == null else selected_ship.player + 1
	if t_index < ships.size():
		select_ship(ships[t_index])


func on_move_selected(a_ship: Ship) -> void:
	ship_move_selected.emit(a_ship)


func move_ships() -> void:
	fade_traces()
	fade_dots()
	preserve_ship_paths()
	var t_duration: float = 0.5
	# Find tic count
	var t_tic_count: int = 0
	for i_ship: Ship in ships:
		t_tic_count = maxi(t_tic_count, i_ship.descrete_path.count())
	# Loop through tics
	for i_ship: Ship in ships:
		var t_path: DescretePath = i_ship.descrete_path
		t_path.populate_padded_steps(t_tic_count, t_path.coords[0], t_path.coords[-1])
	for i_tic: int in range(0, t_tic_count):
		for i_ship: Ship in ships:
				# Create tween to move i_ship the next step
				var t_coord: Vector2i = i_ship.descrete_path.padded_steps[i_tic]
				move_ship_to(i_ship, t_coord, t_duration)
		# Create await timer with duration of move
		await get_tree().create_timer(t_duration).timeout
		# We want both ships to move once per tic (if it has a move remaining)
		# Then move on to next tic
		# TODO: find and resolve collisions
		var t_report: Dictionary[Vector2i, ArrayInt] = collision_report(i_tic)
		for i_key: Vector2i in t_report.keys():
			var t_players: ArrayInt = t_report[i_key]
			if t_players.i.size() > 1:
				print("collision!")
	all_moves_completed.emit()


# Key is coord of collision; item is list of players
func collision_report(a_tic: int) -> Dictionary[Vector2i, ArrayInt]:
	var t_report: Dictionary[Vector2i, ArrayInt] = {}
	for i_ship: Ship in ships:
			var t_coord: Vector2i = coords_from_position(i_ship.position)
			# TODO: we are looking at steps but should be looking at board coords
			if not t_report.has(t_coord): t_report[t_coord] = ArrayInt.new()
			t_report[t_coord].i.append(i_ship.player)
	return t_report


func coords_from_position(a_pos: Vector2) -> Vector2i:
	var t_x: int = floori(a_pos.x / Constants.ORIGINAL_SQUARE_SIZE as float)
	var t_y: int = floori(a_pos.y / Constants.ORIGINAL_SQUARE_SIZE as float)
	return Vector2i(t_x, t_y)




# Given a tic, returns list of ships (by player) that are sharing a square
# Assumes populate_padded_steps has been called on all ships
func collision_list(a_tic: int) -> Array[ArrayInt]:
	return []



# Returns array filled with false, with a_count of true distributed evenly
func distributed_bools(a_total: int, a_count: int) -> Array[bool]:
	var t_array: Array[bool] = []
	t_array.resize(a_total)
	t_array.fill(false)
	var t_step: float = a_total as float / a_count
	for i_index: int in range(0, a_count):
			t_array[floori(i_index * t_step)] = true
	return t_array


func preserve_ship_paths() -> void:
	for i_ship: Ship in ships:
		var t_path: DescretePath = DescretePath.new()
		t_path.coords = i_ship.descrete_path.coords
		t_path.color = Constants.player_color[i_ship.player]
		t_path.draw_points(t_path.coords)
		descrete_path_register.append(t_path)
		grid_rect.add_child(t_path)
		t_path.global_position = i_ship.descrete_path.global_position
		i_ship.descrete_path.clear_line()
	fade_descrete_paths()


func fade_descrete_paths() -> void:
	for i_path: DescretePath in descrete_path_register:
		i_path.fade(Constants.FADE_INCR)
	remove_old_paths()


func remove_old_paths() -> void:
	for i_index: int in range(descrete_path_register.size()):
		var t_path: DescretePath = descrete_path_register[i_index]
		if t_path.alpha() <= 0.0:
			descrete_path_register[i_index] = null
			t_path.queue_free()
	var t_register: Array[DescretePath] = []
	for i_path: DescretePath in descrete_path_register:
		if i_path != null:
			t_register.append(i_path)
	descrete_path_register = t_register


# This will have to be reworked as it does not take collisions in to account
func move_ship(a_ship: Ship) -> void:
	var t_coord: Vector2i = a_ship.coords()
	a_ship.destroy_markers()
	draw_dot(t_coord, a_ship.player)
	var t_end: Vector2 = a_ship.position + Constants.ORIGINAL_SQUARE_SIZE * a_ship.velocity
	var t_tween: Tween = get_tree().create_tween()
	t_tween.tween_property(a_ship, "position", t_end, Constants.MOVE_TIME)
	t_tween.finished.connect(ship_move_completed.emit.bind(a_ship))
	draw_trace(t_coord, a_ship.coords() + a_ship.velocity, 0)



func move_ship_to(a_ship: Ship, a_coord: Vector2i, a_duration: float) -> void:
	var t_end: Vector2 = a_ship.position + Constants.ORIGINAL_SQUARE_SIZE * a_coord
	var t_tween: Tween = get_tree().create_tween()
	t_tween.tween_property(a_ship, "position", t_end, a_duration)



func draw_trace(a_start: Vector2i, a_end: Vector2i, _a_player: int) -> void:
	var t_line: Line2D = Line2D.new()
	var t_start: Vector2 = a_start * Constants.ORIGINAL_SQUARE_SIZE
	var t_end: Vector2 = a_end * Constants.ORIGINAL_SQUARE_SIZE
	t_line.add_point(t_start)
	t_line.add_point(t_start)
	t_line.texture = DOT
	t_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	t_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	t_line.width = 25.0
	t_line.modulate = Color.CHARTREUSE
	grid_rect.add_child(t_line)
	trace_register.append(t_line)
	var t_tween: Tween = get_tree().create_tween()
	t_tween.tween_method(extend_line.bind(t_line), t_start, t_end, Constants.MOVE_TIME)


func extend_line(a_end: Vector2, a_line: Line2D) -> void:
	a_line.points[1] = a_end


func fade_traces() -> void:
	for i_trace: Line2D in trace_register:
		i_trace.modulate.a -= Constants.FADE_INCR
	remove_old_traces()


func remove_old_traces() -> void:
	for i_index: int in range(trace_register.size()):
		var t_trace: Line2D = trace_register[i_index]
		if t_trace.modulate.a <= 0.0:
			trace_register[i_index] = null
			t_trace.queue_free()
	var t_register: Array[Line2D] = []
	for i_trace: Line2D in trace_register:
		if i_trace != null:
			t_register.append(i_trace)
	trace_register = t_register


func fade_dots() -> void:
	for i_dot: Sprite2D in dot_register:
		#i_dot.modulate.a *= Constants.FADE_FACTOR
		i_dot.modulate.a -= Constants.FADE_INCR


func draw_dot(a_coord: Vector2i, a_player: int) -> void:
	var t_dot: Sprite2D = Sprite2D.new()
	t_dot.texture = DOT
	grid_rect.add_child(t_dot)
	t_dot.scale = Vector2(1.5, 1.5)
	t_dot.modulate = Constants.player_color[a_player]
	t_dot.position = Constants.ORIGINAL_SQUARE_SIZE * a_coord
	dot_register.append(t_dot)


func on_ship_selected(a_ship: Ship) -> void:
	selected_ship = a_ship
	a_ship.create_markers()
