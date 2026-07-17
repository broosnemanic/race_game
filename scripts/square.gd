extends RefCounted
class_name Square

## Represents contents at a coordinate - including wall location ##

var normal: Vector2i		# Normal to wall direction, if any
var is_convex: bool			# If a corner square, is it a convex corner?


# Does `this` handle a wall corner?
func is_corner() -> bool:
	if normal == null: return false
	return normal.x != 0 and normal.y != 0
