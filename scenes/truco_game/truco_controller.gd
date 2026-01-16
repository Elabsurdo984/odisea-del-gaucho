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

var deck: Deck
var es_turno_jugador: bool = true
var estado_respuesta_pendiente: String = "" # "envido", "truco", ""

# ============================================================
# PRIVATE VARIABLES
# ============================================================
var _puntos_ganar: int = 15


# ============================================================
# LIFECYCLE
# ============================================================
func _ready() -> void:
	# Inyectar dependencias en la IA
	ai.truco_state = state
	ai.truco_betting = betting

	# Cargar estado guardado si existe (puntos anteriores)
	if SaveManager:
		var loaded_data = SaveManager.consume_pending_truco_state()
		if not loaded_data.is_empty():
			state.puntos_jugador = loaded_data.get("puntos_jugador", 0)
			state.puntos_muerte = loaded_data.get("puntos_muerte", 0)
			print("🃏 Truco: Puntos restaurados - Jugador: ", state.puntos_jugador, " | Muerte: ", state.puntos_muerte)

	deck = Deck.new()
	conectar_senales()
	comenzar_nueva_mano()

	# Mostrar comandos de debug si estamos en modo debug
	if OS.is_debug_build():
		print("🔧 COMANDOS DEBUG TRUCO:")
		print("   [F9] - Ganar instantáneamente")
		print("   [F10] - Perder instantáneamente")
		print("   [F11] - +10 puntos al jugador")

func conectar_senales() -> void:
	# Conexiones de UI (Botones y Cartas)
	ui.boton_envido_presionado.connect(_on_ui_envido)
	ui.boton_truco_presionado.connect(_on_ui_truco)
	ui.boton_irse_presionado.connect(_on_ui_irse_al_mazo)
	ui.carta_jugada.connect(_on_player_jugar_carta)
	
	# Conexiones de Respuesta UI
	ui.respuesta_envido.connect(_on_player_responde_envido)
	ui.respuesta_truco.connect(_on_player_responde_truco)
	ui.contra_envido.connect(_on_player_contra_envido)
	
	# Conexiones de Sistemas
	ai.accion_tomada.connect(_on_ai_accion)
	envido_sys.envido_resuelto.connect(_on_envido_resuelto)
	# Las señales de betting ya no las usamos directamente aqui, sino la respuesta explicita
	# betting.apuesta_aceptada.connect(_on_apuesta_aceptada)

# ============================================================
# FLUJO DE JUEGO
# ============================================================
func comenzar_nueva_mano() -> void:
	state.resetear_mano()
	betting.resetear_apuestas()
	envido_sys.puntos_acumulados = 0
	estado_respuesta_pendiente = ""
	
	# Lógica de Mazo
	deck.reiniciar()
	deck.barajar()

	state.cartas_jugador = deck.repartir(3)
	state.cartas_muerte = deck.repartir(3)

	# Guardar copias de las cartas originales para calcular envido correctamente
	state.cartas_originales_jugador = state.cartas_jugador.duplicate(true)
	state.cartas_originales_muerte = state.cartas_muerte.duplicate(true)

	# Actualizar UI
	ui.actualizar_puntos(state.puntos_jugador, state.puntos_muerte)
	ui.mostrar_cartas_jugador(state.cartas_jugador)
	ui.mostrar_cartas_muerte_dorso(3)
	ui.limpiar_mesa()
	
	# Iniciar turno (Por ahora siempre empieza jugador para simplificar)
	es_turno_jugador = true
	iniciar_turno()

func iniciar_turno() -> void:
	if estado_respuesta_pendiente != "": return
	
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
# MANEJO DE JUGADAS
# ============================================================
func _on_player_jugar_carta(carta_nodo: Carta) -> void:
	if not es_turno_jugador: return
	if estado_respuesta_pendiente != "": return

	# Convertir el nodo Carta a Dictionary para trabajar con el state
	var carta_data = {
		"numero": carta_nodo.numero,
		"palo": carta_nodo.palo
	}

	# Procesar la jugada del jugador
	procesar_jugada("jugador", carta_data)

	# Remover carta de la mano del jugador (buscar y eliminar el Dictionary equivalente)
	for i in range(state.cartas_jugador.size()):
		var c = state.cartas_jugador[i]
		if c["numero"] == carta_data["numero"] and c["palo"] == carta_data["palo"]:
			state.cartas_jugador.remove_at(i)
			break

	ui.mostrar_cartas_jugador(state.cartas_jugador)

