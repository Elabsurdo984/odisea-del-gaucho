# truco.gd
# Juego de truco argentino contra la Muerte
extends Control

# ==================== RECURSOS ====================
const CARTA_SCENE = preload("res://scenes/truco/carta.tscn")

# ==================== REFERENCIAS ====================
@onready var jugador_cartas_container = $JugadorCartas
@onready var muerte_cartas_container = $MuerteCartas
@onready var mesa_jugador = $Mesa/CartaJugador
@onready var mesa_muerte = $Mesa/CartaMuerte
@onready var placeholder_jugador = $Mesa/CartaJugador/Placeholder
@onready var placeholder_muerte = $Mesa/CartaMuerte/Placeholder

@onready var puntos_jugador_label = $UI/PuntosPanel/PuntosJugador
@onready var puntos_muerte_label = $UI/PuntosPanel/PuntosMuerte

@onready var btn_envido = $UI/BotonesPanel/BtnEnvido
@onready var btn_truco = $UI/BotonesPanel/BtnTruco
@onready var btn_mazo = $UI/BotonesPanel/BtnMazo

@onready var mensaje_label = $UI/MensajeLabel

@onready var gaucho_sprite = $Personajes/Gaucho
@onready var muerte_sprite = $Personajes/Muerte

# ==================== CONFIGURACIÓN ====================
const PUNTOS_PARA_GANAR = 1

# ==================== ESTADO DEL JUEGO ====================
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
var envido_ya_cantado := false
var puntos_envido_jugador := 0
var puntos_envido_muerte := 0

# Mano (quién empieza)
var es_mano_jugador := true  # Al inicio, el jugador es mano

# ==================== INICIALIZACIÓN ====================
func _ready():
	print("🎴 Iniciando partida de truco contra la Muerte...")

	# Conectar botones
	if btn_envido:
		btn_envido.pressed.connect(_on_envido_pressed)
	if btn_truco:
		btn_truco.pressed.connect(_on_truco_pressed)
	if btn_mazo:
		btn_mazo.pressed.connect(_on_mazo_pressed)

	# Iniciar partida
	await get_tree().create_timer(1.0).timeout
	iniciar_nueva_mano()

# ==================== FLUJO DEL JUEGO ====================
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
	envido_ya_cantado = false
	if btn_envido:
		btn_envido.disabled = false  # Habilitar envido para nueva mano

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

# ==================== TURNO DE LA MUERTE ====================
func turno_muerte():
	mostrar_mensaje("Turno de la Muerte...")

	# IA simple: jugar carta aleatoria por ahora
	if cartas_muerte.is_empty():
		push_error("❌ La Muerte no tiene cartas!")
		return

	var carta = cartas_muerte[randi() % cartas_muerte.size()]
	jugar_carta_muerte(carta)

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

# ==================== COMPARACIÓN Y RESOLUCIÓN ====================
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

# ==================== CALLBACKS BOTONES ====================
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

# ==================== SISTEMA DE ENVIDO ====================
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

func cantar_envido_jugador():
	print("🗣️ Jugador canta: ¡ENVIDO!")
	envido_ya_cantado = true
	mostrar_mensaje("¡ENVIDO! (Vale 2 puntos) - Tenés: %d" % puntos_envido_jugador)

	# Desactivar botón
	btn_envido.disabled = true

	# Esperar y que la Muerte responda
	await get_tree().create_timer(1.0).timeout
	muerte_responde_envido()

func muerte_responde_envido():
	# IA: Si tiene 25+ puntos, acepta. Si no, 50% de probabilidad
	var acepta = puntos_envido_muerte >= 25 or randf() < 0.5

	if acepta:
		print("💀 Muerte: ¡Quiero!")
		mostrar_mensaje("Muerte acepta - Tiene: %d" % puntos_envido_muerte)

		await get_tree().create_timer(1.5).timeout

		# Comparar puntos
		if puntos_envido_jugador > puntos_envido_muerte:
			print("✅ Jugador gana el envido!")
			mostrar_mensaje("¡Ganás el envido! (+2 puntos)")
			puntos_jugador += 2
		elif puntos_envido_muerte > puntos_envido_jugador:
			print("💀 Muerte gana el envido")
			mostrar_mensaje("Muerte gana el envido (+2 puntos)")
			puntos_muerte += 2
		else:
			# Empate - gana el mano (jugador por ahora)
			print("🤝 Empate - Gana el mano (Jugador)")
			mostrar_mensaje("Empate - Ganás vos (sos mano) (+2 puntos)")
			puntos_jugador += 2

		actualizar_ui()
	else:
		print("💀 Muerte: No quiero")
		mostrar_mensaje("Muerte rechaza - Ganás 1 punto")
		puntos_jugador += 1
		actualizar_ui()

# ==================== SISTEMA DE TRUCO ====================
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
	# IA simple: 70% acepta, 30% rechaza
	var acepta = randf() < 0.7

	if acepta:
		# 50% chance de subir a Retruco
		if randf() < 0.5:
			print("💀 Muerte: ¡RETRUCO!")
			estado_truco = EstadoTruco.RETRUCO
			truco_cantado_por_jugador = false
			mostrar_mensaje("Muerte dice: ¡RETRUCO! (Vale 3 puntos)")
			puntos_en_juego = 3

			# Actualizar botón para que jugador pueda decir Vale Cuatro
			await get_tree().create_timer(1.5).timeout
			btn_truco.text = "VALE 4"
			btn_truco.disabled = false
		else:
			print("💀 Muerte: Quiero")
			mostrar_mensaje("Muerte acepta el Truco")
			puntos_en_juego = 2
			btn_truco.disabled = true
	else:
		print("💀 Muerte: No quiero")
		mostrar_mensaje("Muerte rechaza - Ganás 1 punto")
		puntos_jugador += 1
		actualizar_ui()
		await get_tree().create_timer(2.0).timeout
		iniciar_nueva_mano()

func muerte_responde_retruco():
	# IA simple: 60% acepta, 40% rechaza
	var acepta = randf() < 0.6

	if acepta:
		# 30% chance de subir a Vale Cuatro
		if randf() < 0.3:
			print("💀 Muerte: ¡VALE CUATRO!")
			estado_truco = EstadoTruco.VALE_CUATRO
			truco_cantado_por_jugador = false
			mostrar_mensaje("Muerte dice: ¡VALE CUATRO! (Vale 4 puntos)")
			puntos_en_juego = 4
			btn_truco.disabled = true
		else:
			print("💀 Muerte: Quiero")
			mostrar_mensaje("Muerte acepta el Retruco")
			puntos_en_juego = 3
			btn_truco.disabled = true
	else:
		print("💀 Muerte: No quiero")
		mostrar_mensaje("Muerte rechaza - Ganás 2 puntos")
		puntos_jugador += 2
		actualizar_ui()
		await get_tree().create_timer(2.0).timeout
		iniciar_nueva_mano()

func muerte_responde_vale_cuatro():
	# IA simple: 50% acepta, 50% rechaza
	var acepta = randf() < 0.5

	if acepta:
		print("💀 Muerte: Quiero")
		mostrar_mensaje("Muerte acepta el Vale Cuatro")
		puntos_en_juego = 4
		btn_truco.disabled = true
	else:
		print("💀 Muerte: No quiero")
		mostrar_mensaje("Muerte rechaza - Ganás 3 puntos")
		puntos_jugador += 3
		actualizar_ui()
		await get_tree().create_timer(2.0).timeout
		iniciar_nueva_mano()

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

# ==================== VICTORIA ====================
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
