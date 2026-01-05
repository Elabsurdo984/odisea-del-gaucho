# obstacle.gd
# Obstáculo del juego
extends Area2D

# ============================================================
# SIGNALS
# ============================================================
signal jugador_muerto()

# ============================================================
# EXPORTS
# ============================================================
@export var speed: float = 200.0  # Velocidad de movimiento

# ============================================================
# VARIABLES
# ============================================================
var tipo: ObstacleTypes.Tipo = ObstacleTypes.Tipo.CACTUS_ALTO

# ============================================================
# LIFECYCLE
# ============================================================
func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	configurar_tipo()

func _process(delta: float) -> void:
	# Mover el obstáculo hacia la izquierda
	position.x -= speed * delta

	# Eliminar cuando sale de la pantalla
	if position.x < -580:
		queue_free()

# ============================================================
# PUBLIC METHODS
# ============================================================

## Establece un tipo aleatorio de obstáculo
func set_tipo_aleatorio() -> void:
	tipo = ObstacleTypes.get_random_tipo()
	if is_node_ready():
		configurar_tipo()

# ============================================================
# PRIVATE METHODS
# ============================================================

## Configura el obstáculo según su tipo
func configurar_tipo() -> void:
	var config: Dictionary = ObstacleTypes.get_config(tipo)

	# Configurar AnimatedSprite2D
	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	sprite.scale = config["escala"]
	sprite.position.y = config["offset_y"]
	sprite.animation = config["animacion"]
	sprite.play()

	# Configurar colisión
	var collision: CollisionShape2D = $CollisionShape2D
	collision.shape.size = config["colision_size"]
	collision.position.y = config["offset_y"]

# ============================================================
# SIGNAL HANDLERS
# ============================================================

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Obtener nombre del obstáculo para causa de muerte
		var nombre_causa: String = ObstacleTypes.get_nombre(tipo)

		# Infligir daño al jugador
		if body.has_method("recibir_dano"):
			body.recibir_dano(nombre_causa)
		elif body.has_method("morir"):
			body.morir(nombre_causa)
