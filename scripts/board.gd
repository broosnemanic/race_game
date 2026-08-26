extends SubViewportContainer
class_name Board

signal ship_move_selected(a_ship: Ship)
signal all_moves_completed()

@onready var board_camera: Camera2D = %BoardCamera			# Shows an area of the board
@onready var grid_rect: TextureRect = %GridRect				# Board texture; parent to all added ships
@onready var board_viewport: SubViewport = $BoardViewport	# As it says
const ARROW_N: Texture2D = preload("uid://okolfthjmlqn")


var ships: Array[Ship]
var selected_ship: Ship
var descrete_path_register: Array[DescretePath] = []
var squares: Dictionary[Vector2i, Square] = {}			# Content at coords including wall location
var square_sprites: Dictionary[Vector2i, Sprite2D] = {}	# Sprite at coord
var trail_markers: Dictionary[int, Array] = {}			# Key: player; value: array of trail markers
var _last_mouse_coord: Vector2i = Vector2i.ZERO
var is_edit_mode: bool
var track_data: Dictionary[Vector2i, Constants.SQUARE_TYPE] = {}


# Unused
func _ready() -> void:
	pass


# Used for debugging
func _process(_delta: float) -> void:
	var t_mouse_coord: Vector2i = get_mouse_coord()
	if t_mouse_coord != _last_mouse_coord:
		#if squares.has(t_mouse_coord):
			#print(squares[t_mouse_coord].normal)
		_last_mouse_coord = t_mouse_coord


# 
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and is_edit_mode:
		var t_event: InputEventMouseButton = event
		if t_event.button_index == MOUSE_BUTTON_LEFT:
			add_block_at_mouse_pos(true)
		elif t_event.button_index == MOUSE_BUTTON_RIGHT:
			add_block_at_mouse_pos(false)
	if event is InputEventKey:
		var t_event: InputEventKey = event
		if t_event.pressed:
			if t_event.keycode == KEY_S:
				save_track()
			if t_event.keycode == KEY_L:
				load_track()


# As it says
func add_block_at_mouse_pos(a_is_add: bool) -> void:
	add_block_at(get_mouse_coord(), a_is_add)


# Used for building a track; populates track_data (to be saved to file)
func add_block_at(a_coord: Vector2i, a_is_add: bool) -> void:
	var t_block_sprite: Sprite2D
	if not a_is_add:
		if square_sprites.has(a_coord):
			t_block_sprite = square_sprites[a_coord]
			if not t_block_sprite == null:
				t_block_sprite.visible = false
				grid_rect.remove_child(t_block_sprite)
				t_block_sprite.queue_free()
				square_sprites[a_coord] = null
				track_data.erase(a_coord)
	elif not (square_sprites.has(a_coord) and square_sprites[a_coord] != null):
		t_block_sprite = new_block_sprite()
		square_sprites[a_coord] = t_block_sprite
		track_data[a_coord] = Constants.SQUARE_TYPE.BLOCK
		grid_rect.add_child(t_block_sprite)
		t_block_sprite.position = pos_from_coords(a_coord)


# As it says
func new_block_sprite() -> Sprite2D:
	var t_sprite: Sprite2D = Sprite2D.new()
	t_sprite.texture = Constants.LIGHT_TILE
	t_sprite.scale = Vector2(0.5, 0.5)
	return t_sprite


# TODO: add arg for file name
func save_track() -> void:
	var t_file: FileAccess = FileAccess.open("user://save_game.dat", FileAccess.WRITE)
	var t_string: String = var_to_str(track_data)
	t_file.store_string(t_string)
	t_file.flush()
	t_file.close()


# TODO: add arg for file name
func load_track() -> void:
	var t_file: FileAccess = FileAccess.open("user://save_game.dat", FileAccess.READ)
	track_data = str_to_var(t_file.get_as_text())
	process_track_data()
	display_track()


