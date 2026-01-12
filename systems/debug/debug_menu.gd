# debug_menu.gd
# Menú de desarrollo para testing rápido sin jugar todo el juego
# Acceso: Presionar F12 en cualquier momento

extends CanvasLayer

#region REFERENCIAS
@onready var panel: Panel = $Panel
@onready var container: VBoxContainer = $Panel/MarginContainer/VBoxContainer
#endregion

#region ESTADO
var is_visible: bool = false
var buttons: Array = []
#endregion

#region LIFECYCLE
func _ready():
	# Solo disponible en modo debug
	if not OS.is_debug_build():
		queue_free()
		return

	# CRÍTICO: Permitir que procese incluso cuando el juego está pausado
	process_mode = Node.PROCESS_MODE_ALWAYS

	hide_menu()
	crear_botones()

	print("🔧 Debug Menu cargado - Presiona F12 para abrir")

func _input(event):
	# Toggle con F12
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		toggle_menu()
#endregion

#region UI MANAGEMENT
func toggle_menu():
	is_visible = !is_visible

	if is_visible:
		show_menu()
	else:
		hide_menu()

func show_menu():
	panel.visible = true
	get_tree().paused = true

func hide_menu():
	panel.visible = false
	get_tree().paused = false

func crear_botones():
	# Título
	var titulo = Label.new()
	titulo.text = "🔧 DEBUG MENU - Testing Rápido"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 20)
	container.add_child(titulo)

	# Separador
	var separator1 = HSeparator.new()
	container.add_child(separator1)

	# Sección: Cinemáticas
	agregar_label("CINEMÁTICAS:", true)
	agregar_boton("▶ Cinemática Intro", "res://scenes/cinematics/intro_cinematic/cinematica_inicio.tscn")
	agregar_boton("▶ Transición Rancho", "res://scenes/cinematics/rancho_transition/transicion_rancho.tscn")
	agregar_boton("▶ Victoria Jugador", "res://scenes/cinematics/jugador_victoria/jugador_victoria.tscn")
	agregar_boton("▶ Victoria Muerte", "res://scenes/cinematics/muerte_victoria/muerte_victoria.tscn")

	# Separador
	var separator2 = HSeparator.new()
	container.add_child(separator2)

	# Sección: Gameplay
	agregar_label("GAMEPLAY:", true)
	agregar_boton("▶ Nivel Pampa (Endless Runner)", "res://scenes/levels/nivel_pampa.tscn")
	agregar_boton("▶ Truco Game", "res://scenes/truco_game/truco.tscn")

	# Separador
	var separator3 = HSeparator.new()
	container.add_child(separator3)

	# Sección: Pantallas
	agregar_label("PANTALLAS:", true)
	agregar_boton("▶ Continuará...", "res://ui/screens/continuara/continuara.tscn")
	agregar_boton("▶ Menú Principal", "res://ui/menus/main_menu/menu_principal.tscn")

	# Separador
	var separator4 = HSeparator.new()
	container.add_child(separator4)

	# Sección: Utilidades
	agregar_label("UTILIDADES:", true)
	agregar_boton_accion("⚡ Test TransitionManager", _test_transition_manager)
	agregar_boton_accion("📊 Ver Estado GameManager", _mostrar_estado_game_manager)
	agregar_boton_accion("🔄 Reset GameManager", _reset_game_manager)

	# Separador
	var separator5 = HSeparator.new()
	container.add_child(separator5)

	# Botón cerrar
	var btn_cerrar = Button.new()
	btn_cerrar.text = "❌ Cerrar (F12)"
	btn_cerrar.pressed.connect(toggle_menu)
	container.add_child(btn_cerrar)

func agregar_label(texto: String, bold: bool = false):
	var label = Label.new()
	label.text = texto
	if bold:
		label.add_theme_font_size_override("font_size", 16)
	container.add_child(label)

func agregar_boton(texto: String, escena: String):
	var btn = Button.new()
	btn.text = texto
	btn.pressed.connect(func(): cambiar_escena(escena))
	container.add_child(btn)
	buttons.append(btn)

func agregar_boton_accion(texto: String, callback: Callable):
	var btn = Button.new()
	btn.text = texto
	btn.pressed.connect(callback)
	container.add_child(btn)
	buttons.append(btn)
#endregion

#region ACCIONES
func cambiar_escena(ruta: String):
	hide_menu()
	get_tree().paused = false

	# Pequeño delay para asegurar que el pause se quite
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file(ruta)

func _test_transition_manager():
	print("🧪 Testing TransitionManager...")
	hide_menu()

	# Crear un nodo temporal para testear
	var test_node = Control.new()
	test_node.modulate.a = 1.0
	add_child(test_node)

	# Agregar label visual
	var label = Label.new()
	label.text = "Testing TransitionManager...\nFade Out en 2 segundos"
	label.position = Vector2(400, 300)
	label.add_theme_font_size_override("font_size", 24)
	test_node.add_child(label)

	# Test fade out
	await get_tree().create_timer(1.0).timeout
	await TransitionManager.quick_fade_to_scene(test_node, get_tree().current_scene.scene_file_path, 2.0)

func _mostrar_estado_game_manager():
	if GameManager:
		print("==================================================")
		print("📊 Estado de GameManager:")
		print("   Mates: %d / %d" % [GameManager.obtener_mates(), ScoreManager.OBJETIVO_MATES if ScoreManager else 100])
		print("   Velocidad: %.1f px/s" % GameManager.obtener_velocidad_actual())
		print("   En transición: %s" % GameManager.en_transicion())
		print("   Vidas: %d" % GameManager.vidas)
		print("==================================================")
	else:
		print("⚠️ GameManager no encontrado")

func _reset_game_manager():
	if GameManager:
		GameManager.reiniciar_juego()
		print("🔄 GameManager reseteado")
		_mostrar_estado_game_manager()
	else:
		print("⚠️ GameManager no encontrado")
#endregion
