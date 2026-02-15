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
const POINT_TEXTURE: Texture2D = preload("uid://dup115kj27cgg")
const ENDPOINT_TEXTURE: Texture2D = preload("uid://dipjdkw86aunk")


var crosshair: Sprite2D
var ships: Array[Ship]
var selected_ship: Ship
var mouse_pos: Vector2		# Relative to SubViewportContainer not viewport position
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
	preserve_ship_paths()
	# Find tic count
	var t_tic_count: int = 0
	for i_ship: Ship in ships:
		t_tic_count = maxi(t_tic_count, i_ship.descrete_path.count())
	# Loop through tics
	for i_ship: Ship in ships:
		var t_path: DescretePath = i_ship.descrete_path
		t_path.populate_padded_steps(t_tic_count, t_path.coords[0], t_path.coords[-1])
	for i_tic: int in range(0, t_tic_count - 1):
		for i_ship: Ship in ships:
				# TODO: Look ahead to see if a collision would happen
				# then swap velocities to avoid collision
				var t_list: Array[Ship] = collision_list(i_ship, i_tic)
				if not t_list.is_empty():
					swap_ship_velocities(i_ship, t_list[0])
					i_ship.point_at_velocity()
					t_list[0].point_at_velocity()
				# Create tween to move i_ship the next step
				var t_coord: Vector2i = i_ship.descrete_path.padded_steps[i_tic]
				move_ship_to(i_ship, t_coord, Constants.MOVE_TIME)
				# Create await timer with duration of move
				await get_tree().create_timer(Constants.MOVE_TIME).timeout


	all_moves_completed.emit()


func swap_ship_velocities(a_ship_1: Ship, a_ship_2: Ship) -> void:
	var t_paths: Array[DescretePath] = []
	t_paths.append(a_ship_1.descrete_path)
	t_paths.append(a_ship_2.descrete_path)
	a_ship_1.descrete_path = t_paths[1]
	a_ship_2.descrete_path = t_paths[0]
	var t_velocities: Array[Vector2i] = []
	t_velocities.append(a_ship_1.velocity)
	t_velocities.append(a_ship_2.velocity)
	a_ship_1.velocity = t_velocities[1]
	a_ship_2.velocity = t_velocities[0]



func collision_list(a_ship: Ship, a_tic: int) -> Array[Ship]:
	var t_list: Array[Ship] = []
	var t_coord: Vector2i = coords_from_position(a_ship.position)	# Current position
	t_coord += a_ship.descrete_path.padded_steps[a_tic]
	for i_ship: Ship in ships:
		if i_ship == a_ship: continue	# If current move is Zero we could match with a_ship
		if coords_from_position(i_ship.position) == t_coord:
			t_list.append(i_ship)
	return t_list


func process_collisions(a_players: ArrayInt) -> void:
	var t_ships: Array[Ship] = []
	var t_paths: Array[DescretePath] = []
	var t_velocities: Array[Vector2i] = []
	for i_player: int in a_players.i:
		t_ships.append(ships[i_player])
	for i_ship: Ship in t_ships:
		t_paths.append(i_ship.descrete_path)
		t_velocities.append(i_ship.velocity)
	# Take first path and put it at end
	# TODO: refactor to remove the double counting of velocity / path
	var t_path: DescretePath = t_paths.pop_front()
	var t_velocity: Vector2i = t_velocities.pop_front()
	t_paths.append(t_path)
	t_velocities.append(t_velocity)
	for i_index: int in range(t_ships.size()):
		t_ships[i_index].descrete_path = t_paths[i_index]
		t_ships[i_index].velocity = t_velocities[i_index]
	for i_ship: Ship in ships:
		i_ship.point_at_velocity()



# Key is coord of collision; item is list of players
func collision_report() -> Dictionary[Vector2i, ArrayInt]:
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



func move_ship_to(a_ship: Ship, a_coord: Vector2i, a_duration: float) -> void:
	var t_end: Vector2 = a_ship.position + Constants.ORIGINAL_SQUARE_SIZE * a_coord
	var t_tween: Tween = get_tree().create_tween()
	t_tween.tween_property(a_ship, "position", t_end, a_duration)
	draw_dot(coords_from_position(t_end), a_ship.player)


func draw_dot(a_coord: Vector2i, a_player: int) -> void:
	var t_dot: Sprite2D = Sprite2D.new()
	t_dot.texture = DOT
	grid_rect.add_child(t_dot)
	t_dot.scale = Vector2(10.5, 10.5)
	t_dot.modulate = Constants.player_color[a_player]
	t_dot.position = Constants.ORIGINAL_SQUARE_SIZE * a_coord
	dot_register.append(t_dot)


func on_ship_selected(a_ship: Ship) -> void:
	selected_ship = a_ship
	a_ship.create_markers()
