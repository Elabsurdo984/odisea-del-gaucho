extends Node
class_name TrucoRules

# Constantes para retorno de ganador
const GANADOR_JUGADOR = 1
const GANADOR_MUERTE = 2
const EMPATE = 3

func determinar_ganador_ronda(carta_jugador: Carta, carta_muerte: Carta) -> int:
	var valor1 = carta_jugador.obtener_valor_truco()
	var valor2 = carta_muerte.obtener_valor_truco()
	
	if valor1 > valor2:
		return GANADOR_JUGADOR
	elif valor2 > valor1:
		return GANADOR_MUERTE
	else:
		return EMPATE

func determinar_ganador_mano(resultados: Array) -> int:
	# resultados es un array de ints (1, 2, 3) donde 0 es no jugado
	# Lógica de "mejor de 3" con empates
	var victorias_jugador = 0
	var victorias_muerte = 0
	
	for res in resultados:
		if res == GANADOR_JUGADOR:
			victorias_jugador += 1
		elif res == GANADOR_MUERTE:
			victorias_muerte += 1
			
	# Si alguien gana 2 rondas, gana
	if victorias_jugador >= 2:
		return GANADOR_JUGADOR
	if victorias_muerte >= 2:
		return GANADOR_MUERTE
		
	# Manejo de empates (Parda)
	# Primera parda: Gana quien gane la segunda
	if resultados[0] == EMPATE:
		if resultados[1] != 0:
			if resultados[1] != EMPATE:
				return resultados[1] # Gana quien gano la segunda
			elif resultados[2] != 0:
				return resultados[2] # Tercera parda: Gana quien gana la tercera (o el mano si empatan todo, pero simplificado aqui)
				
	# Primera no parda, segunda parda: Gana el que gano la primera
	if resultados[1] == EMPATE and resultados[0] != 0 and resultados[0] != EMPATE:
		return resultados[0]
		
	# Tercera parda (si 1-1 en las primeras): Gana el que gano la primera
	if resultados[2] == EMPATE:
		return resultados[0]
	
	return 0

func es_fin_de_mano(resultados: Array, ronda_actual: int) -> bool:
	# Termina si alguien ganó 2 rondas
	var victorias_jugador = 0
	var victorias_muerte = 0
	for res in resultados:
		if res == GANADOR_JUGADOR: victorias_jugador += 1
		if res == GANADOR_MUERTE: victorias_muerte += 1
	
	if victorias_jugador >= 2 or victorias_muerte >= 2:
		return true
		
	# Termina si hay parda en primera y alguien gana la segunda
	if resultados[0] == EMPATE and resultados[1] != 0 and resultados[1] != EMPATE:
		return true
		
	# Termina si se jugaron las 3 rondas
	if ronda_actual > 3:
		return true
		
	return false
