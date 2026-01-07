# difficulty_manager.gd
# Sistema de dificultad progresiva del juego
extends Node

# ============================================================
# SIGNALS
# ============================================================
signal velocidad_cambiada(nueva_velocidad: float)

# ============================================================
# CONSTANTES
# ============================================================
const VELOCIDAD_BASE: float = 200.0
const INCREMENTO_VELOCIDAD: float = 10.0  # Aumenta por nivel
const MATES_POR_NIVEL: int = 10  # Mates necesarios para subir de nivel

# ============================================================
# VARIABLES
# ============================================================
var velocidad_actual: float = VELOCIDAD_BASE
var nivel_actual: int = 0  # Nivel de dificultad alcanzado

# ============================================================
# PUBLIC METHODS
# ============================================================

## Verifica si hay que aumentar la velocidad basado en los mates recolectados
func verificar_aumento_velocidad(mates_totales: int) -> void:
	@warning_ignore("integer_division")
	var nuevo_nivel: int = mates_totales / MATES_POR_NIVEL

	if nuevo_nivel > nivel_actual:
		nivel_actual = nuevo_nivel
		aumentar_velocidad()

## Aumenta la velocidad del juego según el nivel actual
func aumentar_velocidad() -> void:
	velocidad_actual = VELOCIDAD_BASE + (nivel_actual * INCREMENTO_VELOCIDAD)
	velocidad_cambiada.emit(velocidad_actual)
	print("🚀 Velocidad aumentada a: ", velocidad_actual, " (Nivel ", nivel_actual, ")")

## Reinicia el sistema de dificultad a valores iniciales
func reiniciar() -> void:
	nivel_actual = 0
	velocidad_actual = VELOCIDAD_BASE
	velocidad_cambiada.emit(velocidad_actual)
	print("🔄 Dificultad reiniciada")

## Obtiene la velocidad actual del juego
func obtener_velocidad_actual() -> float:
	return velocidad_actual

## Obtiene el nivel de dificultad actual
func obtener_nivel_actual() -> int:
	return nivel_actual
