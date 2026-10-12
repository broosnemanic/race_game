extends Node

# Grid coords from position on board
func coords_from_position(a_pos: Vector2) -> Vector2i:
	var t_x: int = floori(a_pos.x / Constants.SQUARE_SIZE)
	var t_y: int = floori(a_pos.y / Constants.SQUARE_SIZE)
	return Vector2i(t_x, t_y)


# As it says
func pos_from_coords(a_coords: Vector2i) -> Vector2:
	var t_x: float = a_coords.x as float * Constants.SQUARE_SIZE
	var t_y: float = a_coords.y as float * Constants.SQUARE_SIZE
	return Vector2(t_x, t_y)


# Square coords from a position
func coords_from_pos(a_pos: Vector2) -> Vector2i:
	var t_x: float = a_pos.x + 0.5 * Constants.SQUARE_SIZE	# Grid texture ends at 1/2 square for better tiling
	var t_y: float = a_pos.y + 0.5 * Constants.SQUARE_SIZE
	return Vector2i(floori(t_x / Constants.SQUARE_SIZE), floori(t_y / Constants.SQUARE_SIZE))
