# player.gd (Complete & Simplified)
extends "res://celestial_body.gd"

#==============================================================================
# --- EXPORTED VARIABLES ---
#==============================================================================

@export_group("Player Control")
@export var thrust_force: float = 1000000.0

@export_group("Camera Control")
@export var base_zoom: float = 1.0
@export var max_zoom_out: float = 0.4
@export var zoom_speed_threshold: float = 1000.0
@export var zoom_smoothing_speed: float = 5.0

#==============================================================================
# --- NODE REFERENCES & PRIVATE VARIABLES ---
#==============================================================================

@onready var camera: Camera2D = $Camera2D
@onready var speed_label: Label = get_node("/root/Main/CanvasLayer/SpeedometerLabel")
#@onready var orbital_belt: Node = $OrbitalBelt

#==============================================================================
# --- BUILT-IN GODOT FUNCTIONS ---
#==============================================================================

func _ready():
	super()
	add_to_group("player")
	
	if not is_instance_valid(speed_label):
		print("DIAGNOSTIC: SpeedometerLabel node was NOT found.")
	else:
		print("DIAGNOSTIC: SpeedometerLabel node found successfully.")
	
	#if not is_instance_valid(orbital_belt):
		#push_error("Player ERROR: Child node 'OrbitalBelt' not found!")


func _physics_process(delta: float):
	super(delta)
	
	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_direction != Vector2.ZERO:
		apply_central_force(input_direction * thrust_force)

	var current_speed := linear_velocity.length()
	if is_instance_valid(speed_label):
		speed_label.text = "Speed: " + str(int(current_speed))

	var target_zoom_value := remap(current_speed, 0, zoom_speed_threshold, base_zoom, max_zoom_out)
	target_zoom_value = clamp(target_zoom_value, max_zoom_out, base_zoom)
	var target_zoom_vector = Vector2(target_zoom_value, target_zoom_value)
	camera.zoom = camera.zoom.lerp(target_zoom_vector, zoom_smoothing_speed * delta)


# --- REVISED INPUT HANDLING ---
# Simplified to two actions: add and remove.
#func _unhandled_input(event: InputEvent):
	#if not event is InputEventKey:
		#return
#
	#if event.pressed and not event.is_echo():
		#
		#match event.keycode:
			#
			## Press E to add an orbital.
			#KEY_E:
				#if is_instance_valid(orbital_belt):
					#orbital_belt.add_orbital()
				#get_tree().get_root().set_input_as_handled()
#
			## Press Q to remove an orbital.
			#KEY_Q:
				#if is_instance_valid(orbital_belt):
					#orbital_belt.remove_orbital()
				#get_tree().get_root().set_input_as_handled()