# Populate `squares` from `track_data`
func process_track_data() -> void:
	for i_coord: Vector2i in track_data:
		if track_data[i_coord] != Constants.SQUARE_TYPE.BLOCK: continue
		var t_set: Dictionary[Vector2i, Vector2i] = normal_set_from_coord(i_coord)
		# Merge t_set` into `squares`
		for j_coord: Vector2i in t_set:
			var t_normal: Vector2i = t_set[j_coord]
			if not squares.has(j_coord):
				squares[j_coord] = Square.new(t_set[j_coord], false)
			else:
				if is_semicardinal_dir(t_normal): continue
				t_normal = normal_sum(squares[j_coord].normal, t_set[j_coord])
				squares[j_coord] = Square.new(t_normal, false)
	# Add a block in `squares` at `i_coord`
	for i_coord: Vector2i in track_data:
		squares[i_coord] = Square.new()
	# Convex vs concave corners need to be marked
	process_corners()
	# Add normal arrows
	for i_coord: Vector2i in squares.keys():
		var t_square: Square = squares[i_coord]
		if t_square.is_block: continue
		var t_sprite: Sprite2D = arrow_from_normal(t_square.normal)
		grid_rect.add_child(t_sprite)
		t_sprite.position = pos_from_coords(i_coord)


# Returns set of normals surrounding a block at `a_coord`
func normal_set_from_coord(a_coord: Vector2i) -> Dictionary[Vector2i, Vector2i]:
	var t_set: Dictionary[Vector2i, Vector2i] = {}
	for i_dir: Vector2i in Constants.directions:
		var t_coord: Vector2i = a_coord + i_dir
		t_set[t_coord] = i_dir
	return t_set


# Sums two normals while keeping magnitude of x and y <= 1
func normal_sum(a_normal_0: Vector2i, a_normal_1: Vector2i) -> Vector2i:
	if is_cardinal_dir(a_normal_0) and is_semicardinal_dir(a_normal_1):
		return a_normal_0
	if is_cardinal_dir(a_normal_1) and is_semicardinal_dir(a_normal_0):
		return a_normal_1
	var t_x: int = a_normal_0.x + a_normal_1.x
	var t_y: int = a_normal_0.y + a_normal_1.y
	t_x = maxi(t_x, -1)		# Min value of t_x == -1
	t_x = mini(t_x, 1)		# Max value of t_x == 1
	t_y = maxi(t_y, -1)		# Min value of t_y == -1
	t_y = mini(t_y, 1)		# Max value of t_y == 1
	return Vector2i(t_x, t_y)


# Find and mark outer vs inner corners
func process_corners() -> void:
	for i_coord: Vector2i in squares.keys():
		var t_square: Square = squares[i_coord]
		if t_square.is_corner():
			t_square.is_convex = is_convex_corner(i_coord)


# As it says
func is_convex_corner(a_coord: Vector2i) -> bool:
	if not squares.has(a_coord): return false
	var t_square: Square = squares[a_coord]
	if not t_square.is_corner(): return false
	for i_dir: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if not squares.has(a_coord + i_dir): continue
		if squares[a_coord + i_dir].is_block: return false
	return true


# For debugging
func arrow_from_normal(a_normal: Vector2i) -> Sprite2D:
	var t_sprite: Sprite2D = Sprite2D.new()
	t_sprite.texture = ARROW_N
	t_sprite.modulate = Color.CORNFLOWER_BLUE
	t_sprite.modulate.a = 0.5
	var t_angle: float
	var t_pi_4: float = PI / 4.0
	match a_normal:
		Vector2i.UP:
			t_angle = 0.0
		Vector2i(1, -1):
			t_angle = 1.0 * t_pi_4
		Vector2i.RIGHT:
			t_angle = 2.0 * t_pi_4
		Vector2i(1, 1):
			t_angle = 3 * t_pi_4
		Vector2i.DOWN:
			t_angle = 4.0 * t_pi_4
		Vector2i(-1, 1):
			t_angle = 5.0 * t_pi_4
		Vector2i.LEFT:
			t_angle = 6.0 * t_pi_4
		Vector2i(-1, -1):
			t_angle = 7.0 * t_pi_4
		_:
			t_angle = 0.0	
	t_sprite.rotation = t_angle
	return t_sprite
	
	

