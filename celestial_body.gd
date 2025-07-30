extends RigidBody2D

#==============================================================================
# --- EXPORTED VARIABLES ---
#==============================================================================
@export var gravity_enabled: bool = true
# NEW: We add a speed cap variable here so all celestial bodies can have one.
@export var max_speed: float = 1200.0


#==============================================================================
# --- PRIVATE VARIABLES & CONSTANTS ---
#==============================================================================
const GRAVITATIONAL_CONSTANT = 10000.0


#==============================================================================
# --- BUILT-IN GODOT FUNCTIONS ---
#==============================================================================
func _ready():
	add_to_group("celestial_bodies")

func _physics_process(delta):
	# --- Gravity Calculation ---
	if gravity_enabled:
		var bodies = get_tree().get_nodes_in_group("celestial_bodies")
		for body in bodies:
			# FIX: Add robust guard clauses to prevent incorrect force application.
			# 1. Don't attract yourself.
			# 2. Don't attract things that aren't RigidBody2D (like orbitals).
			# 3. Ensure the other body is valid.
			if body == self or not body is RigidBody2D or not is_instance_valid(body):
				continue
			
			var distance_vec = body.global_position - self.global_position
			var distance = distance_vec.length()
			
			if distance == 0:
				continue
			
			var force_magnitude = (GRAVITATIONAL_CONSTANT * self.mass * body.mass) / (distance * distance)
			var force_vector = distance_vec.normalized() * force_magnitude
			
			apply_central_force(force_vector)

	# --- SPEED CAP FIX ---
	# By placing this at the end of the physics process, it will reliably cap
	# the final velocity after all forces for this frame have been applied.
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.limit_length(max_speed)
