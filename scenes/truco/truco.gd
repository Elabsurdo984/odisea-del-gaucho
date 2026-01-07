# truco.gd
# Juego de truco argentino contra la Muerte
extends Control

#region RECURSOS
const CARTA_SCENE = preload("res://scenes/truco/carta.tscn")
#endregion

#region REFERENCIAS
@export var jugador_cartas_container: HBoxContainer
@export var muerte_cartas_container: HBoxContainer
@export var mesa_jugador: Node2D
@export var mesa_muerte: Node2D
@export var placeholder_jugador: ColorRect
@export var placeholder_muerte: ColorRect

@export var puntos_jugador_label: Label
@export var puntos_muerte_label: Label

@export var btn_envido: Button
@export var btn_truco: Button
@export var btn_mazo: Button

# Botones de respuesta al envido
@export var btn_envido_envido: Button
@export var btn_real_envido: Button
@export var btn_falta_envido: Button
@export var btn_quiero: Button
@export var btn_no_quiero: Button

@export var mensaje_label: Label

@export var gaucho_sprite: Sprite2D
@export var muerte_sprite: Sprite2D
#endregion

#region CONFIGURACION
const PUNTOS_PARA_GANAR = 15
#endregion

#region ESTADO DEL JUEGO
var puntos_jugador := 0
var puntos_muerte := 0

var cartas_jugador: Array = []  # Array de nodos Carta
var cartas_muerte: Array = []  # Array de nodos Carta

var mazo: Mazo  # Instancia del mazo

var es_turno_jugador := true
var ronda_actual := 1  # 1, 2 o 3
var carta_jugada_jugador: Carta = null
var carta_jugada_muerte: Carta = null

# Resultados de rondas: 0 = no jugada, 1 = jugador gana, 2 = muerte gana, 3 = empate
var resultado_ronda_1 := 0
var resultado_ronda_2 := 0
var resultado_ronda_3 := 0

var puntos_en_juego := 1  # Puntos que vale la mano actual

# Estado del truco
enum EstadoTruco { NINGUNO, TRUCO, RETRUCO, VALE_CUATRO }
var estado_truco: EstadoTruco = EstadoTruco.NINGUNO
var truco_cantado_por_jugador := false  # Para saber quién puede subir la apuesta

# Estado del envido
enum EstadoEnvido { NINGUNO, ENVIDO, ENVIDO_ENVIDO, REAL_ENVIDO, FALTA_ENVIDO }
var estado_envido: EstadoEnvido = EstadoEnvido.NINGUNO
var envido_cantado_por_jugador := false  # Quién cantó último
var puntos_envido_en_juego := 0  # Puntos acumulados del envido
var envido_ya_cantado := false  # Para deshabilitar después de primera carta
var puntos_envido_jugador := 0
var puntos_envido_muerte := 0

# Mano (quién empieza)
var es_mano_jugador := true  # Al inicio, el jugador es mano
#endregion

#region INICIALIZACION
func _ready():
	print("🎴 Iniciando partida de truco contra la Muerte...")

	# Conectar botones principales
	if btn_envido:
		btn_envido.pressed.connect(_on_envido_pressed)
	if btn_truco:
		btn_truco.pressed.connect(_on_truco_pressed)
	if btn_mazo:
		btn_mazo.pressed.connect(_on_mazo_pressed)

	# Conectar botones de respuesta al envido
	if btn_envido_envido:
		btn_envido_envido.pressed.connect(_on_envido_envido_pressed)
		btn_envido_envido.visible = false
	if btn_real_envido:
		btn_real_envido.pressed.connect(_on_real_envido_pressed)
		btn_real_envido.visible = false
	if btn_falta_envido:
		btn_falta_envido.pressed.connect(_on_falta_envido_pressed)
		btn_falta_envido.visible = false
	if btn_quiero:
		btn_quiero.pressed.connect(_on_quiero_envido_pressed)
		btn_quiero.visible = false
	if btn_no_quiero:
		btn_no_quiero.pressed.connect(_on_no_quiero_envido_pressed)
		btn_no_quiero.visible = false

	# Iniciar partida
	await get_tree().create_timer(1.0).timeout
	iniciar_nueva_mano()
#endregion

#region FLUJO DEL JUEGO
func iniciar_nueva_mano():
	print("🃏 Nueva mano - Repartiendo cartas...")

	# Resetear estado
	ronda_actual = 1
	resultado_ronda_1 = 0
	resultado_ronda_2 = 0
	resultado_ronda_3 = 0
	carta_jugada_jugador = null
	carta_jugada_muerte = null
	puntos_en_juego = 1
	es_turno_jugador = es_mano_jugador  # El mano empieza

	# Resetear truco
	estado_truco = EstadoTruco.NINGUNO
	truco_cantado_por_jugador = false

	# Resetear envido
	estado_envido = EstadoEnvido.NINGUNO
	envido_cantado_por_jugador = false
	puntos_envido_en_juego = 0
	envido_ya_cantado = false
	if btn_envido:
		btn_envido.disabled = false
		btn_envido.visible = true
	ocultar_botones_respuesta_envido()

	# Limpiar cartas anteriores
	limpiar_cartas()

	# Crear nuevo mazo
	mazo = Mazo.new()

	# Repartir 3 cartas al jugador
	repartir_cartas_jugador()

	# Repartir 3 cartas a la muerte
	repartir_cartas_muerte()

	# Calcular puntos de envido
	puntos_envido_jugador = calcular_envido(cartas_jugador)
	puntos_envido_muerte = calcular_envido(cartas_muerte)

	print("📊 Envido - Jugador: %d | Muerte: %d" % [puntos_envido_jugador, puntos_envido_muerte])

	actualizar_ui()

	# Si la Muerte es mano, ella juega primero
	if not es_mano_jugador:
		mostrar_mensaje("Ronda %d - Turno de la Muerte (es mano)" % ronda_actual)
		await get_tree().create_timer(1.0).timeout
		turno_muerte()
	else:
		mostrar_mensaje("Ronda %d - Tu turno (sos mano)" % ronda_actual)

