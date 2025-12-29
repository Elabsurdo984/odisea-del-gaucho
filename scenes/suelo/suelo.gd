extends TileMapLayer

@export var speed := 200.0
@export var loop_width := 2000.0  # Ancho del bucle en píxeles

func _process(delta):
	position.x -= speed * delta
	
	# Cuando se mueve demasiado a la izquierda, resetear posición
	if position.x <= -loop_width:
		position.x += loop_width