func procesar_jugada(quien: String, carta) -> void:
	# Guardar la carta jugada en el estado
	if quien == "jugador":
		state.carta_jugada_jugador = carta
		ui.mostrar_carta_mesa_jugador(carta)
		ui.mostrar_mensaje("Jugaste: %d de %s" % [carta["numero"], _nombre_palo(carta["palo"])])
		es_turno_jugador = false

		# Si ambos jugaron, evaluar la ronda
		if state.carta_jugada_muerte != null:
			await get_tree().create_timer(1.5).timeout
			evaluar_ronda()
		else:
			# Es el turno de la muerte, llamar a iniciar_turno para que juegue
			await get_tree().create_timer(0.5).timeout
			iniciar_turno()

	else:  # "muerte"
		state.carta_jugada_muerte = carta
		ui.mostrar_carta_mesa_muerte(carta)
		ui.mostrar_mensaje("La Muerte jugó: %d de %s" % [carta["numero"], _nombre_palo(carta["palo"])])
		es_turno_jugador = true

		# Remover carta de la mano de la muerte
		for i in range(state.cartas_muerte.size()):
			var c = state.cartas_muerte[i]
			if c["numero"] == carta["numero"] and c["palo"] == carta["palo"]:
				state.cartas_muerte.remove_at(i)
				break

		# Eliminar visualmente una carta del dorso de la muerte
		ui.eliminar_carta_muerte_dorso()

		# Si ambos jugaron, evaluar la ronda
		if state.carta_jugada_jugador != null:
			await get_tree().create_timer(1.5).timeout
			evaluar_ronda()

func evaluar_ronda() -> void:
	var ganador = rules.determinar_ganador_ronda(state.carta_jugada_jugador, state.carta_jugada_muerte)
	state.registrar_resultado_ronda(ganador)

	# Mostrar resultado de la ronda con duración más larga
	match ganador:
		TrucoRules.GANADOR_JUGADOR:
			ui.mostrar_mensaje("¡Ganaste la ronda %d!" % (state.ronda_actual - 1), 4.0)
		TrucoRules.GANADOR_MUERTE:
			ui.mostrar_mensaje("La Muerte ganó la ronda %d" % (state.ronda_actual - 1), 4.0)
		TrucoRules.EMPATE:
			ui.mostrar_mensaje("Ronda %d: Empate (parda)" % (state.ronda_actual - 1), 4.0)

	# Limpiar cartas jugadas
	state.carta_jugada_jugador = null
	state.carta_jugada_muerte = null

	# El ganador de la ronda juega primero en la siguiente
	match ganador:
		TrucoRules.GANADOR_JUGADOR:
			es_turno_jugador = true
		TrucoRules.GANADOR_MUERTE:
			es_turno_jugador = false
		TrucoRules.EMPATE:
			pass  # En empate, mantiene el turno actual

	# Verificar si terminó la mano
	if rules.es_fin_de_mano(state.resultados_rondas, state.ronda_actual):
		await get_tree().create_timer(2.0).timeout
		finalizar_mano()
	else:
		# Continuar con la siguiente ronda
		await get_tree().create_timer(1.0).timeout
		ui.limpiar_mesa()
		iniciar_turno()

func finalizar_mano() -> void:
	var ganador_mano = rules.determinar_ganador_mano(state.resultados_rondas)
	var puntos_ganados = betting.puntos_en_juego

	match ganador_mano:
		TrucoRules.GANADOR_JUGADOR:
			state.agregar_puntos_jugador(puntos_ganados)
			ui.mostrar_mensaje("¡Ganaste la mano! (+%d puntos)" % puntos_ganados, 5.0)
		TrucoRules.GANADOR_MUERTE:
			state.agregar_puntos_muerte(puntos_ganados)
			ui.mostrar_mensaje("La Muerte ganó la mano (+%d puntos)" % puntos_ganados, 5.0)

	ui.actualizar_puntos(state.puntos_jugador, state.puntos_muerte)

	# Verificar si alguien ganó la partida (30 puntos)
	if state.puntos_jugador >= _puntos_ganar:
		ui.mostrar_mensaje("¡VICTORIA! Derrotaste a La Muerte", 6.0)
		await get_tree().create_timer(6.0).timeout
		# Transicionar a la cinemática de victoria
		get_tree().change_scene_to_file("res://scenes/cinematics/jugador_victoria/jugador_victoria.tscn")
		return
	elif state.puntos_muerte >= _puntos_ganar:
		ui.mostrar_mensaje("DERROTA... La Muerte te venció", 3.0)
		await get_tree().create_timer(3.0).timeout
		# Transicionar a la cinemática de derrota
		get_tree().change_scene_to_file("res://scenes/cinematics/muerte_victoria/muerte_victoria.tscn")
		return

	# Continuar con nueva mano
	await get_tree().create_timer(3.0).timeout
	comenzar_nueva_mano()