func limpiar_cartas():
	# Limpiar TODOS los hijos de los contenedores visuales inmediatamente
	for child in jugador_cartas_container.get_children():
		child.queue_free()
	for child in muerte_cartas_container.get_children():
		child.queue_free()

	# Limpiar cartas de la mesa si quedaron (ANTES de limpiar los arrays)
	if carta_jugada_jugador and is_instance_valid(carta_jugada_jugador):
		carta_jugada_jugador.queue_free()
	if carta_jugada_muerte and is_instance_valid(carta_jugada_muerte):
		carta_jugada_muerte.queue_free()
	
	# Ahora sí, establecer a null
	carta_jugada_jugador = null
	carta_jugada_muerte = null

	# Limpiar cartas restantes en los contenedores de mesa
	for child in mesa_jugador.get_children():
		if child != placeholder_jugador:
			child.queue_free()
	for child in mesa_muerte.get_children():
		if child != placeholder_muerte:
			child.queue_free()

	# Limpiar arrays AL FINAL
	cartas_jugador.clear()
	cartas_muerte.clear()

func repartir_cartas_jugador():
	var cartas_data = mazo.repartir_cartas(3)

	for carta_data in cartas_data:
		# Crear instancia de carta
		var carta = CARTA_SCENE.instantiate()
		carta.setup(carta_data["numero"], carta_data["palo"])

		# Mostrar boca arriba
		carta.mostrar_frente()

		# Hacer clickeable
		carta.hacer_clickeable(true)

		# Conectar señal
		carta.carta_clickeada.connect(_on_carta_jugador_clickeada)

		# Agregar al contenedor visual
		jugador_cartas_container.add_child(carta)

		# Guardar referencia
		cartas_jugador.append(carta)

	print("✅ Jugador recibe: ", cartas_jugador.size(), " cartas")

func repartir_cartas_muerte():
	var cartas_data = mazo.repartir_cartas(3)

	for carta_data in cartas_data:
		# Crear instancia de carta
		var carta = CARTA_SCENE.instantiate()
		carta.setup(carta_data["numero"], carta_data["palo"])

		# Mantener boca abajo
		carta.mostrar_dorso()

		# No hacer clickeable
		carta.hacer_clickeable(false)

		# Agregar al contenedor visual
		muerte_cartas_container.add_child(carta)

		# Guardar referencia
		cartas_muerte.append(carta)

	print("✅ Muerte recibe: ", cartas_muerte.size(), " cartas")

func _on_carta_jugador_clickeada(carta: Carta):
	if not es_turno_jugador:
		mostrar_mensaje("No es tu turno")
		return

	print("🃏 Jugador juega: ", carta.obtener_nombre_completo())
	jugar_carta_jugador(carta)

func jugar_carta_jugador(carta: Carta):
	# Guardar carta jugada
	carta_jugada_jugador = carta

	# Remover del array (pero no destruir, solo reparentar)
	cartas_jugador.erase(carta)

	# Deshabilitar envido después de jugar primera carta
	if ronda_actual == 1:
		btn_envido.disabled = true

	# Desactivar todas las cartas del jugador mientras espera
	for c in cartas_jugador:
		c.hacer_clickeable(false)

	# Mover carta a la mesa
	carta.get_parent().remove_child(carta)
	mesa_jugador.add_child(carta)

	# Posicionar la carta EXACTAMENTE donde está el placeholder
	# El placeholder va de offset -40,-60 a 40,60
	# La carta Control tiene origen en esquina superior izquierda
	# Entonces la posicionamos en -40,-60 para que coincida
	carta.position = Vector2(-40, -60)
	carta.hacer_clickeable(false)  # No clickeable en la mesa

	# Ocultar placeholder DESPUÉS de posicionar la carta
	if placeholder_jugador:
		placeholder_jugador.visible = false

	mostrar_mensaje("Jugaste: " + carta.obtener_nombre_completo())

	# Cambiar turno
	es_turno_jugador = false

	await get_tree().create_timer(1.0).timeout

	# Si la muerte ya jugó su carta, comparar
	if carta_jugada_muerte:
		comparar_cartas()
	else:
		# La muerte aún no jugó, es su turno
		turno_muerte()

func actualizar_ui():
	if puntos_jugador_label:
		puntos_jugador_label.text = "Jugador: %d" % puntos_jugador
	if puntos_muerte_label:
		puntos_muerte_label.text = "Muerte: %d" % puntos_muerte

	actualizar_boton_truco()

func actualizar_boton_truco():
	if not btn_truco:
		return

	# Determinar el texto del botón según el estado
	match estado_truco:
		EstadoTruco.NINGUNO:
			btn_truco.text = "TRUCO"
			btn_truco.disabled = not es_turno_jugador
		EstadoTruco.TRUCO:
			if truco_cantado_por_jugador:
				# Esperando respuesta de la Muerte
				btn_truco.disabled = true
			else:
				# La Muerte cantó, puedo retruco
				btn_truco.text = "RETRUCO"
				btn_truco.disabled = false
		EstadoTruco.RETRUCO:
			if truco_cantado_por_jugador:
				# Esperando respuesta de la Muerte
				btn_truco.disabled = true
			else:
				# La Muerte cantó, puedo vale cuatro
				btn_truco.text = "VALE 4"
				btn_truco.disabled = false
		EstadoTruco.VALE_CUATRO:
			# No se puede subir más
			btn_truco.disabled = true

