extends RigidBody2D

# We have removed the line "@export var mass: float = 100.0"
# because RigidBody2D already has a built-in 'mass' property.

# This is NOT the real-world gravitational constant.
# We use a much larger number that works well for game physics.
const GRAVITATIONAL_CONSTANT = 10000.0

# Every body belongs to the "celestial_bodies" group so they can find each other.
func _ready():
	add_to_group("celestial_bodies")

func _physics_process(delta):
	# Get a list of all other nodes in the same group.
	var bodies = get_tree().get_nodes_in_group("celestial_bodies")
	
	# Loop through every other body to calculate the force it exerts on this one.
	for body in bodies:
		# Don't try to attract yourself!
		if body == self:
			continue
			
		# --- Calculate Gravitational Force (Newton's Law) ---
		# 1. Find the distance and direction between this body and the other.
		var distance_vec = body.global_position - self.global_position
		var distance = distance_vec.length()
		
		# Avoid division by zero if bodies are somehow in the same spot.
		if distance == 0:
			continue
			
		# 2. Calculate the force magnitude: F = G * (m1*m2) / r^2
		# This will now correctly use the built-in mass of both this body and the other.
		var force_magnitude = (GRAVITATIONAL_CONSTANT * self.mass * body.mass) / (distance * distance)
		
		# 3. Create the force vector by combining the direction and magnitude.
		var force_vector = distance_vec.normalized() * force_magnitude
		
		# 4. Apply the force to this body.
		apply_central_force(force_vector)
