extends Node

# Starts at zero deg -> ccw; pos y: downwards
const directions: Array[Vector2i] = [	Vector2i(1, 0),
										Vector2i(1, -1),
										Vector2i(0, -1),
										Vector2i(-1, -1),
										Vector2i(-1, 0),
										Vector2i(-1, 1),
										Vector2i(0, 1),
										Vector2i(1, 1),
										]


const player_color: Dictionary[int, Color] = {	0: Color("blue"),
												1: Color("red"),
												2: Color("00a07aff")
											}

const MOVE_TIME: float = 0.5
#const SHIP_Z: int = 3
# Tiling grid image is 256 px with 4x4 squares
const ORIGINAL_SQUARE_SIZE: float = 256.0 / 4.0
const WHITE_TILE: Texture2D = preload("uid://o1lgoog0pi14")

const MARKER_COLOR: Color = Color.DARK_GREEN

const FADE_FACTOR: float = 0.85
const FADE_INCR: float = 0.15

const PATH_Z_INDEX: int = 10
const SHIP_Z_INDEX: int = 20
