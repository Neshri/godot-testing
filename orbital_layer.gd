# OrbitalLayer.gd
# This is a custom Resource, not a node script.
# It defines the properties for a single ring of orbitals in the belt.
class_name OrbitalLayer
extends Resource

# The PackedScene for the orbitals that will spawn in this layer.
@export var orbital_scene: PackedScene

# The distance from the center body.
@export var orbit_distance: float = 150.0

# The base speed of the orbitals. Use a negative value for the opposite direction.
@export var base_orbit_speed: float = 5.0

# This will hold the actual orbital nodes for this layer at runtime.
var active_orbitals: Array[Node] = []