# Is `a_dir` N, S, E, W?
func is_cardinal_dir(a_dir: Vector2i) -> bool:
	var t_sum: int = absi(a_dir.x + a_dir.y)
	return t_sum == 1


# Is `a_dir` NE, SE, SW, NW?
func is_semicardinal_dir(a_dir: Vector2i) -> bool:
	if a_dir == Vector2i.ZERO: return false
	var t_sum: int = absi(a_dir.x + a_dir.y)
	return t_sum != 1


# Display currently loaded track
func display_track() -> void:
	for i_coord: Vector2i in squares.keys():
		var t_square: Square = squares[i_coord]
		if t_square.is_block:
			add_block_at(i_coord, true)


# As it says
func get_mouse_coord() -> Vector2i:
	return coords_from_pos(grid_rect.get_local_mouse_position())


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


# As it says
func center_camera() -> void:
	board_camera.offset = Vector2(0.5 * grid_rect.size.x, 0.5 * grid_rect.size.y)


# Position snapped to center of nearest square
func snapped_pos(a_pos: Vector2) -> Vector2:
	return pos_from_coords(coords_from_pos(a_pos))


# As it says
func pos_from_coords(a_coords: Vector2i) -> Vector2:
	var t_x: float = a_coords.x as float * square_size
	var t_y: float = a_coords.y as float * square_size
	return Vector2(t_x, t_y)


# Square coords from a position
func coords_from_pos(a_pos: Vector2) -> Vector2i:
	var t_x: float = a_pos.x + 0.5 * square_size	# Grid texture ends at 1/2 square for better tiling
	var t_y: float = a_pos.y + 0.5 * square_size
	return Vector2i(floori(t_x / square_size), floori(t_y / square_size))


# Adds `a_ship` as a child of `grid_rect and connects `on_move_selected`
func add_ship(a_ship: Ship) -> void:
	ships.append(a_ship)
	grid_rect.add_child(a_ship)
	a_ship.z_index = Constants.SHIP_Z_INDEX + a_ship.player
	a_ship.move_selected.connect(on_move_selected)


# As it says
func select_ship(a_ship: Ship) -> void:
	on_ship_selected(a_ship)


# As it says
func select_first_ship() -> void:
	select_ship(ships[0])


# As it says
func select_next_ship() -> void:
	var t_index: int = 0 if selected_ship == null else selected_ship.player + 1
	if t_index < ships.size():
		select_ship(ships[t_index])


# Signal subscribed to by `GameControl`
func on_move_selected(a_ship: Ship) -> void:
	ship_move_selected.emit(a_ship)


