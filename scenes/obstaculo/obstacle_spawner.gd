# obstacle_spawner.gd
extends Node2D

@export var obstacle_scene: PackedScene  # Arrastra aquí la escena del obstáculo
@export var spawn_distance := 300.0  # Distancia entre obstáculos en píxeles
@export var ground_y := 251.0  # Altura Y del suelo (ajusta según tu juego)
@export var speed := 200.0  # Misma velocidad que el suelo
@export var spawn_offset := 200.0  # A qué distancia adelante del borde derecho spawner

var distance_since_last_spawn := 0.0
var spawning_activo := true  # Flag para controlar si se sigue spawneando

func _ready():
	if obstacle_scene == null:
		push_error("⚠️ Asigna la escena del obstáculo en el inspector!")
		return

	# Primer obstáculo pronto
	distance_since_last_spawn = spawn_distance - 100.0

	# Conectar señal de transición del GameManager
	if GameManager:
		GameManager.iniciar_transicion_rancho.connect(_on_transicion_iniciada)

func _process(delta):
	if obstacle_scene == null or not spawning_activo:
		return

	# Acumular distancia recorrida
	distance_since_last_spawn += speed * delta

	# Verificar si es momento de spawnear
	if distance_since_last_spawn >= spawn_distance:
		spawn_obstacle()
		distance_since_last_spawn = 0.0

func spawn_obstacle():
	# Crear el obstáculo
	var obstacle = obstacle_scene.instantiate()

	# Configurar tipo aleatorio ANTES de agregar a la escena
	obstacle.set_tipo_aleatorio()
	
	# Obtener la cámara
	var camera = get_viewport().get_camera_2d()
	var spawn_x = 0.0
	
	if camera:
		# Spawnear justo afuera del borde derecho de la cámara
		var camera_pos = camera.get_screen_center_position()
		var viewport_width = get_viewport_rect().size.x
		spawn_x = camera_pos.x + (viewport_width / 2.0) + spawn_offset
		print("📷 Cámara en X: ", camera_pos.x, " | Viewport width: ", viewport_width)
	else:
		# Fallback si no hay cámara
		spawn_x = get_viewport_rect().size.x + spawn_offset
		print("⚠️ No se encontró cámara, usando fallback")
	
	# Posicionarlo
	obstacle.position.x = spawn_x
	obstacle.position.y = ground_y
	
	# Agregarlo a la escena
	get_parent().add_child(obstacle)

	print("🎯 Obstáculo spawneado en X: ", spawn_x, " Y: ", ground_y)

# ==================== CALLBACKS ====================
func _on_transicion_iniciada():
	print("🛑 ObstacleSpawner: Deteniendo spawning por transición")
	spawning_activo = false
