# custom_spring_mass.gd
extends RigidBody2D

# --- Public Properties ---
@export var rest_length: float = 100.0
@export var stiffness: float = 200.0
@export var damping: float = 25.0
@export var max_length: float = 150.0

# --- NEW ---
# The stiffness of the "force field" at the max_length boundary.
# Make this MUCH higher than the normal stiffness.
@export var max_length_stiffness: float = 2000.0

# --- Private Variables ---
var anchor_node: Node2D


func _integrate_forces(state: PhysicsDirectBodyState2D):
	if not is_instance_valid(anchor_node):
		return

	var anchor_pos = anchor_node.global_position
	var my_pos = state.transform.origin
	var offset_vector = my_pos - anchor_pos
	var current_length = offset_vector.length()
	var direction = offset_vector.normalized()

	if direction == Vector2.ZERO:
		return

	# --- NEW: Force-Based Limit ---
	# This logic now ADDs a force instead of overriding physics.
	var boundary_force = Vector2.ZERO
	if current_length > max_length:
		var penetration_depth = current_length - max_length
		# Calculate a powerful restoring force based on the penetration.
		boundary_force = -direction * max_length_stiffness * penetration_depth

	# --- UNCHANGED: Original Spring Logic ---
	# This code now runs ALL THE TIME, as it should.
	var displacement = current_length - rest_length
	var spring_force_magnitude = -stiffness * displacement
	var spring_force = direction * spring_force_magnitude

	var my_velocity = state.linear_velocity
	var velocity_along_spring = my_velocity.dot(direction)
	var damping_force = -damping * velocity_along_spring * direction

	# Apply ALL forces combined. The physics engine will resolve them.
	state.apply_force(spring_force + damping_force + boundary_force)
