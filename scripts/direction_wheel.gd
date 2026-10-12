extends Area2D
class_name DirectionWheel

signal direction_selected(a_direction: Vector2i)			# Emitted when user selects a direction
signal direction_hovered(a_direction: Vector2i)				# Emitted when user hovers over a new direction

@onready var sprite: Sprite2D = $Sprite

var _last_mouse_position: Vector2							# For checking if mouse has moved
var is_mouse_in_area: bool									# Is mouse over `this`?
var octant: int												# Where is `this` pointing?
var hovered_direction: Vector2i								# Direction currently hovered over
var selected_direction: Vector2i							# Direction selected
var wait: float												# Time elapsed since last mouse position evaluation

const IDLE_SPRITE: CompressedTexture2D = preload("uid://b02ss0xdgapn4")
const POINTING_SPRITE: CompressedTexture2D = preload("uid://b0uakq4kdwuvh")
const PI_DIV_8: float = PI / 8.0
const PI_DIV_4: float = PI / 4.0
const MIN_WAIT: float = 0.1									# Minimum wait time between mouse position evaluations
const MIN_DIST: float = 0.1									# Minimum distance between mouse positions to register as a change
const CENTRAL_DIST: float = 64.0							# Defines area that registers as zero accelaration



func _ready() -> void:
	direction_hovered.connect(func(a_dir: Vector2i): prints("hovered", hovered_direction))
	direction_selected.connect(func(a_dir: Vector2i): prints("selected", selected_direction))


func _process(delta: float) -> void:
	var t_pos: Vector2
	if is_valid_process_conditions(delta):
		t_pos = get_local_mouse_position()
		_last_mouse_position = t_pos
		wait = 0.0
	else:
		wait += delta
		return
	handle_mouse_move(t_pos)


# Has time and mouse position changed enough to warrent action?
func is_valid_process_conditions(a_delta: float) -> bool:
	if not is_mouse_in_area: return false
	if is_near(_last_mouse_position, get_local_mouse_position()): return false
	if wait + a_delta < MIN_WAIT: return false
	return true


# Trigger direction change actions if necessary
func handle_mouse_move(a_position: Vector2) -> void:
	var t_direction: Vector2i
	if a_position.length() < CENTRAL_DIST:
		sprite.texture = IDLE_SPRITE
		t_direction = Vector2i.ZERO
	else:
		sprite.texture = POINTING_SPRITE
		t_direction = direction_from_angle(a_position.angle())
	if hovered_direction != t_direction:
		hovered_direction = t_direction
		direction_hovered.emit(hovered_direction)
		set_sprite_rotation(a_position.angle())


# Are `a_vec_1` and `a_vec_2` close enough to be considered the same?
func is_near(a_vec_1: Vector2, a_vec_2: Vector2) -> bool:
	return (a_vec_2 - a_vec_1).length() < MIN_DIST


# Handle mouse input
func _input(a_event: InputEvent) -> void:
	if not is_mouse_in_area: return
	if a_event is InputEventMouseButton:
		var t_event: InputEventMouseButton = a_event as InputEventMouseButton
		if t_event.button_index == MOUSE_BUTTON_LEFT:
			if t_event.pressed:
				selected_direction = hovered_direction
				direction_selected.emit(selected_direction)


# As it says
func _mouse_enter() -> void:
	is_mouse_in_area = true


# As it says
func _mouse_exit() -> void:
	is_mouse_in_area = false


# 
func set_octant_from_angle(a_radians: float) -> void:
	var t_radians: float = clamped_angle(a_radians)
	t_radians += PI_DIV_8
	var t_slice_multiple: int =  floori(t_radians / PI_DIV_4)
	octant = t_slice_multiple % 8
	sprite.rotation = ((octant + 2) as float) * PI_DIV_4


# Snaps sprite rotation to closest 8-cardinal direction
func set_sprite_rotation(a_radians: float) -> void:
	var t_radians: float = clamped_angle(a_radians)
	t_radians += PI_DIV_8
	var t_slice_multiple: int =  floori(t_radians / PI_DIV_4)
	var t_octant: int = t_slice_multiple % 8
	sprite.rotation = ((t_octant + 2) as float) * PI_DIV_4


# 
func octant_from_angle(a_radians: float) -> int:
	var t_radians: float = clamped_angle(a_radians)
	t_radians += PI_DIV_8
	var t_slice_multiple: int =  floori(t_radians / PI_DIV_4)
	return t_slice_multiple % 8


#
func set_hovered_direction_from_angle(a_radians: float) -> void:
	hovered_direction = direction_from_angle(a_radians)
	direction_hovered.emit(hovered_direction)


# 
func direction_from_angle(a_radians: float) -> Vector2i:
	var t_octant: int = octant_from_angle(a_radians)
	match t_octant:
		0: return Vector2i.RIGHT
		1: return Vector2i(1, 1)
		2: return Vector2i.DOWN
		3: return Vector2i(-1, 1)
		4: return Vector2i.LEFT
		5: return Vector2i(-1, -1)
		6: return Vector2i.UP
		7: return Vector2i(1, -1)
		_: return Vector2i.ZERO


# Convert `a_angle` to equivalent [0, 2PI]
func clamped_angle(a_angle: float) -> float:
	var t_direction: float
	var t_angle: float = a_angle
	if t_angle <= 0.0:
		t_direction = 1.0
	else:
		t_direction = -1.0
	while t_angle < 0.0 or t_angle > 2.0 * PI:
		t_angle += t_direction * 2.0 * PI
	return t_angle
	
	
	
	
	
	
	
