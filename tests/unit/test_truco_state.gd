extends GutTest

var state: TrucoState

func before_each():
	state = autofree(TrucoState.new())

func test_estado_inicial():
	assert_eq(state.puntos_jugador, 0)
	assert_eq(state.puntos_muerte, 0)
	assert_eq(state.ronda_actual, 1)

func test_agregar_puntos():
	state.agregar_puntos_jugador(5)
	state.agregar_puntos_muerte(3)
	assert_eq(state.puntos_jugador, 5)
	assert_eq(state.puntos_muerte, 3)

func test_registrar_resultado_ronda():
	state.registrar_resultado_ronda(1) # Gana jugador
	assert_eq(state.resultados_rondas[0], 1)
	assert_eq(state.ronda_actual, 2)
	
	state.registrar_resultado_ronda(2) # Gana muerte
	assert_eq(state.resultados_rondas[1], 2)
	assert_eq(state.ronda_actual, 3)

func test_resetear_mano():
	state.registrar_resultado_ronda(1)
	state.carta_jugada_jugador = autofree(Carta.new())
	
	state.resetear_mano()
	
	assert_eq(state.ronda_actual, 1)
	assert_eq(state.resultados_rondas, [0, 0, 0])
	assert_null(state.carta_jugada_jugador)

func test_resetear_partida():
	state.agregar_puntos_jugador(10)
	state.registrar_resultado_ronda(1)
	
	state.resetear_partida()
	
	assert_eq(state.puntos_jugador, 0)
	assert_eq(state.ronda_actual, 1)
