extends Node3D

@onready var enemy : PackedScene = preload("res://scenes/enemy.tscn") # Ładowanie sceny wroga
@onready var player_spawner := $PlayerSpawner # Spawner gracza
@onready var spawn_point : Marker3D = $SpawnPoint # Punkt, w którym gracz się pojawi
@onready var spawn_timer := $SpawnTimer # Timer do spawnowania wrogów
@onready var path_node := $Maps/Path3D # Ścieżka, po której poruszają się wrogowie
var existing_enemies: Array[String] = [] # Lista istniejących wrogów

@export var player_scene : PackedScene # Scena gracza, którą można eksportować

var enemies_to_spawn : int = 3 # Ilość wrogów do spawnowania
var can_spawn : bool = true # Czy można spawnować wrogów

var peer = ENetMultiplayerPeer.new() # Obiekt odpowiadający za komunikację w multiplayerze


func _ready():
	player_spawner.spawn_function = spawn_player # Funkcja do spawnowania gracza

	# Sprawdzenie trybu połączenia
	if Global.connection_mode == "host":
		host_create() # Tworzenie serwera
	elif Global.connection_mode == "client":
		join_to_game() # Łączenie się jako klient
	elif Global.connection_mode == "single":
		add_player(multiplayer.get_unique_id()) # Dodanie gracza w trybie offline

# Funkcja do spawnowania gracza
func spawn_player(id: int) -> Node:
	var player = player_scene.instantiate() # Tworzenie instancji gracza
	player.name = str(id) # Nadanie unikalnej nazwy gracza
	player.set_multiplayer_authority(id) # Przypisanie graczowi autorytetu
	return player

# Funkcja do tworzenia serwera
func host_create():
	peer.create_server(1027) # Tworzenie serwera na porcie 1027
	multiplayer.multiplayer_peer = peer # Ustawienie połączenia multiplayer
	multiplayer.peer_connected.connect(add_player) # Połączenie sygnału do dodawania gracza
	print("✅ Server created on port 1027") # Informacja o utworzeniu serwera
	add_player(multiplayer.get_unique_id()) # Dodanie gracza jako host

# Funkcja do łączenia się z serwerem
func join_to_game():
	peer.create_client("localhost", 1027) # Tworzenie klienta i połączenie z serwerem
	multiplayer.multiplayer_peer = peer # Ustawienie połączenia multiplayer
	peer.connect("peer_connected", _on_peer_connected) # Podłączenie sygnału połączenia gracza
	print("🌐 Client connecting to localhost:1027") # Informacja o próbie połączenia

# Funkcja wywoływana po połączeniu gracza
func _on_peer_connected(id):
	print("👤 Игрок с ID", id, "подключился.") # Informacja o połączeniu gracza
	# Nie spawniamy lokalnie! Hoster sam wywoła add_player po sygnale

# Funkcja do dodawania gracza do gry
func add_player(id = 1):
	print("📦 Спавним игрока с ID:", id) # Informacja o spawnowaniu gracza
	rpc("_remote_add_player", id) # Wywołanie funkcji na zdalnym hoście, aby dodać gracza

	# Tylko host wysyła wrogów
	if multiplayer.is_server():
		for enemy_id in existing_enemies:
			rpc_id(id, "spawn_enemy", enemy_id) # Wysyłanie informacji o wrogach do nowego gracza


@rpc("any_peer", "call_local")
# Funkcja zdalnego dodawania gracza
func _remote_add_player(id):
	player_spawner.spawn(id) # Spawnowanie gracza
	# Tylko host ustawia pozycję
	if multiplayer.is_server():
		rpc_id(id, "initialize_player_position", id) # Ustawienie pozycji gracza

# Funkcja wyjścia z gry
func exit_game(id):
	multiplayer.peer_disconnected.connect(del_player) # Łączenie sygnału rozłączenia
	del_player(id) # Usuwanie gracza

# Funkcja do usuwania gracza
func del_player(id):
	rpc("_del_player", id) # Usuwanie gracza na zdalnych urządzeniach

@rpc("any_peer", "call_local")
# Funkcja usuwania gracza na zdalnym urządzeniu
func _del_player(id):
	if has_node(str(id)):
		get_node(str(id)).queue_free() # Usunięcie gracza z sceny
		print("Player", id, "removed from scene") # Informacja o usunięciu gracza

@rpc("authority", "call_local")
# Funkcja ustawiania pozycji gracza
func initialize_player_position(id):
	var player_node = get_node_or_null(str(id)) # Pobranie węzła gracza
	if player_node:
		player_node.global_transform.origin = spawn_point.global_transform.origin # Ustawienie pozycji gracza

# Funkcja do zarządzania procesem gry
func _process(delta):
	if is_multiplayer_authority(): # Jeśli mamy autorytet w multiplayerze
		game_manager() # Zarządzanie grą

# Funkcja zarządzania spawnem wrogów
func game_manager():
	if enemies_to_spawn > 0 and can_spawn: # Jeśli można spawnować wrogów
		spawn_timer.start() # Uruchomienie timera

		# Generowanie unikalnego ID dla wroga
		var enemy_id = "enemy_%s_%s" % [str(Time.get_unix_time_from_system()), str(randi())]
		rpc("spawn_enemy", enemy_id) # Wysłanie sygnału o spawnowaniu wroga

		enemies_to_spawn -= 1 # Zmniejszenie liczby wrogów do spawnowania
		can_spawn = false # Blokada spawnowania

@rpc("any_peer", "call_local")
# Funkcja spawnowania wroga
func spawn_enemy(enemy_id: String):
	if enemy_id in existing_enemies:
		return # Jeśli wróg już istnieje, nie twórz go

	existing_enemies.append(enemy_id) # Dodanie ID wroga do listy

	var tempEnemy = enemy.instantiate() # Tworzenie instancji wroga
	tempEnemy.name = enemy_id # Nadanie unikalnej nazwy
	tempEnemy.set_multiplayer_authority(1)  # Hoster ma zawsze autorytet
	path_node.add_child(tempEnemy) # Dodanie wroga do ścieżki
	tempEnemy.add_to_group("enemies") # Dodanie wroga do grupy wrogów

# Funkcja wywoływana po zakończeniu timera
func _on_spawn_timer_timeout():
	can_spawn = true # Odblokowanie spawnowania
