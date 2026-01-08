extends Node
class_name TrucoUI

# ============================================================
# SEÑALES
# ============================================================
signal boton_envido_presionado()
signal boton_truco_presionado()
signal boton_irse_presionado()
signal carta_jugada(carta: Carta)
signal respuesta_envido(acepta: bool)
signal respuesta_truco(acepta: bool)

# ============================================================
# REFERENCIAS UI (Asignar en Editor)
# ============================================================
@export_group("Contenedores")
@export var contenedor_cartas_jugador: Control
@export var contenedor_cartas_muerte: Control
@export var posicion_mesa_jugador: Marker2D
@export var posicion_mesa_muerte: Marker2D

@export_group("Labels")
@export var lbl_puntos_jugador: Label
@export var lbl_puntos_muerte: Label
@export var lbl_mensaje: Label
@export var lbl_resultado_ronda: Label

@export_group("Botones Acciones")
@export var btn_envido: Button
@export var btn_truco: Button
@export var btn_irse: Button

@export_group("Botones Respuesta")
@export var contenedor_respuestas: Control
@export var btn_quiero: Button
@export var btn_no_quiero: Button

# ============================================================
# VARIABLES
# ============================================================
const CARTA_SCENE = preload("res://scenes/truco_game/carta.tscn") # Usamos la carta existente

# ============================================================
# LIFECYCLE
# ============================================================
func _ready() -> void:
	# Conectar botones fijos
	if btn_envido: btn_envido.pressed.connect(func(): boton_envido_presionado.emit())
	if btn_truco: btn_truco.pressed.connect(func(): boton_truco_presionado.emit())
	if btn_irse: btn_irse.pressed.connect(func(): boton_irse_presionado.emit())
	
	if btn_quiero: btn_quiero.pressed.connect(func(): _responder(true))
	if btn_no_quiero: btn_no_quiero.pressed.connect(func(): _responder(false))
	
	ocultar_respuestas()
	lbl_mensaje.text = ""
	lbl_resultado_ronda.text = ""

# ============================================================
# MÉTODOS PÚBLICOS
# ============================================================

func actualizar_puntos(puntos_jugador: int, puntos_muerte: int) -> void:
	if lbl_puntos_jugador: lbl_puntos_jugador.text = "Jugador: %d" % puntos_jugador
	if lbl_puntos_muerte: lbl_puntos_muerte.text = "Muerte: %d" % puntos_muerte

func mostrar_mensaje(texto: String, duracion: float = 2.0) -> void:
	if lbl_mensaje:
		lbl_mensaje.text = texto
		lbl_mensaje.visible = true
		
		# Ocultar automáticamente si hay duración
		if duracion > 0:
			await get_tree().create_timer(duracion).timeout
			lbl_mensaje.visible = false

func mostrar_resultado_ronda(ganador: int) -> void:
	var texto = ""
	match ganador:
		TrucoRules.GANADOR_JUGADOR: texto = "Ganaste la ronda"
		TrucoRules.GANADOR_MUERTE: texto = "Perdiste la ronda"
		TrucoRules.EMPATE: texto = "Parda"
	
	if lbl_resultado_ronda:
		lbl_resultado_ronda.text = texto
		lbl_resultado_ronda.visible = true
		await get_tree().create_timer(1.5).timeout
		lbl_resultado_ronda.visible = false

func habilitar_controles(state: TrucoState, betting: TrucoBetting) -> void:
	# Lógica para habilitar botones según reglas
	# Ejemplo: Solo habilitar Envido en primera ronda y si no se cantó
	var puede_envido = state.ronda_actual == 1 and betting.nivel_actual == TrucoBetting.NivelApuesta.NINGUNO
	
	if btn_envido: btn_envido.disabled = not puede_envido
	if btn_truco: btn_truco.disabled = false # Simplificado
	if btn_irse: btn_irse.disabled = false
	
	_hacer_cartas_clickeables(true)

func deshabilitar_controles() -> void:
	if btn_envido: btn_envido.disabled = true
	if btn_truco: btn_truco.disabled = true
	if btn_irse: btn_irse.disabled = true
	
	_hacer_cartas_clickeables(false)

func mostrar_cartas_jugador(cartas_data: Array) -> void:
	_limpiar_contenedor(contenedor_cartas_jugador)
	
	for data in cartas_data:
		var carta = CARTA_SCENE.instantiate()
		contenedor_cartas_jugador.add_child(carta)
		carta.setup(data.numero, data.palo)
		carta.mostrar_frente()
		
		# Conectar señal de la carta
		carta.carta_clickeada.connect(_on_carta_clickeada)

