extends PanelContainer
class_name PlayerLabel
## UI component which displays icon (color corresponding to player number) and player name ##

@onready var icon: TextureRect = $MarginContainer/HBoxContainer/IconPanel/MarginContainer/PanelContainer/IconTexture
@onready var bot_label: TextureRect = $MarginContainer/HBoxContainer/TextPanel/MarginContainer/PanelContainer/BOTLabel

var player: int
var is_selected: bool

const bg_color: Color = Color.BLACK
const selected_color: Color = Color(51, 180, 137)

var is_bot: bool:
	set(a_is_bot):
		is_bot = a_is_bot
		bot_label.visible = a_is_bot

var color: Color:
	set(a_color):
		color = a_color
		icon.modulate = a_color


# Only changes appearance
func set_selected(a_is_selected: bool) -> void:
	is_selected = a_is_selected
	color = selected_color if a_is_selected else bg_color
