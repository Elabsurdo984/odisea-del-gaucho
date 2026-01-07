extends GutTest

var ai: AIMuerte
var state: TrucoState
var betting: TrucoBetting

func before_each():
	ai = autofree(AIMuerte.new())
	state = autofree(TrucoState.new())
	betting = autofree(TrucoBetting.new())
	
	ai.truco_state = state
	ai.truco_betting = betting
	add_child(ai)

func test_ejecutar_turno_emite_senal():
	# Configurar estado básico
	state.cartas_muerte = [_crear_carta(1, Carta.Palo.ESPADA)]
	
	watch_signals(ai)
	ai.ejecutar_turno()
		
	assert_signal_emitted(ai, "accion_tomada")
		
		# Verificar que el payload de la señal tenga sentido
	var signals = get_signal_parameters(ai, "accion_tomada")
		
	if signals.size() > 0:
		var primer_emision = signals[0]
		var accion = null
			
		# Caso 1: Array de argumentos (Standard GUT) -> [[arg1]]
		if typeof(primer_emision) == TYPE_ARRAY and primer_emision.size() > 0:
			accion = primer_emision[0]
				
			# Caso 2: El argumento directo (Lo que parece estar pasando) -> [arg1]
		elif typeof(primer_emision) == TYPE_DICTIONARY:
			accion = primer_emision
				
			if accion and typeof(accion) == TYPE_DICTIONARY:
				assert_has(accion, "tipo", "La accion debe tener un tipo")
			else:
				fail_test("No se pudo extraer una accion valida de: " + str(signals))
	else:
		fail_test("No se emitio la señal o no tiene parametros")

func _crear_carta(numero, palo) -> Carta:
	var c = autofree(Carta.new())
	c.setup(numero, palo)
	return c
