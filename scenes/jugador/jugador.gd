# jugador.gd
extends CharacterBody2D

@export var gravity := 1000
@export var jump_force := -420
@export var crouch_collision_reduction := 0.5  # Reducir colisión a la mitad

var esta_vivo := true
var esta_agachado := false
var collision_shape_original_size: Vector2
var collision_shape_original_position: Vector2

func _ready() -> void:
	add_to_group("player")
	
	# Guardar tamaño y posición original de la colisión
	var collision = $CollisionShape2D
	collision_shape_original_size = collision.shape.size
	collision_shape_original_position = collision.position

func _physics_process(delta):
	if not esta_vivo:
		return
	
	# Gravedad
	velocity.y += gravity * delta

	# Agacharse
	manejar_agachado()

	# Salto (solo si está en el suelo y NO está agachado)
	if is_on_floor() and Input.is_action_just_pressed("salto") and not esta_agachado:
		velocity.y = jump_force
		
	move_and_slide()

func manejar_agachado():
	# Detectar si se presiona la tecla de agacharse
	if Input.is_action_pressed("agacharse") and is_on_floor():
		if not esta_agachado:
			agacharse()
	else:
		if esta_agachado:
			levantarse()

func agacharse():
	esta_agachado = true
	
	# Cambiar a animación de agacharse
	$AnimatedSprite2D.animation = "agacharse"
	$AnimatedSprite2D.play()
	
	# Reducir el tamaño de la colisión
	var collision = $CollisionShape2D
	collision.shape.size.y = collision_shape_original_size.y * crouch_collision_reduction
	
	# Ajustar la posición de la colisión para que quede en el suelo
	var offset_y = collision_shape_original_size.y * (1 - crouch_collision_reduction) / 2
	collision.position.y = collision_shape_original_position.y + offset_y

func levantarse():
	esta_agachado = false
	
	# Volver a la animación de correr
	$AnimatedSprite2D.animation = "correr"
	$AnimatedSprite2D.play()
	
	# Restaurar el tamaño original de la colisión
	var collision = $CollisionShape2D
	collision.shape.size = collision_shape_original_size
	collision.position = collision_shape_original_position

func morir():
	if not esta_vivo:
		return
	
	esta_vivo = false
	
	$AnimatedSprite2D.modulate = Color.RED
	
	set_physics_process(false)
	get_tree().paused = true
	
	await get_tree().create_timer(1.0).timeout
	get_tree().paused = false
	get_tree().reload_current_scene()
