# test_cinematics_runner.gd
# Escena de testing para ejecutar cinemáticas con el estado correcto pre-configurado
# Útil para desarrollo y testing de diálogos/transiciones

extends Control

#region CONFIGURACIÓN
@export_category("Setup Cinemática")
@export var configurar_gamemanager: bool = true
@export var mates_iniciales: int = 100
@export var velocidad_inicial: float = 200.0
#endregion

#region LIFECYCLE
func _ready():
	print("🧪 Test Cinematics Runner - Configurando estado...")

	if configurar_gamemanager and ScoreManager:
		# Configurar ScoreManager para cinemáticas de transición
		# Agregar mates para simular que llegaste a 100
		for i in range(mates_iniciales):
			ScoreManager.agregar_mates(1)
		print("   ✅ ScoreManager configurado: %d mates" % ScoreManager.obtener_mates())

	# Mostrar instrucciones
	mostrar_instrucciones()

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				cargar_cinematica("res://scenes/cinematics/intro_cinematic/cinematica_inicio.tscn")
			KEY_2:
				cargar_cinematica("res://scenes/cinematics/rancho_transition/transicion_rancho.tscn")
			KEY_3:
				cargar_cinematica("res://scenes/cinematics/jugador_victoria/jugador_victoria.tscn")
			KEY_4:
				cargar_cinematica("res://scenes/cinematics/muerte_victoria/muerte_victoria.tscn")
			KEY_5:
				cargar_cinematica("res://ui/screens/continuara/continuara.tscn")
			KEY_ESCAPE:
				get_tree().quit()
#endregion

#region ACCIONES
func cargar_cinematica(ruta: String):
	print("▶️ Cargando: %s" % ruta)
	get_tree().change_scene_to_file(ruta)

func mostrar_instrucciones():
	print("============================================================")
	print("🎬 TEST CINEMATICS RUNNER")
	print("============================================================")
	print("Presiona:")
	print("  [1] - Cinemática Intro")
	print("  [2] - Transición Rancho (requiere 100 mates)")
	print("  [3] - Victoria Jugador")
	print("  [4] - Victoria Muerte")
	print("  [5] - Pantalla Continuará")
	print("  [ESC] - Salir")
	print("============================================================")
#endregion
