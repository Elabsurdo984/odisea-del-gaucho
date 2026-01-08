extends Node
class_name TrucoState

# Estado de la partida
var puntos_jugador: int = 0
var puntos_muerte: int = 0

# Estado de la mano
var cartas_jugador: Array = []
var cartas_muerte: Array = []
var cartas_originales_jugador: Array = []  # Copia de las cartas iniciales para calcular envido
var cartas_originales_muerte: Array = []   # Copia de las cartas iniciales para calcular envido
var ronda_actual: int = 1
var carta_jugada_jugador = null # Variant: Carta (Node) or Dictionary
var carta_jugada_muerte = null  # Variant: Carta (Node) or Dictionary

# Resultados de rondas (0=sin jugar, 1=jugador, 2=muerte, 3=empate)
var resultados_rondas: Array[int] = [0, 0, 0]

# Estado de apuestas (managed by TrucoBetting separately, but tracked for context if needed)
# Por ahora delegamos apuestas a TrucoBetting y aquí solo guardamos puntos totales
var envido_cantado: bool = false

func agregar_puntos_jugador(puntos: int) -> void:
	puntos_jugador += puntos

func agregar_puntos_muerte(puntos: int) -> void:
	puntos_muerte += puntos

func registrar_resultado_ronda(ganador: int) -> void:
	if ronda_actual <= 3:
		resultados_rondas[ronda_actual - 1] = ganador
		ronda_actual += 1

func resetear_mano() -> void:
	cartas_jugador.clear()
	cartas_muerte.clear()
	cartas_originales_jugador.clear()
	cartas_originales_muerte.clear()
	ronda_actual = 1
	resultados_rondas = [0, 0, 0]
	carta_jugada_jugador = null
	carta_jugada_muerte = null
	envido_cantado = false

func resetear_partida() -> void:
	puntos_jugador = 0
	puntos_muerte = 0
	resetear_mano()