func mostrar_cartas_muerte_dorso(cantidad: int = 3) -> void:
	_limpiar_contenedor(contenedor_cartas_muerte)
	for i in range(cantidad):
		var carta = CARTA_SCENE.instantiate()
		contenedor_cartas_muerte.add_child(carta)
		# No hacemos setup de datos para que no se sepa qué es (o ponemos dummy)
		carta.mostrar_dorso()
		carta.hacer_clickeable(false)

func animar_carta_a_mesa(carta: Carta, quien: String) -> void:
	# Reparentar carta a la escena principal o un nodo superior para moverla libremente
	# O simplemente moverla desde su contenedor actual hacia el marker
	
	var destino = Vector2.ZERO
	if quien == "jugador" and posicion_mesa_jugador:
		destino = posicion_mesa_jugador.global_position
	elif quien == "muerte" and posicion_mesa_muerte:
		destino = posicion_mesa_muerte.global_position
	
	# Si es la carta de la muerte, revelarla si estaba boca abajo
	if quien == "muerte":
		carta.mostrar_frente()
	
	# Usar Tween para mover
	var tween = create_tween()
	# Nota: Para mover entre contenedores suavemente se requiere cambio de padre o usar global_position
	# Aquí asumimos que "carta" es el nodo visual
	
	# Truco para que la carta salga del HBoxContainer y flote:
	var global_pos_inicial = carta.global_position
	carta.get_parent().remove_child(carta)
	add_child(carta) # Añadir temporalmente a TrucoUI o un nodo 'Table'
	carta.global_position = global_pos_inicial
	
	tween.tween_property(carta, "global_position", destino, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func mostrar_carta_mesa_jugador(carta_data) -> void:
	# Crear una carta visual en la posición de la mesa del jugador
	if not posicion_mesa_jugador: return

	var carta = CARTA_SCENE.instantiate()
	add_child(carta)
	carta.setup(carta_data["numero"], carta_data["palo"])
	carta.mostrar_frente()
	carta.hacer_clickeable(false)
	carta.global_position = posicion_mesa_jugador.global_position

func mostrar_carta_mesa_muerte(carta_data) -> void:
	# Crear una carta visual en la posición de la mesa de la muerte
	if not posicion_mesa_muerte: return

	var carta = CARTA_SCENE.instantiate()
	add_child(carta)
	carta.setup(carta_data["numero"], carta_data["palo"])
	carta.mostrar_frente()
	carta.hacer_clickeable(false)
	carta.global_position = posicion_mesa_muerte.global_position

func limpiar_mesa() -> void:
	# Eliminar cartas que quedaron flotando en la mesa (hijos de TrucoUI que sean cartas)
	for child in get_children():
		if child is Carta:
			child.queue_free()

func mostrar_dialogo_respuesta(tipo: String) -> void:
	if contenedor_respuestas:
		contenedor_respuestas.visible = true
		lbl_mensaje.text = "La Muerte cantó " + tipo

func ocultar_respuestas() -> void:
	if contenedor_respuestas:
		contenedor_respuestas.visible = false

# ============================================================
# PRIVADOS
# ============================================================
func obtener_carta_muerte_visual() -> Carta:
	if not contenedor_cartas_muerte: return null
	# Retornar la primera carta disponible que no haya sido jugada
	# (Las cartas jugadas se mueven fuera del contenedor en animar_carta_a_mesa)
	for child in contenedor_cartas_muerte.get_children():
		if child is Carta:
			return child
	return null

func _limpiar_contenedor(contenedor: Control) -> void:
	if not contenedor: return
	for child in contenedor.get_children():
		child.queue_free()

func _hacer_cartas_clickeables(clickeable: bool) -> void:
	if not contenedor_cartas_jugador: return
	for carta in contenedor_cartas_jugador.get_children():
		if carta is Carta:
			carta.hacer_clickeable(clickeable)

func _on_carta_clickeada(carta: Carta) -> void:
	carta_jugada.emit(carta)

func _responder(acepta: bool) -> void:
	ocultar_respuestas()
	# Aquí falta saber qué se está respondiendo, idealmente el controller gestiona el estado
	# O emitimos señales genéricas
	# Por simplificación asumimos que el controller sabe qué se preguntó
	# Emitimos ambas señales y el controller decide cual escuchar o usamos una genérica
	respuesta_envido.emit(acepta) 
	respuesta_truco.emit(acepta)
