# felicitaciones.gd
extends Control

@export var mates_label: Label
@export var boton_continuar: Button
@export var boton_menu_principal: Button

func _ready():
    # Mostrar cuántos mates recolectaste
    var mates = GameManager.obtener_mates()
    $VBoxContainer/MatesLabel.text = "¡Recolectaste " + str(mates) + " mates!"

    # Conectar botones
    $VBoxContainer/BotonContinuar.pressed.connect(_on_continuar_pressed)
    $VBoxContainer/BotonMenuPrincipal.pressed.connect(_on_menu_pressed)

func _on_continuar_pressed():
    # Aquí irá la transición al juego de truco
    # Por ahora, muestra un mensaje
    print("Próximamente: ¡Juego de truco con la muerte!")
    # Temporal: volver al juego
    get_tree().change_scene_to_file("res://scenes/nivel_pampa/nivel_pampa.tscn")

func _on_menu_pressed():
    # Reiniciar el contador de mates
    GameManager.reiniciar_mates()
    # Volver al menú principal o al nivel
    get_tree().change_scene_to_file("res://scenes/nivel_pampa/nivel_pampa.tscn")
