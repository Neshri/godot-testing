extends "res://celestial_body.gd"

# --- Player Control ---
@export var thrust_force: float = 1500.0

# --- Camera Control ---
@export_group("Zoom Settings")
# The zoom level when the player is stationary. 1.0 is normal zoom.
@export var base_zoom: float = 1.0
# The most the camera will zoom out. Smaller number = more zoomed out.
@export var max_zoom_out: float = 0.4
# The speed at which the camera will be fully zoomed out.
@export var zoom_speed_threshold: float = 1000.0
# How quickly the camera catches up to the target zoom. Higher is faster.
@export var zoom_smoothing_speed: float = 5.0

# A variable to hold a reference to our Camera2D node.
@onready var camera: Camera2D = $Camera2D

# _physics_process is called every physics frame.
func _physics_process(delta):
	# Run the gravity calculations from the parent script.
	super(delta)

	# --- Player Control Logic ---
	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_direction != Vector2.ZERO:
		apply_central_force(input_direction * thrust_force)

	# --- Camera Zoom Logic ---
	# 1. Get the player's current speed.
	var current_speed := linear_velocity.length()

	# 2. Calculate the TARGET zoom level based on speed.
	var target_zoom_value := remap(current_speed, 0, zoom_speed_threshold, base_zoom, max_zoom_out)
	target_zoom_value = clamp(target_zoom_value, max_zoom_out, base_zoom)
	var target_zoom_vector = Vector2(target_zoom_value, target_zoom_value)

	# 3. Smoothly move the CURRENT zoom towards the TARGET zoom.
	# lerp() (linear interpolation) is perfect for this.
	# It moves a value towards a target by a certain weight.
	camera.zoom = camera.zoom.lerp(target_zoom_vector, zoom_smoothing_speed * delta)
