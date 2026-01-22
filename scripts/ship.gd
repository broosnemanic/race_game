extends Node2D
class_name Ship


signal move_selected(a_ship: Ship)
#signal selected(a_ship: Ship)


@onready var sprite: Sprite2D = $Sprite
@onready var area: Area2D = $Area
@onready var marker_prefab: PackedScene = preload("res://scenes/marker.tscn")

var player: int
var health: int
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


const LIGHT_TILE: Texture2D = preload("uid://crkmjka1gcgkc")


# Helper to convert to grid coords
func coords() -> Vector2i:
	var t_pos: Vector2i = Vector2i.ZERO
	t_pos.x = (position.x / Constants.ORIGINAL_SQUARE_SIZE) as int
	t_pos.y = (position.y / Constants.ORIGINAL_SQUARE_SIZE) as int
	return t_pos

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


func on_area_entered(a_area: Area2D) -> void:
	if a_area.is_in_group("ship"):
		pass


func _process(_delta: float) -> void:
	return


func setup_arrowhead() -> void:
	marker_arrow = ArrowHead.new()
	marker_arrow.width = 20.0
	marker_arrow.height = 20.0
	marker_arrow.offset = Vector2(0.0, 20.0)
	marker_pointer.add_child(marker_arrow)
	
	

func handle_marker_pointer() -> void:
	if pointed_marker != null:
		marker_pointer.visible = true
		point_at_marker(pointed_marker)
	else:
		marker_pointer.visible = false



# Default 1 acc in all directions
func setup_default_acc() -> void:
	for i_dir: Vector2i in Constants.directions:
		max_accelerations[i_dir] = 1


func _mouse_enter() -> void:
	is_mouse_over = true


func _mouse_exit() -> void:
	is_mouse_over = false


#func _input(event: InputEvent) -> void:
	#pass
	#if not is_mouse_over: return
	#if event is InputEventMouseButton:
		#var t_even: InputEventMouseButton = event as InputEventMouseButton
		#if t_even.button_index == MOUSE_BUTTON_LEFT:
			#if t_even.pressed:
				#selected.emit(self)


#func set_is_selected(a_is_selected: bool) -> void:
	#if a_is_selected:
		#selected.emit(self)


func create_markers() -> void:
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
		t_marker.position = (velocity + t_marker.coord) * Constants.ORIGINAL_SQUARE_SIZE
		if a_acc == Vector2i.ZERO:
			t_marker.target_marker.modulate = Color.FUCHSIA
		return t_marker



func on_mouse_enter_marker(a_marker: Marker) -> void:
	point_at_marker(a_marker)
	pointed_marker = a_marker



func point_at_marker(a_marker: Marker) -> void:
	marker_pointer.points[1] = a_marker.position
	marker_arrow.position = marker_pointer.points[1]
	marker_arrow.point_along_coords(Vector2.ZERO, a_marker.position)
	# Grid line
	var t_coords: Array[Vector2i] = line_coords(Vector2i.ZERO, a_marker.coord + velocity)
	clear_line()
	path = t_coords
	
	#draw_squares(t_coords)
	descrete_path.clear_line()
	descrete_path = DescretePath.new()
	descrete_path.color = Constants.player_color[player]
	add_child(descrete_path)
	descrete_path.draw_points(t_coords)
	
	


func display_markers(a_is_displayed: bool) -> void:
	for i_index: int in range(markers.size()):
		var t_marker: Marker = markers[i_index]
		t_marker.set_enabled(a_is_displayed)
		if a_is_displayed:
			t_marker.coord = max_accelerations.keys()[i_index]


func on_marker_selected(a_marker: Marker) -> void:
	velocity += a_marker.coord
	moves.append(velocity)
	path = line_coords(Vector2i.ZERO, velocity)
	move_selected.emit(self)
	destroy_markers()


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


#region Grid Line
# Utility for drawing grid-style line
# Applies list of moves from distributed_directions to a start and end coord
func line_coords(a_start: Vector2i, a_end: Vector2i) -> Array[Vector2i]:
	var t_coord: Vector2i = a_start
	var t_coords: Array[Vector2i] = [t_coord]
	var t_steps: Array[Vector2i] = distributed_directions(a_start, a_end)
	for i_step: Vector2i in t_steps:
		t_coord += i_step
		t_coords.append(t_coord)
	return t_coords


# Utility for drawing grid-style line
# Returns list of unit vectors which draw a reasonble straight line
func distributed_directions(a_start: Vector2i, a_end: Vector2i) -> Array[Vector2i]:
	var t_directions: Array[Vector2i] = []
	var t_counts: Array[int] = direction_counts(a_start, a_end)
	var t_sign_x: int = 1 if a_end.x - a_start.x >= 0 else -1
	var t_sign_y: int = 1 if a_end.y - a_start.y >= 0 else -1
	var t_total: int = t_counts[0] + t_counts[1] + t_counts[2]
	var t_diag: Vector2i = Vector2i(t_sign_x, t_sign_y)
	var t_x: Vector2i = Vector2i(t_sign_x, 0)
	var t_y: Vector2i = Vector2i(0, t_sign_y)
	t_directions.resize(t_total)
	t_directions.fill(t_diag)
	var t_step: float
	if t_counts[0] > 0:
		t_step = t_total as float / t_counts[0]
		for i_index: int in range(0, t_counts[0]):
				t_directions[floori(i_index * t_step)] = t_x
	if t_counts[1] > 0:
		t_step = t_total as float / t_counts[1]
		for i_index: int in range(0, t_counts[1]):
				t_directions[floori(i_index * t_step)] = t_y
	return t_directions



# Utility for drawing grid-style line
# [x dir count, y dir count, diag dir count]
func direction_counts(a_start: Vector2i, a_end: Vector2i) -> Array[int]:
	var t_delta: Vector2i = abs(a_end - a_start)
	var t_diag: int = mini(t_delta.x, t_delta.y)
	var t_x: int = maxi(0, t_delta.x - t_diag)
	var t_y: int = maxi(0, t_delta.y - t_diag)
	return [t_x, t_y, t_diag]


func clear_line() -> void:
	for i_square: Sprite2D in line_squares:
		i_square.queue_free()
	line_squares = []



func draw_squares(a_coords: Array[Vector2i]) -> void:
	clear_line()
	for i_coord: Vector2i in a_coords:
		var t_sprite: Sprite2D = Sprite2D.new()
		t_sprite.texture = LIGHT_TILE
		t_sprite.z_index = 10
		t_sprite.scale = 0.25 * Vector2.ONE
		add_child(t_sprite)
		t_sprite.position = i_coord * Constants.ORIGINAL_SQUARE_SIZE
		line_squares.append(t_sprite)
	

#endregion
