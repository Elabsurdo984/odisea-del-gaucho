# jugador.gd
extends CharacterBody2D

@export var gravity := 1000
@export var jump_force := -420
@export var crouch_collision_reduction := 0.5

@export var animacion: AnimatedSprite2D

var esta_vivo := true
var esta_agachado := false
var invencible := false
var collision_shape_original_size: Vector2
var collision_shape_original_position: Vector2

func _ready() -> void:
    add_to_group("player")
    
    var collision = $CollisionShape2D
    collision_shape_original_size = collision.shape.size
    collision_shape_original_position = collision.position

func _physics_process(delta):
    if not esta_vivo:
        return
    
    velocity.y += gravity * delta

    manejar_agachado()

    if is_on_floor() and Input.is_action_just_pressed("salto") and not esta_agachado:
        velocity.y = jump_force
        $SonidoSalto.play()

    if not esta_agachado:
        if not is_on_floor():
            if animacion.animation != "salto":
                animacion.play("salto")
        else:
            if animacion.animation != "correr":
                animacion.play("correr")

    move_and_slide()

func manejar_agachado():
    if Input.is_action_pressed("agacharse") and is_on_floor():
        if not esta_agachado:
            agacharse()
        elif not animacion.is_playing() and animacion.animation == "agacharse":
            animacion.frame = animacion.sprite_frames.get_frame_count("agacharse") - 1
    else:
        if esta_agachado:
            levantarse()

func agacharse():
    esta_agachado = true
    animacion.animation = "agacharse"
    animacion.play()

    var collision = $CollisionShape2D
    collision.shape.size.y = collision_shape_original_size.y * crouch_collision_reduction
    var offset_y = collision_shape_original_size.y * (1 - crouch_collision_reduction) / 2
    collision.position.y = collision_shape_original_position.y + offset_y

func levantarse():
    esta_agachado = false
    $AnimatedSprite2D.animation = "correr"
    $AnimatedSprite2D.play()
    
    var collision = $CollisionShape2D
    collision.shape.size = collision_shape_original_size
    collision.position = collision_shape_original_position

func recibir_dano(causa: String = ""):
    if not esta_vivo or invencible:
        return

    if GameManager and "vidas" in GameManager:
        if GameManager.descontar_vida():
            iniciar_invencibilidad()
        else:
            morir(causa)
    else:
        morir(causa)

func iniciar_invencibilidad():
    invencible = true
    
    var tween = create_tween()
    tween.set_loops(6)
    tween.tween_property($AnimatedSprite2D, "modulate:a", 0.5, 0.1)
    tween.tween_property($AnimatedSprite2D, "modulate:a", 1.0, 0.1)
    
    await tween.finished
    invencible = false

func morir(causa: String = ""):
    if not esta_vivo:
        return

    if GameManager and GameManager.en_transicion:
        print("⚠️ Muerte durante transición - ignorando")
        return

    # Guardar la causa de muerte en GameManager
    if GameManager:
        GameManager.causa_muerte = causa
        print("💀 Muerte causada por: ", causa)

    esta_vivo = false
    set_physics_process(false)

    # SECUENCIA CINEMATOGRÁFICA DE MUERTE
    await secuencia_muerte_cinematica()

func secuencia_muerte_cinematica():
    # 1. Slow motion inicial
    Engine.time_scale = 0.3
    
    # 2. Animación de impacto del gaucho
    var tween_impacto = create_tween()
    tween_impacto.tween_property($AnimatedSprite2D, "rotation", -PI/4, 0.3)
    tween_impacto.parallel().tween_property($AnimatedSprite2D, "modulate", Color(1, 0.3, 0.3), 0.3)
    animacion.stop()
    
    # 3. Reproducir sonido de muerte
    $SonidoMorir.play()
    
    await get_tree().create_timer(0.4).timeout  # En tiempo real: 1.2s
    
    # 4. Pausar todo excepto el proceso de muerte
    get_tree().paused = true
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    # 5. Crear efecto de desvanecimiento a negro
    # Usar CanvasLayer para que cubra toda la pantalla
    var canvas_layer = CanvasLayer.new()
    canvas_layer.layer = 100  # Por encima de todo
    canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS  # Funcionar incluso pausado
    get_tree().root.add_child(canvas_layer)
    
    var fade_overlay = ColorRect.new()
    fade_overlay.color = Color.BLACK
    fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    fade_overlay.modulate.a = 0.0
    canvas_layer.add_child(fade_overlay)
    
    var tween_fade = create_tween()
    tween_fade.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)  # Funcionar incluso pausado
    tween_fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween_fade.tween_property(fade_overlay, "modulate:a", 1.0, 1.0)
    await tween_fade.finished
    
    # 6. Restaurar velocidad normal
    Engine.time_scale = 1.0
    get_tree().paused = false
    
    # 7. Pequeña pausa en negro
    await get_tree().create_timer(0.5).timeout
    
    # 8. Borrar el CanvasLayer
    canvas_layer.queue_free()
    
    # 9. Ir a pantalla de Game Over
    get_tree().change_scene_to_file("res://scenes/game_over/game_over.tscn")
