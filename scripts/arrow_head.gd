extends Node2D
class_name ArrowHead

var color: Color = Color.RED
var width: float = 100.0		# X direction
var height: float = 150.0		# Y-direction
var angle: float = 0.0			# Zero == pointing up
var offset: Vector2 = Vector2.ZERO


func _draw() -> void:
	var t_tip: Vector2 = Vector2(0, -height) + offset
	var t_left: Vector2 = Vector2(-0.5 * width, 0.0) + offset
	var t_right: Vector2 = Vector2(0.5 * width, 0.0) + offset
	draw_colored_polygon([t_tip, t_left, t_right], color)


func circle_coord(a_time: float) -> Vector2:
	var t_factor: float = 0.0001
	var t_x: float = cos(a_time * t_factor)
	var t_y: float = sin(a_time * t_factor)
	return 100.0 * Vector2(t_x, t_y)


# Zero radians is pointing up
func point_at_angle(a_radians: float) -> void:
	rotation = a_radians


func point_along_coords(a_start: Vector2, a_end: Vector2) -> void:
	rotation = head_rotation(a_start, a_end)
	queue_redraw()


func head_rotation(a_start: Vector2, a_end: Vector2) -> float:
	var t_x_dist: float = 1.0 * a_end.x - a_start.x
	var t_y_dist: float = 1.0 * (a_end.y - a_start.y)
	var t_hyp: float = sqrt(pow(t_x_dist, 2.0) + pow(t_y_dist, 2.0))
	var t_rot: float = asin(absf(t_y_dist) / t_hyp)
	if t_x_dist > 0.0 and t_y_dist > 0.0:
		t_rot = t_rot
	if t_x_dist >= 0.0 and t_y_dist < 0.0:
		t_rot = (2.0 * PI) - t_rot
	if t_x_dist < 0.0 and t_y_dist >= 0.0:
		t_rot = PI - t_rot
	if t_x_dist < 0.0 and t_y_dist < 0.0:
		t_rot = PI + t_rot
	t_rot -= 0.5 * PI
	t_rot += PI
	return t_rot
