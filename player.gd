extends "res://celestial_body.gd"

#==============================================================================
# --- EXPORTED VARIABLES ---
#==============================================================================

@export_group("Player Control")
@export var thrust_force: float = 1500.0

@export_group("Camera Control")
@export var base_zoom: float = 1.0
@export var max_zoom_out: float = 0.4
@export var zoom_speed_threshold: float = 1000.0
@export var zoom_smoothing_speed: float = 5.0

@export_group("Orbital Management")
@export var orbital_type_1: PackedScene
@export var orbital_type_2: PackedScene


#==============================================================================
# --- NODE REFERENCES & PRIVATE VARIABLES ---
#==============================================================================

@onready var camera: Camera2D = $Camera2D
@onready var speed_label: Label = get_node("/root/Main/CanvasLayer/SpeedometerLabel")

var active_orbitals: Array[Node] = []


#==============================================================================
# --- BUILT-IN GODOT FUNCTIONS ---
#==============================================================================

func _ready():
	super()
	if not is_instance_valid(speed_label):
		print("DIAGNOSTIC: SpeedometerLabel node was NOT found.")
	else:
		print("DIAGNOSTIC: SpeedometerLabel node found successfully.")


func _physics_process(delta):
	# We call super() to run the gravity and new speed cap logic first.
	super(delta)
	
	# Apply player thrust
	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_direction != Vector2.ZERO:
		apply_central_force(input_direction * thrust_force)

	# The speed cap logic has been REMOVED from here and moved to celestial_body.gd

	# Update camera and speedometer
	var current_speed := linear_velocity.length()
	if is_instance_valid(speed_label):
		speed_label.text = "Speed: " + str(int(current_speed))

	var target_zoom_value := remap(current_speed, 0, zoom_speed_threshold, base_zoom, max_zoom_out)
	target_zoom_value = clamp(target_zoom_value, max_zoom_out, base_zoom)
	var target_zoom_vector = Vector2(target_zoom_value, target_zoom_value)
	camera.zoom = camera.zoom.lerp(target_zoom_vector, zoom_smoothing_speed * delta)


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_accept"):
		_clear_orbitals()
		_spawn_orbital(orbital_type_1, 0)
		get_tree().get_root().set_input_as_handled()


#==============================================================================
# --- CUSTOM HELPER FUNCTIONS ---
#==============================================================================

func _clear_orbitals():
	for orbital in active_orbitals:
		if is_instance_valid(orbital):
			orbital.queue_free()
	active_orbitals.clear()

func _spawn_orbital(orbital_blueprint: PackedScene, start_angle: float):
	if orbital_blueprint == null:
		print("Cannot spawn orbital: No scene assigned in the Inspector.")
		return
	var new_orbital = orbital_blueprint.instantiate()
	add_child(new_orbital)
	new_orbital.initialize(start_angle)
	active_orbitals.append(new_orbital)
