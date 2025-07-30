@tool
extends Node2D

# You can change these values in the Inspector.
@export var radius: float = 30.0
@export var color: Color = Color("0080ff")

# This function is now called by the editor as well as the game.
func _draw():
	draw_circle(Vector2.ZERO, radius, color)

# We need to tell the editor to redraw when a property changes.
# This code block is only necessary because we are in @tool mode.
func _get_property_list():
	queue_redraw()
	return []
