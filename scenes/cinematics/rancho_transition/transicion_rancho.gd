# transicion_rancho.gd
# Mini-cinemática cuando el jugador llega a 100 mates
extends Control

#region REFERENCIAS
@export var muerte_sprite: Sprite2D
@export var gaucho_sprite: Sprite2D
@export var rancho_sprite: Sprite2D
@export var dialogue_ui_scene: CanvasLayer
@export var dialogue_manager: Node
#endregion


#region CONFIGURACION
@export_file("*.csv") var dialogue_file: String = "res://data/dialogues/transicion_rancho.csv"
#endregion

#region DIALOGOS
var dialogos: Array = []
#endregion

#region INICIALIZACION
func _ready():
    # Asegurar que el tiempo esté normal
    Engine.time_scale = 1.0
    get_tree().paused = false

    # Obtener referencia al DialogueManager desde la escena instanciada
    if dialogue_ui_scene:
        dialogue_manager = dialogue_ui_scene.get_dialogue_manager()
    else:
        push_error("❌ Transición: No se encontró dialogue_ui_scene")
        return

    # Cargar diálogos desde CSV
    print("📖 Cargando diálogos desde: ", dialogue_file)
    dialogos = DialogueLoader.load_from_csv(dialogue_file)

    # Validar que se cargaron correctamente
    if dialogos.is_empty():
        push_error("❌ Transición: No se pudieron cargar los diálogos desde ", dialogue_file)
        return

    print("✅ Diálogos cargados: ", dialogos.size(), " líneas")

    # Configuración inicial
    if dialogue_ui_scene:
        dialogue_ui_scene.ocultar()

    # Rancho empieza invisible
    if rancho_sprite:
        rancho_sprite.modulate.a = 0.0

    # Muerte empieza invisible
    if muerte_sprite:
        muerte_sprite.modulate.a = 0.0

    # Conectar señales del DialogueManager
    if dialogue_manager:
        dialogue_manager.dialogue_line_started.connect(_on_dialogue_line_started)
        dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)

    # Empezar la secuencia
    iniciar_transicion()
#endregion

#region SECUENCIA DE TRANSICION
func iniciar_transicion():
    # 1. Esperar un momento
    await get_tree().create_timer(0.5).timeout

    # 2. Hacer aparecer el rancho al fondo (fade in lento)
    if rancho_sprite:
        var tween1 = create_tween()
        tween1.tween_property(rancho_sprite, "modulate:a", 1.0, 2.0)

    # 3. Esperar un poco mientras aparece el rancho
    await get_tree().create_timer(1.0).timeout

    # 4. Mostrar UI de diálogo
    if dialogue_ui_scene:
        dialogue_ui_scene.mostrar()

    # 5. Iniciar primer diálogo del gaucho
    if dialogue_manager:
        dialogue_manager.setup(dialogos)
        dialogue_manager.start()

    # 6. Después de la primera línea, hacer aparecer la muerte
    await get_tree().create_timer(2.0).timeout
    aparecer_muerte()

func aparecer_muerte():
    # Fade in de la Muerte
    if muerte_sprite and is_instance_valid(muerte_sprite):
        var tween = create_tween()
        tween.tween_property(muerte_sprite, "modulate:a", 1.0, 1.5)
#endregion

#region CALLBACKS
func _on_dialogue_line_started(character_name: String, text: String):
    print("💬 ", character_name, ": ", text)

func _on_dialogue_ended():
    print("🎴 Transición terminada - Yendo a la escena del truco...")

    # Fade out
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 1.0)
    await tween.finished

    # Ir a la escena del truco
    await get_tree().create_timer(0.5).timeout
    get_tree().change_scene_to_file("res://scenes/truco/truco.tscn")
#endregion
