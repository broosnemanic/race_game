extends Area2D
class_name DirectionWheel

signal selected(a_wheel: DirectionWheel)					# Emitted when user selects a direction



@onready var sprite: Sprite2D = $Sprite

var _last_mouse_position: Vector2							# For checking if mouse has moved
var is_mouse_in_area: bool									# Is mouse over `this`?
var octant: int												# Where is `this` pointing?


const IDLE_SPRITE = preload("uid://b02ss0xdgapn4")
const POINTING_SPRITE = preload("uid://b0uakq4kdwuvh")
const PI_DIV_8: float = PI / 8.0
const PI_DIV_4: float = PI / 4.0

var t_wait: float


func _process(delta: float) -> void:
	if not is_mouse_in_area: return
	var t_pos: Vector2 = get_local_mouse_position()
	if is_near(_last_mouse_position, t_pos): return
	_last_mouse_position = t_pos
	t_wait += delta
	if t_wait < 0.1:
		return
	else:
		t_wait = 0.0
	if t_pos.length() < 64.0:
		sprite.texture = IDLE_SPRITE
	else:
		sprite.texture = POINTING_SPRITE
	var t_angle: float = t_pos.angle()
	set_octant_from_angle(t_angle)


func is_near(a_vec_1: Vector2, a_vec_2: Vector2) -> bool:
	return (a_vec_2 - a_vec_1).length() < 0.1


func _input(a_event: InputEvent) -> void:
	if not is_mouse_in_area: return
	if a_event is InputEventMouseButton:
		var t_event: InputEventMouseButton = a_event as InputEventMouseButton
		if t_event.button_index == MOUSE_BUTTON_LEFT:
			if t_event.pressed:
				selected.emit(self)



func _mouse_enter() -> void:
	is_mouse_in_area = true


func _mouse_exit() -> void:
	is_mouse_in_area = false


# 
func set_octant_from_angle(a_radians: float) -> void:
	var t_radians: float = clamped_angle(a_radians)
	t_radians += PI_DIV_8
	var t_slice_multiple: int =  floori(t_radians / PI_DIV_4)
	octant = t_slice_multiple % 8
	sprite.rotation = ((octant + 2) as float) * PI_DIV_4


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
	
	
	
	
	
	
	
