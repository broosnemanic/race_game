extends RefCounted
class_name Square

## Represents contents at a coordinate - including wall location ##

var normal: Vector2i		# Normal to wall direction, if any
var is_convex: bool			# If a corner square, is it a convex corner?
var is_block: bool			# Is `this` a solid block?


# By default this creates a block
func _init(a_normal: Vector2i = Vector2i.ZERO, a_is_block: bool = true) -> void:
	normal = a_normal
	is_block = a_is_block
	

# Does `this` handle a wall corner?
func is_corner() -> bool:
	if normal == Vector2i.ZERO: return false
	return normal.x != 0 and normal.y != 0
