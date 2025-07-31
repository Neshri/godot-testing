@tool
extends Node2D

# You can change this color in the Inspector.
@export var color: Color = Color.DODGER_BLUE

func _process(delta):
	# This ensures the visual updates in the editor when you move or resize the collision shape.
	queue_redraw()

func _draw():
	# Get a reference to the CollisionShape2D sibling node.
	var collision_shape = get_parent().get_node_or_null("CollisionShape2D")

	# --- Safety Checks ---
	if not collision_shape or not collision_shape.shape or not collision_shape.shape is RectangleShape2D:
		# If the collision shape isn't set up correctly, do nothing.
		return

	# --- Drawing Logic ---
	# 1. Get the size from the shape resource itself.
	var shape_size = collision_shape.shape.size
	
	# 2. Get the offset from the CollisionShape2D node's own position. THIS IS THE FIX.
	var shape_offset = collision_shape.position
	
	# Calculate the top-left corner for the rectangle. This now correctly
	# combines the offset of the node with the size of the shape,
	# ensuring the visual is perfectly aligned with the physics.
	var top_left_position = shape_offset - (shape_size / 2)
	
	# Draw the rectangle using the combined data.
	draw_rect(Rect2(top_left_position, shape_size), color)
