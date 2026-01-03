extends Node

signal mates_cambiados(nuevos_mates)
signal objetivo_alcanzado  # Nueva señal para cuando llegues a 100
signal iniciar_transicion_rancho  # Señal para iniciar mini-cinemática
signal velocidad_cambiada(nueva_velocidad)  # Señal para dificultad progresiva

var mates_totales := 0
var objetivo := 100 # Mates necesarios para ganar
var objetivo_alcanzado_flag := false  # Para que solo se active una vez
var en_transicion := false  # Flag para saber si está en transición

# Sistema de dificultad progresiva
const VELOCIDAD_BASE := 200.0
const INCREMENTO_VELOCIDAD := 10.0  # Aumenta 20 píxeles/seg cada 10 mates
const MATES_POR_NIVEL := 10
var velocidad_actual := VELOCIDAD_BASE
var ultimo_nivel_velocidad := 0  # Último nivel de dificultad alcanzado

# Configuración
const CONFIG_FILE = "user://settings.cfg"

func _ready():
    cargar_y_aplicar_configuracion()

func cargar_y_aplicar_configuracion():
    var config = ConfigFile.new()
    var err = config.load(CONFIG_FILE)

    if err == OK:
        # Aplicar volumen de música
        var volumen_musica = config.get_value("audio", "volumen_musica", 80)
        var db_musica = linear_to_db(volumen_musica / 100.0)
        AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db_musica)

        # Aplicar pantalla completa
        var pantalla_completa = config.get_value("video", "pantalla_completa", false)
        if pantalla_completa:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        else:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

        print("✅ Configuración aplicada desde GameManager")
    else:
        print("📝 No se encontró configuración guardada, usando valores por defecto")

func agregar_mates(cantidad: int):
    mates_totales += cantidad
    mates_cambiados.emit(mates_totales)
    print("Mates recolectados: ", mates_totales)

    # Verificar si se debe aumentar la velocidad (cada 10 mates)
    var nivel_actual = mates_totales / MATES_POR_NIVEL
    if nivel_actual > ultimo_nivel_velocidad:
        ultimo_nivel_velocidad = nivel_actual
        aumentar_velocidad()

    # Verificar si llegaste al objetivo
    if mates_totales >= objetivo and not objetivo_alcanzado_flag:
        objetivo_alcanzado_flag = true
        en_transicion = true
        objetivo_alcanzado.emit()

        # Iniciar secuencia de transición
        iniciar_secuencia_transicion()

func iniciar_secuencia_transicion():
    print("🎬 GameManager: Iniciando transición al rancho...")

    # 1. Detener spawning
    iniciar_transicion_rancho.emit()

    # 2. Slow motion dramático
    await get_tree().create_timer(0.3).timeout
    Engine.time_scale = 0.3  # Slow motion

    # 3. Esperar un momento en slow motion
    await get_tree().create_timer(0.5).timeout  # En tiempo real sería 1.5s

    # 4. Restaurar velocidad ANTES de cambiar escena
    Engine.time_scale = 1.0
    get_tree().paused = false  # Asegurar que no esté pausado

    # 5. Cambiar a escena de transición
    await get_tree().create_timer(0.2).timeout

    # Resetear flag antes de cambiar escena
    en_transicion = false

    get_tree().change_scene_to_file("res://scenes/transicion_rancho/transicion_rancho.tscn")

func aumentar_velocidad():
    velocidad_actual = VELOCIDAD_BASE + (ultimo_nivel_velocidad * INCREMENTO_VELOCIDAD)
    velocidad_cambiada.emit(velocidad_actual)
    print("🚀 Velocidad aumentada a: ", velocidad_actual, " (Nivel ", ultimo_nivel_velocidad, ")")

func reiniciar_mates():
    mates_totales = 0
    objetivo_alcanzado_flag = false
    ultimo_nivel_velocidad = 0
    velocidad_actual = VELOCIDAD_BASE
    mates_cambiados.emit(mates_totales)
    velocidad_cambiada.emit(velocidad_actual)

func obtener_mates() -> int:
    return mates_totales

func obtener_velocidad_actual() -> float:
    return velocidad_actual