# TODO: imp non-overlap tidying
func move_ships() -> void:
	preserve_ship_paths()
	# Tic count = max move count of all ships this turn
	var t_tic_count: int = 0
	for i_ship: Ship in ships:
		t_tic_count = maxi(t_tic_count, i_ship.descrete_path.count())
	# Pad all ship paths to have length wqual to `t_tic_count`
	for i_ship: Ship in ships:
		var t_path: DescretePath = i_ship.descrete_path
		t_path.populate_padded_steps(t_tic_count, t_path.coords[0], t_path.coords[-1])
		prints(coords_from_pos(i_ship.position), i_ship.velocity)
	# Loop through tics
	for i_tic: int in range(0, t_tic_count - 1):
		var t_coords: Array[Vector2i] = occupied_coords()
		for i_coord: Vector2i in t_coords:
			handle_wall_collisions_at(i_coord, i_tic)
		for i_ship: Ship in ships:
			# Move ship
			draw_trail_point(coords_from_pos(i_ship.position), i_ship.player)
			i_ship.point_at_endpoint(i_tic)
			var t_coord: Vector2i = i_ship.descrete_path.padded_steps[i_tic]
			move_ship_to(i_ship, t_coord, Constants.MOVE_TIME)
			# Create await timer with duration of move
			await get_tree().create_timer(Constants.MOVE_TIME).timeout
		recenter_ships()
		t_coords = occupied_coords()
		for i_coord: Vector2i in t_coords:
			handle_collisions_at(i_coord)
		fade_trail_markers()
		#for i_coord: Vector2i in t_coords:
			#handle_wall_collisions_at(i_coord)
		#for i_ship: Ship in ships:
			#var t_list: Array[Ship] = collision_list(i_ship, i_tic)
			#if not t_list.is_empty():
				#swap_ship_velocities(i_ship, t_list[0])
				#i_ship.point_at_velocity()
				#t_list[0].point_at_velocity()
	if t_tic_count <= 1:	# Ensures at least on wait interval (to properly sych)
		await get_tree().create_timer(Constants.MOVE_TIME).timeout
	all_moves_completed.emit()


#
func fade_trail_markers() -> void:
	for i_player: int in trail_markers.keys():
		# Remove nulls from set of trail markers for `i_player`
		var t_markers: Array = trail_markers[i_player]
		trail_markers[i_player] = null_trimmed_array(t_markers)
		t_markers = trail_markers[i_player]
		# Fade markers
		for i_marker: Sprite2D in t_markers:
			var t_mod: Color = i_marker.modulate
			t_mod.a *= 0.9
			i_marker.modulate = t_mod
		# Remove invisible markers
		for i_index: int in range(t_markers.size()):
			var t_marker: Sprite2D = t_markers[i_index]
			if t_marker.modulate.a < 0.1:
				t_marker.queue_free()
				t_markers[i_index] = null


# Returns copy of `a_array` with no null items 
func null_trimmed_array(a_array: Array) -> Array:
	var t_array: Array = []
	for i_index: int in range(a_array.size()):
		if a_array[i_index] != null:
			t_array.append(a_array[i_index])
	return t_array


# Snap all ships to center of occupied square
func recenter_ships() -> void:
	for i_ship: Ship in ships:
		var t_pos: Vector2 = i_ship.position
		t_pos = pos_from_coords(coords_from_pos(t_pos))
		i_ship.position = t_pos 




# At this momenet which squares are coccupied by a ship?
func occupied_coords() -> Array[Vector2i]:
	var t_dict: Dictionary[Vector2i, Vector2i] = {}
	for i_ship: Ship in ships:
		var t_coords: Vector2i = coords_from_position(i_ship.position)
		t_dict[t_coords] = t_coords
	return t_dict.keys()


#
func ships_at(a_coords: Vector2i) -> Array[Ship]:
	var t_ships: Array[Ship] = []
	for i_ship: Ship in ships:
		var t_coords: Vector2i = coords_from_position(i_ship.position)
		if t_coords == a_coords:
			t_ships.append(i_ship)
	return t_ships


# If there ia a collision at `a_coord` shuffle ship velocities
func handle_collisions_at(a_coords: Vector2i) -> void:
	var t_ships: Array[Ship] = ships_at(a_coords)
	var t_size: int = t_ships.size()
	if t_size <= 1: return
	var t_new_velocities: Array[Vector2i] = []
	var x_offset: int = _random_index_offset(t_size)
	var y_offset: int = _random_index_offset(t_size)
	for i_index: int in range(t_size):
		var t_x: int = (i_index + x_offset) % t_size
		var t_y: int = (i_index + y_offset) % t_size
		var t_velocity: Vector2i = Vector2i(ships[t_x].velocity.x, ships[t_y].velocity.y)
		t_new_velocities.append(t_velocity)
	for i_index: int in range(t_size):
		var t_ship: Ship = ships[i_index]
		var t_tic_count: int = t_ship.descrete_path.padded_steps.size()
		t_ship.set_velocity(t_new_velocities[i_index])
		var t_path: DescretePath = t_ship.descrete_path
		t_path.populate_padded_steps(t_tic_count, Vector2i.ZERO, t_ship.velocity)
		#t_ship.point_at_velocity()


