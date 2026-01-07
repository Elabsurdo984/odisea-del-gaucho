# scene_manager.gd
# Gestión de transiciones entre escenas con efectos
extends Node

# ============================================================
# SIGNALS
# ============================================================
signal transicion_iniciada()
signal transicion_completada()
signal iniciar_transicion_rancho  # Señal para detener spawners

# ============================================================
# VARIABLES
# ============================================================
var en_transicion: bool = false

# ============================================================
# PUBLIC METHODS
# ============================================================

## Cambia a una escena con efecto de fade
func cambiar_escena_con_fade(ruta: String, _duracion_fade: float = 1.0) -> void:
	en_transicion = true
	transicion_iniciada.emit()

	# TODO: Implementar fade out/in con ColorRect
	# Por ahora, cambio directo
	await get_tree().create_timer(0.1).timeout

	get_tree().change_scene_to_file(ruta)

	en_transicion = false
	transicion_completada.emit()

## Cambia a una escena directamente sin efectos
func cambiar_escena(ruta: String) -> void:
	en_transicion = true
	transicion_iniciada.emit()

	get_tree().change_scene_to_file(ruta)

	en_transicion = false
	transicion_completada.emit()

## Aplica efecto de slow motion durante un tiempo
func slow_motion(escala: float, duracion: float) -> void:
	Engine.time_scale = escala
	await get_tree().create_timer(duracion).timeout
	Engine.time_scale = 1.0

## Inicia la secuencia de transición al rancho (cuando se alcanzan 100 mates)
func iniciar_secuencia_transicion_rancho() -> void:
	print("🎬 SceneManager: Iniciando transición al rancho...")

	en_transicion = true

	# 1. Detener spawning
	iniciar_transicion_rancho.emit()

	# 2. Slow motion dramático
	await get_tree().create_timer(0.3).timeout
	Engine.time_scale = 0.3

	# 3. Esperar un momento en slow motion
	await get_tree().create_timer(0.5).timeout  # En tiempo real sería 1.5s

	# 4. Restaurar velocidad ANTES de cambiar escena
	Engine.time_scale = 1.0
	get_tree().paused = false  # Asegurar que no esté pausado

	# 5. Cambiar a escena de transición
	await get_tree().create_timer(0.2).timeout

	# Resetear flag antes de cambiar escena
	en_transicion = false

	get_tree().change_scene_to_file("res://scenes/cinematics/rancho_transition/transicion_rancho.tscn")

	transicion_completada.emit()

## Verifica si hay una transición en curso
func esta_en_transicion() -> bool:
	return en_transicion

## Pausa el juego
func pausar_juego() -> void:
	get_tree().paused = true

## Reanuda el juego
func reanudar_juego() -> void:
	get_tree().paused = false
