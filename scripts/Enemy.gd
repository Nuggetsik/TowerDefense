extends CharacterBody3D

@export var speed : int = 15                # Prędkość poruszania się wroga po ścieżce
@export var health : int = 15               # Początkowe zdrowie wroga
@export var size : float = 0.3              # Skalowanie wroga
@export var jump_amplitude : float = 0.5    # Amplituda skoku (wysokość)
@export var jump_speed : float = 3.0        # Szybkość skoku (częstotliwość)

@onready var Path : PathFollow3D = get_parent()     # Ścieżka, po której porusza się wróg
@onready var health_ui: Sprite3D                    # Interfejs pokazujący zdrowie

var base_height: float                    # Bazowa wysokość do obliczeń skoku
var jump_timer: float = 0.0               # Licznik czasu skoku

# Ustawienie rozmiaru wroga
func set_size(multiplier: float):
	scale = Vector3(multiplier, multiplier, multiplier)

# Inicjalizacja obiektu
func _ready():
	set_size(size)
	base_height = global_transform.origin.y
	health_ui = $HealthUI
	if health_ui == null:
		print("HealthUI not found!")  # Ostrzeżenie, jeśli UI zdrowia nie znaleziono
	health_ui.set_health(health)

# Synchronizuje postęp ruchu na ścieżce między graczami
@rpc("authority", "call_local")
func sync_progress(value: float):
	Path.set_progress(value)

# Główna fizyczna logika ruchu
func _physics_process(delta):
	# Poruszanie się wzdłuż ścieżki
	var new_progress = Path.get_progress() + speed * delta
	Path.set_progress(new_progress)
	rpc("sync_progress", new_progress)

	# Skakanie: modyfikacja pozycji Y na podstawie funkcji sinusoidalnej
	jump_timer += delta * jump_speed
	var y_offset = sin(jump_timer * PI * 2.0) * jump_amplitude
	var current_pos = global_transform.origin
	current_pos.y = base_height + y_offset
	global_transform.origin = current_pos

	# Jeśli dotarł do końca ścieżki — usuń wroga
	if Path.get_progress_ratio() >= 0.99:
		rpc("destroy_enemy")
		queue_free()

# Sygnał wysyłany, gdy wróg zostaje zniszczony
signal enemy_destroyed

# Funkcja odebrania obrażeń
func take_damage(damage: int):
	health -= damage
	print("Current health: ", health)
	health_ui.take_damage(damage)  # Aktualizacja UI zdrowia

	if health <= 0:
		health = 0
		rpc("destroy_enemy")       # Usunięcie wroga
		emit_signal("enemy_destroyed")  # Emisja sygnału zniszczenia

# RPC do zniszczenia wroga (może być wywołane z każdego klienta)
@rpc("any_peer", "call_local")
func destroy_enemy():
	queue_free()
