# OrbitalBelt.gd (Proportional Asymmetrical Teardrop Model)
extends Node2D

@export var layers: Array[OrbitalLayer]
@export var target_body_path: NodePath

@export_group("Visuals")
# How quickly the shape adapts to acceleration changes.
@export var effect_smoothing_speed: float = 6.0
# The closest an orbital can be pulled IN towards the center (in pixels).
@export var min_radius: float = 40.0

@export_group("Teardrop Shape")
# How much the tail stretches, as a factor of the orbit's radius.
@export_range(0.0, 2.0) var displacement_factor: float = 0.8
# Controls the "pointiness" of the tail. Higher values = sharper tail.
@export_range(1.0, 8.0) var tail_sharpness: float = 3.0
# Controls the width of the teardrop's head.
# > 1.0 = NARROWER sides (pinched).
# < 1.0 = WIDER sides (rounded).
@export_range(0.5, 4.0) var head_width_factor: float = 1.5

@export_group("Physics")
# The acceleration magnitude that should produce the maximum effect.
@export var max_effective_acceleration: float = 3000.0


var target_body: RigidBody2D

var _last_velocity: Vector2 = Vector2.ZERO
var _smoothed_acceleration: Vector2 = Vector2.ZERO


func _ready():
	if target_body_path:
		target_body = get_node(target_body_path)
	if not is_instance_valid(target_body) or not target_body is RigidBody2D:
		push_error("OrbitalBelt target is invalid or not a RigidBody2D! Disabling.")
		set_process(false); return
	if layers.is_empty():
		push_error("OrbitalBelt has no layers configured! Disabling."); set_process(false); return

	_last_velocity = target_body.linear_velocity

func _physics_process(delta: float):
	self.global_position = target_body.global_position

	if delta == 0: return

	# --- 1. CALCULATE AND SMOOTH ACCELERATION (The Trigger) ---
	var current_velocity = target_body.linear_velocity
	var acceleration = (current_velocity - _last_velocity) / delta
	_last_velocity = current_velocity

	var weight = 1.0 - exp(-delta * effect_smoothing_speed)
	_smoothed_acceleration = _smoothed_acceleration.lerp(acceleration, weight)

	# --- 2. CALCULATE THE OVERALL EFFECT STRENGTH (0.0 to 1.0) ---
	var accel_ratio = clampf(_smoothed_acceleration.length() / max_effective_acceleration, 0.0, 1.0)
	
	# --- 3. POSITION ORBITALS USING THE PROPORTIONAL MODEL ---
	for layer_index in range(layers.size()):
		var layer = layers[layer_index]
		var base_speed = layer.base_orbit_speed * (-1.0 if layer_index % 2 != 0 else 1.0)

		for orbital in layer.active_orbitals:
			orbital.current_angle += base_speed * delta

			var orbital_direction = Vector2.from_angle(orbital.current_angle)
			
			if accel_ratio > 0.001:
				var max_offset_for_this_layer = orbital.orbit_distance * displacement_factor
				var current_max_offset = max_offset_for_this_layer * accel_ratio
				
				var pull_direction = -_smoothed_acceleration.normalized()
				var influence = orbital_direction.dot(pull_direction)
				
				var eased_influence: float
				if influence > 0:
					# Back half (the tail): Apply tail_sharpness for a pointy shape.
					eased_influence = pow(influence, tail_sharpness)
				else:
					# *** THE FIX IS HERE ***
					# Front half (the head): Use the CORRECT variable name.
					eased_influence = -pow(abs(influence), head_width_factor)

				var displacement = current_max_offset * eased_influence
				var final_distance = orbital.orbit_distance + displacement
				
				orbital.position = orbital_direction * maxf(min_radius, final_distance)
			else:
				orbital.position = orbital_direction * orbital.orbit_distance

# --- All functions below this line are unchanged and correct. ---

func add_orbital():
	for i in range(layers.size()):
		var layer = layers[i]
		var capacity = _get_shell_capacity(i)
		if layer.active_orbitals.size() < capacity:
			if layer.orbital_scene == null: return
			var new_orbital = layer.orbital_scene.instantiate()
			add_child(new_orbital)
			layer.active_orbitals.append(new_orbital)
			_rebalance_layer(i)
			return
	print("All orbital shells are full.")

func remove_orbital():
	for i in range(layers.size() - 1, -1, -1):
		var layer = layers[i]
		if not layer.active_orbitals.is_empty():
			var orbital_to_remove = layer.active_orbitals.pop_back()
			if is_instance_valid(orbital_to_remove): orbital_to_remove.queue_free()
			_rebalance_layer(i)
			return

func _get_shell_capacity(shell_index: int) -> int:
	var n = shell_index + 1
	return 2 * n * n

func _rebalance_layer(layer_index: int):
	var layer = layers[layer_index]
	var orbital_count = layer.active_orbitals.size()
	if orbital_count == 0: return
	var angle_step = TAU / orbital_count
	for i in range(orbital_count):
		var orbital = layer.active_orbitals[i]
		var target_angle = i * angle_step
		if orbital.has_method("initialize"):
			orbital.initialize(self, target_angle, layer.orbit_distance)
		else:
			push_error("Orbital is missing initialize() method.")
