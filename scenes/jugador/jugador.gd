extends CharacterBody2D

@export var gravity := 1000
@export var jump_force := -420

var esta_vivo := true

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta):
	if not esta_vivo:
		return
	
	# Gravedad
	velocity.y += gravity * delta

	# Salto
	if is_on_floor() and Input.is_action_just_pressed("salto"):
		velocity.y = jump_force
		
	move_and_slide()

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
	
