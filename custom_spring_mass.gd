# custom_spring_mass.gd
extends RigidBody2D

#==============================================================================
# --- EXPORTED VARIABLES ---
#==============================================================================
@export_group("Spring Physics")
@export var rest_length: float = 40.0
@export var stiffness: float = 500.0
@export var damping: float = 25.0
@export var max_length: float = 200.0
@export var max_length_stiffness: float = 2000.0

# --- NEW: Damage Properties for the swinging mass ---
@export_group("Collision Damage")
@export var damage_threshold_mass_factor: float = 1.0
@export var damage_coefficient: float = 0.1 # A higher coefficient for more damage

#==============================================================================
# --- PRIVATE VARIABLES ---
#==============================================================================
var anchor_node: Node2D
var _actual_damage_threshold: float = 0.0


#==============================================================================
# --- BUILT-IN GODOT FUNCTIONS ---
#==============================================================================
func _ready():
	# Calculate the damage threshold once for efficiency.
	_actual_damage_threshold = mass * damage_threshold_mass_factor

func _integrate_forces(state: PhysicsDirectBodyState2D):
	# --- SPRING LOGIC ---
	if is_instance_valid(anchor_node):
		var anchor_pos = anchor_node.global_position
		var my_pos = state.transform.origin
		var offset_vector = my_pos - anchor_pos
		var current_length = offset_vector.length()
		var direction = offset_vector.normalized()

		if direction != Vector2.ZERO:
			var boundary_force = Vector2.ZERO
			if current_length > max_length:
				var penetration_depth = current_length - max_length
				boundary_force = -direction * max_length_stiffness * penetration_depth

			var displacement = current_length - rest_length
			var spring_force_magnitude = -stiffness * displacement
			var spring_force = direction * spring_force_magnitude

			var my_velocity = state.linear_velocity
			var velocity_along_spring = my_velocity.dot(direction)
			var damping_force = -damping * velocity_along_spring * direction
			
			state.apply_force(spring_force + damping_force + boundary_force)

	# --- NEW: COLLISION DAMAGE LOGIC ---
	# This is the same logic used by CelestialBody.
	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)
		if collider == null:
			continue
			
		var collider_velocity = state.get_contact_collider_velocity_at_position(i)
		var contact_normal = state.get_contact_local_normal(i)
		var relative_velocity = state.linear_velocity - collider_velocity
		var impulse_magnitude = abs(relative_velocity.dot(contact_normal))

		if impulse_magnitude > _actual_damage_threshold:
			var damage = (impulse_magnitude - _actual_damage_threshold) * damage_coefficient
			
			if collider.has_method("take_damage"):
				collider.take_damage(damage)

# Helper function for the spawner to call.
func set_anchor_node(anchor: Node2D):
	anchor_node = anchor
