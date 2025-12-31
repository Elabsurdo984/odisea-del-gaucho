# transicion_rancho.gd
# Mini-cinemática cuando el jugador llega a 100 mates
extends Control

# ==================== REFERENCIAS ====================
@onready var muerte_sprite = $Personajes/Muerte
@onready var gaucho_sprite = $Personajes/Gaucho
@onready var rancho_sprite = $Fondo/Rancho
@onready var dialogue_ui = $DialogoUI/PanelDialogo
@onready var dialogue_manager = $DialogueManager

# ==================== CONFIGURACIÓN ====================
@export_file("*.csv") var dialogue_file: String = "res://data/dialogues/transicion_rancho.csv"

# ==================== DIÁLOGOS ====================
var dialogos: Array = []

# ==================== INICIALIZACIÓN ====================
func _ready():
	# Cargar diálogos desde CSV
	dialogos = DialogueLoader.load_from_csv(dialogue_file)

	# Validar que se cargaron correctamente
	if dialogos.is_empty():
		push_error("❌ Transición: No se pudieron cargar los diálogos")
		return

	# Configuración inicial
	if dialogue_ui:
		dialogue_ui.visible = false

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

# ==================== SECUENCIA DE TRANSICIÓN ====================
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
	if dialogue_ui:
		dialogue_ui.visible = true

	# 5. Iniciar primer diálogo del gaucho
	if dialogue_manager:
		dialogue_manager.setup(dialogos)
		dialogue_manager.start()

	# 6. Después de la primera línea, hacer aparecer la muerte
	await get_tree().create_timer(2.0).timeout
	aparecer_muerte()

func aparecer_muerte():
	# Fade in de la Muerte
	if muerte_sprite:
		var tween = create_tween()
		tween.tween_property(muerte_sprite, "modulate:a", 1.0, 1.5)

# ==================== CALLBACKS ====================
func _on_dialogue_line_started(character_name: String, text: String):
	print("💬 ", character_name, ": ", text)

func _on_dialogue_ended():
	print("🎴 Transición terminada - Yendo a la escena del truco...")

	# Fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	await tween.finished

	# Ir a la escena del truco (o felicitaciones por ahora)
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/felicitaciones/felicitaciones.tscn")
