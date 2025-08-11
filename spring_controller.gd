# SpringController.gd (Final, with Manual Sync)
extends Node2D

@export var weapon_scene: PackedScene

@export_group("Spring Settings")
# The length the spring wants to be.
@export var rest_length: float = 100.0
# How strong the spring is. Higher values = more rigid.
@export var stiffness: float = 300.0
# How much the spring resists bouncing. Higher values = less bounce.
@export var damping: float = 5.0

func _ready():
	# --- 1. Validation ---
	var anchor_node = get_parent()
	if not anchor_node is StaticBody2D: # Checking for StaticBody2D now
		push_error("SpringController's parent must be a StaticBody2D named 'SpringAnchor'! Disabling.")
		set_process(false)
		return
		
	var player_body = anchor_node.get_parent()
	if not player_body is RigidBody2D:
		push_error("The SpringAnchor's parent must be a RigidBody2D (the player)! Disabling.")
		set_process(false)
		return

	if weapon_scene == null:
		push_error("Weapon Scene is not set in the SpringController! Disabling.")
		set_process(false)
		return

	# Defer the setup to prevent "node is busy" errors.
	call_deferred("_setup_spring_system")


func _setup_spring_system():
	var anchor_node = get_parent()
	var player_body = anchor_node.get_parent()

	# --- 2. Create the Weapon ---
	var weapon_instance = weapon_scene.instantiate()
	weapon_instance.global_position = player_body.global_position + Vector2.RIGHT * rest_length
	get_tree().root.add_child(weapon_instance)
	
	# --- 3. Create the Spring Joint ---
	var spring_joint = DampedSpringJoint2D.new()
	
	spring_joint.rest_length = rest_length
	spring_joint.stiffness = stiffness
	spring_joint.damping = damping
	
	spring_joint.node_a = anchor_node.get_path()
	spring_joint.node_b = weapon_instance.get_path()
	
	# Add the joint to the root for stability.
	get_tree().root.add_child(spring_joint)


# --- THE FIX ---
# This function runs every physics frame.
func _physics_process(delta: float):
	# We manually force the anchor's position to match the player's position.
	# This guarantees the physics server knows exactly where the anchor is.
	var anchor_node = get_parent()
	var player_body = anchor_node.get_parent()
	anchor_node.global_position = player_body.global_position
