extends Node
class_name AIDecision

# Decidir acción
# Retorna Dictionary con { "tipo": String, ...params }
# Tipos: "jugar_carta", "cantar_envido", "cantar_truco", "irse_al_mazo", "responder_apuesta"

func evaluar_mano(cartas: Array) -> Dictionary:
	var fuerza = calcular_fuerza_mano(cartas)
	var envido_sys = EnvidoSystem.new()
	var envido = envido_sys.calcular_envido(cartas)
	envido_sys.free()
	
	return {
		"fuerza": fuerza,
		"envido": envido,
		"cantidad_cartas": cartas.size()
	}

func calcular_fuerza_mano(cartas: Array) -> float:
	if cartas.is_empty(): return 0.0
	
	var suma_valores = 0.0
	for c in cartas:
		# Normalizar valor truco (1-14) a 0.0-1.0
		# 1 (4) -> 0.0
		# 14 (1 esp) -> 1.0
		var valor_norm = (c.obtener_valor_truco() - 1) / 13.0
		suma_valores += valor_norm
		
	return suma_valores / cartas.size()

func decidir_accion_turno(estrategia: int, state: TrucoState, evaluacion: Dictionary, betting: TrucoBetting) -> Dictionary:
	# Prioridad:
	# 1. Cantar Envido (si es posible y conviene)
	# 2. Cantar Truco (si es posible y conviene)
	# 3. Jugar Carta
	
	# --- ENVIDO ---
	# Solo se puede cantar en primera ronda
	if state.ronda_actual == 1 and betting.nivel_actual == TrucoBetting.NivelApuesta.NINGUNO: 
		# TODO: Verificar si ya se cantó envido (necesitaria estado de envido en TrucoState)
		# Por ahora asumimos que si nivel_apuesta es NINGUNO se puede
		if _debe_cantar_envido(estrategia, evaluacion.envido):
			return { "tipo": "cantar_envido", "envido_puntos": evaluacion.envido }
	
	# --- TRUCO ---
	if _debe_cantar_truco(estrategia, evaluacion.fuerza, betting):
		return { "tipo": "cantar_truco" }
		
	# --- JUGAR CARTA ---
	var carta = _elegir_mejor_carta(state.cartas_muerte, state)
	return { "tipo": "jugar_carta", "carta": carta }

func _debe_cantar_envido(estrategia: int, puntos_envido: int) -> bool:
	# Umbrales
	match estrategia:
		AIStrategy.Estrategia.CONSERVADORA: return puntos_envido >= 28
		AIStrategy.Estrategia.EQUILIBRADA: return puntos_envido >= 26
		AIStrategy.Estrategia.AGRESIVA: return puntos_envido >= 23
		AIStrategy.Estrategia.DESESPERADA: return puntos_envido >= 20
	return false

func _debe_cantar_truco(estrategia: int, fuerza: float, betting: TrucoBetting) -> bool:
	# Solo si no soy el que cantó (simple check, controller debe validar mas)
	if betting.ultimo_apostador == "muerte": return false
	if betting.nivel_actual >= TrucoBetting.NivelApuesta.VALE_CUATRO: return false
	
	var umbral = 0.6
	match estrategia:
		AIStrategy.Estrategia.CONSERVADORA: umbral = 0.8
		AIStrategy.Estrategia.EQUILIBRADA: umbral = 0.6
		AIStrategy.Estrategia.AGRESIVA: umbral = 0.4
		AIStrategy.Estrategia.DESESPERADA: umbral = 0.2
		
	return fuerza >= umbral

func _elegir_mejor_carta(cartas: Array, state: TrucoState) -> Carta:
	# Logica simple:
	# Si soy mano (carta_jugador is null): tirar la mas alta para asegurar? O la mas baja para esconder?
	# Estrategia basica: Tirar la mas alta posible para ganar, o la mas baja si no puedo ganar
	
	if cartas.is_empty(): return null
	
	var oponente_jugo = state.carta_jugada_jugador != null
	
	# Ordenar mis cartas por valor (ascendente: debil a fuerte)
	var mis_cartas = cartas.duplicate()
	mis_cartas.sort_custom(func(a, b): return a.obtener_valor_truco() < b.obtener_valor_truco())
	
	if not oponente_jugo:
		# Soy mano: tirar la mas fuerte (agresivo) o media?
		# Simplificacion: tirar la mas fuerte
		return mis_cartas.back()
	else:
		# Oponente jugó
		var valor_oponente = state.carta_jugada_jugador.obtener_valor_truco()
		
		# Buscar la carta mas baja que le gane
		for carta in mis_cartas:
			if carta.obtener_valor_truco() > valor_oponente:
				return carta
		
		# Si no puedo ganar, tirar la mas baja (la primera)
		return mis_cartas.front()
