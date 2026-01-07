extends GutTest

var decision: AIDecision
var state: TrucoState
var betting: TrucoBetting

func before_each():
	decision = autofree(AIDecision.new())
	state = autofree(TrucoState.new())
	betting = autofree(TrucoBetting.new())

func test_calcular_fuerza_mano_baja():
	var c1 = _crear_carta(4, Carta.Palo.COPA) # 1 (0.0)
	var c2 = _crear_carta(4, Carta.Palo.ORO)  # 1 (0.0)
	var fuerza = decision.calcular_fuerza_mano([c1, c2])
	assert_eq(fuerza, 0.0, "Fuerza minima debe ser 0.0")

func test_calcular_fuerza_mano_alta():
	var c1 = _crear_carta(1, Carta.Palo.ESPADA) # 14 (1.0)
	var c2 = _crear_carta(1, Carta.Palo.BASTO)  # 13 (~0.92)
	var fuerza = decision.calcular_fuerza_mano([c1, c2])
	assert_gt(fuerza, 0.9, "Fuerza debe ser alta")

func test_debe_cantar_envido_agresivo():
	var evaluacion = { "envido": 24, "fuerza": 0.5 }
	var accion = decision.decidir_accion_turno(AIStrategy.Estrategia.AGRESIVA, state, evaluacion, betting)
	
	assert_eq(accion.tipo, "cantar_envido", "Debe cantar envido con 24 siendo agresivo")

func test_no_cantar_envido_conservador():
	var evaluacion = { "envido": 24, "fuerza": 0.5 }
	var accion = decision.decidir_accion_turno(AIStrategy.Estrategia.CONSERVADORA, state, evaluacion, betting)
	
	# Si no canta envido, cantara truco o jugara carta
	assert_ne(accion.tipo, "cantar_envido", "No debe cantar envido con 24 siendo conservador")

func test_elegir_carta_mata_oponente():
	var c_baja = _crear_carta(4, Carta.Palo.COPA) # 1
	var c_alta = _crear_carta(1, Carta.Palo.ESPADA) # 14
	state.cartas_muerte = [c_baja, c_alta]
	
	# Oponente jugó un 3 (valor 10)
	var c_oponente = _crear_carta(3, Carta.Palo.ORO)
	state.carta_jugada_jugador = c_oponente
	
	var elegida = decision._elegir_mejor_carta(state.cartas_muerte, state)
	assert_eq(elegida, c_alta, "Debe elegir el ancho de espadas para ganar al 3")

func test_elegir_carta_mas_baja_si_pierde():
	var c_baja = _crear_carta(4, Carta.Palo.COPA) # 1
	var c_media = _crear_carta(5, Carta.Palo.COPA) # 2
	state.cartas_muerte = [c_baja, c_media]
	
	# Oponente jugó un 3 (valor 10) - Imposible ganar
	var c_oponente = _crear_carta(3, Carta.Palo.ORO)
	state.carta_jugada_jugador = c_oponente
	
	var elegida = decision._elegir_mejor_carta(state.cartas_muerte, state)
	assert_eq(elegida, c_baja, "Debe tirar la mas baja (4) si no puede ganar")

# Helper
func _crear_carta(numero, palo) -> Carta:
	var c = autofree(Carta.new())
	c.setup(numero, palo)
	return c
