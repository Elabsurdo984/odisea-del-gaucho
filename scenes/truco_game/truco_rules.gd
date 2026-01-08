extends Node
class_name TrucoRules

# Constantes para retorno de ganador
const GANADOR_JUGADOR = 1
const GANADOR_MUERTE = 2
const EMPATE = 3

func determinar_ganador_ronda(carta_jugador, carta_muerte) -> int:
	var valor1 = _get_truco_val(carta_jugador)
	var valor2 = _get_truco_val(carta_muerte)
	
	if valor1 > valor2:
		return GANADOR_JUGADOR
	elif valor2 > valor1:
		return GANADOR_MUERTE
	else:
		return EMPATE

func determinar_ganador_mano(resultados: Array) -> int:
	var victorias_jugador = 0
	var victorias_muerte = 0
	
	for res in resultados:
		if res == GANADOR_JUGADOR: victorias_jugador += 1
		elif res == GANADOR_MUERTE: victorias_muerte += 1
			
	if victorias_jugador >= 2: return GANADOR_JUGADOR
	if victorias_muerte >= 2: return GANADOR_MUERTE
		
	if resultados[0] == EMPATE:
		if resultados[1] != 0:
			if resultados[1] != EMPATE: return resultados[1]
			elif resultados[2] != 0: return resultados[2]
				
	if resultados[1] == EMPATE and resultados[0] != 0 and resultados[0] != EMPATE:
		return resultados[0]
		
	if resultados[2] == EMPATE:
		return resultados[0]
	
	return 0

func es_fin_de_mano(resultados: Array, ronda_actual: int) -> bool:
	var victorias_jugador = 0
	var victorias_muerte = 0
	for res in resultados:
		if res == GANADOR_JUGADOR: victorias_jugador += 1
		if res == GANADOR_MUERTE: victorias_muerte += 1
	
	if victorias_jugador >= 2 or victorias_muerte >= 2: return true
	if resultados[0] == EMPATE and resultados[1] != 0 and resultados[1] != EMPATE: return true
	if ronda_actual > 3: return true
	return false

func _get_truco_val(c) -> int:
	if c is Dictionary:
		return Carta.calcular_valor_truco(c["numero"], c["palo"])
	elif c is Carta:
		return c.obtener_valor_truco()
	return 0
