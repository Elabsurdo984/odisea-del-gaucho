# menu_principal.gd
# Menú principal del juego
extends Control

#region REFERENCIAS
@export var btn_jugar: Button
@export var btn_como_jugar: Button
@export var btn_configuracion: Button
@export var btn_salir: Button
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

	print("🎮 Menú principal cargado (DEMO)")
#endregion

#region CALLBACKS
func _on_jugar_pressed():
	print("▶️ Iniciando Capítulo 1...")
	# Ir a la pantalla de transición del capítulo 1
	get_tree().change_scene_to_file("res://scenes/chapter_transition/chapter_transition.tscn")

func _on_como_jugar_pressed():
	print("📖 Mostrando instrucciones...")
	get_tree().change_scene_to_file("res://ui/screens/how_to_play/como_jugar.tscn")

func _on_configuracion_pressed():
	print("⚙️ Abriendo configuración...")
	get_tree().change_scene_to_file("res://ui/menus/config_menu/configuracion.tscn")

func _on_salir_pressed():
	print("👋 Saliendo del juego...")
	get_tree().quit()
#endregion

#region HELPER
func mostrar_mensaje(texto: String):
	# Por ahora solo imprime, luego se puede agregar un popup
	print("💬 ", texto)
#endregion
