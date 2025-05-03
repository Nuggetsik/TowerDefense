extends Node3D

func _ready() -> void:
	$TowerPlace.add_to_group("tower_places")
	$TowerPlace2.add_to_group("tower_places")
	$TowerPlace3.add_to_group("tower_places")
	$TowerPlace4.add_to_group("tower_places")
