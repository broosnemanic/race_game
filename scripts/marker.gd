extends Area2D
class_name Marker

signal selected(a_marker: Marker)



@onready var target_marker: Sprite2D = $TargetMarker

var coord: Vector2i			# Relative to parent ship
var is_enabled: bool = true
var is_mouse_over: bool

func _ready() -> void:
	target_marker.modulate = Constants.MARKER_COLOR
	target_marker.scale = Vector2(0.5, 0.5)


func _mouse_enter() -> void:
	is_mouse_over = true


func _mouse_exit() -> void:
	is_mouse_over = false


func _input(event: InputEvent) -> void:
	if not is_mouse_over: return
	if event is InputEventMouseButton:
		var t_even: InputEventMouseButton = event as InputEventMouseButton
		if t_even.button_index == MOUSE_BUTTON_LEFT:
			if t_even.pressed:
				selected.emit(self)


func set_enabled(a_is_enabled: bool) -> void:
	target_marker.visible = a_is_enabled
	is_enabled = a_is_enabled
	
