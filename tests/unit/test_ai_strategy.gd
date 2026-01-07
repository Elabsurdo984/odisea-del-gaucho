extends GutTest

var strategy: AIStrategy
var state: TrucoState

func before_each():
	strategy = autofree(AIStrategy.new())
	state = autofree(TrucoState.new())

func test_estrategia_desesperada_por_puntos():
	state.puntos_muerte = 2
	state.puntos_jugador = 13 # Diferencia -11
	
	var eval = {"fuerza": 0.5}
	var res = strategy.elegir_estrategia(eval, state)
	
	assert_eq(res, AIStrategy.Estrategia.DESESPERADA, "Debe ser desesperada si pierde por mucho")

func test_estrategia_desesperada_jugador_cerca_ganar():
	state.puntos_muerte = 10
	state.puntos_jugador = 13
	
	var eval = {"fuerza": 0.5}
	var res = strategy.elegir_estrategia(eval, state)
	
	assert_eq(res, AIStrategy.Estrategia.DESESPERADA, "Debe ser desesperada si jugador esta por ganar")

func test_estrategia_agresiva_buena_mano():
	state.puntos_muerte = 0
	state.puntos_jugador = 0
	
	var eval = {"fuerza": 0.8} # Mano muy fuerte
	var res = strategy.elegir_estrategia(eval, state)
	
	assert_eq(res, AIStrategy.Estrategia.AGRESIVA, "Debe ser agresiva con buena mano")

func test_estrategia_conservadora_ganando():
	state.puntos_muerte = 10
	state.puntos_jugador = 2 # Diferencia +8
	
	var eval = {"fuerza": 0.4}
	var res = strategy.elegir_estrategia(eval, state)
	
	assert_eq(res, AIStrategy.Estrategia.CONSERVADORA, "Debe ser conservadora si gana por mucho")

func test_estrategia_equilibrada_default():
	state.puntos_muerte = 5
	state.puntos_jugador = 5
	
	var eval = {"fuerza": 0.5}
	var res = strategy.elegir_estrategia(eval, state)
	
	assert_eq(res, AIStrategy.Estrategia.EQUILIBRADA, "Debe ser equilibrada en situaciones normales")
