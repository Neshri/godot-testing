extends Area2D

#==============================================================================
# --- EXPORTED VARIABLES ---
#==============================================================================

@export_group("Orbit Configuration")
@export var mass: float = 2.5
@export var orbit_speed: float = 2.5 # NOTE: This is now radians/sec for rotation
@export var orbit_distance: float = 75.0
@export var orbit_smoothing_speed: float = 15.0

@export_group("Mechanics")
@export var elongation_factor: float = 0.5
@export var hit_impulse_factor: float = 1.0


#==============================================================================
# --- PRIVATE VARIABLES ---
#==============================================================================

var target: RigidBody2D
# We now use a persistent angle for stable rotation.
var _current_angle: float = 0.0
var _current_velocity: Vector2 = Vector2.ZERO
var _last_position: Vector2 = Vector2.ZERO


#==============================================================================
# --- BUILT-IN GODOT FUNCTIONS ---
#==============================================================================

func _ready():
	target = get_parent() as RigidBody2D
	if not is_instance_valid(target):
		print("ERROR: Orbital parent is not a RigidBody2D or is invalid.")
		set_physics_process(false)


func _physics_process(delta):
	if not is_instance_valid(target):
		return

	# --- STABLE ORBIT FIX ---
	# 1. Increment our angle. This is a stable, predictable change.
	_current_angle += orbit_speed * delta

	# 2. Calculate the ideal relative position based ONLY on the angle and distance.
	var ideal_distance = orbit_distance
	if target.linear_velocity.length_squared() > 1:
		var velocity_dir = target.linear_velocity.normalized()
		# We now calculate direction from the stable angle, not the jittery position.
		var orbit_direction = Vector2.from_angle(_current_angle)
		var alignment = abs(velocity_dir.dot(orbit_direction))
		ideal_distance += orbit_distance * elongation_factor * alignment
	
	# This calculation is now free of any feedback loops.
	var ideal_position = Vector2.from_angle(_current_angle) * ideal_distance

	# 3. Lerp to the ideal position to maintain smoothness.
	self.position = self.position.lerp(ideal_position, orbit_smoothing_speed * delta)

	# 4. The velocity calculation will now be stable because the position is stable.
	_current_velocity = (self.global_position - _last_position) / delta
	_last_position = self.global_position


func _on_body_entered(body: Node2D):
	if not body is RigidBody2D or body == target:
		return
	
	var relative_velocity = _current_velocity - target.linear_velocity
	var impulse = relative_velocity * self.mass * hit_impulse_factor
	body.apply_central_impulse(impulse)


#==============================================================================
# --- INITIALIZATION FUNCTION ---
#==============================================================================

func initialize(start_angle_degrees: float):
	_current_angle = deg_to_rad(start_angle_degrees)
	
	var start_pos = Vector2.from_angle(_current_angle) * orbit_distance
	self.position = start_pos
	
	await get_tree().process_frame
	if is_instance_valid(self):
		_last_position = self.global_position
