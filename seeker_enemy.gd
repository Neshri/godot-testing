# SeekerController.gd (Corrected with Death Handling)
extends Node2D

@export var thrust_force: float = 50000.0
@export var idle_color: Color = Color("0f00ff")
@export var seeking_color: Color = Color("ff0000")

var current_target: Node2D = null
# --- NEW ---
# This flag will prevent logic from running after the body is destroyed.
var _is_dead: bool = false

@onready var detection_area = $CelestialBody/DetectionArea
@onready var visuals_node = $CelestialBody/Visuals
@onready var rigid_body = $CelestialBody

func _ready():
	# Robustness checks
	if detection_area == null:
		push_error("SeekerController ERROR: Child 'DetectionArea' not found.")
		return
	if visuals_node == null:
		push_error("SeekerController ERROR: Child 'CelestialBody/Visuals' not found.")
		return
	if rigid_body == null:
		push_error("SeekerController ERROR: Child 'CelestialBody' not found.")
		return
	
	# --- NEW: Connect to our own body's death signal ---
	# This tells the controller to listen for the 'died' signal from its own CelestialBody.
	# When that signal is received, it will call our new _on_celestial_body_died function.
	rigid_body.died.connect(_on_celestial_body_died)
	
	visuals_node.set_display_color(idle_color)

func _physics_process(delta):
	# --- NEW: Guard Clause ---
	# If the body is dead, stop all processing immediately.
	if _is_dead:
		return

	# --- 1. FIND THE TARGET ---
	var player_in_zone = find_player_in_zone()

	# --- 2. UPDATE STATE BASED ON FINDINGS ---
	if player_in_zone and not is_instance_valid(current_target):
		current_target = player_in_zone
		visuals_node.set_display_color(seeking_color)
	elif not player_in_zone and is_instance_valid(current_target):
		current_target = null
		visuals_node.set_display_color(idle_color)
		
	# --- 3. EXECUTE LOGIC ---
	if is_instance_valid(current_target):
		var direction_to_player = (current_target.global_position - rigid_body.global_position).normalized()
		rigid_body.apply_central_force(direction_to_player * thrust_force)

func find_player_in_zone() -> Node2D:
	var bodies = detection_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			return body
	return null

# --- NEW: This function handles the 'died' signal ---
func _on_celestial_body_died():
	# Set our flag to true to stop any further logic in _physics_process.
	_is_dead = true
	
	# The controller is now useless, so we should clean it up as well.
	queue_free()