func mostrar_mensaje(texto: String):
	if mensaje_label:
		mensaje_label.text = texto
	print("💬 ", texto)
#endregion

#region TURNO DE LA MUERTE
func turno_muerte():
	mostrar_mensaje("Turno de la Muerte...")

	# Verificar que tenga cartas
	if cartas_muerte.is_empty():
		push_error("❌ La Muerte no tiene cartas!")
		return

	# EVALUAR SI DEBE CANTAR ENVIDO (solo ronda 1, antes de jugar carta)
	if ronda_actual == 1 and not envido_ya_cantado and estado_envido == EstadoEnvido.NINGUNO:
		if await ia_evaluar_cantar_envido():
			return  # Si cantó envido, espera respuesta del jugador

	# EVALUAR SI DEBE CANTAR TRUCO (rondas 1 o 2, antes de jugar carta)
	if ronda_actual <= 2 and estado_truco == EstadoTruco.NINGUNO:
		if await ia_evaluar_cantar_truco():
			return  # Si cantó truco, espera respuesta del jugador

	# Preparar contexto para la IA
	var contexto = {
		"ronda_actual": ronda_actual,
		"resultado_ronda_1": resultado_ronda_1,
		"resultado_ronda_2": resultado_ronda_2,
		"es_mano": not es_mano_jugador,  # Si jugador es mano, muerte NO es mano
		"carta_jugador": carta_jugada_jugador
	}

	# Usar IA estratégica para seleccionar carta
	var carta = IAMuerte.seleccionar_carta_estrategico(cartas_muerte, contexto)

	# Debug (opcional - descomentar para ver decisiones de IA)
	IAMuerte.debug_mano(cartas_muerte)
	print("🤖 IA seleccionó: %s (Ronda %d)" % [carta.obtener_nombre_completo(), ronda_actual])

	jugar_carta_muerte(carta)

# Evalúa si la IA debe cantar envido proactivamente
func ia_evaluar_cantar_envido() -> bool:
	var fuerza_mano = IAMuerte.evaluar_fuerza_mano(cartas_muerte)
	var contexto = {
		"puntos_envido_muerte": puntos_envido_muerte,
		"puntos_muerte": puntos_muerte,
		"puntos_jugador": puntos_jugador,
		"puntos_para_ganar": PUNTOS_PARA_GANAR,
		"fuerza_mano": fuerza_mano,
		"ronda_actual": ronda_actual
	}

	# Preguntar a la IA si debe cantar
	if IAMuerte.debe_cantar_envido(contexto):
		# Considerar si cantar falta envido directamente
		if IAMuerte.debe_cantar_falta_envido(contexto):
			await ia_cantar_falta_envido()
			return true
		else:
			await ia_cantar_envido()
			return true

	return false

# La Muerte canta ENVIDO proactivamente
func ia_cantar_envido():
	print("💀 Muerte: ¡ENVIDO!")
	estado_envido = EstadoEnvido.ENVIDO
	envido_cantado_por_jugador = false
	puntos_envido_en_juego = 2
	envido_ya_cantado = true

	mostrar_mensaje("Muerte canta: ¡ENVIDO! (2 puntos)")

	# Ocultar botón de envido del jugador
	if btn_envido:
		btn_envido.visible = false

	# Mostrar botones de respuesta al jugador
	mostrar_botones_respuesta_envido()

	await get_tree().create_timer(1.5).timeout

# La Muerte canta FALTA ENVIDO directamente
func ia_cantar_falta_envido():
	print("💀 Muerte: ¡FALTA ENVIDO!")
	estado_envido = EstadoEnvido.FALTA_ENVIDO
	envido_cantado_por_jugador = false
	var puntos_falta = PUNTOS_PARA_GANAR - puntos_jugador
	envido_ya_cantado = true

	mostrar_mensaje("Muerte canta: ¡FALTA ENVIDO! (%d puntos)" % puntos_falta)

	# Ocultar botón de envido del jugador
	if btn_envido:
		btn_envido.visible = false

	# Mostrar solo botones Quiero/No Quiero (no puede subir más)
	if btn_quiero:
		btn_quiero.visible = true
	if btn_no_quiero:
		btn_no_quiero.visible = true

	await get_tree().create_timer(1.5).timeout

# Evalúa si la IA debe cantar truco proactivamente
func ia_evaluar_cantar_truco() -> bool:
	var fuerza_mano = IAMuerte.evaluar_fuerza_mano(cartas_muerte)
	var contexto = {
		"ronda_actual": ronda_actual,
		"resultado_ronda_1": resultado_ronda_1,
		"puntos_muerte": puntos_muerte,
		"puntos_jugador": puntos_jugador,
		"puntos_para_ganar": PUNTOS_PARA_GANAR,
		"estado_truco": int(estado_truco),
		"fuerza_mano": fuerza_mano
	}

	# Preguntar a la IA si debe cantar truco
	if IAMuerte.debe_cantar_truco(cartas_muerte, contexto):
		await ia_cantar_truco()
		# No retornar true - permitir que continúe jugando carta
		return false

	return false

