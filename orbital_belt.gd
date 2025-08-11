# OrbitalBelt.gd (Corrected with Global Space Physics)
extends Node2D

@export var spring_parameters: SpringParameters 
@export var layers: Array[OrbitalLayer]
@export var target_body_path: NodePath

@export_group("Visuals")
# How quickly the belt's orientation adapts to acceleration.
@export var effect_smoothing_speed: float = 6.0

# --- PRIVATE STATE VARIABLES ---
var target_body: RigidBody2D
var _last_velocity: Vector2 = Vector2.ZERO
var _smoothed_acceleration: Vector2 = Vector2.ZERO
# This will now store each orbital's velocity in GLOBAL space.
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
		push_error("SpringParameters resource is not assigned! Disabling belt.")
		set_process(false); return

	_last_velocity = target_body.linear_velocity
	_rebalance_all_layers()


# In OrbitalBelt.gd

func _physics_process(delta: float):
	if delta == 0: return

	# --- 1. SETUP: GET ACCELERATION, SET BELT POSITION ---
	var current_velocity = target_body.linear_velocity
	var acceleration = (current_velocity - _last_velocity) / delta
	_last_velocity = current_velocity
	
	# Smooth the acceleration for a less jerky reaction
	_smoothed_acceleration = _smoothed_acceleration.lerp(acceleration, 1.0 - exp(-delta * effect_smoothing_speed))

	# The belt follows the player but DOES NOT ROTATE. Its local space is stable.
	self.global_position = target_body.global_position

	# --- 2. THE LOOP: CONSTANT ROTATION ANCHOR + INERTIAL FORCE ---
	# Replace the for loop in _physics_process with this corrected version.

	var orbital_index = 0
	for layer_index in range(layers.size()):
		var layer = layers[layer_index]
		if layer.active_orbitals.is_empty(): continue
		
		var base_speed = layer.base_orbit_speed * (-1.0 if layer_index % 2 != 0 else 1.0)
		
		for orbital in layer.active_orbitals:
			if not is_instance_valid(orbital): continue

			# A. CONSTANT ROTATION ANCHOR: Unchanged.
			orbital.current_angle += base_speed * delta
			var anchor_point_local = Vector2.RIGHT.rotated(orbital.current_angle) * orbital.orbit_distance

			# --- THE FIX: Scale Spring and Damping forces by mass ---
			# This ensures they are strong enough to counteract the inertial effect.

			# B. SPRING FORCE: Pulls the orbital toward its anchor.
			var displacement = orbital.position - anchor_point_local
			var spring_force = -spring_parameters.stiffness * displacement * orbital.mass # Multiplied by mass
			
			# C. DAMPING FORCE: Slows the orbital's oscillation.
			var damping_force = -spring_parameters.damping * _orbital_velocities[orbital_index] * orbital.mass # Multiplied by mass

			# D. INERTIAL FORCE: Pushes the orbital opposite to player acceleration.
			var inertial_force = -_smoothed_acceleration * orbital.mass

			# E. UPDATE: Combine forces and update local velocity and position.
			# Because all forces are now proportional to mass, the mass cancels out,
			# creating a stable system that is easy to tune.
			var total_force = spring_force + damping_force + inertial_force
			var local_accel = total_force / orbital.mass
			
			_orbital_velocities[orbital_index] += local_accel * delta
			orbital.position += _orbital_velocities[orbital_index] * delta

			orbital_index += 1


# --- Rebalance functions adjusted for global positioning ---

func _rebalance_all_layers():
	_orbital_velocities.clear()
	var orbital_index = 0
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
				# Set the orbital's initial GLOBAL position correctly.
				# We assume the belt starts with no rotation.
				orbital.global_position = self.global_position + Vector2.RIGHT.rotated(target_angle) * layer.orbit_distance
			else:
				push_error("Orbital is missing initialize() method.")
			orbital_index += 1


# --- Other functions remain correct ---

func add_orbital():
	for i in range(layers.size()):
		var layer = layers[i]
		var capacity = _get_shell_capacity(i)
		if layer.active_orbitals.size() < capacity:
			if layer.orbital_scene == null: return
			var new_orbital = layer.orbital_scene.instantiate()
			add_child(new_orbital)
			layer.active_orbitals.append(new_orbital)
			# Rebalance will add the velocity and set the correct position.
			_rebalance_layer(i)
			return
	print("All orbital shells are full.")

func _get_shell_capacity(shell_index: int) -> int:
	var n = shell_index + 1
	return 2 * n * n

func _rebalance_layer(layer_index: int):
	_rebalance_all_layers()

# remove_orbital() does not need to change.
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
