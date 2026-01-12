# muerte_victoria.gd
# Cinemática cuando la Muerte gana el Truco
extends Control

#region REFERENCIAS
@export var muerte_sprite: Sprite2D
@export var dialogue_ui_scene: CanvasLayer
var dialogue_manager: Node  # Se obtiene dinámicamente de dialogue_ui_scene
#endregion

#region CONFIGURACIÓN
@export_file("*.csv") var dialogue_file: String = "res://data/dialogues/muerte_gana_truco.csv"
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
		push_error("❌ Muerte Victoria: No se encontró dialogue_ui_scene")
		return

	# Cargar diálogos desde CSV
	print("📖 Cargando diálogos desde: ", dialogue_file)
	dialogos = DialogueLoader.load_from_csv(dialogue_file)

	# Validar que se cargaron correctamente
	if dialogos.is_empty():
		push_error("❌ Muerte Victoria: No se pudieron cargar los diálogos desde ", dialogue_file)
		return

	print("✅ Diálogos cargados: ", dialogos.size(), " líneas")

	# Ocultar UI de diálogo al inicio
	if dialogue_ui_scene:
		dialogue_ui_scene.ocultar()

	# La muerte está visible desde el inicio
	if muerte_sprite:
		muerte_sprite.modulate.a = 1.0

	# Conectar señales del DialogueManager
	if dialogue_manager:
		dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)

	# Empezar la secuencia
	iniciar_cinematica()
#endregion

#region SECUENCIA DE CINEMÁTICA
func iniciar_cinematica():
	# Esperar un momento antes de empezar
	await get_tree().create_timer(1.0).timeout

	# Mostrar UI de diálogo
	if dialogue_ui_scene:
		dialogue_ui_scene.mostrar()

	# Iniciar sistema de diálogo
	if dialogue_manager:
		dialogue_manager.setup(dialogos)
		dialogue_manager.start()
#endregion

#region CALLBACKS DEL DIALOGUE MANAGER
func _on_dialogue_ended():
	print("☠️ Muerte Victoria - Transicionando a Game Over...")

	# Establecer causa de muerte para la pantalla de Game Over
	GameManager.causa_muerte = "truco"

	# Transición a Game Over usando TransitionManager
	await TransitionManager.transition_to_scene(
		self,
		"res://ui/screens/game_over/game_over.tscn",
		dialogue_ui_scene,
		1.0,
		0.5
	)
#endregion
