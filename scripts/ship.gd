extends Node2D
class_name Ship

signal move_selected(a_ship: Ship)
signal direction_selected(a_ship: Ship)

@onready var sprite: Sprite2D = $Sprite
@onready var shadow: Sprite2D = $Shadow
@onready var area: Area2D = $Area
@onready var marker_prefab: PackedScene = preload("res://scenes/marker.tscn")
@onready var bubble_particles: CPUParticles2D = $Sprite/BubbleParticles
@onready var froth_particles: CPUParticles2D = $Sprite/FrothParticles
@onready var direction_wheel: DirectionWheel = $DirectionWheel


var player: int
var velocity: Vector2i = Vector2i.ZERO
var path: Array[Vector2i] = []
var max_accelerations: Dictionary[Vector2i, int]		# Max acc available in each of 8 cardinal directions
var markers: Array[Marker] = []							# Displays possible next move; rebuilt as needed
var moves: Array[Vector2i] = [Vector2i.ZERO]			# Index: turn#; value: velocity
var is_mouse_over: bool
var pointed_marker: Marker								# Marker, if any, mouse is over
var marker_pointer: Line2D
var is_bot: bool = false
var marker_arrow: ArrowHead
var line_squares: Array[Sprite2D] = []
var descrete_path: DescretePath = DescretePath.new()
var square_size: float									# How far is one unit of movment? (set from `board.square_size`)

const LIGHT_TILE: Texture2D = preload("uid://crkmjka1gcgkc")

var health: int:
	set(a_value):
		health = a_value
		if health <= 0:
			on_destruction()


#
func _ready() -> void:
	setup_default_acc()
	marker_pointer = Line2D.new()
	marker_pointer.points = [Vector2.ZERO, Vector2.ZERO]
	marker_pointer.modulate = Constants.player_color[player]
	marker_pointer.z_as_relative = true
	marker_pointer.z_index = -1
	marker_pointer.width = 5
	add_child(marker_pointer)
	area.mouse_entered.connect(func()->void:is_mouse_over = true)
	area.mouse_exited.connect(func()->void:is_mouse_over = false)
	sprite.modulate = Constants.player_color[player]
	setup_arrowhead()
	area.area_entered.connect(on_area_entered)
	area.add_to_group("ship")
	z_as_relative = false
	health = Constants.DEFAULT_SHIP_HEALTH
	froth_particles.color = Constants.player_color[player]
	bubble_particles.color = Constants.player_color[player]
	direction_wheel.direction_selected.connect(on_direction_selected)
	direction_wheel.direction_hovered.connect(on_hovered_direction_changed)


func on_area_entered(a_area: Area2D) -> void:
	if a_area.is_in_group("ship"):
		pass


# Actions to perform when health reaches zero
func on_destruction() -> void:
	prints(player, "destroyed")


func setup_arrowhead() -> void:
	marker_arrow = ArrowHead.new()
	marker_arrow.width = 20.0
	marker_arrow.height = 20.0
	marker_arrow.offset = Vector2(0.0, 20.0)
	marker_pointer.add_child(marker_arrow)


#func handle_marker_pointer() -> void:
	#if pointed_marker != null:
		#marker_pointer.visible = true
		#point_at_marker(pointed_marker)
	#else:
		#marker_pointer.visible = false


# Default 1 acc in all directions
func setup_default_acc() -> void:
	for i_dir: Vector2i in Constants.directions:
		max_accelerations[i_dir] = 1


func _mouse_enter() -> void:
	is_mouse_over = true


func _mouse_exit() -> void:
	is_mouse_over = false


func create_markers() -> void:
	return	# TODO: for debugging
	markers = []
	add_new_marker(Vector2i.ZERO)
	for i_dir: Vector2i in Constants.directions:
		var t_max_acc: int = max_accelerations[i_dir]
		for i_magnitude: int in range(t_max_acc):
			var t_acc: Vector2i = i_dir * (1 + i_magnitude)
			add_new_marker(t_acc)


func destroy_markers() -> void:
	for i_marker: Marker in markers:
		i_marker.queue_free()
	markers = []


func add_new_marker(a_acc: Vector2i) -> Marker:
		var t_marker: Marker = marker_prefab.instantiate()
		markers.append(t_marker)
		t_marker.selected.connect(on_marker_selected)
		t_marker.mouse_entered.connect(on_mouse_enter_marker.bind(t_marker))
		t_marker.coord = a_acc
		add_child(t_marker)
		#t_marker.position = (velocity + t_marker.coord) * Constants.ORIGINAL_SQUARE_SIZE
		t_marker.position = (velocity + t_marker.coord) * square_size
		if a_acc == Vector2i.ZERO:
			t_marker.target_marker.modulate = Color.FUCHSIA
		return t_marker


func on_mouse_enter_marker(a_marker: Marker) -> void:
	point_at_marker(a_marker)
	pointed_marker = a_marker


func point_at_marker(a_marker: Marker) -> void:
	# Point arrow at marker
	marker_pointer.points[1] = a_marker.position
	marker_arrow.position = marker_pointer.points[1]
	marker_arrow.point_along_coords(Vector2.ZERO, a_marker.position)
	# Grid line
	clear_line()
	descrete_path.clear_line()
	descrete_path = DescretePath.new()
	descrete_path.color = Constants.player_color[player]
	descrete_path.square_size = square_size
	add_child(descrete_path)
	descrete_path.draw_from_endpoints(Vector2i.ZERO, a_marker.coord + velocity)
	path = descrete_path.coords
	# Point ship at marker
	point_ship_at_position(a_marker.position)


