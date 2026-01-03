extends TileMapLayer

@export var speed := 200.0
@export var loop_width := 2000.0  # Ancho del bucle en píxeles

func _ready():
    # Conectar a la señal de cambio de velocidad del GameManager
    if GameManager:
        GameManager.velocidad_cambiada.connect(_on_velocidad_cambiada)
        # Sincronizar con la velocidad actual al inicio
        speed = GameManager.obtener_velocidad_actual()

func _process(delta):
    position.x -= speed * delta

    # Cuando se mueve demasiado a la izquierda, resetear posición
    if position.x <= -loop_width:
        position.x += loop_width

func _on_velocidad_cambiada(nueva_velocidad: float):
    speed = nueva_velocidad
    print("🌱 Suelo: Velocidad actualizada a ", speed)
