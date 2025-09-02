# CelestialBody.gd (Complete Script)
extends RigidBody2D

# --- MODIFIED SIGNAL ---
# The signal now carries a reference to the node that emitted it.
signal died(body)

# (All exports and constants are unchanged)
@export_group("Physics")
@export var gravity_enabled: bool = true
@export var max_speed: float = 1200.0
#@export_group("Visuals")
#@export var 
@export_group("Health & Damage")
@export var health: float = 100.0
@export var damage_threshold_mass_factor: float = 1.0
@export var damage_coefficient: float = 0.05
const GRAVITATIONAL_CONSTANT = 10000.0
var _actual_damage_threshold: float = 0.0

func _ready():
	add_to_group("celestial_bodies")
	_actual_damage_threshold = mass * damage_threshold_mass_factor

func _integrate_forces(state: PhysicsDirectBodyState2D):
	# (This function is unchanged)
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
			var target_body = collider
			if not target_body.has_method("take_damage"):
				target_body = collider.get_parent()
			if target_body != null and target_body.has_method("take_damage"):
				target_body.take_damage(damage)

func _physics_process(delta):
	# (This function is unchanged)
	if gravity_enabled:
		var bodies = get_tree().get_nodes_in_group("celestial_bodies")
		for body in bodies:
			if body == self or not body is RigidBody2D or not is_instance_valid(body):
				continue
			var distance_vec = body.global_position - self.global_position
			var distance = distance_vec.length()
			if distance == 0:
				continue
			var force_magnitude = (GRAVITATIONAL_CONSTANT * self.mass * body.mass) / (distance * distance)
			var force_vector = distance_vec.normalized() * force_magnitude
			apply_central_force(force_vector)
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.limit_length(max_speed)

func take_damage(amount: float):
	if health <= 0:
		return
	health -= amount
	if health <= 0:
		health = 0
		# --- MODIFIED EMIT ---
		# We now pass 'self' as an argument when emitting the signal.
		died.emit(self)
		queue_free()
