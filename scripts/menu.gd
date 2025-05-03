extends Node3D

const WORLD = preload("res://scenes/node_3d.tscn")  # Scena gry
@onready var menu = $VBoxContainer  # Menu główne
@onready var multiplayer_ui = $VBoxContainer2  # Interfejs multiplayera
@onready var gun = $Gun  # Działo / broń gracza
const MAX_ROTATION_ANGLE = 15  # Maksymalny kąt obrotu działa

var peer = ENetMultiplayerPeer.new()  # Obiekt sieciowy ENet do połączeń
@export var player_scene : PackedScene  # Scena gracza

signal create_host()     # Sygnał do utworzenia hosta
signal join_to_host()    # Sygnał do dołączenia do hosta

# Funkcja inicjalizująca
func _ready() -> void:
	multiplayer_ui.hide()  # Ukrywamy UI multiplayera
	menu.show()            # Pokazujemy menu główne

# Obsługa rotacji działa w zależności od pozycji myszy
func _process(delta):
	if gun == null:
		return
	
	var viewport_size = get_viewport().size
	var mouse_pos = get_viewport().get_mouse_position()
	var center_x = viewport_size.x / 2
	
	var offset = (mouse_pos.x - center_x) / center_x  # Wartość od -1 do 1
	offset = clamp(offset, -1, 1)

	gun.rotation_degrees.y = offset * MAX_ROTATION_ANGLE  # Obrót działa

# Obsługa przycisku "Start"
func _on_start_button_pressed() -> void:
	Global.connection_mode = "single"  # Tryb jednoosobowy
	get_tree().change_scene_to_packed(WORLD)  # Przejście do sceny gry

# Obsługa przycisku "Multiplayer"
func _on_multy_button_pressed() -> void:
	multiplayer_ui.show()  # Pokazujemy interfejs multiplayera
	menu.hide()            # Ukrywamy menu główne

# Obsługa przycisku "Wyjście"
func _on_exit_button_pressed() -> void:
	get_tree().quit()  # Zamyka grę

# Obsługa przycisku "Anuluj" w multiplayerze
func _on_cancel_button_pressed() -> void:
	multiplayer_ui.hide()  # Ukrywamy UI multiplayera
	menu.show()            # Wracamy do menu głównego

# Obsługa przycisku "Hostuj grę"
func _on_host_button_pressed():
	Global.connection_mode = "host"  # Ustawiamy tryb hosta
	get_tree().change_scene_to_packed(WORLD)  # Przechodzimy do gry

# Obsługa przycisku "Dołącz do gry"
func _on_join_button_pressed():
	Global.connection_mode = "client"  # Ustawiamy tryb klienta
	get_tree().change_scene_to_packed(WORLD)  # Przechodzimy do gry