# La Muerte canta TRUCO proactivamente
func ia_cantar_truco():
	print("💀 Muerte: ¡TRUCO!")
	estado_truco = EstadoTruco.TRUCO
	truco_cantado_por_jugador = false
	mostrar_mensaje("Muerte canta: ¡TRUCO! (Vale 2 puntos)")

	# Deshabilitar botón de truco del jugador temporalmente
	if btn_truco:
		btn_truco.disabled = true

	await get_tree().create_timer(1.5).timeout

	# El jugador puede responder (actualizar botón)
	actualizar_boton_truco()

func jugar_carta_muerte(carta: Carta):
	# Guardar carta jugada
	carta_jugada_muerte = carta

	# Remover del array
	cartas_muerte.erase(carta)

	# Mover carta a la mesa
	carta.get_parent().remove_child(carta)
	mesa_muerte.add_child(carta)

	# Posicionar la carta EXACTAMENTE donde está el placeholder
	carta.position = Vector2(-40, -60)

	# Mostrar boca arriba
	carta.mostrar_frente()

	# Ocultar placeholder DESPUÉS de posicionar la carta
	if placeholder_muerte:
		placeholder_muerte.visible = false

	print("💀 Muerte juega: ", carta.obtener_nombre_completo())
	mostrar_mensaje("Muerte juega: " + carta.obtener_nombre_completo())

	# Cambiar turno
	es_turno_jugador = true

	await get_tree().create_timer(1.5).timeout

	# Si el jugador ya jugó su carta, comparar
	if carta_jugada_jugador:
		comparar_cartas()
	else:
		# El jugador aún no jugó, activar sus cartas
		for c in cartas_jugador:
			c.hacer_clickeable(true)
		mostrar_mensaje("Tu turno")
#endregion

#region COMPARACION Y RESOLUCION
func comparar_cartas():
	if not carta_jugada_jugador or not carta_jugada_muerte:
		push_error("❌ Faltan cartas para comparar!")
		return

	var valor_jugador = carta_jugada_jugador.obtener_valor_truco()
	var valor_muerte = carta_jugada_muerte.obtener_valor_truco()

	var ganador := 0  # 0 = empate, 1 = jugador, 2 = muerte

	if valor_jugador > valor_muerte:
		ganador = 1
		mostrar_mensaje("¡Ganaste la ronda!")
		print("✅ Jugador gana ronda %d (%d vs %d)" % [ronda_actual, valor_jugador, valor_muerte])
	elif valor_muerte > valor_jugador:
		ganador = 2
		mostrar_mensaje("Muerte gana la ronda")
		print("💀 Muerte gana ronda %d (%d vs %d)" % [ronda_actual, valor_muerte, valor_jugador])
	else:
		ganador = 3
		mostrar_mensaje("¡Empate!")
		print("🤝 Empate en ronda %d" % ronda_actual)

	# Guardar resultado
	match ronda_actual:
		1: resultado_ronda_1 = ganador
		2: resultado_ronda_2 = ganador
		3: resultado_ronda_3 = ganador

	# Esperar y pasar a la siguiente ronda
	await get_tree().create_timer(2.0).timeout
	siguiente_ronda()

func siguiente_ronda():
	# Verificar si la mano ya está decidida
	if verificar_mano_terminada():
		return

	# Limpiar cartas de la mesa
	if carta_jugada_jugador:
		carta_jugada_jugador.queue_free()
		carta_jugada_jugador = null
	if carta_jugada_muerte:
		carta_jugada_muerte.queue_free()
		carta_jugada_muerte = null

	# Mostrar placeholders de nuevo
	if placeholder_jugador:
		placeholder_jugador.visible = true
	if placeholder_muerte:
		placeholder_muerte.visible = true

	# Siguiente ronda
	ronda_actual += 1

	if ronda_actual > 3:
		resolver_mano()
		return

	# Reactivar cartas del jugador
	for c in cartas_jugador:
		c.hacer_clickeable(true)

	# Determinar quién empieza según quién ganó la ronda anterior
	var resultado_ronda_anterior = 0
	if ronda_actual == 2:
		resultado_ronda_anterior = resultado_ronda_1
	elif ronda_actual == 3:
		resultado_ronda_anterior = resultado_ronda_2

	# El que ganó la ronda anterior empieza
	if resultado_ronda_anterior == 1:
		es_turno_jugador = true  # Jugador ganó, empieza
	elif resultado_ronda_anterior == 2:
		es_turno_jugador = false  # Muerte ganó, empieza ella
	else:
		# Empate o primera ronda: empieza el mano
		es_turno_jugador = es_mano_jugador

	# Si no es turno del jugador, la Muerte juega primero
	if not es_turno_jugador:
		mostrar_mensaje("Ronda %d - Turno de la Muerte (ganó la anterior)" % ronda_actual)
		await get_tree().create_timer(1.0).timeout
		turno_muerte()
	else:
		mostrar_mensaje("Ronda %d - Tu turno (ganaste la anterior)" % ronda_actual)

func verificar_mano_terminada() -> bool:
	# Contar rondas ganadas
	var rondas_jugador = 0
	var rondas_muerte = 0

	for resultado in [resultado_ronda_1, resultado_ronda_2, resultado_ronda_3]:
		if resultado == 1:
			rondas_jugador += 1
		elif resultado == 2:
			rondas_muerte += 1

	# Si alguien ganó 2 rondas, la mano está decidida
	if rondas_jugador >= 2:
		print("🏆 Jugador gana la mano!")
		resolver_mano_ganada(1)
		return true
	elif rondas_muerte >= 2:
		print("💀 Muerte gana la mano!")
		resolver_mano_ganada(2)
		return true

	return false

