extends Node
class_name AIDecision

# Decidir acción
# Retorna Dictionary con { "tipo": String, ...params }

func evaluar_mano(cartas_actuales: Array, cartas_originales: Array = []) -> Dictionary:
	# Si no se pasan cartas originales, usar las actuales para ambos cálculos
	var cartas_para_envido = cartas_originales if not cartas_originales.is_empty() else cartas_actuales

	var fuerza = calcular_fuerza_mano(cartas_actuales)
	var envido_sys = EnvidoSystem.new()
	var envido = envido_sys.calcular_envido(cartas_para_envido)
	envido_sys.free()

	return {
		"fuerza": fuerza,
		"envido": envido,
		"cantidad_cartas": cartas_actuales.size()
	}

func calcular_fuerza_mano(cartas: Array) -> float:
	if cartas.is_empty(): return 0.0
	
	var suma_valores = 0.0
	for c in cartas:
		var v = _get_truco_val(c)
		var valor_norm = (v - 1) / 13.0
		suma_valores += valor_norm
		
	return suma_valores / cartas.size()

func decidir_accion_turno(estrategia: int, state: TrucoState, evaluacion: Dictionary, betting: TrucoBetting) -> Dictionary:
	# Solo cantar envido si: es primera ronda, no hay truco, y NO se cantó envido ya
	if state.ronda_actual == 1 and not state.envido_cantado and betting.nivel_actual == TrucoBetting.NivelApuesta.NINGUNO:
		if _debe_cantar_envido(estrategia, evaluacion.envido):
			return {
				"tipo": "cantar_envido",
				"envido_puntos": evaluacion.envido,
				"tipo_envido": EnvidoSystem.TipoEnvido.ENVIDO
			}
	
	if _debe_cantar_truco(estrategia, evaluacion.fuerza, betting):
		return { "tipo": "cantar_truco" }
		
	var carta = _elegir_mejor_carta(state.cartas_muerte, state)
	return { "tipo": "jugar_carta", "carta": carta }

func _debe_cantar_envido(estrategia: int, puntos_envido: int) -> bool:
	match estrategia:
		AIStrategy.Estrategia.CONSERVADORA: return puntos_envido >= 28
		AIStrategy.Estrategia.EQUILIBRADA: return puntos_envido >= 26
		AIStrategy.Estrategia.AGRESIVA: return puntos_envido >= 23
		AIStrategy.Estrategia.DESESPERADA: return puntos_envido >= 20
	return false

func _debe_cantar_truco(estrategia: int, fuerza: float, betting: TrucoBetting) -> bool:
	# No cantar si la muerte ya cantó y está esperando respuesta o ya se aceptó
	if betting.ultimo_apostador == "muerte": return false
	# No cantar truco si ya hay un truco activo (solo se puede subir a retruco/vale4)
	if betting.nivel_actual >= TrucoBetting.NivelApuesta.TRUCO: return false
	
	var umbral = 0.6
	match estrategia:
		AIStrategy.Estrategia.CONSERVADORA: umbral = 0.8
		AIStrategy.Estrategia.EQUILIBRADA: umbral = 0.6
		AIStrategy.Estrategia.AGRESIVA: umbral = 0.4
		AIStrategy.Estrategia.DESESPERADA: umbral = 0.2
		
	return fuerza >= umbral

func _elegir_mejor_carta(cartas: Array, state: TrucoState) -> Variant:
	if cartas.is_empty(): return null
	
	var oponente_jugo = state.carta_jugada_jugador != null
	
	var mis_cartas = cartas.duplicate()
	mis_cartas.sort_custom(func(a, b): return _get_truco_val(a) < _get_truco_val(b))
	
	if not oponente_jugo:
		return mis_cartas.back()
	else:
		var valor_oponente = _get_truco_val(state.carta_jugada_jugador)
		for carta in mis_cartas:
			if _get_truco_val(carta) > valor_oponente:
				return carta
		return mis_cartas.front()

# Helper para obtener valor de truco soportando Dictionary o Nodo Carta
func _get_truco_val(c) -> int:
	if c is Dictionary:
		return Carta.calcular_valor_truco(c["numero"], c["palo"])
	elif c is Carta:
		return c.obtener_valor_truco()
	return 0
