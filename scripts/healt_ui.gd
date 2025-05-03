extends Sprite3D

signal no_hp_left  # Sygnał emitowany, gdy zdrowie spadnie do zera

@export var max_hp : int = 100   # Maksymalne zdrowie
var current_hp : int             # Aktualne zdrowie

func _ready() -> void:
	# Inicjalizacja aktualnego zdrowia i ustawienie wartości paska zdrowia
	current_hp = max_hp
	$SubViewport/Panel/ProgressBar.max_value = max_hp
	$SubViewport/Panel/ProgressBar.value = current_hp

# Ustawia zdrowie na wartość początkową
func set_health(hp: int):
	max_hp = hp
	current_hp = hp
	$SubViewport/Panel/ProgressBar.max_value = max_hp
	$SubViewport/Panel/ProgressBar.value = current_hp

# Funkcja przyjmująca obrażenia
func take_damage(damage: float):
	# Odejmujemy obrażenia od aktualnego zdrowia
	current_hp -= damage
	if current_hp < 0:
		current_hp = 0  # Nie pozwalamy, by zdrowie było ujemne

	# Aktualizacja wartości paska zdrowia
	$SubViewport/Panel/ProgressBar.value = current_hp

	# Jeśli zdrowie spadnie do zera lub poniżej — emitujemy sygnał
	if current_hp <= 0:
		no_hp_left.emit()  # Emitujemy sygnał śmierci
