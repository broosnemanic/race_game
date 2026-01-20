extends Node2D

const SQUARE_WIDTH: float = 128.0

@onready var texture_rect: TextureRect = $TextureRect
@onready var camera_2d: Camera2D = $Camera2D
@onready var dot: Sprite2D = $Dot
@onready var viewport_size: Vector2 = get_viewport_rect().size
@onready var dark_tile: Sprite2D = $DarkTile
@onready var highlight: Sprite2D = $Highlight


const DARK_TILE: Texture2D = preload("uid://10h1y52et7j0")
const LIGHT_TILE: Texture2D = preload("uid://crkmjka1gcgkc")



var selected_coord: Vector2i = Vector2i.ZERO
var line_squares: Array[Sprite2D] = []


func _ready() -> void:
	texture_rect.size = Vector2(SQUARE_WIDTH * 40, SQUARE_WIDTH * 40)
	texture_rect.position = -0.5 * texture_rect.size
	highlight.position = position_from_coord(Vector2i.ZERO)
	dark_tile.z_index = 1
	highlight.z_index = 2


#func _draw() -> void:
	#draw_circle(Vector2i(500.0, 300.0), 100.0, Color.DARK_MAGENTA,)
	



func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var t_event: InputEventMouseMotion = event as InputEventMouseMotion
		var t_pos: Vector2 = centered_position(t_event.position)
		var t_coord: Vector2i = coords_from_pos(t_pos)
		if t_coord != selected_coord:
			selected_coord = t_coord
			dark_tile.position = position_from_coord(t_coord)
			draw_squares(line_coords(Vector2i.ZERO, selected_coord))



func centered_position(a_pos: Vector2) -> Vector2:
	return a_pos - 0.5 * viewport_size

func coords_from_pos(a_pos: Vector2) -> Vector2i:
	var t_factor: float = pow(SQUARE_WIDTH * camera_2d.zoom.x, -1)
	var t_x: int = ceili(t_factor * a_pos.x)
	var t_y: int = ceili(t_factor * a_pos.y)
	return Vector2i(t_x, t_y)


func position_from_coord(a_coord: Vector2i) -> Vector2:
	var t_x: float = a_coord.x as float * SQUARE_WIDTH
	var t_y: float = a_coord.y as float * SQUARE_WIDTH
	return Vector2(t_x, t_y) - 0.5 * Vector2(SQUARE_WIDTH, SQUARE_WIDTH)


# [x dist, y dist, diag dist]
func direction_counts(a_start: Vector2i, a_end: Vector2i) -> Array[int]:
	var t_delta: Vector2i = abs(a_end - a_start)
	var t_diag: int = mini(t_delta.x, t_delta.y)
	var t_x: int = maxi(0, t_delta.x - t_diag)
	var t_y: int = maxi(0, t_delta.y - t_diag)
	return [t_x, t_y, t_diag]


func distributed_directions(a_start: Vector2i, a_end: Vector2i) -> Array[Vector2i]:
	var t_directions: Array[Vector2i] = []
	var t_counts: Array[int] = direction_counts(a_start, a_end)
	var t_sign_x: int = 1 if a_end.x - a_start.x >= 0 else -1
	var t_sign_y: int = 1 if a_end.y - a_start.y >= 0 else -1
	var t_total: int = t_counts[0] + t_counts[1] + t_counts[2]
	var t_diag: Vector2i = Vector2i(t_sign_x, t_sign_y)
	var t_x: Vector2i = Vector2i(t_sign_x, 0)
	var t_y: Vector2i = Vector2i(0, t_sign_y)
	t_directions.resize(t_total)
	t_directions.fill(t_diag)
	var t_step: float
	if t_counts[0] > 0:
		t_step = t_total as float / t_counts[0]
		for i_index: int in range(0, t_counts[0]):
				t_directions[floori(i_index * t_step)] = t_x

	if t_counts[1] > 0:
		t_step = t_total as float / t_counts[1]
		for i_index: int in range(0, t_counts[1]):
				t_directions[floori(i_index * t_step)] = t_y


	return t_directions
#
#
#func distributed_directions(a_direction_counts: Array[int]) -> Array[int]:
	#var t_horz: int = a_direction_counts[0]
	#var t_vert: int = a_direction_counts[1]
	#var t_diag: int = a_direction_counts[2]
	#while t_horz > 0 and t_vert > 0 and t_diag > 0:
		#pass
	#return []


# Version before attempting to add interpollation
#func line_coords(a_start: Vector2i, a_end: Vector2i) -> Array[Vector2i]:
	#var t_coords: Array[Vector2i] = [a_start]
	#var t_dir_counts: Array[int] = direction_counts(a_start, a_end)
	#var t_sign_x: int = 1 if a_end.x - a_start.x >= 0 else -1
	#var t_coord: Vector2i = a_start
	#for i_index: int in range(t_dir_counts[0]):
		#t_coord += Vector2i(t_sign_x, 0)
		#t_coords.append(t_coord)
	#var t_sign_y: int = 1 if a_end.y - a_start.y >= 0 else -1
	#for i_index: int in range(t_dir_counts[1]):
		#t_coord += Vector2i(0, t_sign_y)
		#t_coords.append(t_coord)
	#for i_index: int in range(t_dir_counts[2]):
		#t_coord += Vector2i(t_sign_x, t_sign_y)
		#t_coords.append(t_coord)
	#return t_coords


func line_coords(a_start: Vector2i, a_end: Vector2i) -> Array[Vector2i]:
	var t_coord: Vector2i = a_start
	var t_coords: Array[Vector2i] = [t_coord]
	var t_steps: Array[Vector2i] = distributed_directions(a_start, a_end)
	for i_step: Vector2i in t_steps:
		t_coord += i_step
		t_coords.append(t_coord)
	return t_coords


func clear_line() -> void:
	for i_square: Sprite2D in line_squares:
		i_square.queue_free()
	line_squares = []



func draw_squares(a_coords: Array[Vector2i]) -> void:
	clear_line()
	for i_coord: Vector2i in a_coords:
		var t_sprite: Sprite2D = Sprite2D.new()
		t_sprite.texture = LIGHT_TILE
		t_sprite.z_index = 10
		add_child(t_sprite)
		t_sprite.position = position_from_coord(i_coord)
		line_squares.append(t_sprite)
	
	
	
	
	
	
