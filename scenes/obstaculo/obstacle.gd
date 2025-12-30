extends Area2D

signal jugador_muerto

@export var speed := 200.0  # Misma velocidad que el suelo

func _ready():
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

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
