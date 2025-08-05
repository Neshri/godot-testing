# SeekerController.gd (Corrected with Polling Method)
extends Node2D

@export var thrust_force: float = 50000.0
@export var idle_color: Color = Color("0f00ff")
@export var seeking_color: Color = Color("ff0000")

var current_target: Node2D = null

@onready var detection_area = $CelestialBody/DetectionArea
@onready var visuals_node = $CelestialBody/Visuals
@onready var rigid_body = $CelestialBody # Added for convenience

func _ready():
	# Robustness checks - Note that we no longer connect any signals.
	if detection_area == null:
		push_error("SeekerController ERROR: Child 'DetectionArea' not found.")
		return
	if visuals_node == null:
		push_error("SeekerController ERROR: Child 'CelestialBody/Visuals' not found. Check scene tree.")
		return
	if rigid_body == null:
		push_error("SeekerController ERROR: Child 'CelestialBody' not found.")
		return
	
	visuals_node.set_display_color(idle_color)

func _physics_process(delta):
	# --- 1. FIND THE TARGET ---
	var player_in_zone = find_player_in_zone()

	# --- 2. UPDATE STATE BASED ON FINDINGS ---
	if player_in_zone and not is_instance_valid(current_target):
		# We found a player, but we weren't tracking one before.
		# START SEEKING.
		current_target = player_in_zone
		visuals_node.set_display_color(seeking_color)
	elif not player_in_zone and is_instance_valid(current_target):
		# We didn't find a player, but we WERE tracking one.
		# STOP SEEKING.
		current_target = null
		visuals_node.set_display_color(idle_color)
		
	# --- 3. EXECUTE LOGIC ---
	# If we have a valid target at the end of all that, apply force.
	if is_instance_valid(current_target):
		var direction_to_player = (current_target.global_position - rigid_body.global_position).normalized()
		rigid_body.apply_central_force(direction_to_player * thrust_force)

# This new helper function does the core work.
func find_player_in_zone() -> Node2D:
	# Get a list of all physics bodies currently inside our detection area.
	var bodies = detection_area.get_overlapping_bodies()
	
	for body in bodies:
		# Check each body to see if it's the player.
		if body.is_in_group("player"):
			# We found the player! Return it immediately and stop searching.
			return body
			
	# If the loop finishes and we haven't found the player, return null.
	return null
