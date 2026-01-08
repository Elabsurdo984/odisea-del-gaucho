extends Node
class_name EnvidoSystem

signal envido_cantado(quien: String, tipo: String)
signal envido_resuelto(ganador: String, puntos: int)

enum TipoEnvido { ENVIDO, ENVIDO_ENVIDO, REAL_ENVIDO, FALTA_ENVIDO }

var puntos_por_tipo = {
	TipoEnvido.ENVIDO: 2,
	TipoEnvido.ENVIDO_ENVIDO: 2,
	TipoEnvido.REAL_ENVIDO: 3,
	TipoEnvido.FALTA_ENVIDO: 0
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
	
	for c in cartas:
		var p = c["palo"] if c is Dictionary else c.palo
		if not por_palo.has(p):
			por_palo[p] = []
		por_palo[p].append(c)
	
	for palo in por_palo:
		var grupo = por_palo[palo]
		if grupo.size() >= 2:
			grupo.sort_custom(func(a, b): return _get_envido_val(a) > _get_envido_val(b))
			var envido = 20 + _get_envido_val(grupo[0]) + _get_envido_val(grupo[1])
			if envido > mejor_envido: mejor_envido = envido
		else:
			var val = _get_envido_val(grupo[0])
			if val > mejor_envido: mejor_envido = val
				
	return mejor_envido

func resolver_envido(puntos_jugador: int, puntos_muerte: int, es_mano_jugador: bool = true) -> Dictionary:
	var ganador = ""
	if puntos_jugador > puntos_muerte:
		ganador = "jugador"
	elif puntos_muerte > puntos_jugador:
		ganador = "muerte"
	else:
		ganador = "jugador" if es_mano_jugador else "muerte"
	
	var puntos = puntos_acumulados
	if puntos == 0: puntos = 2 

	envido_resuelto.emit(ganador, puntos)
	return { "ganador": ganador, "puntos": puntos }

func _get_envido_val(c) -> int:
	if c is Dictionary:
		return Carta.calcular_valor_envido(c["numero"])
	return c.obtener_valor_envido()