#
func handle_wall_collisions_at(a_coords: Vector2i, a_tic: int) -> void:
	if not squares.has(a_coords): return
	var t_square: Square = squares[a_coords]
	if t_square == null: return
	var t_normal: Vector2i = t_square.normal
	if t_normal == null: return
	var t_ships: Array[Ship] = ships_at(a_coords)
	var t_size: int = t_ships.size()
	for i_index: int in range(t_size):
		var t_ship: Ship = ships[i_index]
		var t_step: Vector2i = t_ship.descrete_path.padded_steps[a_tic]
		#if is_wall_collision(t_square, t_ship.velocity):
		if is_wall_collision(t_square, t_step):
			var t_new_velocity: Vector2i = -2 * abs(t_normal) * t_ship.velocity + t_ship.velocity
			t_ship.set_velocity(t_new_velocity)
			var t_tic_count: int = t_ship.descrete_path.padded_steps.size()
			var t_path: DescretePath = t_ship.descrete_path
			t_path.populate_padded_steps(t_tic_count, Vector2i.ZERO, t_ship.velocity)
			t_ship.point_at_velocity()


# Will stepping _out_ of `a_square` in direction `a_step` result in being inside a wall?
func is_wall_collision(a_square: Square, a_step: Vector2i) -> bool:
	if a_step == Vector2i.ZERO: return false
	var t_normal: Vector2i = a_square.normal
	if a_square.is_corner():
		var t_is_opp_x: bool = is_opposing_sign(t_normal.x, a_step.x)
		var t_is_opp_y: bool = is_opposing_sign(t_normal.y, a_step.y)
		if a_square.is_convex:
			return t_is_opp_x and t_is_opp_y
		else:
			return t_is_opp_x or t_is_opp_y
	else:
		if t_normal.x == 0:
			return is_same_sign(-t_normal.y, a_step.y)
		else:
			return is_same_sign(-t_normal.x, a_step.x)


# Note: Zero matches nothing
func is_same_sign(a_int_0: int, a_int_1: int) -> bool:
	if a_int_0 == 0 or a_int_1 == 0: return false
	return sign(a_int_0) == sign(a_int_1)


# 
func is_opposing_sign(a_int_0: int, a_int_1: int) -> bool:
	if a_int_0 == 0 or a_int_1 == 0: return false
	return sign(a_int_0) != sign(a_int_1)


# Returns random offset guaranteed to not wrap back to zero
func _random_index_offset(a_array_size: int) -> int:
	return 1 + randi() % (a_array_size - 1)


# TODO: this is simplest version; rewrite to allow many-ship collisions
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


# List of ships at same coords as `a_ship` at time `a_tic`
func collision_list(a_ship: Ship, a_tic: int) -> Array[Ship]:
	var t_list: Array[Ship] = []
	var t_coord: Vector2i = coords_from_position(a_ship.position)	# Current position
	t_coord += a_ship.descrete_path.padded_steps[a_tic]
	for i_ship: Ship in ships:
		if i_ship == a_ship: continue	# If current move is Zero we could match with a_ship
		if coords_from_position(i_ship.position) == t_coord:
			t_list.append(i_ship)
	return t_list


# Does not seem to be used
func _process_collisions(a_players: ArrayInt) -> void:
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


# Grid coords from position on board
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