func _nombre_palo(palo: int) -> String:
	match palo:
		Carta.Palo.ORO: return "Oro"
		Carta.Palo.COPA: return "Copa"
		Carta.Palo.ESPADA: return "Espada"
		Carta.Palo.BASTO: return "Basto"
	return ""


# ============================================================
# MANEJO DE IA
# ============================================================
func _on_ai_accion(accion: Dictionary) -> void:
	match accion.tipo:
		"jugar_carta":
			procesar_jugada("muerte", accion.carta)
		"cantar_envido":
			# Marcar que se cantó envido para evitar que se vuelva a cantar
			state.envido_cantado = true
			envido_sys.cantar_envido(accion.tipo_envido, "muerte")
			estado_respuesta_pendiente = "envido"
			ui.mostrar_dialogo_respuesta("envido")
		"cantar_truco":
			betting.cantar_truco("muerte")
			estado_respuesta_pendiente = "truco"
			ui.mostrar_dialogo_respuesta("truco")
		"irse_al_mazo":
			state.agregar_puntos_jugador(betting.puntos_en_juego)
			finalizar_mano()

# ============================================================
# MANEJO DE APUESTAS (UI -> Controller -> Systems)
# ============================================================
func _on_ui_envido() -> void:
	# Validar que no se haya cantado envido ya
	if state.envido_cantado:
		ui.mostrar_mensaje("Ya se cantó envido en esta mano")
		return

	# Validar que sea primera ronda
	if state.ronda_actual > 1:
		ui.mostrar_mensaje("El envido solo se puede cantar en la primera ronda")
		return

	# Marcar envido como cantado
	state.envido_cantado = true

	# Deshabilitar controles mientras se resuelve
	ui.deshabilitar_controles()

	# Cantar envido
	envido_sys.cantar_envido(EnvidoSystem.TipoEnvido.ENVIDO, "jugador")
	ui.mostrar_mensaje("¡Cantaste Envido!", 2.5)

	# La IA evalúa su envido y decide si acepta
	await get_tree().create_timer(2.5).timeout
	var envido_muerte = envido_sys.calcular_envido(state.cartas_originales_muerte)
	# Acepta si tiene 25 o más puntos de envido (umbral razonable)
	var acepta_envido = envido_muerte >= 25
	_on_ai_responde_envido(acepta_envido)

func _on_ui_truco() -> void:
	# Intentar cantar truco
	var exito = betting.cantar_truco("jugador")

	if not exito:
		ui.mostrar_mensaje("No puedes cantar truco en este momento")
		return

	# Deshabilitar controles mientras se resuelve
	ui.deshabilitar_controles()

	ui.mostrar_mensaje("¡Cantaste Truco!", 2.5)
	await get_tree().create_timer(2.5).timeout

	# La IA decide si acepta o no (por ahora siempre acepta)
	_on_ai_responde_truco(true)

func _on_ui_irse_al_mazo() -> void:
	# El jugador se rinde y la muerte gana los puntos en juego
	ui.deshabilitar_controles()
	ui.mostrar_mensaje("Te fuiste al mazo...", 2.5)
	await get_tree().create_timer(2.5).timeout

	# La muerte gana los puntos en juego (mínimo 1)
	var puntos = max(betting.puntos_en_juego, 1)
	state.agregar_puntos_muerte(puntos)
	ui.actualizar_puntos(state.puntos_jugador, state.puntos_muerte)
	ui.mostrar_mensaje("La Muerte gana %d punto%s" % [puntos, "s" if puntos > 1 else ""], 3.0)
	await get_tree().create_timer(3.0).timeout

	# Verificar si la muerte ganó la partida
	if state.puntos_muerte >= _puntos_ganar:
		ui.mostrar_mensaje("DERROTA... La Muerte te venció", 3.0)
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://scenes/cinematics/muerte_victoria/muerte_victoria.tscn")
		return

	# Comenzar nueva mano
	comenzar_nueva_mano()

