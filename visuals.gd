# visuals.gd (Revised and Simplified)
@tool
extends Node2D

@export var radius: float = 30.0
# The 'color' variable is now public. We'll set it from the outside.
@export var color: Color = Color("0080ff")

func _draw():
	# Always draw with the current public color.
	draw_circle(Vector2.ZERO, radius, color)

# We need to tell the editor to redraw when a property changes.
func _get_property_list():
	queue_redraw()
	return []

# --- NEW PUBLIC FUNCTION ---
# Other scripts will call this to change the color AND trigger a redraw.
# This is better than just changing the 'color' var from outside,
# because it guarantees the redraw happens.
func set_display_color(new_color: Color):
	if color != new_color:
		color = new_color
		queue_redraw()
