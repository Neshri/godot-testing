extends RigidBody2D

signal died

#==============================================================================
# --- EXPORTED VARIABLES ---
#==============================================================================
@export_group("Physics")
@export var gravity_enabled: bool = true
@export var max_speed: float = 1200.0

@export_group("Health & Damage")
@export var health: float = 100.0
@export var damage_threshold_mass_factor: float = 1.0
@export var damage_coefficient: float = 0.05


#==============================================================================
# --- PRIVATE VARIABLES & CONSTANTS ---
#==============================================================================
const GRAVITATIONAL_CONSTANT = 10000.0
var _actual_damage_threshold: float = 0.0


#==============================================================================
# --- BUILT-IN GODOT FUNCTIONS ---
#==============================================================================
func _ready():
	add_to_group("celestial_bodies")
	_actual_damage_threshold = mass * damage_threshold_mass_factor


func _integrate_forces(state: PhysicsDirectBodyState2D):
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
				# --- DIAGNOSTIC PRINT #1 ---
				# This line has been added to see the damage being sent.
				print("%s is dealing %.2f damage to %s" % [self.name, damage, collider.name])
				
				collider.take_damage(damage)


func _physics_process(delta):
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


#==============================================================================
# --- DAMAGE & HEALTH FUNCTIONS ---
#==============================================================================
func take_damage(amount: float):
	# --- DIAGNOSTIC PRINT #2 ---
	# This line has been added to confirm the function is being entered.
	print("%s is receiving %.2f damage. %s Health remaining." % [self.name, amount, health-amount])

	if health <= 0:
		return
	
	health -= amount
	
	if health <= 0:
		health = 0
		died.emit()
		queue_free()
