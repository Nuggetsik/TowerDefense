extends Node3D

@export var health_wall: int = 20  # Zdrowie ściany
@export var enemy_group: String = "enemies"  # Nazwa grupy przeciwników

func _ready():
	$DamageDetector.body_entered.connect(_on_body_entered)

# Funkcja wywoływana przy wejściu ciała do detektora
func _on_body_entered(body):
	if body.is_in_group(enemy_group):
		health_wall -= 10
		print("Ściana otrzymała obrażenia, aktualne zdrowie: ", health_wall)
		if body.has_method("take_damage"):
			body.take_damage(10)
		body.queue_free()  # Usunięcie obiektu przeciwnika

		if health_wall <= 0:
			print("Ściana została zniszczona!")
			queue_free()
