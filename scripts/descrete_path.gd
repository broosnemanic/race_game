extends Node2D
class_name DescretePath

var coords: Array[Vector2i] = []				# Int coord of points
var point_markers: Array[Sprite2D] = []			# Graphical representation of points
var color: Color = Color.FUCHSIA				# Default point_marker color
var tic: int = 0								# Current place in coords list
var padded_steps: Array[Vector2i]				# Unit steps composing entire path, padded to a length with ZERO steps 

const POINT_TEXTURE: Texture2D = preload("uid://dup115kj27cgg")
const ENDPOINT_TEXTURE: Texture2D = preload("uid://dipjdkw86aunk")


func _init() -> void:
	z_index = Constants.PATH_Z_INDEX
	z_as_relative = false


# Utility for drawing grid-style line
# [x dir count, y dir count, diag dir count]
func direction_counts(a_start: Vector2i, a_end: Vector2i) -> Array[int]:
	var t_delta: Vector2i = abs(a_end - a_start)
	var t_diag: int = mini(t_delta.x, t_delta.y)
	var t_x: int = maxi(0, t_delta.x - t_diag)
	var t_y: int = maxi(0, t_delta.y - t_diag)
	return [t_x, t_y, t_diag]


# Count of descrete points
func count() -> int:
	return coords.size()


func clear_line() -> void:
	for i_square: Sprite2D in point_markers:
		i_square.queue_free()
	point_markers = []


func draw_points(a_coords: Array[Vector2i]) -> void:
	clear_line()
	coords = a_coords
	for i_coord: Vector2i in a_coords:
		var t_sprite: Sprite2D = Sprite2D.new()
		t_sprite.texture = Constants.WHITE_TILE
		t_sprite.modulate = color
		t_sprite.modulate.a = 0.85
		t_sprite.scale = 0.15 * Vector2.ONE
		add_child(t_sprite)
		t_sprite.position = i_coord * Constants.ORIGINAL_SQUARE_SIZE
		point_markers.append(t_sprite)
	if not point_markers.is_empty():
		point_markers.back().modulate.a = 1.0
		point_markers.back().scale = 0.25 * Vector2i.ONE


func draw_from_endpoints(a_start: Vector2i, a_end: Vector2i) -> void:
	var t_coords: Array[Vector2i] = line_coords(a_start, a_end)
	draw_points(t_coords)


# Utility for drawing grid-style line
# Applies list of moves from distributed_directions to a start and end coord
func line_coords(a_start: Vector2i, a_end: Vector2i) -> Array[Vector2i]:
	var t_coord: Vector2i = a_start
	var t_coords: Array[Vector2i] = [t_coord]
	var t_steps: Array[Vector2i] = distributed_directions(a_start, a_end)
	for i_step: Vector2i in t_steps:
		t_coord += i_step
		t_coords.append(t_coord)
	return t_coords


# Utility for drawing grid-style line
# Returns list of unit vectors which draw a reasonble straight line
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


func populate_padded_steps(a_path_length: int, a_start: Vector2i, a_end: Vector2i) -> void:
	var t_steps: Array[Vector2i] = distributed_directions(a_start, a_end)
	var t_padded: Array[Vector2i] = []
	t_padded.resize(a_path_length)
	t_padded.fill(Vector2i.ZERO)
	var t_step: float = a_path_length as float / t_steps.size()
	for i_index: int in range(0, t_steps.size()):
			t_padded[floori(i_index * t_step)] = t_steps[i_index]
	padded_steps = t_padded


func fade(a_fraction: float) -> void:
	for i_sprite: Sprite2D in point_markers:
		var t_alpha: float = i_sprite.modulate.a
		t_alpha = maxf(0.0, t_alpha - a_fraction)
		i_sprite.modulate.a = t_alpha


func alpha() -> float:
	if point_markers.is_empty(): return 0.0
	return point_markers.front().modulate.a
