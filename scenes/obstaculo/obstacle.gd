extends Area2D

signal jugador_muerto()

@export var speed: float = 200.0  # Misma velocidad que el suelo

enum TipoObstaculo { CACTUS_ALTO, PIEDRA_BAJA, ARBUSTO_MEDIO, TERO }

var tipo: TipoObstaculo = TipoObstaculo.CACTUS_ALTO

# Configuración de cada tipo de obstáculo
# NOTA: Las animaciones ("cactus", "piedra", "arbusto", "tero") deben configurarse
# en el AnimatedSprite2D desde el editor de Godot
var config_obstaculos: Dictionary = {
    TipoObstaculo.CACTUS_ALTO: {
        "animacion": "cactus",
        "escala": Vector2(3.22, 3.28),
        "colision_size": Vector2(16, 58),
        "offset_y": -9.5
    },
    TipoObstaculo.PIEDRA_BAJA: {
        "animacion": "piedra",
        "escala": Vector2(1, 1),
        "colision_size": Vector2(14, 30),
        "offset_y": 2.0
    },
    TipoObstaculo.ARBUSTO_MEDIO: {
        "animacion": "arbusto",
        "escala": Vector2(3.0, 3.0),
        "colision_size": Vector2(16, 45),
        "offset_y": -5.0
    },
    TipoObstaculo.TERO: {
        "animacion": "tero",
        "escala": Vector2(1, 1),
        "colision_size": Vector2(20, 16),
        "offset_y": -80.0  # Vuela más alto
    }
}

func _ready() -> void:
    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)

    configurar_tipo()

func set_tipo_aleatorio() -> void:
    # Seleccionar un tipo aleatorio
    var tipos: Array[TipoObstaculo] = [TipoObstaculo.CACTUS_ALTO, TipoObstaculo.PIEDRA_BAJA, TipoObstaculo.ARBUSTO_MEDIO, TipoObstaculo.TERO]
    tipo = tipos[randi() % tipos.size()]
    if is_node_ready():
        configurar_tipo()

func configurar_tipo() -> void:
    var config: Dictionary = config_obstaculos[tipo]

    # Configurar AnimatedSprite2D
    var sprite: AnimatedSprite2D = $AnimatedSprite2D
    sprite.scale = config["escala"]
    sprite.position.y = config["offset_y"]

    # Cambiar a la animación correspondiente
    sprite.animation = config["animacion"]
    sprite.play()

    # Configurar colisión
    var collision: CollisionShape2D = $CollisionShape2D
    collision.shape.size = config["colision_size"]
    collision.position.y = config["offset_y"]

func _process(delta: float) -> void:
    # Mover el obstáculo hacia la izquierda
    position.x -= speed * delta

    # Eliminar el obstáculo cuando salga de la pantalla
    if position.x < -580:
        queue_free()

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        # Obtener el nombre de la causa según el tipo
        var nombre_causa: String = obtener_nombre_causa()

        if body.has_method("recibir_dano"):
            body.recibir_dano(nombre_causa)
        else:
            body.morir(nombre_causa)

        # Opcional: Destruir obstáculo al chocar si no mata
        # queue_free()

func obtener_nombre_causa() -> String:
    # Mapear el tipo de obstáculo a la causa de muerte esperada por game_over
    match tipo:
        TipoObstaculo.CACTUS_ALTO:
            return "cactus"
        TipoObstaculo.PIEDRA_BAJA:
            return "piedra"
        TipoObstaculo.ARBUSTO_MEDIO:
            return "arbusto"
        TipoObstaculo.TERO:
            return "tero"
        _:
            return "desconocido" 
