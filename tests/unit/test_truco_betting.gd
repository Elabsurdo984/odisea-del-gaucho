extends GutTest

var betting: TrucoBetting

func before_each():
	betting = autofree(TrucoBetting.new())

func test_cantar_truco_inicial():
	var exito = betting.cantar_truco("jugador")
	assert_true(exito, "Debe poder cantar truco desde inicio")
	assert_eq(betting.nivel_actual, TrucoBetting.NivelApuesta.TRUCO)
	assert_eq(betting.puntos_en_juego, 2)
	assert_eq(betting.ultimo_apostador, "jugador")

func test_cantar_retruco_valido():
	betting.cantar_truco("jugador")
	var exito = betting.cantar_retruco("muerte")
	assert_true(exito, "Muerte debe poder responder con retruco")
	assert_eq(betting.nivel_actual, TrucoBetting.NivelApuesta.RETRUCO)
	assert_eq(betting.puntos_en_juego, 3)
	assert_eq(betting.ultimo_apostador, "muerte")

func test_no_puede_auto_retrucar():
	betting.cantar_truco("jugador")
	var exito = betting.cantar_retruco("jugador")
	assert_false(exito, "Jugador no puede retrucarse a si mismo")
	assert_eq(betting.nivel_actual, TrucoBetting.NivelApuesta.TRUCO, "Nivel no debe cambiar")

func test_cantar_vale_cuatro_valido():
	betting.cantar_truco("jugador")
	betting.cantar_retruco("muerte")
	var exito = betting.cantar_vale_cuatro("jugador")
	assert_true(exito, "Jugador debe poder responder vale cuatro")
	assert_eq(betting.nivel_actual, TrucoBetting.NivelApuesta.VALE_CUATRO)
	assert_eq(betting.puntos_en_juego, 4)

func test_rechazar_truco():
	betting.cantar_truco("jugador")
	var puntos_perdidos = betting.rechazar_apuesta()
	assert_eq(puntos_perdidos, 1, "Rechazar truco cuesta 1 punto")

func test_rechazar_retruco():
	betting.cantar_truco("jugador")
	betting.cantar_retruco("muerte")
	var puntos_perdidos = betting.rechazar_apuesta()
	assert_eq(puntos_perdidos, 2, "Rechazar retruco cuesta 2 puntos (los del truco querido)")

func test_rechazar_vale_cuatro():
	betting.cantar_truco("jugador")
	betting.cantar_retruco("muerte")
	betting.cantar_vale_cuatro("jugador")
	var puntos_perdidos = betting.rechazar_apuesta()
	assert_eq(puntos_perdidos, 3, "Rechazar vale cuatro cuesta 3 puntos")

func test_resetear_apuestas():
	betting.cantar_truco("jugador")
	betting.resetear_apuestas()
	assert_eq(betting.nivel_actual, TrucoBetting.NivelApuesta.NINGUNO)
	assert_eq(betting.puntos_en_juego, 1)
	assert_eq(betting.ultimo_apostador, "")
