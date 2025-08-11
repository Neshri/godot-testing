# movable_anchor.gd
extends AnimatableBody2D

## The node that this anchor should follow. Assign this in the Inspector.
@export var target_node: NodePath

## The swinging mass scene to spawn. Assign this in the Inspector.
@export var swinging_mass_scene: PackedScene

## The position where the new mass spawns, relative to the anchor.
@export var spawn_offset: Vector2 = Vector2(0, 100) # <-- NEW: Added this line

# A private variable to hold a direct reference to the target node for efficiency.
var _target_reference: Node2D


func _ready():
	# This function runs once when the node enters the scene tree.
	# We get the actual node from the NodePath and store it.
	if not target_node.is_empty():
		_target_reference = get_node(target_node)
	
	# A safety check to ensure you've assigned the target in the editor.
	if not _target_reference:
		push_error("Target node not assigned or found for MovableAnchor. Please assign it in the Inspector.")


func _unhandled_input(event: InputEvent):
	# Listen for a specific key press.
	# We check if the event is a key event, if the key is 'E', and if it's being pressed down.
	if event is InputEventKey and event.keycode == KEY_E and event.pressed:
		# Call the function to add a new mass and mark the event as handled.
		add_swinging_mass()
		get_viewport().set_input_as_handled()


func _physics_process(delta):
	# This function runs every physics frame.
	# We only proceed if the target reference is valid.
	if _target_reference:
		# Set this anchor's global position to the target's global position.
		global_position = _target_reference.global_position


func add_swinging_mass():
	if not swinging_mass_scene:
		push_error("Cannot add swinging mass because the scene has not been assigned in the Inspector.")
		return

	# 1. Instantiate the new scene. Its root is the RigidBody2D itself.
	var mass_body = swinging_mass_scene.instantiate()
	
	if not mass_body is RigidBody2D:
		push_error("Spawned scene's root is not a RigidBody2D.")
		mass_body.queue_free()
		return

	# 2. Add it to the tree as a child of the main scene, NOT the belt.
	#    This prevents weird physics interactions with the AnimatableBody2D.
	get_tree().root.add_child(mass_body)

	# 3. Configure the new mass.
	#    Set its spawn position.
	mass_body.global_position = self.global_position + spawn_offset
	#    Link its anchor_node variable directly to this belt.
	mass_body.anchor_node = self