# Draw and store path each ship is about to make
# Note this means the incorrect path gets drawn when there is a collision
func preserve_ship_paths() -> void:
	for i_ship: Ship in ships:
		# TODO: Note - we no longer preserve the path all at once, but instead
		# point by point
		#var t_path: DescretePath = DescretePath.new()
		#t_path.coords = i_ship.descrete_path.coords
		#t_path.color = Constants.player_color[i_ship.player]
		#t_path.draw_points(t_path.coords)
		#descrete_path_register.append(t_path)
		#grid_rect.add_child(t_path)
		#t_path.global_position = i_ship.descrete_path.global_position
		i_ship.descrete_path.clear_line()
	fade_descrete_paths()


func draw_trail_point(a_coord: Vector2i, a_player: int) -> void:
	var t_sprite: Sprite2D = Sprite2D.new()
	t_sprite.texture = Constants.WHITE_TILE
	t_sprite.modulate = Constants.player_color[a_player]
	t_sprite.modulate.a = 0.85
	t_sprite.scale = 0.15 * Vector2.ONE
	grid_rect.add_child(t_sprite)
	t_sprite.position = a_coord * Constants.ORIGINAL_SQUARE_SIZE
	var t_markers: Array
	t_markers = [] if not trail_markers.has(a_player) else trail_markers[a_player]
	t_markers.append(t_sprite)
	trail_markers[a_player] = t_markers
	#if not point_markers.is_empty():
		#point_markers.back().modulate.a = 1.0
		#point_markers.back().scale = 0.25 * Vector2i.ONE





# As it says
func fade_descrete_paths() -> void:
	for i_path: DescretePath in descrete_path_register:
		i_path.fade(Constants.FADE_INCR)
	remove_old_paths()


# Remove paths that are no longer visible
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


# Note this is used to move `a_ship` one square on a valid tic
func move_ship_to(a_ship: Ship, a_coord: Vector2i, a_duration: float) -> void:
	var t_end: Vector2 = a_ship.position + Constants.ORIGINAL_SQUARE_SIZE * a_coord
	# Check that we are not trying to move into a wall
	if is_block_at_pos(t_end):
		# TODO: debugging
		pass
		#t_end = a_ship.position
	var t_tween: Tween = get_tree().create_tween()
	t_tween.tween_property(a_ship, "position", t_end, a_duration)


#
func is_block_at_pos(a_pos: Vector2) -> bool:
	return  is_block_at_coord(coords_from_pos(a_pos))


#
func is_block_at_coord(a_coord: Vector2i) -> bool:
	if not squares.has(a_coord): return false
	var t_square: Square = squares[a_coord]
	return t_square.is_block



# Actions to perform when `a_ship` is selected
func on_ship_selected(a_ship: Ship) -> void:
	selected_ship = a_ship
	a_ship.create_markers()


#
func draw_track() -> void:
	for i_coord: Vector2i in squares.keys():
		draw_square_at(i_coord, squares[i_coord])


#
func draw_square_at(a_coord: Vector2i, a_square: Square) -> void:
	var t_center: Vector2 = pos_from_coords(a_coord)
	var t_offest: float = 0.5 * square_size
	var t_normal: Vector2i = a_square.normal
	var t_perp: Vector2i = Vector2i(t_normal.y, t_normal.x)
	if not is_corner_normal(t_normal):
		var t_point_0: Vector2 = t_center
		var t_point_1: Vector2 = t_center
		t_point_0 += -1.0 * t_offest * t_normal
		t_point_1 += -1.0 * t_offest * t_normal
		t_point_0 += 1.0 * t_offest * t_perp
		t_point_1 += -1.0 * t_offest * t_perp
		var t_line: Line2D = Line2D.new()
		t_line.default_color = Color.TEAL
		grid_rect.add_child(t_line)
		t_line.add_point(t_point_0)
		t_line.add_point(t_point_1)



# Does `a_normal` represent a wall corner?
func is_corner_normal(a_normal: Vector2i) -> bool:
	return a_normal.x != 0 and a_normal.y != 0
	
	
