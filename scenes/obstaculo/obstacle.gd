extends Area2D

signal jugador_muerto

@export var speed := 200.0  # Misma velocidad que el suelo

enum TipoObstaculo { CACTUS_ALTO, PIEDRA_BAJA, ARBUSTO_MEDIO, TERO }

var tipo: TipoObstaculo = TipoObstaculo.CACTUS_ALTO

# Configuración de cada tipo de obstáculo
# NOTA: Las animaciones ("cactus", "piedra", "arbusto", "tero") deben configurarse
# en el AnimatedSprite2D desde el editor de Godot
var config_obstaculos = {
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

func _ready():
    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)

    configurar_tipo()

func set_tipo_aleatorio():
    # Seleccionar un tipo aleatorio
    var tipos = [TipoObstaculo.CACTUS_ALTO, TipoObstaculo.PIEDRA_BAJA, TipoObstaculo.ARBUSTO_MEDIO, TipoObstaculo.TERO]
    tipo = tipos[randi() % tipos.size()]
    if is_node_ready():
        configurar_tipo()

func configurar_tipo():
    var config = config_obstaculos[tipo]

    # Configurar AnimatedSprite2D
    var sprite = $AnimatedSprite2D
    sprite.scale = config["escala"]
    sprite.position.y = config["offset_y"]

    # Cambiar a la animación correspondiente
    sprite.animation = config["animacion"]
    sprite.play()

    # Configurar colisión
    var collision = $CollisionShape2D
    collision.shape.size = config["colision_size"]
    collision.position.y = config["offset_y"]

func _process(delta):
    # Mover el obstáculo hacia la izquierda
    position.x -= speed * delta
    
    # Eliminar el obstáculo cuando salga de la pantalla
    if position.x < -580:
        queue_free()

func _on_body_entered(body):
    if body.is_in_group("player"):
        jugador_muerto.emit()
        body.morir()