func on_hovered_direction_changed(a_direction: Vector2i) -> void:
	var t_coord: Vector2i = a_direction + velocity
	point_at_coord(t_coord)
	
	clear_line()
	descrete_path.clear_line()
	descrete_path = DescretePath.new()
	descrete_path.color = Constants.player_color[player]
	descrete_path.square_size = square_size
	add_child(descrete_path)
	descrete_path.draw_from_endpoints(Vector2i.ZERO, t_coord)
	path = descrete_path.coords
	# Point ship at marker
	point_ship_at_position(Utilities.pos_from_coords(t_coord))



# Set `marker_pointer` to point at center of square at `a_coord`
func point_at_coord(a_coord: Vector2i) -> void:
	point_at_position(Utilities.pos_from_coords(a_coord))


# Set `marker_pointer` to point at `a_pos`
func point_at_position(a_pos: Vector2) -> void:
	marker_pointer.points[1] = a_pos
	marker_arrow.position = a_pos
	marker_arrow.point_along_coords(Vector2.ZERO, a_pos)


#
func point_ship_at_position(a_position: Vector2) -> void:
	var t_angle: float = a_position.angle() + 0.5 * PI
	sprite.rotation = t_angle
	shadow.rotation = t_angle


# 
func set_velocity(a_velocity: Vector2i) -> void:
	velocity = a_velocity
	var t_descrete: DescretePath = DescretePath.new()
	path = t_descrete.line_coords(Vector2i.ZERO, velocity)
	t_descrete.color = Constants.player_color[player]



func point_at_velocity() -> void:
	#var t_pos: Vector2 = velocity * Constants.ORIGINAL_SQUARE_SIZE
	var t_pos: Vector2 = velocity * square_size
	var t_tween: Tween = get_tree().create_tween()
	t_tween.tween_method(point_at_position, marker_pointer.points[1], t_pos, Constants.MOVE_TIME)
	point_at_position(t_pos)
	#marker_pointer.points[1] = t_pos
	#marker_arrow.position = t_pos
	#marker_arrow.point_along_coords(Vector2.ZERO, t_pos)


# Point at predicted destination given current tic
func point_at_endpoint(a_tic: int) -> void:
	#var t_pos: Vector2 = endpoint_from_tic(a_tic) * Constants.ORIGINAL_SQUARE_SIZE
	var t_pos: Vector2 = endpoint_from_tic(a_tic) * square_size
	#var t_pos: Vector2 = descrete_path.coords.back() * Constants.ORIGINAL_SQUARE_SIZE
	#var t_pos: Vector2 = path.back() * Constants.ORIGINAL_SQUARE_SIZE
	var t_tween: Tween = get_tree().create_tween()
	t_tween.tween_method(point_at_position, marker_pointer.points[1], t_pos, Constants.MOVE_TIME)
	point_at_position(t_pos)
	#prints(t_pos, position)
	#marker_pointer.points[1] = t_pos
	#marker_arrow.position = t_pos
	#marker_arrow.point_along_coords(Vector2.ZERO, t_pos)


# Predicted destination (relative to `this`) starting from `a_tic`
func endpoint_from_tic(a_tic: int) -> Vector2i:
	var t_pos: Vector2i = Vector2i.ZERO
	for i_index: int in range(a_tic + 1, descrete_path.padded_steps.size()):
		t_pos += descrete_path.padded_steps[i_index]
	return t_pos
	
	



#func display_markers(a_is_displayed: bool) -> void:
	#for i_index: int in range(markers.size()):
		#var t_marker: Marker = markers[i_index]
		#t_marker.set_enabled(a_is_displayed)
		#if a_is_displayed:
			#t_marker.coord = max_accelerations.keys()[i_index]


func on_marker_selected(a_marker: Marker) -> void:
	velocity += a_marker.coord
	moves.append(velocity)
	path = descrete_path.coords
	move_selected.emit(self)
	destroy_markers()


func on_direction_selected(a_direction: Vector2i) -> void:
	velocity += a_direction
	moves.append(velocity)
	path = descrete_path.coords
	direction_selected.emit(self)
	direction_wheel.visible = false

func max_acc_at(a_dir: Vector2i) -> Vector2i:
	if max_accelerations.has(a_dir):
		return a_dir * max_accelerations[a_dir]
	return Vector2i.ZERO


# Set player index and set sprite color
func set_player(a_player: int) -> void:
	player = a_player
	if sprite != null:
		sprite.modulate = Constants.player_color[player]


# Possible destinations relative to <this>
func available_destinations() -> Array[Vector2i]:
	var t_coords: Array[Vector2i] = [velocity]
	for i_dir: Vector2i in Constants.directions:
		t_coords.append(velocity + i_dir)
	return t_coords


func clear_line() -> void:
	for i_square: Sprite2D in line_squares:
		i_square.queue_free()
	line_squares = []


# 
func set_particles_visible(a_is_visible: bool) -> void:
	bubble_particles.emitting = a_is_visible
	froth_particles.emitting = a_is_visible
