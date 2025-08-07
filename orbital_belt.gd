# OrbitalBelt.gd (Final Version)
extends Node2D

# Your excellent fix is now the standard: directly typed resource.
@export var spring_parameters: SpringParameters 

@export var layers: Array[OrbitalLayer]
@export var target_body_path: NodePath

@export_group("Visuals")
# How quickly the belt's orientation adapts to acceleration changes.
@export var effect_smoothing_speed: float = 6.0

# --- PRIVATE STATE VARIABLES ---
var target_body: RigidBody2D
var _last_velocity: Vector2 = Vector2.ZERO
var _smoothed_acceleration: Vector2 = Vector2.ZERO
var _orbital_velocities: Array[Vector2] = []


func _ready():
	if target_body_path:
		target_body = get_node(target_body_path)
	if not is_instance_valid(target_body) or not target_body is RigidBody2D:
		push_error("OrbitalBelt target is invalid or not a RigidBody2D! Disabling.")
		set_process(false); return
	if layers.is_empty():
		push_error("OrbitalBelt has no layers configured! Disabling."); set_process(false); return
	if spring_parameters == null:
		push_error("SpringParameters resource is not assigned! Please create one in the Inspector. Disabling belt.")
		set_process(false); return

	# Use the target's velocity for smoother startup
	_last_velocity = target_body.linear_velocity
	_rebalance_all_layers()


func _physics_process(delta: float):
	if delta == 0: return

	# --- 1. UPDATE BELT POSITION AND CALCULATE SMOOTHED ACCELERATION ---
	self.global_position = target_body.global_position
	
	var current_velocity = target_body.linear_velocity
	var acceleration = (current_velocity - _last_velocity) / delta
	_last_velocity = current_velocity

	# Lerp (smooth) the acceleration vector for a less jerky reaction
	_smoothed_acceleration = _smoothed_acceleration.lerp(acceleration, 1.0 - exp(-delta * effect_smoothing_speed))

	# --- 2. ROTATE THE ENTIRE BELT TO CREATE THE "SWING" EFFECT ---
	# The belt now points away from the direction of acceleration, creating lag.
	if _smoothed_acceleration.length_squared() > 0.1:
		self.global_rotation = (-_smoothed_acceleration).angle()

	# --- 3. UPDATE ORBITALS USING SIMULATED SPRING PHYSICS (WITHIN THE ROTATED BELT) ---
	var orbital_index = 0
	for layer_index in range(layers.size()):
		var layer = layers[layer_index]
		if layer.active_orbitals.is_empty(): continue
		
		# Make sure your OrbitalLayer resource has a non-zero base_orbit_speed!
		var base_speed = layer.base_orbit_speed * (-1.0 if layer_index % 2 != 0 else 1.0)
		
		for orbital in layer.active_orbitals:
			if not is_instance_valid(orbital): continue

			# A. Calculate the rotating anchor point for the spring. This happens in the belt's LOCAL space.
			orbital.current_angle += base_speed * delta
			var anchor_point_local = Vector2.RIGHT.rotated(orbital.current_angle) * orbital.orbit_distance

			# B. Calculate spring force
			var displacement = orbital.position - anchor_point_local
			var spring_force = -spring_parameters.stiffness * displacement
			
			# C. Calculate damping force
			var damping_force = -spring_parameters.damping * _orbital_velocities[orbital_index]

			# D. Update velocity and position
			var total_force = spring_force + damping_force
			var accel = total_force / orbital.mass
			
			_orbital_velocities[orbital_index] += accel * delta
			orbital.position += _orbital_velocities[orbital_index] * delta

			orbital_index += 1


# --- All functions below this line are correct and do not need changes ---

func add_orbital():
	for i in range(layers.size()):
		var layer = layers[i]
		var capacity = _get_shell_capacity(i)
		if layer.active_orbitals.size() < capacity:
			if layer.orbital_scene == null: return
			var new_orbital = layer.orbital_scene.instantiate()
			add_child(new_orbital)
			layer.active_orbitals.append(new_orbital)
			_orbital_velocities.append(Vector2.ZERO)
			_rebalance_layer(i)
			return
	print("All orbital shells are full.")


func remove_orbital():
	var orbital_to_remove = null
	var absolute_index = -1
	var found = false
	
	for i in range(layers.size() - 1, -1, -1):
		if not layers[i].active_orbitals.is_empty():
			orbital_to_remove = layers[i].active_orbitals.pop_back()
			found = true
			break
			
	if found:
		var current_index = 0
		for layer in layers:
			for orbital in layer.active_orbitals:
				current_index += 1
		absolute_index = current_index 
		
		if absolute_index < _orbital_velocities.size():
			_orbital_velocities.remove_at(absolute_index)
		if is_instance_valid(orbital_to_remove):
			orbital_to_remove.queue_free()
		
		_rebalance_all_layers()


func _get_shell_capacity(shell_index: int) -> int:
	var n = shell_index + 1
	return 2 * n * n


func _rebalance_all_layers():
	_orbital_velocities.clear()
	for i in range(layers.size()):
		var layer = layers[i]
		var orbital_count = layer.active_orbitals.size()
		if orbital_count == 0: continue
		
		var angle_step = TAU / orbital_count
		for j in range(orbital_count):
			var orbital = layer.active_orbitals[j]
			var target_angle = j * angle_step
			
			_orbital_velocities.append(Vector2.ZERO)
			
			if orbital.has_method("initialize"):
				orbital.initialize(self, target_angle, layer.orbit_distance)
				orbital.position = Vector2.RIGHT.rotated(target_angle) * layer.orbit_distance
			else:
				push_error("Orbital is missing initialize() method.")


func _rebalance_layer(layer_index: int):
	_rebalance_all_layers()
