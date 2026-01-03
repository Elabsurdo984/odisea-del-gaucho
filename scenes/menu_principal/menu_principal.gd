# menu_principal.gd
# Menú principal del juego
extends Control

#region REFERENCIAS
@onready var btn_jugar = $BotonesPanel/VBoxContainer/BtnJugar
@onready var btn_como_jugar = $BotonesPanel/VBoxContainer/BtnComoJugar
@onready var btn_configuracion = $BotonesPanel/VBoxContainer/BtnConfiguracion
@onready var btn_salir = $BotonesPanel/VBoxContainer/BtnSalir
#endregion

#region INICIALIZACIÓN
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
#endregion

#region CALLBACKS
func _on_jugar_pressed():
	print("▶️ Iniciando juego...")
	# Ir a la cinemática de inicio
	get_tree().change_scene_to_file("res://scenes/cinematica/cinematica_inicio.tscn")

func _on_como_jugar_pressed():
	print("📖 Mostrando instrucciones...")
	get_tree().change_scene_to_file("res://scenes/como_jugar/como_jugar.tscn")

func _on_configuracion_pressed():
	print("⚙️ Abriendo configuración...")
	get_tree().change_scene_to_file("res://scenes/configuracion/configuracion.tscn")

func _on_salir_pressed():
	print("👋 Saliendo del juego...")
	get_tree().quit()
#endregion

#region HELPER
func mostrar_mensaje(texto: String):
	# Por ahora solo imprime, luego se puede agregar un popup
	print("💬 ", texto)
#endregion
