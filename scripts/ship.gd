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
	clear_line()
	descrete_path.clear_line()
	descrete_path = DescretePath.new()
	descrete_path.color = Constants.player_color[player]
	add_child(descrete_path)
	descrete_path.draw_from_endpoints(Vector2i.ZERO, a_marker.coord + velocity)
	path = descrete_path.coords
	
	


func display_markers(a_is_displayed: bool) -> void:
	for i_index: int in range(markers.size()):
		var t_marker: Marker = markers[i_index]
		t_marker.set_enabled(a_is_displayed)
		if a_is_displayed:
			t_marker.coord = max_accelerations.keys()[i_index]


func on_marker_selected(a_marker: Marker) -> void:
	velocity += a_marker.coord
	moves.append(velocity)
	path = descrete_path.coords
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


func clear_line() -> void:
	for i_square: Sprite2D in line_squares:
		i_square.queue_free()
	line_squares = []
