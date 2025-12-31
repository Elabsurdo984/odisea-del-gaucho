extends Node

signal mates_cambiados(nuevos_mates)
signal objetivo_alcanzado  # Nueva señal para cuando llegues a 100
signal iniciar_transicion_rancho  # Señal para iniciar mini-cinemática

var mates_totales := 0
var objetivo := 1  # Mates necesarios para ganar
var objetivo_alcanzado_flag := false  # Para que solo se active una vez
var en_transicion := false  # Flag para saber si está en transición

func agregar_mates(cantidad: int):
	mates_totales += cantidad
	mates_cambiados.emit(mates_totales)
	print("Mates recolectados: ", mates_totales)

	# Verificar si llegaste al objetivo
	if mates_totales >= objetivo and not objetivo_alcanzado_flag:
		objetivo_alcanzado_flag = true
		en_transicion = true
		objetivo_alcanzado.emit()

		# Iniciar secuencia de transición
		iniciar_secuencia_transicion()

func iniciar_secuencia_transicion():
	print("🎬 GameManager: Iniciando transición al rancho...")

	# 1. Detener spawning
	iniciar_transicion_rancho.emit()

	# 2. Slow motion dramático
	await get_tree().create_timer(0.3).timeout
	Engine.time_scale = 0.3  # Slow motion

	# 3. Esperar un momento en slow motion
	await get_tree().create_timer(0.5).timeout  # En tiempo real sería 1.5s

	# 4. Restaurar velocidad
	Engine.time_scale = 1.0

	# 5. Cambiar a escena de transición
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://scenes/transicion_rancho/transicion_rancho.tscn")

func reiniciar_mates():
	mates_totales = 0
	objetivo_alcanzado_flag = false
	mates_cambiados.emit(mates_totales)

func obtener_mates() -> int:
	return mates_totales
