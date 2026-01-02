# menu_principal.gd
# Menú principal del juego
extends Control

# ==================== REFERENCIAS ====================
@onready var btn_jugar = $VBoxContainer/BtnJugar
@onready var btn_como_jugar = $VBoxContainer/BtnComoJugar
@onready var btn_configuracion = $VBoxContainer/BtnConfiguracion
@onready var btn_salir = $VBoxContainer/BtnSalir

# ==================== INICIALIZACIÓN ====================
func _ready():
	# Conectar botones
	if btn_jugar:
		btn_jugar.pressed.connect(_on_jugar_pressed)
	if btn_como_jugar:
		btn_como_jugar.pressed.connect(_on_como_jugar_pressed)
	if btn_configuracion:
		btn_configuracion.pressed.connect(_on_configuracion_pressed)
	if btn_salir:
		btn_salir.pressed.connect(_on_salir_pressed)

	print("🎮 Menú principal cargado")

# ==================== CALLBACKS ====================
func _on_jugar_pressed():
	print("▶️ Iniciando juego...")
	# Ir a la cinemática de inicio
	get_tree().change_scene_to_file("res://scenes/cinematica/cinematica_inicio.tscn")

func _on_como_jugar_pressed():
	print("📖 Mostrando instrucciones...")
	# TODO: Implementar escena de instrucciones
	mostrar_mensaje("¡Próximamente!")

func _on_configuracion_pressed():
	print("⚙️ Abriendo configuración...")
	# TODO: Implementar escena de configuración
	mostrar_mensaje("¡Próximamente!")

func _on_salir_pressed():
	print("👋 Saliendo del juego...")
	get_tree().quit()

# ==================== HELPER ====================
func mostrar_mensaje(texto: String):
	# Por ahora solo imprime, luego se puede agregar un popup
	print("💬 ", texto)
