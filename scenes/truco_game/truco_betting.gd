extends Node
class_name TrucoBetting

signal apuesta_cantada(quien: String, tipo: String)
signal apuesta_aceptada()
signal apuesta_rechazada()

enum NivelApuesta { NINGUNO, TRUCO, RETRUCO, VALE_CUATRO }

var nivel_actual: NivelApuesta = NivelApuesta.NINGUNO
var puntos_en_juego: int = 1
var ultimo_apostador: String = ""

var puntos_por_nivel = {
	NivelApuesta.TRUCO: 2,
	NivelApuesta.RETRUCO: 3,
	NivelApuesta.VALE_CUATRO: 4
}

func resetear_apuestas() -> void:
	nivel_actual = NivelApuesta.NINGUNO
	puntos_en_juego = 1
	ultimo_apostador = ""

func cantar_truco(quien: String) -> bool:
	if nivel_actual < NivelApuesta.TRUCO:
		_actualizar_apuesta(NivelApuesta.TRUCO, quien)
		apuesta_cantada.emit(quien, "truco")
		return true
	return false

func cantar_retruco(quien: String) -> bool:
	if nivel_actual == NivelApuesta.TRUCO and quien != ultimo_apostador:
		_actualizar_apuesta(NivelApuesta.RETRUCO, quien)
		apuesta_cantada.emit(quien, "retruco")
		return true
	return false

func cantar_vale_cuatro(quien: String) -> bool:
	if nivel_actual == NivelApuesta.RETRUCO and quien != ultimo_apostador:
		_actualizar_apuesta(NivelApuesta.VALE_CUATRO, quien)
		apuesta_cantada.emit(quien, "vale cuatro")
		return true
	return false

func aceptar_apuesta() -> void:
	apuesta_aceptada.emit()

func rechazar_apuesta() -> int:
	apuesta_rechazada.emit()
	# Si se rechaza el Truco (nivel 1), se pierde 1 punto.
	# Si se rechaza Retruco (nivel 2), se pierden los puntos del nivel anterior (Truco = 2).
	# Si se rechaza Vale 4 (nivel 3), se pierden los puntos del nivel anterior (Retruco = 3).
	
	if nivel_actual == NivelApuesta.TRUCO:
		return 1
	elif nivel_actual == NivelApuesta.RETRUCO:
		return 2
	elif nivel_actual == NivelApuesta.VALE_CUATRO:
		return 3
	return 1

func _actualizar_apuesta(nuevo_nivel: NivelApuesta, quien: String) -> void:
	nivel_actual = nuevo_nivel
	puntos_en_juego = puntos_por_nivel[nuevo_nivel]
	ultimo_apostador = quien
