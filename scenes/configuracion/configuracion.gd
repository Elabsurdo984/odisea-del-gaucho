# configuracion.gd
# Pantalla de configuración del juego
extends Control

#region REFERENCIAS
@export var slider_musica: HSlider
@export var label_musica: Label
@export var slider_efectos: HSlider
@export var label_efectos: Label
@export var check_pantalla_completa: CheckBox
@export var btn_volver: Button
@export var btn_restablecer: Button
#endregion

#region CONFIGURACIÓN
const CONFIG_FILE: String = "user://settings.cfg"
var config = ConfigFile.new()

# Valores por defecto
const DEFAULT_VOLUMEN_MUSICA = 80
const DEFAULT_VOLUMEN_EFECTOS = 80
const DEFAULT_PANTALLA_COMPLETA = false
#endregion

#region INICIALIZACIÓN
func _ready():
    # Cargar configuración guardada
    cargar_configuracion()

    # Conectar señales
    if slider_musica:
        slider_musica.value_changed.connect(_on_musica_changed)
    if slider_efectos:
        slider_efectos.value_changed.connect(_on_efectos_changed)
    if check_pantalla_completa:
        check_pantalla_completa.toggled.connect(_on_pantalla_completa_toggled)
    if btn_volver:
        btn_volver.pressed.connect(_on_volver_pressed)
    if btn_restablecer:
        btn_restablecer.pressed.connect(_on_restablecer_pressed)

    # Actualizar labels iniciales
    actualizar_labels()

    print("⚙️ Pantalla de Configuración cargada")
#endregion

#region MÉTODOS DE CONFIGURACIÓN
func cargar_configuracion():
    var err = config.load(CONFIG_FILE)

    if err == OK:
        # Cargar valores guardados
        if slider_musica:
            slider_musica.value = config.get_value("audio", "volumen_musica", DEFAULT_VOLUMEN_MUSICA)
        if slider_efectos:
            slider_efectos.value = config.get_value("audio", "volumen_efectos", DEFAULT_VOLUMEN_EFECTOS)
        if check_pantalla_completa:
            check_pantalla_completa.button_pressed = config.get_value("video", "pantalla_completa", DEFAULT_PANTALLA_COMPLETA)

        print("✅ Configuración cargada")
    else:
        # Usar valores por defecto
        print("📝 Usando configuración por defecto")
        aplicar_valores_defecto()

func guardar_configuracion():
    config.set_value("audio", "volumen_musica", slider_musica.value if slider_musica else DEFAULT_VOLUMEN_MUSICA)
    config.set_value("audio", "volumen_efectos", slider_efectos.value if slider_efectos else DEFAULT_VOLUMEN_EFECTOS)
    config.set_value("video", "pantalla_completa", check_pantalla_completa.button_pressed if check_pantalla_completa else DEFAULT_PANTALLA_COMPLETA)

    var err = config.save(CONFIG_FILE)
    if err == OK:
        print("💾 Configuración guardada")
    else:
        push_error("❌ Error guardando configuración")

func aplicar_valores_defecto():
    if slider_musica:
        slider_musica.value = DEFAULT_VOLUMEN_MUSICA
    if slider_efectos:
        slider_efectos.value = DEFAULT_VOLUMEN_EFECTOS
    if check_pantalla_completa:
        check_pantalla_completa.button_pressed = DEFAULT_PANTALLA_COMPLETA

func actualizar_labels():
    if label_musica and slider_musica:
        label_musica.text = str(int(slider_musica.value)) + "%"
    if label_efectos and slider_efectos:
        label_efectos.text = str(int(slider_efectos.value)) + "%"
#endregion

#region CALLBACKS
func _on_musica_changed(value: float):
    if label_musica:
        label_musica.text = str(int(value)) + "%"

    # Aplicar volumen al bus de audio
    var db = linear_to_db(value / 100.0)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

    guardar_configuracion()

func _on_efectos_changed(value: float):
    if label_efectos:
        label_efectos.text = str(int(value)) + "%"

    # TODO: Aplicar volumen al bus de efectos cuando exista
    # var db = linear_to_db(value / 100.0)
    # AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)

    guardar_configuracion()

func _on_pantalla_completa_toggled(toggled_on: bool):
    if toggled_on:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

    guardar_configuracion()

func _on_restablecer_pressed():
    print("🔄 Restableciendo valores por defecto...")
    aplicar_valores_defecto()
    actualizar_labels()

    # Aplicar cambios
    _on_musica_changed(DEFAULT_VOLUMEN_MUSICA)
    _on_pantalla_completa_toggled(DEFAULT_PANTALLA_COMPLETA)

    guardar_configuracion()

func _on_volver_pressed():
    print("🏠 Volviendo al menú principal...")
    get_tree().change_scene_to_file("res://scenes/menu_principal/menu_principal.tscn")
#endregion
