extends RigidBody3D

var mouse_sensitivity := 0.001  # Czułość myszy
var twist_input := 0.0
var pitch_input := 0.0
var walk_speed := 1.0  # Prędkość chodzenia
var run_speed := 2.0   # Prędkość biegu
var speed := 1.0
var selected = 0  # Indeks wybranej wieży
var run = false   # Czy gracz biegnie

@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot
@onready var hotbar = $TwistPivot/PitchPivot/Hotbar
@onready var placement_ray := $TwistPivot/PitchPivot/PlacementRay  # RayCast3D do wykrywania pozycji umieszczenia wieży

@export var tower_scenes: Array[PackedScene]  # Lista dostępnych scen wież

@export var jump_strength: float = 13.0  # Siła skoku
@export var gravity: float = 9.8  # Wartość grawitacji
@export var money: int = 200  # Początkowa ilość pieniędzy

@onready var floor_ray = $FloorRay  # RayCast3D do sprawdzania, czy gracz stoi na ziemi
@onready var skin: Node3D = $Skin  # Model gracza

@onready var animation_player = $Skin/AnimationPlayer
@onready var cam = $TwistPivot/PitchPivot/Camera3D
@onready var label = $TwistPivot/PitchPivot/Panel/CountMoney  # UI pokazujące ilość pieniędzy

# Ustawienie autorytetu multiplayera
func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

# Kliknięcie myszą – ulepszenie wieży
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if placement_ray.is_colliding():
			var tower = placement_ray.get_collider()
			if tower and tower.has_method("upgrade"):
				tower.upgrade()

# Inicjalizacja
func _ready() -> void:
	if is_multiplayer_authority():
		cam.current = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		placement_ray.enabled = true
		floor_ray.enabled = true
		
		label.clear()
		label.append_text(str(money))
	else:
		cam.current = false
		set_process(false)
		set_physics_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)

# Fizyczne przetwarzanie: ruch, grawitacja, animacje
func _physics_process(delta):
	var velocity := Vector3.ZERO

	# Pobieranie wejścia z klawiszy ruchu
	var input := Vector3.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_back")

	if input.length() > 0.01:
		var move_dir = (twist_pivot.basis * input).normalized()
		move_dir.y = 0
		velocity = move_dir

		# Obrót modelu gracza w kierunku ruchu
		var target_pos = global_transform.origin + move_dir
		skin.look_at(target_pos, Vector3.UP)
		skin.rotation.x = 0
		skin.rotation.z = 0
		skin.rotate_y(deg_to_rad(180))  # Odwrócenie modelu jeśli trzeba

		# Odtwarzanie animacji
		if run:
			animation_player.play("Running/mixamo_com")
		else:
			animation_player.play("Walking/mixamo_com")
	else:
		animation_player.play("Idle/mixamo_com")

	# Przesuwanie gracza
	apply_central_force(twist_pivot.basis * input * 1200.0 * delta * speed)

	# Grawitacja
	if not is_on_floor():
		apply_force(Vector3(0, -gravity * mass, 0))

	# Skakanie
	if Input.is_action_just_pressed("jump") and is_on_floor():
		jump()

# Skok
func jump():
	apply_impulse(Vector3(0, jump_strength * mass, 0))

# Sprawdza, czy gracz stoi na ziemi
func is_on_floor():
	return floor_ray.is_colliding()

# Przetwarzanie każdego frame'u: prędkość, tryb myszy, wybór wieży
func _process(delta: float) -> void:

	if Input.is_action_pressed("move_run"):
		run = true
		speed = run_speed
	else:
		run = false
		speed = walk_speed

	# Przełączanie widoczności kursora
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Obracanie kamery
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-80), deg_to_rad(30))
	twist_input = 0.0
	pitch_input = 0.0

	# Wybór wieży
	if Input.is_action_just_pressed("one"):
		selected = 0
		hotbar.select(0)
	if Input.is_action_just_pressed("two"):
		selected = 1
		hotbar.select(1)
	if Input.is_action_just_pressed("three"):
		selected = 2
		hotbar.select(2)
	if Input.is_action_just_pressed("four"):
		selected = 3
		hotbar.select(3)

	# Próba postawienia wieży
	if Input.is_action_just_pressed("place_tower"):
		place_tower()

# Obsługa ruchu myszy
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = -event.relative.x * mouse_sensitivity
			pitch_input = -event.relative.y * mouse_sensitivity

# Funkcja stawiająca wieżę
func place_tower():
	if placement_ray.is_colliding():
		var position = placement_ray.get_collision_point()
		var colliding_object = placement_ray.get_collider()

		if colliding_object.is_in_group("tower_places"):
			if selected < tower_scenes.size():
				var tower_id = selected
				rpc("spawn_tower", position, tower_id)  # Zgłaszamy postawienie wieży wszystkim graczom

# RPC do tworzenia wieży w danym miejscu
@rpc("any_peer", "call_local")
func spawn_tower(position: Vector3, tower_id: int):
	if tower_id < tower_scenes.size():
		var new_tower = tower_scenes[tower_id].instantiate()
		new_tower.global_transform.origin = position
		get_tree().current_scene.add_child(new_tower)