func resolver_mano():
	# Contar rondas ganadas (sin contar empates)
	var rondas_jugador = 0
	var rondas_muerte = 0

	for resultado in [resultado_ronda_1, resultado_ronda_2, resultado_ronda_3]:
		if resultado == 1:
			rondas_jugador += 1
		elif resultado == 2:
			rondas_muerte += 1

	# Determinar ganador
	if rondas_jugador > rondas_muerte:
		resolver_mano_ganada(1)
	elif rondas_muerte > rondas_jugador:
		resolver_mano_ganada(2)
	else:
		# En caso de empate total, gana el que ganó la primera ronda
		if resultado_ronda_1 == 1:
			resolver_mano_ganada(1)
		elif resultado_ronda_1 == 2:
			resolver_mano_ganada(2)
		else:
			# Si la primera fue empate, no gana nadie
			mostrar_mensaje("Mano empatada - No hay puntos")
			await get_tree().create_timer(2.0).timeout
			iniciar_nueva_mano()

func resolver_mano_ganada(ganador: int):
	if ganador == 1:
		puntos_jugador += puntos_en_juego
		mostrar_mensaje("¡Ganaste %d punto(s)!" % puntos_en_juego)
		es_mano_jugador = true  # Jugador es mano en la siguiente
	else:
		puntos_muerte += puntos_en_juego
		mostrar_mensaje("Muerte gana %d punto(s)" % puntos_en_juego)
		es_mano_jugador = false  # Muerte es mano en la siguiente

	actualizar_ui()

	# Verificar victoria
	await get_tree().create_timer(2.0).timeout
	if await verificar_victoria():
		return

	# Nueva mano
	iniciar_nueva_mano()
#endregion

#region CALLBACK BOTONES
func _on_envido_pressed():
	if envido_ya_cantado:
		mostrar_mensaje("El envido ya fue cantado")
		return

	if ronda_actual > 1:
		mostrar_mensaje("No se puede cantar envido después de la primera carta")
		return

	cantar_envido_jugador()

func _on_truco_pressed():
	# Determinar qué cantar según el estado actual
	match estado_truco:
		EstadoTruco.NINGUNO:
			cantar_truco_jugador()
		EstadoTruco.TRUCO:
			if not truco_cantado_por_jugador:  # La Muerte cantó, puedo subir
				cantar_retruco_jugador()
		EstadoTruco.RETRUCO:
			if not truco_cantado_por_jugador:  # La Muerte cantó, puedo subir
				cantar_vale_cuatro_jugador()

func _on_mazo_pressed():
	print("🚪 Jugador se va al mazo")
	irse_al_mazo_jugador()
#endregion

#region SISTEMA DE ENVIDO
func calcular_envido(cartas: Array) -> int:
	# Agrupar cartas por palo
	var cartas_por_palo = {
		Carta.Palo.ORO: [],
		Carta.Palo.COPA: [],
		Carta.Palo.ESPADA: [],
		Carta.Palo.BASTO: []
	}

	for carta in cartas:
		cartas_por_palo[carta.palo].append(carta)

	var max_envido = 0

	# Para cada palo, calcular envido
	for palo in cartas_por_palo:
		var cartas_palo = cartas_por_palo[palo]

		if cartas_palo.size() >= 2:
			# Ordenar por valor de envido (descendente)
			cartas_palo.sort_custom(func(a, b): return a.obtener_valor_envido() > b.obtener_valor_envido())

			# Tomar las 2 más altas
			var valor1 = cartas_palo[0].obtener_valor_envido()
			var valor2 = cartas_palo[1].obtener_valor_envido()

			var envido = 20 + valor1 + valor2
			max_envido = max(max_envido, envido)
		elif cartas_palo.size() == 1:
			# Solo 1 carta de este palo
			var valor = cartas_palo[0].obtener_valor_envido()
			max_envido = max(max_envido, valor)

	return max_envido

func calcular_puntos_falta_envido(es_para_jugador: bool) -> int:
	# Falta envido vale los puntos que le faltan al OPONENTE para ganar
	if es_para_jugador:
		# Si el jugador gana, recibe lo que le falta a la Muerte
		return PUNTOS_PARA_GANAR - puntos_muerte
	else:
		# Si la Muerte gana, recibe lo que le falta al jugador
		return PUNTOS_PARA_GANAR - puntos_jugador

func ocultar_botones_respuesta_envido():
	if btn_envido_envido:
		btn_envido_envido.visible = false
	if btn_real_envido:
		btn_real_envido.visible = false
	if btn_falta_envido:
		btn_falta_envido.visible = false
	if btn_quiero:
		btn_quiero.visible = false
	if btn_no_quiero:
		btn_no_quiero.visible = false

func mostrar_botones_respuesta_envido():
	# Mostrar opciones según el estado actual
	var puede_subir_envido = estado_envido == EstadoEnvido.ENVIDO
	var puede_subir_real = estado_envido <= EstadoEnvido.ENVIDO_ENVIDO

	if btn_envido_envido and puede_subir_envido:
		btn_envido_envido.visible = true
	if btn_real_envido and puede_subir_real:
		btn_real_envido.visible = true
	if btn_falta_envido:
		btn_falta_envido.visible = true
	if btn_quiero:
		btn_quiero.visible = true
	if btn_no_quiero:
		btn_no_quiero.visible = true

# JUGADOR CANTA ENVIDO
func cantar_envido_jugador():
	print("🗣️ Jugador canta: ¡ENVIDO!")
	estado_envido = EstadoEnvido.ENVIDO
	envido_cantado_por_jugador = true
	puntos_envido_en_juego = 2
	envido_ya_cantado = true

	mostrar_mensaje("¡ENVIDO! (2 puntos) - Tenés: %d" % puntos_envido_jugador)

	# Ocultar botón de envido principal
	if btn_envido:
		btn_envido.visible = false

	# Esperar respuesta de la Muerte
	await get_tree().create_timer(1.0).timeout
	muerte_responde_envido()

