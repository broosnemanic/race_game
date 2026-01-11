extends SubViewportContainer
class_name Board

signal ship_move_completed(a_ship: Ship)
signal ship_move_selected(a_ship: Ship)

@onready var board_camera: Camera2D = %BoardCamera
@onready var grid_rect: TextureRect = %GridRect
@onready var board_viewport: SubViewport = $BoardViewport

const TILE_0680: Texture2D = preload("uid://c413je2hltv8q")
const CROSSHAIR_TEX_00: Texture2D = preload("uid://b01dx1v65uhom")
const TARGET_MARKER: Texture2D = preload("uid://cf85b3rajkbrk")
const DOT: Texture2D = preload("uid://dup115kj27cgg")

var crosshair: Sprite2D
var ships: Array[Ship]
var selected_ship: Ship
var mouse_pos: Vector2		# Relative to SubViewportContainer not viewport position
var trace_register: Array[Line2D]
var dot_register: Array[Sprite2D]


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
		#crosshair.position = snapped_pos(mouse_pos)




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
	a_ship.z_index = Constants.SHIP_Z + a_ship.player
	a_ship.selected.connect(on_ship_selected)
	a_ship.move_selected.connect(on_move_selected)
	#a_ship.position = snapped_pos(board_camera.offset)
	#a_ship.create_markers()


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
	#var t_coord: Vector2i = a_ship.coords()
	#a_ship.destroy_markers()
	#draw_dot(t_coord)
	#var t_end: Vector2 = a_ship.position + Constants.ORIGINAL_SQUARE_SIZE * a_ship.velocity
	#var t_tween: Tween = get_tree().create_tween()
	#t_tween.tween_property(a_ship, "position", t_end, Constants.MOVE_TIME)
	#t_tween.finished.connect(ship_move_completed.emit.bind(a_ship))
	#draw_trace(t_coord, a_ship.coords() + a_ship.velocity, 0)



func move_ships() -> void:
	fade_traces()
	fade_dots()
	for i_ship: Ship in ships:
		move_ship(i_ship)


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
		#i_trace.modulate.a *= Constants.FADE_FACTOR
		i_trace.modulate.a -= Constants.FADE_INCR


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
