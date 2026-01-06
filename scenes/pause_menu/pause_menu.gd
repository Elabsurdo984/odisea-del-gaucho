# pause_menu.gd
# Menú de pausa reutilizable para todas las escenas del juego
extends CanvasLayer

#region REFERENCIAS
@export var panel_pausa: Panel
@export var btn_reanudar: Button
@export var btn_reiniciar: Button
@export var btn_menu_principal: Button
#endregion

#region CONFIGURACIÓN
@export var pausar_con_esc := true

var esta_pausado := false
#endregion

#region INICIALIZACIÓN
func _ready():
    # Ocultar menú al inicio
    visible = false

    # Conectar botones
    if btn_reanudar:
        btn_reanudar.pressed.connect(_on_reanudar_pressed)
    if btn_reiniciar:
        btn_reiniciar.pressed.connect(_on_reiniciar_pressed)
    if btn_menu_principal:
        btn_menu_principal.pressed.connect(_on_menu_principal_pressed)

    # Asegurar que el layer está arriba de todo
    layer = 100

    print("⏸️ Menú de pausa listo")

func _input(event):
    # Detectar ESC para pausar/despausar
    if pausar_con_esc and event.is_action_pressed("ui_cancel"):
        if esta_pausado:
            reanudar()
        else:
            pausar()
        # Consumir el evento para que no se propague
        get_viewport().set_input_as_handled()
#endregion

#region MÉTODOS PÚBLICOS
func pausar():
    if esta_pausado:
        return

    esta_pausado = true
    visible = true
    get_tree().paused = true

    print("⏸️ Juego pausado")

func reanudar():
    if not esta_pausado:
        return

    esta_pausado = false
    visible = false
    get_tree().paused = false

    print("▶️ Juego reanudado")

func esta_en_pausa() -> bool:
    return esta_pausado
#endregion

#region CALLBACKS
func _on_reanudar_pressed():
    print("▶️ Reanudando...")
    reanudar()

func _on_reiniciar_pressed():
    print("🔄 Reiniciando escena...")

    # Despausar antes de recargar
    get_tree().paused = false
    esta_pausado = false

    # Recargar escena actual
    get_tree().reload_current_scene()

func _on_menu_principal_pressed():
    print("🏠 Volviendo al menú principal...")

    # Despausar antes de cambiar de escena
    get_tree().paused = false
    esta_pausado = false

    # Resetear velocidad y estado del juego si existe
    if GameManager:
        GameManager.reiniciar_mates()

    # Volver al menú principal
    get_tree().change_scene_to_file("res://scenes/menu_principal/menu_principal.tscn")
#endregion