func _on_envido_envido_pressed():
	print("🗣️ Jugador responde: ¡ENVIDO!")
	estado_envido = EstadoEnvido.ENVIDO_ENVIDO
	envido_cantado_por_jugador = true
	puntos_envido_en_juego = 4

	mostrar_mensaje("¡ENVIDO! (4 puntos en total)")
	ocultar_botones_respuesta_envido()

	await get_tree().create_timer(1.0).timeout
	muerte_responde_envido()

func _on_real_envido_pressed():
	print("🗣️ Jugador responde: ¡REAL ENVIDO!")
	estado_envido = EstadoEnvido.REAL_ENVIDO
	envido_cantado_por_jugador = true

	# Calcular puntos según lo que ya estaba en juego
	if puntos_envido_en_juego == 2:  # Solo había envido
		puntos_envido_en_juego = 5  # 2 + 3
	elif puntos_envido_en_juego == 4:  # Había envido-envido
		puntos_envido_en_juego = 7  # 4 + 3

	mostrar_mensaje("¡REAL ENVIDO! (%d puntos en total)" % puntos_envido_en_juego)
	ocultar_botones_respuesta_envido()

	await get_tree().create_timer(1.0).timeout
	muerte_responde_envido()

func _on_falta_envido_pressed():
	print("🗣️ Jugador responde: ¡FALTA ENVIDO!")
	estado_envido = EstadoEnvido.FALTA_ENVIDO
	envido_cantado_por_jugador = true

	var puntos_falta = calcular_puntos_falta_envido(true)
	mostrar_mensaje("¡FALTA ENVIDO! (Vale %d puntos)" % puntos_falta)
	ocultar_botones_respuesta_envido()

	await get_tree().create_timer(1.0).timeout
	muerte_responde_envido()

func _on_quiero_envido_pressed():
	print("🗣️ Jugador: ¡Quiero!")
	ocultar_botones_respuesta_envido()
	await resolver_envido()

	# Si la Muerte fue quien cantó el envido y aún no jugó carta, debe jugarla
	if not envido_cantado_por_jugador and not es_turno_jugador and not carta_jugada_muerte:
		await get_tree().create_timer(1.0).timeout
		turno_muerte()

func _on_no_quiero_envido_pressed():
	print("🗣️ Jugador: No quiero")
	ocultar_botones_respuesta_envido()

	# El jugador rechaza, la Muerte gana los puntos anteriores
	var puntos_ganados = calcular_puntos_rechazo_envido()
	mostrar_mensaje("No querés - Muerte gana %d punto(s)" % puntos_ganados)
	puntos_muerte += puntos_ganados
	actualizar_ui()

	# Si la Muerte fue quien cantó el envido y aún no jugó carta, debe jugarla
	if not envido_cantado_por_jugador and not es_turno_jugador and not carta_jugada_muerte:
		await get_tree().create_timer(1.0).timeout
		turno_muerte()

func calcular_puntos_rechazo_envido() -> int:
	# Cuando rechazás, el que cantó gana los puntos del canto ANTERIOR
	match estado_envido:
		EstadoEnvido.ENVIDO:
			return 1  # Rechazás envido, pierde 1
		EstadoEnvido.ENVIDO_ENVIDO:
			return 2  # Rechazás envido-envido, pierdes 2 (el envido anterior)
		EstadoEnvido.REAL_ENVIDO:
			if puntos_envido_en_juego == 5:  # Era envido + real
				return 2
			else:  # Era envido-envido + real
				return 4
		EstadoEnvido.FALTA_ENVIDO:
			# Rechazar falta envido da los puntos acumulados hasta ese momento
			return puntos_envido_en_juego
	return 1

# IA: MUERTE RESPONDE AL ENVIDO
func muerte_responde_envido():
	# Preparar contexto para la IA
	var fuerza_mano = IAMuerte.evaluar_fuerza_mano(cartas_muerte)
	var contexto = {
		"puntos_envido_muerte": puntos_envido_muerte,
		"puntos_muerte": puntos_muerte,
		"puntos_jugador": puntos_jugador,
		"puntos_para_ganar": PUNTOS_PARA_GANAR,
		"estado_envido": int(estado_envido),
		"puntos_envido_en_juego": puntos_envido_en_juego,
		"fuerza_mano": fuerza_mano,
		"ronda_actual": ronda_actual
	}

	# Usar IA para decidir respuesta
	var respuesta = IAMuerte.responder_envido(contexto)

	if respuesta == "envido":
		muerte_sube_envido("envido")
	elif respuesta == "real_envido":
		muerte_sube_envido("real_envido")
	elif respuesta == "falta_envido":
		muerte_sube_envido("falta_envido")
	elif respuesta == "quiero":
		print("💀 Muerte: ¡Quiero!")
		mostrar_mensaje("Muerte acepta")
		await get_tree().create_timer(1.0).timeout
		await resolver_envido()
	else:  # no_quiero
		# Rechaza
		var puntos_ganados = calcular_puntos_rechazo_envido()
		print("💀 Muerte: No quiero")
		mostrar_mensaje("Muerte rechaza - Ganás %d punto(s)" % puntos_ganados)
		puntos_jugador += puntos_ganados
		actualizar_ui()

