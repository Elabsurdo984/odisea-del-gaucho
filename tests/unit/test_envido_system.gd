extends GutTest

var envido_sys: EnvidoSystem

func before_each():
	envido_sys = autofree(EnvidoSystem.new())

func test_calcular_envido_dos_cartas_mismo_palo():
	var c1 = _crear_carta(7, Carta.Palo.ESPADA)
	var c2 = _crear_carta(6, Carta.Palo.ESPADA)
	var c3 = _crear_carta(1, Carta.Palo.BASTO)
	
	var puntos = envido_sys.calcular_envido([c1, c2, c3])
	assert_eq(puntos, 33, "7 y 6 del mismo palo deben sumar 33")

func test_calcular_envido_tres_cartas_mismo_palo():
	var c1 = _crear_carta(7, Carta.Palo.ORO)
	var c2 = _crear_carta(5, Carta.Palo.ORO)
	var c3 = _crear_carta(4, Carta.Palo.ORO)
	
	var puntos = envido_sys.calcular_envido([c1, c2, c3])
	assert_eq(puntos, 32, "Debe tomar las 2 mas altas: 7 + 5 + 20 = 32")

func test_calcular_envido_tres_cartas_distintas():
	var c1 = _crear_carta(7, Carta.Palo.ESPADA)
	var c2 = _crear_carta(4, Carta.Palo.BASTO)
	var c3 = _crear_carta(1, Carta.Palo.COPA) # As falso
	
	var puntos = envido_sys.calcular_envido([c1, c2, c3])
	assert_eq(puntos, 7, "Debe ser la carta mas alta (7)")

func test_calcular_envido_con_figuras():
	var c1 = _crear_carta(10, Carta.Palo.ESPADA) # Sota (0)
	var c2 = _crear_carta(7, Carta.Palo.ESPADA)  # 7
	var c3 = _crear_carta(1, Carta.Palo.BASTO)
	
	var puntos = envido_sys.calcular_envido([c1, c2, c3])
	assert_eq(puntos, 27, "7 + 0 + 20 = 27")

func test_calcular_envido_dos_figuras_mismo_palo():
	var c1 = _crear_carta(10, Carta.Palo.COPA)
	var c2 = _crear_carta(11, Carta.Palo.COPA)
	var c3 = _crear_carta(1, Carta.Palo.BASTO)
	
	var puntos = envido_sys.calcular_envido([c1, c2, c3])
	assert_eq(puntos, 20, "0 + 0 + 20 = 20")

func test_resolver_envido_gana_jugador():
	envido_sys.puntos_acumulados = 2
	var res = envido_sys.resolver_envido(30, 25)
	assert_eq(res.ganador, "jugador", "30 gana a 25")
	assert_eq(res.puntos, 2)

func test_resolver_envido_gana_muerte():
	envido_sys.puntos_acumulados = 2
	var res = envido_sys.resolver_envido(20, 31)
	assert_eq(res.ganador, "muerte", "31 gana a 20")

func test_resolver_envido_empate_gana_mano_jugador():
	envido_sys.puntos_acumulados = 2
	# Por defecto es_mano_jugador = true
	var res = envido_sys.resolver_envido(30, 30, true)
	assert_eq(res.ganador, "jugador", "Empate gana mano (jugador)")

func test_resolver_envido_empate_gana_mano_muerte():
	envido_sys.puntos_acumulados = 2
	var res = envido_sys.resolver_envido(30, 30, false)
	assert_eq(res.ganador, "muerte", "Empate gana mano (muerte)")

# Helper
func _crear_carta(numero, palo) -> Carta:
	var c = autofree(Carta.new())
	c.setup(numero, palo)
	return c
