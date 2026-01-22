extends Node2D
class_name DescretePath


var coords: Array[Vector2i] = []
var point_markers: Array[Sprite2D] = []
var color: Color = Color.FUCHSIA

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



func fade(a_fraction: float) -> void:
	for i_sprite: Sprite2D in point_markers:
		var t_alpha: float = i_sprite.modulate.a
		t_alpha = maxf(0.0, t_alpha - a_fraction)
		i_sprite.modulate.a = t_alpha


func alpha() -> float:
	if point_markers.is_empty(): return 0.0
	return point_markers.front().modulate.a