func muerte_sube_envido(tipo: String):
	if tipo == "envido":
		print("💀 Muerte: ¡ENVIDO!")
		estado_envido = EstadoEnvido.ENVIDO_ENVIDO
		puntos_envido_en_juego = 4
		envido_cantado_por_jugador = false
		mostrar_mensaje("Muerte dice: ¡ENVIDO! (4 puntos en total)")
	elif tipo == "real_envido":
		print("💀 Muerte: ¡REAL ENVIDO!")
		estado_envido = EstadoEnvido.REAL_ENVIDO
		envido_cantado_por_jugador = false

		if puntos_envido_en_juego == 2:
			puntos_envido_en_juego = 5
		elif puntos_envido_en_juego == 4:
			puntos_envido_en_juego = 7

		mostrar_mensaje("Muerte dice: ¡REAL ENVIDO! (%d puntos)" % puntos_envido_en_juego)
	elif tipo == "falta_envido":
		print("💀 Muerte: ¡FALTA ENVIDO!")
		estado_envido = EstadoEnvido.FALTA_ENVIDO
		envido_cantado_por_jugador = false
		var puntos_falta = calcular_puntos_falta_envido(false)
		mostrar_mensaje("Muerte dice: ¡FALTA ENVIDO! (%d puntos)" % puntos_falta)

	await get_tree().create_timer(1.5).timeout
	mostrar_botones_respuesta_envido()

func resolver_envido():
	var puntos_a_otorgar = puntos_envido_en_juego

	# Si es falta envido, calcular los puntos correctos
	if estado_envido == EstadoEnvido.FALTA_ENVIDO:
		# Los puntos ya están calculados, pero hay que determinar quién gana
		pass

	mostrar_mensaje("Jugador: %d | Muerte: %d" % [puntos_envido_jugador, puntos_envido_muerte])
	await get_tree().create_timer(2.0).timeout

	# Comparar puntos
	if puntos_envido_jugador > puntos_envido_muerte:
		if estado_envido == EstadoEnvido.FALTA_ENVIDO:
			puntos_a_otorgar = calcular_puntos_falta_envido(true)
		print("✅ Jugador gana el envido!")
		mostrar_mensaje("¡Ganás el envido! (+%d puntos)" % puntos_a_otorgar)
		puntos_jugador += puntos_a_otorgar
	elif puntos_envido_muerte > puntos_envido_jugador:
		if estado_envido == EstadoEnvido.FALTA_ENVIDO:
			puntos_a_otorgar = calcular_puntos_falta_envido(false)
		print("💀 Muerte gana el envido")
		mostrar_mensaje("Muerte gana el envido (+%d puntos)" % puntos_a_otorgar)
		puntos_muerte += puntos_a_otorgar
	else:
		# Empate - gana el mano
		if estado_envido == EstadoEnvido.FALTA_ENVIDO:
			puntos_a_otorgar = calcular_puntos_falta_envido(es_mano_jugador)
		if es_mano_jugador:
			print("🤝 Empate - Gana el mano (Jugador)")
			mostrar_mensaje("Empate - Ganás vos (sos mano) (+%d puntos)" % puntos_a_otorgar)
			puntos_jugador += puntos_a_otorgar
		else:
			print("🤝 Empate - Gana el mano (Muerte)")
			mostrar_mensaje("Empate - Gana Muerte (es mano) (+%d puntos)" % puntos_a_otorgar)
			puntos_muerte += puntos_a_otorgar

	actualizar_ui()
#endregion

#region SISTEMA DE TRUCO
func cantar_truco_jugador():
	print("🗣️ Jugador canta: ¡TRUCO!")
	estado_truco = EstadoTruco.TRUCO
	truco_cantado_por_jugador = true
	mostrar_mensaje("¡TRUCO! (Vale 2 puntos)")

	# Desactivar botón mientras espera respuesta
	btn_truco.disabled = true

	# Esperar y que la Muerte responda
	await get_tree().create_timer(1.0).timeout
	muerte_responde_truco()

func cantar_retruco_jugador():
	print("🗣️ Jugador canta: ¡RETRUCO!")
	estado_truco = EstadoTruco.RETRUCO
	truco_cantado_por_jugador = true
	mostrar_mensaje("¡RETRUCO! (Vale 3 puntos)")

	btn_truco.disabled = true

	await get_tree().create_timer(1.0).timeout
	muerte_responde_retruco()

func cantar_vale_cuatro_jugador():
	print("🗣️ Jugador canta: ¡VALE CUATRO!")
	estado_truco = EstadoTruco.VALE_CUATRO
	truco_cantado_por_jugador = true
	mostrar_mensaje("¡VALE CUATRO! (Vale 4 puntos)")

	btn_truco.disabled = true

	await get_tree().create_timer(1.0).timeout
	muerte_responde_vale_cuatro()

func muerte_responde_truco():
	# Preparar contexto para la IA
	var contexto = {
		"ronda_actual": ronda_actual,
		"resultado_ronda_1": resultado_ronda_1,
		"resultado_ronda_2": resultado_ronda_2,
		"puntos_jugador": puntos_jugador,
		"puntos_muerte": puntos_muerte,
		"puntos_para_ganar": PUNTOS_PARA_GANAR,
		"estado_truco": int(estado_truco),
		"puntos_en_juego": puntos_en_juego
	}

	# Usar IA para decidir respuesta
	var respuesta = IAMuerte.responder_truco(cartas_muerte, contexto)

	if respuesta == "retruco":
		print("💀 Muerte: ¡RETRUCO!")
		estado_truco = EstadoTruco.RETRUCO
		truco_cantado_por_jugador = false
		mostrar_mensaje("Muerte dice: ¡RETRUCO! (Vale 3 puntos)")
		puntos_en_juego = 3

		# Actualizar botón para que jugador pueda decir Vale Cuatro
		await get_tree().create_timer(1.5).timeout
		btn_truco.text = "VALE 4"
		btn_truco.disabled = false

	elif respuesta == "quiero":
		print("💀 Muerte: Quiero")
		mostrar_mensaje("Muerte acepta el Truco")
		puntos_en_juego = 2
		btn_truco.disabled = true

	else:  # no_quiero
		print("💀 Muerte: No quiero")
		mostrar_mensaje("Muerte rechaza - Ganás 1 punto")
		puntos_jugador += 1
		actualizar_ui()
		await get_tree().create_timer(2.0).timeout
		iniciar_nueva_mano()

