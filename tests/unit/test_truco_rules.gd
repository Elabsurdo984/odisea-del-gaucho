extends GutTest

var rules: TrucoRules

func before_each():
	rules = autofree(TrucoRules.new())

func test_carta_mas_alta_gana_ronda():
	var carta_jugador = autofree(Carta.new())
	carta_jugador.setup(1, Carta.Palo.ESPADA) # Ancho de espadas (14)
	
	var carta_muerte = autofree(Carta.new())
	carta_muerte.setup(4, Carta.Palo.COPA) # 4 (1)
	
	var resultado = rules.determinar_ganador_ronda(carta_jugador, carta_muerte)
	assert_eq(resultado, TrucoRules.GANADOR_JUGADOR, "El Ancho de Espadas debe ganar al 4")

func test_carta_mas_baja_pierde_ronda():
	var carta_jugador = autofree(Carta.new())
	carta_jugador.setup(7, Carta.Palo.COPA) # 4
	
	var carta_muerte = autofree(Carta.new())
	carta_muerte.setup(7, Carta.Palo.ESPADA) # 12
	
	var resultado = rules.determinar_ganador_ronda(carta_jugador, carta_muerte)
	assert_eq(resultado, TrucoRules.GANADOR_MUERTE, "El 7 de Copas debe perder ante el 7 de Espadas")

func test_empate_ronda():
	var carta_jugador = autofree(Carta.new())
	carta_jugador.setup(3, Carta.Palo.BASTO) # 10
	
	var carta_muerte = autofree(Carta.new())
	carta_muerte.setup(3, Carta.Palo.ORO) # 10
	
	var resultado = rules.determinar_ganador_ronda(carta_jugador, carta_muerte)
	assert_eq(resultado, TrucoRules.EMPATE, "Dos 3 deben empatar")

func test_ganador_mano_dos_victorias_seguidas():
	# Jugador gana 1ra y 2da
	var resultados = [TrucoRules.GANADOR_JUGADOR, TrucoRules.GANADOR_JUGADOR, 0]
	var ganador = rules.determinar_ganador_mano(resultados)
	assert_eq(ganador, TrucoRules.GANADOR_JUGADOR, "Jugador debe ganar con 2 victorias")

func test_ganador_mano_alternada():
	# Muerte gana 1ra, Jugador gana 2da, Muerte gana 3ra
	var resultados = [TrucoRules.GANADOR_MUERTE, TrucoRules.GANADOR_JUGADOR, TrucoRules.GANADOR_MUERTE]
	var ganador = rules.determinar_ganador_mano(resultados)
	assert_eq(ganador, TrucoRules.GANADOR_MUERTE, "Muerte debe ganar 2 a 1")

func test_parda_primera_define_segunda():
	# Empate 1ra, Jugador gana 2da
	var resultados = [TrucoRules.EMPATE, TrucoRules.GANADOR_JUGADOR, 0]
	var ganador = rules.determinar_ganador_mano(resultados)
	assert_eq(ganador, TrucoRules.GANADOR_JUGADOR, "Si hay parda en primera, define la segunda")

func test_parda_primera_y_segunda_define_tercera():
	# Empate 1ra, Empate 2da, Jugador gana 3ra
	var resultados = [TrucoRules.EMPATE, TrucoRules.EMPATE, TrucoRules.GANADOR_JUGADOR]
	var ganador = rules.determinar_ganador_mano(resultados)
	assert_eq(ganador, TrucoRules.GANADOR_JUGADOR, "Si hay 2 pardas, define la tercera")

func test_tercera_parda_gana_primera():
	# Jugador gana 1ra, Muerte gana 2da, Empate 3ra
	var resultados = [TrucoRules.GANADOR_JUGADOR, TrucoRules.GANADOR_MUERTE, TrucoRules.EMPATE]
	var ganador = rules.determinar_ganador_mano(resultados)
	assert_eq(ganador, TrucoRules.GANADOR_JUGADOR, "Si empata la tercera, gana el ganador de la primera")

func test_tercera_parda_gana_primera_muerte():
	# Muerte gana 1ra, Jugador gana 2da, Empate 3ra
	var resultados = [TrucoRules.GANADOR_MUERTE, TrucoRules.GANADOR_JUGADOR, TrucoRules.EMPATE]
	var ganador = rules.determinar_ganador_mano(resultados)
	assert_eq(ganador, TrucoRules.GANADOR_MUERTE, "Si empata la tercera, gana el ganador de la primera (Muerte)")
func test_primera_gana_segunda_parda():
	# Jugador gana 1ra, Empate 2da
	var resultados = [TrucoRules.GANADOR_JUGADOR, TrucoRules.EMPATE, 0]
	var ganador = rules.determinar_ganador_mano(resultados)
	assert_eq(ganador, TrucoRules.GANADOR_JUGADOR, "Si gana primera y empata segunda, gana el de la primera")

func test_fin_de_mano_dos_victorias():
	var resultados = [TrucoRules.GANADOR_JUGADOR, TrucoRules.GANADOR_JUGADOR, 0]
	assert_true(rules.es_fin_de_mano(resultados, 3), "Debe terminar si hay 2 victorias")

func test_fin_de_mano_parda_primera_definida():
	var resultados = [TrucoRules.EMPATE, TrucoRules.GANADOR_MUERTE, 0]
	assert_true(rules.es_fin_de_mano(resultados, 3), "Debe terminar si hubo parda y luego victoria")

func test_no_fin_de_mano_1_a_1():
	var resultados = [TrucoRules.GANADOR_JUGADOR, TrucoRules.GANADOR_MUERTE, 0]
	# Ronda actual seria 3
	assert_false(rules.es_fin_de_mano(resultados, 3), "No termina si van 1 a 1 y falta la 3ra")
