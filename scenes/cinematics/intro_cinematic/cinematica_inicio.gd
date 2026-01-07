# cinematica_inicio.gd
extends Control

#region REFERENCIAS
@export var muerte_sprite: Sprite2D
@export var gaucho_sprite: Sprite2D
@export var dialogue_ui_scene: CanvasLayer

@export var dialogue_manager: Node  # Referencia al DialogueManager dentro de la escena
#endregion

#region CONFIGURACIÓN
@export_file("*.csv") var dialogue_file: String = "res://data/dialogues/cinematica_inicio.csv"
#endregion

#region DIÁLOGOS
var dialogos: Array = []
#endregion

#region INICIALIZACIÓN
func _ready():
    # Asegurar que el tiempo esté normal
    Engine.time_scale = 1.0
    get_tree().paused = false

    # Obtener referencia al DialogueManager desde la escena instanciada
    if dialogue_ui_scene:
        dialogue_manager = dialogue_ui_scene.get_dialogue_manager()
    else:
        push_error("❌ Cinemática: No se encontró dialogue_ui_scene")
        return

    # Cargar diálogos desde CSV
    print("📖 Cargando diálogos desde: ", dialogue_file)
    dialogos = DialogueLoader.load_from_csv(dialogue_file)

    # Validar que se cargaron correctamente
    if dialogos.is_empty():
        push_error("❌ Cinemática: No se pudieron cargar los diálogos desde ", dialogue_file)
        return

    print("✅ Diálogos cargados: ", dialogos.size(), " líneas")

    # Ocultar UI de diálogo al inicio
    if dialogue_ui_scene:
        dialogue_ui_scene.ocultar()

    # Inicialmente la muerte está invisible
    if muerte_sprite:
        muerte_sprite.modulate.a = 0.0

    # Conectar señales del DialogueManager
    if dialogue_manager:
        dialogue_manager.dialogue_line_started.connect(_on_dialogue_line_started)
        dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)

    # Empezar la secuencia
    iniciar_cinematica()
#endregion

#region SECUENCIA DE CINEMÁTICA
func iniciar_cinematica():
    # Esperar un momento antes de empezar
    await get_tree().create_timer(1.0).timeout

    # Hacer aparecer a la Muerte con efecto fade
    await aparecer_muerte()

    # Esperar un momento
    await get_tree().create_timer(0.5).timeout

    # Mostrar UI de diálogo
    if dialogue_ui_scene:
        dialogue_ui_scene.mostrar()

    # Iniciar sistema de diálogo
    if dialogue_manager:
        dialogue_manager.setup(dialogos)
        dialogue_manager.start()

func aparecer_muerte():
    # Fade in de la Muerte
    if muerte_sprite and is_instance_valid(muerte_sprite):
        var tween = create_tween()
        tween.tween_property(muerte_sprite, "modulate:a", 1.0, 1.5)
        await tween.finished
    else:
        # Si no hay sprite, esperar el tiempo equivalente
        await get_tree().create_timer(1.5).timeout
#endregion

#region CALLBACKS DEL DIALOGUE MANAGER
func _on_dialogue_line_started(character_name: String, text: String):
    print("💬 ", character_name, ": ", text)

func _on_dialogue_ended():
    print("🎬 Cinemática terminada - Iniciando gameplay...")

    # Ocultar UI de diálogo
    if dialogue_ui_scene and is_instance_valid(dialogue_ui_scene):
        dialogue_ui_scene.ocultar()

    # Esperar un momento antes de transicionar
    await get_tree().create_timer(0.5).timeout

    # Transición al gameplay
    get_tree().change_scene_to_file("res://scenes/nivel_pampa/nivel_pampa.tscn")
#endregion