func muerte_responde_retruco():
	# Preparar contexto para la IA
	var contexto = {
		"ronda_actual": ronda_actual,
		"resultado_ronda_1": resultado_ronda_1,
		"resultado_ronda_2": resultado_ronda_2,
		"puntos_jugador": puntos_jugador,
		"puntos_muerte": puntos_muerte,
		"puntos_para_ganar": PUNTOS_PARA_GANAR,
		"estado_truco": int(estado_truco),
		"puntos_en_juego": puntos_en_juego
	}

	# Usar IA para decidir respuesta
	var respuesta = IAMuerte.responder_truco(cartas_muerte, contexto)

	if respuesta == "vale_cuatro":
		print("💀 Muerte: ¡VALE CUATRO!")
		estado_truco = EstadoTruco.VALE_CUATRO
		truco_cantado_por_jugador = false
		mostrar_mensaje("Muerte dice: ¡VALE CUATRO! (Vale 4 puntos)")
		puntos_en_juego = 4
		btn_truco.disabled = true

	elif respuesta == "quiero":
		print("💀 Muerte: Quiero")
		mostrar_mensaje("Muerte acepta el Retruco")
		puntos_en_juego = 3
		btn_truco.disabled = true

		# Si la Muerte estaba en su turno y aún no jugó carta, debe jugarla
		if not es_turno_jugador and not carta_jugada_muerte:
			await get_tree().create_timer(1.0).timeout
			turno_muerte()

	else:  # no_quiero
		print("💀 Muerte: No quiero")
		mostrar_mensaje("Muerte rechaza - Ganás 2 puntos")
		puntos_jugador += 2
		actualizar_ui()
		await get_tree().create_timer(2.0).timeout
		iniciar_nueva_mano()

func muerte_responde_vale_cuatro():
	# Preparar contexto para la IA
	var contexto = {
		"ronda_actual": ronda_actual,
		"resultado_ronda_1": resultado_ronda_1,
		"resultado_ronda_2": resultado_ronda_2,
		"puntos_jugador": puntos_jugador,
		"puntos_muerte": puntos_muerte,
		"puntos_para_ganar": PUNTOS_PARA_GANAR,
		"estado_truco": int(estado_truco),
		"puntos_en_juego": puntos_en_juego
	}

	# Usar IA para decidir respuesta
	var respuesta = IAMuerte.responder_truco(cartas_muerte, contexto)

	if respuesta == "no_quiero":
		print("💀 Muerte: No quiero")
		mostrar_mensaje("Muerte rechaza - Ganás 3 puntos")
		puntos_jugador += 3
		actualizar_ui()
		await get_tree().create_timer(2.0).timeout
		iniciar_nueva_mano()
	else:  # quiero (no puede subir más)
		print("💀 Muerte: Quiero")
		mostrar_mensaje("Muerte acepta el Vale Cuatro")
		puntos_en_juego = 4
		btn_truco.disabled = true

		# Si la Muerte estaba en su turno y aún no jugó carta, debe jugarla
		if not es_turno_jugador and not carta_jugada_muerte:
			await get_tree().create_timer(1.0).timeout
			turno_muerte()

func irse_al_mazo_jugador():
	# Calcular cuántos puntos gana la Muerte según el estado del truco
	var puntos_ganados = 1

	match estado_truco:
		EstadoTruco.NINGUNO:
			puntos_ganados = 1
		EstadoTruco.TRUCO:
			puntos_ganados = 1 if truco_cantado_por_jugador else 2
		EstadoTruco.RETRUCO:
			puntos_ganados = 2 if truco_cantado_por_jugador else 3
		EstadoTruco.VALE_CUATRO:
			puntos_ganados = 3 if truco_cantado_por_jugador else 4

	mostrar_mensaje("Te fuiste al mazo - Muerte gana %d punto(s)" % puntos_ganados)
	puntos_muerte += puntos_ganados
	actualizar_ui()

	await get_tree().create_timer(2.0).timeout

	if await verificar_victoria():
		return

	iniciar_nueva_mano()
#endregion

#region VICTORIA
func verificar_victoria() -> bool:
	if puntos_jugador >= PUNTOS_PARA_GANAR:
		await victoria_jugador()
		return true
	elif puntos_muerte >= PUNTOS_PARA_GANAR:
		await derrota_jugador()
		return true
	return false

func victoria_jugador():
	print("🎉 ¡GANASTE! La Muerte cumple su palabra...")
	mostrar_mensaje("¡VICTORIA! Vivís para contar la historia")
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/felicitaciones/felicitaciones.tscn")

func derrota_jugador():
	print("💀 Perdiste... Te toca cebar mate en el más allá")
	mostrar_mensaje("DERROTA - La Muerte gana")
	await get_tree().create_timer(3.0).timeout
	get_tree().quit()
#endregion
