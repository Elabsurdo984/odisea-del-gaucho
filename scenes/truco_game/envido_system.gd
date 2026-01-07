extends Node
class_name EnvidoSystem

signal envido_cantado(quien: String, tipo: String)
signal envido_resuelto(ganador: String, puntos: int)

enum TipoEnvido { ENVIDO, ENVIDO_ENVIDO, REAL_ENVIDO, FALTA_ENVIDO }

var puntos_por_tipo = {
	TipoEnvido.ENVIDO: 2,
	TipoEnvido.ENVIDO_ENVIDO: 2,
	TipoEnvido.REAL_ENVIDO: 3,
	TipoEnvido.FALTA_ENVIDO: 0  # Depende del faltante
}

var puntos_acumulados: int = 0
var tipo_actual: TipoEnvido = TipoEnvido.ENVIDO

func cantar_envido(tipo: TipoEnvido, quien: String) -> void:
	tipo_actual = tipo
	puntos_acumulados += puntos_por_tipo[tipo]
	envido_cantado.emit(quien, TipoEnvido.keys()[tipo])

func calcular_envido(cartas: Array) -> int:
	var mejor_envido = 0
	var por_palo = {}
	
	# Agrupar cartas por palo
	for carta in cartas:
		if not por_palo.has(carta.palo):
			por_palo[carta.palo] = []
		por_palo[carta.palo].append(carta)
	
	# Calcular puntaje
	for palo in por_palo:
		var grupo = por_palo[palo]
		
		# Si hay 2 o más del mismo palo
		if grupo.size() >= 2:
			# Ordenar descendente por valor de envido
			grupo.sort_custom(func(a, b): return a.obtener_valor_envido() > b.obtener_valor_envido())
			
			var val1 = grupo[0].obtener_valor_envido()
			var val2 = grupo[1].obtener_valor_envido()
			
			var envido = 20 + val1 + val2
			if envido > mejor_envido:
				mejor_envido = envido
				
		# Si es carta única de ese palo
		else:
			var val = grupo[0].obtener_valor_envido()
			# Solo consideramos carta sola si es mayor al mejor envido encontrado (ej: si tenemos 33 de mano, un 7 solo no importa)
			# Pero si tenemos 3 cartas distintas, el mejor envido es la carta mas alta
			if val > mejor_envido:
				mejor_envido = val
				
	return mejor_envido

func resolver_envido(puntos_jugador: int, puntos_muerte: int, es_mano_jugador: bool = true) -> Dictionary:
	var ganador = ""
	
	if puntos_jugador > puntos_muerte:
		ganador = "jugador"
	elif puntos_muerte > puntos_jugador:
		ganador = "muerte"
	else:
		# En caso de empate, gana el mano
		ganador = "jugador" if es_mano_jugador else "muerte"
	
	var puntos = puntos_acumulados
	# Si no se acumularon puntos (ej: envido directo no querido o algo asi, pero aqui resolvemos despues de querer), 
	# asumimos minimo 2 si no se seteo
	if puntos == 0: puntos = 2 

	envido_resuelto.emit(ganador, puntos)

	return {
		"ganador": ganador,
		"puntos": puntos,
		"puntos_jugador": puntos_jugador,
		"puntos_muerte": puntos_muerte
	}
