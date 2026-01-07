extends TileMapLayer

@export var speed: float = 200.0
@export var loop_width: float = 2000.0  # Ancho del bucle en píxeles

func _ready() -> void:
    # Conectar a la señal de cambio de velocidad del DifficultyManager
    if DifficultyManager:
        DifficultyManager.velocidad_cambiada.connect(_on_velocidad_cambiada)
        # Sincronizar con la velocidad actual al inicio
        speed = DifficultyManager.obtener_velocidad_actual()

func _process(delta: float) -> void:
    position.x -= speed * delta

    # Cuando se mueve demasiado a la izquierda, resetear posición
    if position.x <= -loop_width:
        position.x += loop_width

func _on_velocidad_cambiada(nueva_velocidad: float) -> void:
    speed = nueva_velocidad
    print("🌱 Suelo: Velocidad actualizada a ", speed)
