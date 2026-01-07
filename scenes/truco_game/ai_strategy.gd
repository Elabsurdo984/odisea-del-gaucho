extends Node
class_name AIStrategy

enum Estrategia { CONSERVADORA, EQUILIBRADA, AGRESIVA, DESESPERADA }

func elegir_estrategia(evaluacion_mano: Dictionary, state: TrucoState) -> Estrategia:
	var diferencia_puntos = state.puntos_muerte - state.puntos_jugador
	var fuerza_mano = evaluacion_mano.fuerza # 0.0 a 1.0
	
	# Si vamos perdiendo por mucho (o estamos cerca de perder y el otro cerca de ganar)
	# Ejemplo: Muerte 5, Jugador 14. Diferencia -9.
	# Ejemplo: Muerte 2, Jugador 13. Diferencia -11.
	if diferencia_puntos <= -10:
		return Estrategia.DESESPERADA
		
	# Si falta poco para que gane el jugador (>= 12 puntos), jugar agresivo/desesperado
	if state.puntos_jugador >= 12 and diferencia_puntos < 0:
		return Estrategia.DESESPERADA
	
	# Si tenemos mano muy fuerte
	if fuerza_mano >= 0.75: # Promedio alto (ej: tres 3s o dos anchos)
		return Estrategia.AGRESIVA
		
	# Si vamos ganando por buen margen
	if diferencia_puntos >= 5:
		return Estrategia.CONSERVADORA
		
	return Estrategia.EQUILIBRADA
