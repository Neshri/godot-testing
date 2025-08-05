# orbital.gd (Complete and Simplified)
extends Area2D

@export_group("Mechanics")
@export var mass: float = 1.0
@export var hit_impulse_factor: float = 1.0

# --- NEW: PUBLIC PROPERTY FOR THE BELT TO CONTROL ---
var current_angle: float = 0.0
var orbit_distance: float = 150.0

# --- PRIVATE VARIABLES ---
var belt: Node # A reference to the belt that owns this orbital
var _current_velocity: Vector2 = Vector2.ZERO
var _last_position: Vector2 = Vector2.ZERO

# --- REVISED: MINIMAL PHYSICS PROCESS ---
func _physics_process(delta: float):
	# The orbital's ONLY job in physics_process is to calculate its own
	# velocity so it can apply a correct impulse when it hits something.
	# It no longer controls its own position.
	if delta > 0:
		_current_velocity = (self.global_position - _last_position) / delta
	_last_position = self.global_position

func _on_body_entered(body: Node2D):
	# This collision logic is still valid, but needs the belt's velocity.
	var belt_target_velocity = belt.target_body.linear_velocity if is_instance_valid(belt) else Vector2.ZERO
	if not body is RigidBody2D or body == belt.target_body:
		return
	
	var relative_velocity = _current_velocity - belt_target_velocity
	var impulse = relative_velocity * self.mass * hit_impulse_factor
	body.apply_central_impulse(impulse)

# --- REVISED INITIALIZATION FUNCTION ---
func initialize(owner_belt: Node, start_angle_rad: float, new_orbit_dist: float):
	self.belt = owner_belt
	self.current_angle = start_angle_rad
	self.orbit_distance = new_orbit_dist
	
	# The belt will set the position, so we just need to set _last_position.
	await get_tree().process_frame
	if is_instance_valid(self):
		_last_position = self.global_position
