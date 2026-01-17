# muerte_victoria.gd
# Cinemática cuando la Muerte gana el Truco
extends Control

#region REFERENCIAS
@export var muerte_sprite: Sprite2D
@export var muerte_guadaña_sprite: Sprite2D
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

	# La muerte con guadaña está oculta al inicio
	if muerte_guadaña_sprite:
		muerte_guadaña_sprite.modulate.a = 0.0
		muerte_guadaña_sprite.visible = false

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
	print("☠️ Muerte Victoria - Iniciando animación de la guadaña...")

	# Establecer causa de muerte para la pantalla de Game Over
	GameManager.causa_muerte = "truco"

	# Ocultar UI de diálogo
	if dialogue_ui_scene:
		dialogue_ui_scene.ocultar()

	# Esperar un momento
	await get_tree().create_timer(0.8).timeout

	# Cambiar al sprite de la guadaña con transición rápida
	await animar_cambio_a_guadaña()

	# Esperar para crear tensión
	await get_tree().create_timer(1.2).timeout

	# Animar el golpe de la guadaña
	await animar_golpe_guadaña()

	# Transición a Game Over usando TransitionManager
	await TransitionManager.transition_to_scene(
		self,
		"res://ui/screens/game_over/game_over.tscn",
		null,  # Ya ocultamos el dialogue_ui antes
		1.0,
		0.5
	)
#endregion

#region ANIMACIONES DE GUADAÑA
func animar_cambio_a_guadaña():
	"""Transición del sprite normal al sprite con guadaña levantada con zoom dramático"""
	if not muerte_sprite or not muerte_guadaña_sprite:
		return

	# Guardar escala y posición original
	var scale_original = muerte_guadaña_sprite.scale
	var _pos_original = muerte_guadaña_sprite.position

	# Fade out del sprite normal
	var tween_out = create_tween()
	tween_out.tween_property(muerte_sprite, "modulate:a", 0.0, 0.3)
	await tween_out.finished

	# Preparar sprite de guadaña (más pequeño al inicio para el zoom in)
	muerte_guadaña_sprite.visible = true
	muerte_guadaña_sprite.modulate.a = 0.0
	muerte_guadaña_sprite.scale = scale_original * 0.8  # Empieza más pequeño

	# Fade in del sprite con guadaña + zoom in simultáneo
	var tween_in = create_tween()
	tween_in.set_parallel(true)

	# Fade in
	tween_in.tween_property(muerte_guadaña_sprite, "modulate:a", 1.0, 0.4)

	# Zoom in dramático
	tween_in.tween_property(muerte_guadaña_sprite, "scale", scale_original * 2.5, 0.6)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	await tween_in.finished

func animar_golpe_guadaña():
	"""Anima el golpe de la guadaña hacia abajo con efectos dramáticos"""
	if not muerte_guadaña_sprite:
		return

	# Crear tween para el golpe
	var tween_golpe = create_tween()
	tween_golpe.set_parallel(true)

	# Aumentar ligeramente el scale durante el golpe para más impacto
	tween_golpe.tween_property(muerte_guadaña_sprite, "scale", muerte_guadaña_sprite.scale * 1.1, 0.1)\
		.set_ease(Tween.EASE_IN)

	# Flash de pantalla: blanco intenso que se convierte en negro
	var flash = ColorRect.new()
	flash.color = Color.WHITE
	flash.modulate.a = 0.0
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(flash)

	# Tween del flash: blanco intenso → mantener → cambiar a negro
	var tween_flash = create_tween()
	# Flash blanco inicial muy rápido
	tween_flash.tween_property(flash, "modulate:a", 1.0, 0.05)
	# Mantener el blanco un momento
	tween_flash.tween_interval(0.1)
	# Cambiar el color a negro mientras está visible
	tween_flash.tween_property(flash, "color", Color.BLACK, 0.15)
	muerte_guadaña_sprite.visible = false

	await tween_golpe.finished
	await tween_flash.finished

	# La pantalla ya está en negro, no limpiar el flash
	# para mantener la pantalla negra durante la transición
#endregion