# --- RESPUESTAS DEL JUGADOR ---
func _on_player_responde_envido(acepta: bool) -> void:
	if estado_respuesta_pendiente != "envido": return

	# Limpiar estado de respuesta pendiente primero
	estado_respuesta_pendiente = ""
	ui.ocultar_respuestas()

	if acepta:
		ui.mostrar_mensaje("¡Quiero!", 2.5)
		await get_tree().create_timer(2.5).timeout

		# Usar las cartas originales para calcular envido (incluye cartas ya jugadas)
		var pts_jug = envido_sys.calcular_envido(state.cartas_originales_jugador)
		var pts_muerte = envido_sys.calcular_envido(state.cartas_originales_muerte)

		# Mostrar los puntos de cada uno con más tiempo
		ui.mostrar_mensaje("Tu envido: %d" % pts_jug, 3.5)
		await get_tree().create_timer(3.5).timeout
		ui.mostrar_mensaje("Envido de La Muerte: %d" % pts_muerte, 3.5)
		await get_tree().create_timer(3.5).timeout

		envido_sys.resolver_envido(pts_jug, pts_muerte)
		await get_tree().create_timer(2.0).timeout
	else:
		ui.mostrar_mensaje("No quiero", 2.5)
		await get_tree().create_timer(2.5).timeout
		state.agregar_puntos_muerte(1)
		ui.actualizar_puntos(state.puntos_jugador, state.puntos_muerte)
		ui.mostrar_mensaje("La Muerte gana 1 punto", 3.5)
		await get_tree().create_timer(3.5).timeout

	# Después de resolver el envido, continuar con el juego normal
	# La muerte debe jugar su carta ahora
	iniciar_turno()

func _on_player_responde_truco(acepta: bool) -> void:
	if estado_respuesta_pendiente != "truco": return

	# Limpiar estado de respuesta pendiente
	estado_respuesta_pendiente = ""
	ui.ocultar_respuestas()

	if acepta:
		betting.aceptar_apuesta()
		ui.mostrar_mensaje("¡Quiero!", 2.5)
		await get_tree().create_timer(2.5).timeout

		# Continuar con el juego - la muerte debe jugar su carta
		iniciar_turno()
	else:
		ui.mostrar_mensaje("No quiero", 2.5)
		await get_tree().create_timer(2.5).timeout

		var pts = betting.rechazar_apuesta()
		state.agregar_puntos_muerte(pts)
		ui.actualizar_puntos(state.puntos_jugador, state.puntos_muerte)
		ui.mostrar_mensaje("La Muerte gana %d puntos" % pts, 4.0)
		await get_tree().create_timer(4.0).timeout
		finalizar_mano()

func _on_player_contra_envido(tipo_envido: int) -> void:
	if estado_respuesta_pendiente != "envido": return

	# Limpiar estado de respuesta pendiente
	estado_respuesta_pendiente = ""
	ui.ocultar_respuestas()

	# Determinar nombre del contra-canto
	var nombre_canto = ""
	match tipo_envido:
		EnvidoSystem.TipoEnvido.ENVIDO_ENVIDO:
			nombre_canto = "Envido"
		EnvidoSystem.TipoEnvido.REAL_ENVIDO:
			nombre_canto = "Real Envido"
		EnvidoSystem.TipoEnvido.FALTA_ENVIDO:
			nombre_canto = "Falta Envido"

	# Acumular puntos del contra-canto
	envido_sys.cantar_envido(tipo_envido, "jugador")
	ui.mostrar_mensaje("¡%s!" % nombre_canto, 2.5)
	await get_tree().create_timer(2.5).timeout

	# La muerte decide si acepta el contra-canto
	var envido_muerte = envido_sys.calcular_envido(state.cartas_originales_muerte)
	# Umbral más alto para aceptar contra-cantos
	var umbral = 27 if tipo_envido == EnvidoSystem.TipoEnvido.FALTA_ENVIDO else 25
	var acepta = envido_muerte >= umbral

	if acepta:
		ui.mostrar_mensaje("La Muerte dijo: ¡Quiero!", 2.5)
		await get_tree().create_timer(2.5).timeout

		# Resolver envido
		var pts_jug = envido_sys.calcular_envido(state.cartas_originales_jugador)
		var pts_muerte = envido_sys.calcular_envido(state.cartas_originales_muerte)

		ui.mostrar_mensaje("Tu envido: %d" % pts_jug, 3.5)
		await get_tree().create_timer(3.5).timeout
		ui.mostrar_mensaje("Envido de La Muerte: %d" % pts_muerte, 3.5)
		await get_tree().create_timer(3.5).timeout

		envido_sys.resolver_envido(pts_jug, pts_muerte)
		await get_tree().create_timer(2.0).timeout
	else:
		ui.mostrar_mensaje("La Muerte dijo: No quiero", 2.5)
		await get_tree().create_timer(2.5).timeout
		# El jugador gana los puntos acumulados hasta antes del contra-canto
		var puntos_ganados = envido_sys.puntos_acumulados - envido_sys.puntos_por_tipo[tipo_envido]
		if puntos_ganados < 1: puntos_ganados = 1
		state.agregar_puntos_jugador(puntos_ganados)
		ui.actualizar_puntos(state.puntos_jugador, state.puntos_muerte)
		ui.mostrar_mensaje("Ganaste %d punto%s" % [puntos_ganados, "s" if puntos_ganados > 1 else ""], 3.5)
		await get_tree().create_timer(3.5).timeout

	# Continuar con el juego
	iniciar_turno()

