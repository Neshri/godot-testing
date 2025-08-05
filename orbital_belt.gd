# OrbitalBelt.gd (Complete with Corrected Positioning and Elliptical Math)
extends Node2D

#==============================================================================
# --- EXPORTED VARIABLES ---
#==============================================================================

@export var layers: Array[OrbitalLayer]
# This path MUST be set in the Inspector to link the belt to the moving player body.
@export var target_body_path: NodePath

@export_group("Visuals")
@export var stretch_factor: float = 0.8
@export var stretch_smoothing_speed: float = 5.0

#==============================================================================
# --- PRIVATE VARIABLES ---
#==============================================================================

var target_body: RigidBody2D
var _smoothed_target_velocity: Vector2 = Vector2.ZERO

#==============================================================================
# --- BUILT-IN GODOT FUNCTIONS ---
#==============================================================================

func _ready():
	if target_body_path:
		target_body = get_node(target_body_path)
	
	if not is_instance_valid(target_body) or not target_body is RigidBody2D:
		push_error("OrbitalBelt target is invalid or not a RigidBody2D! Disabling process.")
		set_process(false)
		return
		
	if layers.is_empty():
		push_error("OrbitalBelt has no layers configured! Please add OrbitalLayer resources in the Inspector.")
		set_process(false)
		return

func _physics_process(delta: float):
	# The belt must follow its target body's global position.
	self.global_position = target_body.global_position
	
	# Smooth the target's velocity for clean, jitter-free stretching.
	_smoothed_target_velocity = _smoothed_target_velocity.lerp(target_body.linear_velocity, stretch_smoothing_speed * delta)
	
	# If the body is barely moving, don't bother with complex math.
	if _smoothed_target_velocity.length_squared() < 1.0:
		_process_circular_orbit(delta) # This already sets position directly.
		return

	# --- Mathematically Correct Elliptical Transformation ---
	var motion_axis = _smoothed_target_velocity.normalized()
	
	# Determine how much to stretch based on speed. 1.0 = no stretch.
	var max_speed = target_body.get("max_speed") if target_body.has_method("get") else 1200.0
	var stretch_magnitude = remap(_smoothed_target_velocity.length(), 0, max_speed, 1.0, 1.0 + stretch_factor)

	for layer_index in range(layers.size()):
		var layer = layers[layer_index]
		var speed = layer.base_orbit_speed * (-1.0 if layer_index % 2 != 0 else 1.0)

		for orbital in layer.active_orbitals:
			orbital.current_angle += speed * delta
			var base_pos = Vector2.from_angle(orbital.current_angle) * orbital.orbit_distance
			
			var parallel_component = base_pos.project(motion_axis)
			var perpendicular_component = base_pos - parallel_component
			
			var final_position = perpendicular_component + (parallel_component * stretch_magnitude)
			
			# --- THE CRITICAL FIX: Direct position assignment ---
			# The orbital's position is NOW exactly where the belt calculates it to be.
			# This removes any smoothing lag or fighting with physics.
			orbital.position = final_position

#==============================================================================
# --- The rest of the script is unchanged and correct ---
#==============================================================================

func _process_circular_orbit(delta: float):
	for layer_index in range(layers.size()):
		var layer = layers[layer_index]
		var speed = layer.base_orbit_speed * (-1.0 if layer_index % 2 != 0 else 1.0)
		for orbital in layer.active_orbitals:
			orbital.current_angle += speed * delta
			var final_position = Vector2.from_angle(orbital.current_angle) * orbital.orbit_distance
			orbital.position = orbital.position.lerp(final_position, 20.0 * delta)

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
