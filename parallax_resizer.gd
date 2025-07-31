extends ParallaxBackground

@export var buffer_pixels_x: int = 50 # Add a small buffer to prevent tiny gaps
@export var buffer_pixels_y: int = 50

func _ready():
	# Set the sizes when the game starts
	set_parallax_sizes()

# Uncomment the func below if you want the background to resize if the player changes window size during gameplay
# func _notification(what):
#    if what == NOTIFICATION_WM_WINDOW_RESIZED:
#        set_parallax_sizes()

func set_parallax_sizes():
	# Get the current size of the game's viewport (window)
	# THIS IS THE CORRECTED LINE FOR GODOT 4
	var viewport_size = get_viewport().get_visible_rect().size

	# Calculate the target width and height for our sprites and mirroring
	# We add a small buffer to ensure it always covers the screen.
	var target_width = viewport_size.x + buffer_pixels_x
	var target_height = viewport_size.y + buffer_pixels_y

	# Iterate through all the ParallaxLayer children of this ParallaxBackground
	for child in get_children():
		if child is ParallaxLayer:
			var parallax_layer = child

			# Find the Sprite2D within this ParallaxLayer
			for layer_child in parallax_layer.get_children():
				if layer_child is Sprite2D:
					var sprite = layer_child

					# 1. Update the Sprite2D's Region Rect
					var region = sprite.region_rect
					region.size = Vector2(target_width, target_height)
					sprite.region_rect = region
					sprite.region_enabled = true

					# 2. Update the ParallaxLayer's Mirroring
					parallax_layer.motion_mirroring = Vector2(target_width, target_height)

					# We've found and updated the sprite for this layer, so break
					# to move to the next ParallaxLayer
					break
