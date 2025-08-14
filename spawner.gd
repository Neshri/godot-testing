# spawner.gd (Complete Script)
extends Node2D

@export_group("Spawner Settings")
@export var scene_to_spawn: PackedScene
@export var max_enemies: int = 5
@export var spawn_interval: float = 3.0

# --- NEW: Array to track our specific children ---
var _spawned_enemies: Array = []

@onready var spawn_timer = $SpawnTimer
@onready var spawn_position = $SpawnPosition

func _ready():
	if not scene_to_spawn:
		push_error("Spawner has no scene to spawn assigned!")
		return
	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()

func _on_spawn_timer_timeout():
	# Use the array's size for the current count. It's more reliable.
	if _spawned_enemies.size() < max_enemies:
		spawn_enemy()

func spawn_enemy():
	var new_enemy_instance = scene_to_spawn.instantiate()
	
	# The SeekerController itself has the 'died' signal we want to connect to.
	if new_enemy_instance.has_signal("died"):
		# Connect to the SeekerController's died signal.
		new_enemy_instance.died.connect(_on_enemy_died)
	else:
		push_error("Could not find a 'died' signal in the spawned scene's root.")
		new_enemy_instance.queue_free()
		return
	
	# --- NEW: Add the new enemy to our tracking list ---
	_spawned_enemies.append(new_enemy_instance)
	# print("Enemy spawned. Current count: ", _spawned_enemies.size())
	
	new_enemy_instance.global_position = spawn_position.global_position
	if new_enemy_instance.has_method("set_home_node"):
		new_enemy_instance.set_home_node(self)
	
	get_tree().root.add_child(new_enemy_instance)

# --- MODIFIED HANDLER ---
# This function now receives the body that died.
func _on_enemy_died(body_that_died):
	print(body_that_died)
	# Check if the enemy that died is one that we are tracking.
	if _spawned_enemies.has(body_that_died):
		# It's one of ours! Remove it from our list.
		_spawned_enemies.erase(body_that_died)
		print("Spawner confirmed its own child died. Current count: ", _spawned_enemies.size())
	# If the enemy is not in our list, we simply do nothing.