# --- RESPUESTAS DE IA (Simuladas por ahora) ---
func _on_ai_responde_envido(acepta: bool) -> void:
	if acepta:
		ui.mostrar_mensaje("La Muerte dijo: ¡Quiero!", 2.5)
		await get_tree().create_timer(2.5).timeout

		# Usar las cartas originales para calcular envido (incluye cartas ya jugadas)
		var pts_jug = envido_sys.calcular_envido(state.cartas_originales_jugador)
		var pts_muerte = envido_sys.calcular_envido(state.cartas_originales_muerte)

		# Mostrar los puntos de cada uno con más tiempo
		ui.mostrar_mensaje("Tu envido: %d" % pts_jug, 3.5)
		await get_tree().create_timer(3.5).timeout
		ui.mostrar_mensaje("Envido de La Muerte: %d" % pts_muerte, 3.5)
		await get_tree().create_timer(3.5).timeout

		envido_sys.resolver_envido(pts_jug, pts_muerte)
	else:
		ui.mostrar_mensaje("La Muerte dijo: No quiero", 2.5)
		await get_tree().create_timer(2.5).timeout
		state.agregar_puntos_jugador(1)
		ui.actualizar_puntos(state.puntos_jugador, state.puntos_muerte)
		ui.mostrar_mensaje("Ganaste 1 punto por el envido rechazado", 3.5)

	# Rehabilitar controles después de resolver el envido
	await get_tree().create_timer(2.0).timeout
	ui.habilitar_controles(state, betting)

func _on_ai_responde_truco(acepta: bool) -> void:
	if acepta:
		betting.aceptar_apuesta()
		ui.mostrar_mensaje("La Muerte dijo: ¡Quiero!", 3.0)
		await get_tree().create_timer(3.0).timeout
		# Rehabilitar controles y continuar jugando
		ui.habilitar_controles(state, betting)
	else:
		betting.rechazar_apuesta()
		ui.mostrar_mensaje("La Muerte dijo: No quiero", 3.0)
		await get_tree().create_timer(3.0).timeout
		finalizar_mano()

func _on_envido_resuelto(ganador: String, puntos: int) -> void:
	if ganador == "jugador":
		state.agregar_puntos_jugador(puntos)
		ui.mostrar_mensaje("¡Ganaste el envido! (+%d puntos)" % puntos, 4.5)
	else:
		state.agregar_puntos_muerte(puntos)
		ui.mostrar_mensaje("La Muerte ganó el envido (+%d puntos)" % puntos, 4.5)

	ui.actualizar_puntos(state.puntos_jugador, state.puntos_muerte)

func _on_apuesta_aceptada() -> void: pass
func _on_apuesta_rechazada() -> void: pass

# ============================================================
# DEBUG COMMANDS (Solo en modo debug)
# ============================================================
func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F9:
				_debug_ganar_instantaneamente()
			KEY_F10:
				_debug_perder_instantaneamente()
			KEY_F11:
				_debug_agregar_puntos_jugador(10)

func _debug_ganar_instantaneamente() -> void:
	print("🎉 DEBUG: Ganando instantáneamente...")
	state.puntos_jugador = _puntos_ganar
	ui.actualizar_puntos(state.puntos_jugador, state.puntos_muerte)
	ui.mostrar_mensaje("¡VICTORIA! (DEBUG)", 3.0)
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/cinematics/jugador_victoria/jugador_victoria.tscn")

func _debug_perder_instantaneamente() -> void:
	print("💀 DEBUG: Perdiendo instantáneamente...")
	state.puntos_muerte = _puntos_ganar
	ui.actualizar_puntos(state.puntos_jugador, state.puntos_muerte)
	ui.mostrar_mensaje("DERROTA (DEBUG)", 3.0)
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/cinematics/muerte_victoria/muerte_victoria.tscn")

func _debug_agregar_puntos_jugador(puntos: int) -> void:
	print("⚡ DEBUG: +%d puntos al jugador" % puntos)
	state.agregar_puntos_jugador(puntos)
	ui.actualizar_puntos(state.puntos_jugador, state.puntos_muerte)
	ui.mostrar_mensaje("DEBUG: +%d puntos" % puntos, 2.0)
