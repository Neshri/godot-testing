extends Area2D

#==============================================================================
# --- EXPORTED VARIABLES ---
#==============================================================================

@export_group("Orbit Configuration")
@export var mass: float = 1
@export var base_orbit_speed: float = 5 
@export var orbit_distance: float = 150.0

@export_group("Mechanics")
@export var stretch_factor: float = 0.75
@export var stretch_smoothing_speed: float = 8.0
@export var hit_impulse_factor: float = 1.0


#==============================================================================
# --- PRIVATE VARIABLES ---
#==============================================================================

var target: RigidBody2D
var _current_angle: float = 0.0
var _current_velocity: Vector2 = Vector2.ZERO
var _last_position: Vector2 = Vector2.ZERO
var _smoothed_target_velocity: Vector2 = Vector2.ZERO


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

	# --- STABLE POSITIONING LOGIC ---
	_smoothed_target_velocity = _smoothed_target_velocity.lerp(target.linear_velocity, stretch_smoothing_speed * delta)
	
	var base_circular_pos = Vector2.from_angle(_current_angle) * orbit_distance
	var stretch_vector = Vector2.ZERO
	if _smoothed_target_velocity.length_squared() > 1:
		var speed = _smoothed_target_velocity.length()
		var direction = _smoothed_target_velocity.normalized() * -1
		var stretch_magnitude = remap(speed, 0, target.max_speed, 0, orbit_distance * stretch_factor)
		stretch_vector = direction * stretch_magnitude
	
	var alignment = max(0, base_circular_pos.normalized().dot(stretch_vector.normalized()))
	var final_position = base_circular_pos + (stretch_vector * alignment)
	
	self.position = final_position

	# --- DIRECT PROPORTIONAL SPEED CALCULATION (Your Instruction) ---
	# 1. Get the orbital's current distance from its center.
	var current_distance = self.position.length()
	# Safety check to prevent division by zero if orbit_distance is 0.
	if orbit_distance < 0.01:
		orbit_distance = 0.01

	# 2. Calculate the speed modifier. It is now DIRECTLY proportional.
	var speed_modifier = orbit_distance / current_distance
	
	# 3. Apply the modifier to the angle update.
	_current_angle += base_orbit_speed * speed_modifier * delta

	# --- VELOCITY CALCULATION ---
	_current_velocity = (self.global_position - _last_position) / delta
	_last_position = self.global_position


func _on_body_entered(body: Node2D):
	if not body is RigidBody2D or body == target:
		return
	
	var relative_velocity = _current_velocity - _smoothed_target_velocity
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
