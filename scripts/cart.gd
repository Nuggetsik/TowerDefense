extends Node3D

@export var detection_range: float = 10.0  # Zasięg wykrywania wrogów
@export var rotation_speed: float = 5.0    # Prędkość obrotu wieży
@export var fire_rate: float = 0.5         # Częstotliwość strzałów (w sekundach)
@export var bullet_scene: PackedScene      # Scena pocisku
@export var enemy_group: String = "enemies"  # Nazwa grupy wrogów
@export var levelTower: int = 1            # Poziom wieży
@export var damageTower: float = 5.0       # Obrażenia zadawane przez pocisk

@onready var bullet_spawn_point: Marker3D = $BulletSpawn  # Punkt wystrzału pocisków
@onready var fire_timer: Timer = Timer.new()              # Timer do strzelania

var current_target: Node3D = null  # Aktualny cel

func _ready():
	add_child(fire_timer)
	fire_timer.wait_time = fire_rate
	fire_timer.timeout.connect(shoot)
	fire_timer.start()
	print("🔥 Timer strzelania uruchomiony.")

func _process(delta: float):
	if not current_target or not is_instance_valid(current_target) or out_of_range(current_target):
		current_target = find_closest_enemy()

		if not current_target:
			fire_timer.stop()  # Zatrzymaj timer, jeśli nie ma celu
			return
		else:
			fire_timer.start()  # Wznów timer, jeśli znaleziono cel

	rotate_towards_target(delta)  # Obróć wieżę w stronę celu

# Znajduje najbliższego wroga w zasięgu
func find_closest_enemy() -> Node3D:
	var closest_enemy: Node3D = null
	var min_distance: float = detection_range

	for enemy in get_tree().get_nodes_in_group(enemy_group):
		if not is_instance_valid(enemy):
			continue

		# Szukamy dziecka z metodą take_damage
		for child in enemy.get_children():
			if child.has_method("take_damage"):
				var distance = global_transform.origin.distance_to(child.global_transform.origin)
				if distance < min_distance:
					closest_enemy = child
					min_distance = distance

	return closest_enemy

# Sprawdza, czy cel jest poza zasięgiem
func out_of_range(enemy: Node3D) -> bool:
	return global_transform.origin.distance_to(enemy.global_transform.origin) > detection_range

# Obraca wieżę w stronę celu
func rotate_towards_target(delta: float):
	if not current_target:
		return

	var A = global_transform.origin                    # Pozycja wieży
	var B = current_target.global_transform.origin     # Pozycja celu
	var C = bullet_spawn_point.global_transform.origin # Pozycja punktu wystrzału

	# Wektory w płaszczyźnie XZ
	var vec_to_target = Vector2(B.x - A.x, B.z - A.z).normalized()
	var current_direction = Vector2(C.x - A.x, C.z - A.z).normalized()

	var target_angle = vec_to_target.angle()
	var current_angle = current_direction.angle()

	var angle_diff = shortest_angle(target_angle, current_angle)
	angle_diff = clamp(angle_diff, -PI/4, PI/4)  # Ograniczenie kąta do ±45°

	rotation.y += angle_diff * delta * rotation_speed  # Płynny obrót

# Oblicza najkrótszy kąt między dwoma wartościami
func shortest_angle(from: float, to: float) -> float:
	var difference = wrapf(to - from, -PI, PI)
	return difference

# Funkcja strzelania
func shoot():
	if not current_target or not is_instance_valid(current_target) or out_of_range(current_target):
		current_target = null
		print("❌ Cel nie znaleziony lub poza zasięgiem.")
		return
	
	print("🎯 Strzelanie do celu:", current_target.name)

	var bullet = bullet_scene.instantiate()
	bullet.global_transform = bullet_spawn_point.global_transform

	if bullet.has_method("set_damage"):
		bullet.set_damage(damageTower)

	if bullet.has_method("set_target"):
		bullet.set_target(current_target)

	get_parent().add_child(bullet)
	print("🚀 Pocisk wystrzelony.")

# Ulepszanie wieży
func upgrade():
	levelTower += 1
	damageTower *= 1.2
	fire_rate = max(fire_rate * 0.9, 0.2)  # Minimalna wartość: 0.2 s
	fire_timer.wait_time = fire_rate
	print("✅ Wieża ulepszona do poziomu", levelTower)
