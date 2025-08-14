# SeekerController.gd (Complete Script with Corrected Signal)
extends Node2D

# The signal now passes a reference to the controller itself.
signal died(controller)

# (All exports, enums, and state variables are unchanged)
enum State { IDLE, SEEKING, RETURNING }
@export_group("AI Settings")
@export var thrust_force: float = 50000.0
@export var return_distance: float = 400.0
@export_group("Visuals")
@export var idle_color: Color = Color("0f00ff")
@export var seeking_color: Color = Color("ff0000")
var current_state: State = State.IDLE
var current_target: Node2D = null
var home_node: Node2D = null 
var _is_dead: bool = false

@onready var detection_area = $CelestialBody/DetectionArea
@onready var visuals_node = $CelestialBody/Visuals
@onready var rigid_body = $CelestialBody

func _ready():
	if detection_area == null or visuals_node == null or rigid_body == null:
		push_error("SeekerController ERROR: One or more required child nodes not found.")
		return
	rigid_body.died.connect(_on_celestial_body_died)
	visuals_node.set_display_color(idle_color)

func set_home_node(node: Node2D):
	home_node = node

func _physics_process(delta):
	# (This function is unchanged)
	if _is_dead or not is_instance_valid(home_node):
		return
	var current_home_position = home_node.global_position
	var player_in_zone = find_player_in_zone()
	var distance_to_home = rigid_body.global_position.distance_to(current_home_position)
	if player_in_zone:
		current_state = State.SEEKING
		current_target = player_in_zone
	elif distance_to_home > return_distance:
		current_state = State.RETURNING
		current_target = null
	else:
		current_state = State.IDLE
		current_target = null
	match current_state:
		State.SEEKING:
			visuals_node.set_display_color(seeking_color)
			if is_instance_valid(current_target):
				var direction = (current_target.global_position - rigid_body.global_position).normalized()
				rigid_body.apply_central_force(direction * thrust_force)
		State.RETURNING:
			visuals_node.set_display_color(idle_color)
			var direction = (current_home_position - rigid_body.global_position).normalized()
			rigid_body.apply_central_force(direction * thrust_force)
		State.IDLE:
			visuals_node.set_display_color(idle_color)

func find_player_in_zone() -> Node2D:
	var bodies = detection_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			return body
	return null

# This function still receives the CelestialBody reference...
func _on_celestial_body_died(body):
	_is_dead = true
	
	# --- THIS IS THE FIX ---
	# ...but when we emit our own signal, we pass 'self' (the controller)
	# instead of the body. This is what the Spawner is listening for.
	died.emit(self)
	
	queue_free()
