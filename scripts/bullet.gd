extends Node3D

@export var speed := 20.0  # Prędkość lotu pocisku
var damage: float = 5      # Obrażenia zadawane przez pocisk

var target: Node3D = null  # Cel, do którego leci pocisk

# Ustawia wartość obrażeń
func set_damage(value: float):
	self.damage = value  # Teraz wartość jest poprawnie aktualizowana

# Ustawia cel pocisku
func set_target(enemy):
	target = enemy

func _process(delta):
	if target and is_instance_valid(target):
		# Poruszaj się w stronę celu
		position = position.move_toward(target.global_transform.origin, speed * delta)

		# Sprawdź, czy pocisk dotarł do celu
		if position.distance_to(target.global_transform.origin) < 1.0:
			# Sprawdź, czy cel ma metodę take_damage i czy jest wrogiem
			if target.has_method("take_damage"):
				target.take_damage(damage)  # Wywołaj metodę zadawania obrażeń
			queue_free()  # Usuń pocisk po trafieniu
	else:
		queue_free()  # Usuń pocisk, jeśli nie ma ważnego celu
