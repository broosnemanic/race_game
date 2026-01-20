extends Node2D
class_name DescretePath

var point_markers: Array[Sprite2D] = []
const POINT_TEXTURE: Texture2D = preload("uid://crkmjka1gcgkc")




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
	for i_coord: Vector2i in a_coords:
		var t_sprite: Sprite2D = Sprite2D.new()
		t_sprite.texture = POINT_TEXTURE
		t_sprite.z_index = 10
		t_sprite.scale = 0.25 * Vector2.ONE
		add_child(t_sprite)
		t_sprite.position = i_coord * Constants.ORIGINAL_SQUARE_SIZE
		point_markers.append(t_sprite)
	
