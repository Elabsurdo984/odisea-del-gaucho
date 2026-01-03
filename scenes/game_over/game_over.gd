extends Control

@export var detalle_label: Label
@export var hora_label: Label
@export var timer_reinicio: Timer
@export var color_rect: ColorRect
@export var vbox_container: VBoxContainer

func _ready():
    # Hacer invisible todo al inicio
    modulate.a = 0.0
    
    # Configurar hora y texto
    configurar_texto()
    actualizar_hora()
    
    # Efecto de entrada dramático
    await entrada_dramatica()
    
    # Iniciar timer para volver al menú
    if timer_reinicio:
        timer_reinicio.start()

func entrada_dramatica():
    # 1. Flash blanco inicial
    var flash = ColorRect.new()
    flash.color = Color.WHITE
    flash.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(flash)
    flash.modulate.a = 0.0
    
    var tween_flash = create_tween()
    tween_flash.tween_property(flash, "modulate:a", 1.0, 0.1)
    tween_flash.tween_property(flash, "modulate:a", 0.0, 0.2)
    await tween_flash.finished
    flash.queue_free()
    
    # 2. Fade in del fondo rojo
    modulate.a = 1.0
    if color_rect:
        color_rect.modulate.a = 0.0
        var tween_bg = create_tween()
        tween_bg.tween_property(color_rect, "modulate:a", 1.0, 0.4)
    
    await get_tree().create_timer(0.3).timeout
    
    # 3. Sacudida de cámara (simular con el contenedor)
    if vbox_container:
        var original_pos = vbox_container.position
        var shake_tween = create_tween()
        shake_tween.set_parallel(true)
        
        for i in range(5):
            var offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))
            shake_tween.tween_property(vbox_container, "position", original_pos + offset, 0.05)
            shake_tween.tween_interval(0.05)
        
        shake_tween.tween_property(vbox_container, "position", original_pos, 0.1)
        await shake_tween.finished
    
    # 4. Sonido de alerta (opcional - si tienes el audio)
    # $SonidoAlerta.play()
    
    await get_tree().create_timer(0.2).timeout

func actualizar_hora():
    if not hora_label:
        return
    
    # Obtener la hora actual del sistema
    var tiempo = Time.get_datetime_dict_from_system()
    var hora = tiempo.hour
    var minutos = tiempo.minute
    
    # Formatear con ceros a la izquierda si es necesario
    var hora_formateada = "%02d:%02d" % [hora, minutos]
    
    hora_label.text = "  " + hora_formateada + "  "

func configurar_texto():
    if not GameManager:
        return
    
    var causa = GameManager.causa_muerte
    var texto_placa = "GAUCHO FALLECE EN LA PAMPA" # Default
    
    match causa:
        "cactus":
            texto_placa = "GAUCHO PINCHADO:\nNO VIO EL CACTUS"
        "piedra":
            texto_placa = "TROPEZÓN FATAL:\nLA PIEDRA FUE MÁS FUERTE"
        "arbusto":
            texto_placa = "CONFUSIÓN EN EL CAMPO:\nSE LLEVÓ PUESTO UN YUYO"
        "tero":
            texto_placa = "ATAQUE AÉREO:\nTERO DEFIENDE SU NIDO"
        _:
            if causa != "":
                texto_placa = causa.to_upper()
    
    if detalle_label:
        detalle_label.text = texto_placa

func _input(event):
    # Permitir saltar con cualquier tecla si ya pasó un tiempo mínimo
    if event.is_pressed() and timer_reinicio and timer_reinicio.time_left < 3.0:
        _on_timer_timeout()

func _on_timer_timeout():
    # Fade out dramático antes de volver al menú
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.5)
    await tween.finished
    
    # Volver al menú
    get_tree().change_scene_to_file("res://scenes/menu_principal/menu_principal.tscn")
