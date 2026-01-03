# mate_spawner.gd
extends Node2D

@export var mate_scene: PackedScene  # Arrastra la escena del mate
@export var spawn_min_distance := 150.0  # Distancia mínima entre mates
@export var spawn_max_distance := 400.0  # Distancia máxima entre mates
@export var ground_y := 200.0  # Altura Y donde aparecen los mates (más arriba que el suelo)
@export var speed := 200.0  # Misma velocidad que el suelo
@export var spawn_offset := 200.0

var distance_since_last_spawn := 0.0
var next_spawn_distance := 0.0
var spawn_intentos := 0
var max_intentos := 3  # Intentos máximos antes de posponer
var spawning_activo := true  # Flag para controlar si se sigue spawneando

func _ready():
    if mate_scene == null:
        push_error("⚠️ Asigna la escena del mate en el inspector!")
        return

    # Calcular primera distancia aleatoria
    next_spawn_distance = randf_range(spawn_min_distance, spawn_max_distance)

    # Conectar señal de transición del GameManager
    if GameManager:
        GameManager.iniciar_transicion_rancho.connect(_on_transicion_iniciada)

func _process(delta):
    if mate_scene == null or not spawning_activo:
        return

    # Acumular distancia recorrida
    distance_since_last_spawn += speed * delta

    # Verificar si es momento de spawnear
    if distance_since_last_spawn >= next_spawn_distance:
        if intentar_spawn_mate():
            # Spawn exitoso
            distance_since_last_spawn = 0.0
            spawn_intentos = 0
            # Nueva distancia aleatoria
            next_spawn_distance = randf_range(spawn_min_distance, spawn_max_distance)
        else:
            # No se pudo spawnear, incrementar intentos
            spawn_intentos += 1
            if spawn_intentos >= max_intentos:
                # Demasiados intentos fallidos, resetear y esperar
                distance_since_last_spawn = 0.0
                spawn_intentos = 0
                next_spawn_distance = spawn_min_distance  # Intentar más pronto
                print("⏸️ Spawn de mate pospuesto después de varios intentos")

func intentar_spawn_mate() -> bool:
    # Obtener la cámara
    var camera = get_viewport().get_camera_2d()
    var spawn_x = 0.0
    
    if camera:
        # Spawnear justo afuera del borde derecho de la cámara
        var camera_pos = camera.get_screen_center_position()
        var viewport_width = get_viewport_rect().size.x
        spawn_x = camera_pos.x + (viewport_width / 2.0) + spawn_offset
    else:
        # Fallback si no hay cámara
        spawn_x = get_viewport_rect().size.x + spawn_offset
    
    # Spawn exitoso
    spawn_mate(spawn_x)
    return true

func spawn_mate(spawn_x: float):
    # Crear el mate
    var mate = mate_scene.instantiate()
    
    # Posicionarlo
    mate.position.x = spawn_x
    mate.position.y = ground_y
    
    # Agregarlo a la escena
    get_parent().add_child(mate)

    print("🧉 Mate spawneado en X: ", spawn_x, " Y: ", ground_y)

#region CALLBACKS
func _on_transicion_iniciada():
    print("🛑 MateSpawner: Deteniendo spawning por transición")
    spawning_activo = false
#endregion
