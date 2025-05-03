extends Sprite3D

func set_label(level : int, damage : float) -> void:
	$SubViewport/LevelLabel.text = "Level: " + "%d" % level
	$SubViewport/DamageLabel.text = "Damage: " + "%.2f" % damage


func _on_upgrade_button_button_down() -> void:
	print("Press down") # Replace with function body.
