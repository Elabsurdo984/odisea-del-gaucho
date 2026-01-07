extends Node
class_name TrucoController

# ============================================================
# REFERENCIAS A SISTEMAS (Hijos o Hermanos)
# ============================================================
@onready var state: TrucoState = $"../TrucoState"
@onready var rules: TrucoRules = $"../TrucoRules"
@onready var envido_sys: EnvidoSystem = $"../EnvidoSystem"
@onready var betting: TrucoBetting = $"../TrucoBetting"
@onready var ui: TrucoUI = $"../TrucoUI"
@onready var ai: AIMuerte = $"../AIMuerte"

# ============================================================
# VARIABLES INTERNAS
# ============================================================
var deck: Deck
var es_turno_jugador: bool = true

# ============================================================
# LIFECYCLE
# ============================================================
func _ready() -> void:
	deck = Deck.new()
	conectar_senales()
	comenzar_nueva_mano()

func conectar_senales() -> void:
	# Conexiones de UI (Botones y Cartas)
	ui.boton_envido_presionado.connect(_on_ui_envido)
	ui.boton_truco_presionado.connect(_on_ui_truco)
	ui.carta_jugada.connect(_on_player_jugar_carta)
	
	# Conexiones de Sistemas
	ai.accion_tomada.connect(_on_ai_accion)
	envido_sys.envido_resuelto.connect(_on_envido_resuelto)
	betting.apuesta_aceptada.connect(_on_apuesta_aceptada)
	betting.apuesta_rechazada.connect(_on_apuesta_rechazada)

# ============================================================
# FLUJO DE JUEGO
# ============================================================
func comenzar_nueva_mano() -> void:
	state.resetear_mano()
	betting.resetear_apuestas()
	envido_sys.puntos_acumulados = 0
	
	# Lógica de Mazo
	deck.reiniciar()
	deck.barajar()
	
	state.cartas_jugador = deck.repartir(3)
	state.cartas_muerte = deck.repartir(3)
	
	# Actualizar UI
	ui.actualizar_puntos(state.puntos_jugador, state.puntos_muerte)
	ui.mostrar_cartas_jugador(state.cartas_jugador)
	ui.limpiar_mesa()
	
	# Iniciar turno (Por ahora siempre empieza jugador para simplificar)
	es_turno_jugador = true
	iniciar_turno()

func iniciar_turno() -> void:
	if es_turno_jugador:
		ui.habilitar_controles(state, betting)
		ui.mostrar_mensaje("Tu turno")
	else:
		ui.deshabilitar_controles()
		ui.mostrar_mensaje("Turno de La Muerte...")
		# Pequeña pausa dramática antes de que la IA piense
		await get_tree().create_timer(1.0).timeout
		ai.ejecutar_turno()

# ============================================================
# ACCIONES DE JUEGO (JUGAR CARTA)
# ============================================================
func _on_player_jugar_carta(carta: Carta) -> void:
	if not es_turno_jugador:
		return
	procesar_jugada("jugador", carta)

func procesar_jugada(quien: String, carta: Carta) -> void:
	# 1. Visual y Estado
	ui.animar_carta_a_mesa(carta, quien)
	
	if quien == "jugador":
		state.carta_jugada_jugador = carta
		es_turno_jugador = false
	else:
		state.carta_jugada_muerte = carta
		es_turno_jugador = true
	
	# 2. Verificar si ambos jugaron para cerrar ronda
	if state.carta_jugada_jugador != null and state.carta_jugada_muerte != null:
		await get_tree().create_timer(1.0).timeout
		finalizar_ronda()
	else:
		iniciar_turno()

func finalizar_ronda() -> void:
	# 1. Determinar ganador
	var ganador = rules.determinar_ganador_ronda(
		state.carta_jugada_jugador, 
		state.carta_jugada_muerte
	)
	state.registrar_resultado_ronda(ganador)
	
	ui.mostrar_resultado_ronda(ganador)
	
	# 2. Limpiar cartas de mesa en estado (no visuales aun)
	state.carta_jugada_jugador = null
	state.carta_jugada_muerte = null
	
	# 3. Verificar fin de mano
	if rules.es_fin_de_mano(state.resultados_rondas, state.ronda_actual):
		finalizar_mano()
	else:
		# Regla: El que gana la ronda, empieza la siguiente
		if ganador == TrucoRules.GANADOR_MUERTE:
			es_turno_jugador = false
		else:
			es_turno_jugador = true
		
		iniciar_turno()

func finalizar_mano() -> void:
	# 1. Calcular puntos Truco
	var ganador_mano = rules.determinar_ganador_mano(state.resultados_rondas)
	var puntos = betting.puntos_en_juego
	
	if ganador_mano == TrucoRules.GANADOR_JUGADOR:
		state.agregar_puntos_jugador(puntos)
		ui.mostrar_mensaje("¡Ganaste la mano!")
	elif ganador_mano == TrucoRules.GANADOR_MUERTE:
		state.agregar_puntos_muerte(puntos)
		ui.mostrar_mensaje("La Muerte gana la mano")
	
	# 2. Verificar fin de partida
	if state.puntos_jugador >= 15 or state.puntos_muerte >= 15:
		game_over()
	else:
		await get_tree().create_timer(2.0).timeout
		comenzar_nueva_mano()

# ============================================================
# MANEJO DE IA
# ============================================================
func _on_ai_accion(accion: Dictionary) -> void:
	match accion.tipo:
		"jugar_carta":
			procesar_jugada("muerte", accion.carta)
		"cantar_envido":
			envido_sys.cantar_envido(accion.tipo_envido, "muerte")
			ui.mostrar_dialogo_respuesta("envido")
		"cantar_truco":
			betting.cantar_truco("muerte")
			ui.mostrar_dialogo_respuesta("truco")
		"irse_al_mazo":
			state.agregar_puntos_jugador(betting.puntos_en_juego)
			finalizar_mano()

# ============================================================
# MANEJO DE APUESTAS (UI -> Controller -> Systems)
# ============================================================
func _on_ui_envido() -> void:
	envido_sys.cantar_envido(EnvidoSystem.TipoEnvido.ENVIDO, "jugador")
	# Aquí la IA debería responder (Quiero/No Quiero)
	# Por ahora simulamos respuesta directa o llamar a una funcion de IA "responder_envido"
	pass

func _on_ui_truco() -> void:
	betting.cantar_truco("jugador")
	# IA responde
	pass

func _on_envido_resuelto(ganador: String, puntos: int) -> void:
	if ganador == "jugador":
		state.agregar_puntos_jugador(puntos)
	else:
		state.agregar_puntos_muerte(puntos)
	ui.actualizar_puntos(state.puntos_jugador, state.puntos_muerte)

func _on_apuesta_aceptada() -> void:
	# Lógica cuando se acepta una apuesta (truco/retruco)
	pass

func _on_apuesta_rechazada() -> void:
	# Lógica cuando se rechaza una apuesta
	pass

func game_over() -> void:
	print("FIN DEL JUEGO")
	# Llamar a SceneManager para ir a creditos o menu
