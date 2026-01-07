# carta.gd
# Representa una carta española del truco
class_name Carta
extends Control

#region ENUMS
enum Palo { ORO, COPA, ESPADA, BASTO }
#endregion

#region PROPIEDADES
var numero: int  # 1-7, 10-12 (no hay 8 ni 9)
var palo: Palo
var boca_arriba: bool = false
#endregion

#region REFERENCIAS
@export var carta_frente: Panel
@export var carta_dorso: Panel
@export var numero_label: Label 
@export var palo_label: Label
@export var boton: Button
#endregion

#region SEÑALES
signal carta_clickeada(carta: Carta)
#endregion

#region INICIALIZACION
func _ready():
	if boton:
		boton.pressed.connect(_on_carta_pressed)
	actualizar_visual()

func setup(num: int, p: Palo):
	numero = num
	palo = p
	if is_node_ready():
		actualizar_visual()
#endregion

#region VISUAL
func actualizar_visual():
	if boca_arriba:
		mostrar_frente()
	else:
		mostrar_dorso()

func mostrar_frente():
	boca_arriba = true
	if carta_frente:
		carta_frente.visible = true
	if carta_dorso:
		carta_dorso.visible = false

	if numero_label:
		numero_label.text = str(numero)
	if palo_label:
		palo_label.text = obtener_simbolo_palo()

func mostrar_dorso():
	boca_arriba = false
	if carta_frente:
		carta_frente.visible = false
	if carta_dorso:
		carta_dorso.visible = true

func obtener_simbolo_palo() -> String:
	match palo:
		Palo.ORO: return "ORO"
		Palo.COPA: return "COPA"
		Palo.ESPADA: return "ESPADA"
		Palo.BASTO: return "BASTO"
	return ""

func obtener_color_palo() -> Color:
	match palo:
		Palo.ORO: return Color(1.0, 0.84, 0.0)  # Dorado
		Palo.COPA: return Color(0.8, 0.2, 0.2)  # Rojo
		Palo.ESPADA: return Color(0.2, 0.2, 0.8)  # Azul
		Palo.BASTO: return Color(0.3, 0.6, 0.3)  # Verde
	return Color.WHITE
#endregion

#region LOGICA DEL TRUCO
func obtener_valor_truco() -> int:
	# Jerarquía del truco (mayor número = carta más fuerte)
	# 14: 1 de espadas
	# 13: 1 de bastos
	# 12: 7 de espadas
	# 11: 7 de oros
	# 10: 3 (todos)
	# 9: 2 (todos)
	# 8: 1 de oros/copa (ases falsos)
	# 7: 12 (rey)
	# 6: 11 (caballo)
	# 5: 10 (sota)
	# 4: 7 de copa/basto
	# 3: 6
	# 2: 5
	# 1: 4

	# Las 4 cartas más fuertes
	if numero == 1 and palo == Palo.ESPADA:
		return 14  # Ancho de espadas
	if numero == 1 and palo == Palo.BASTO:
		return 13  # Ancho de bastos
	if numero == 7 and palo == Palo.ESPADA:
		return 12  # Siete de espadas
	if numero == 7 and palo == Palo.ORO:
		return 11  # Siete de oros

	# Cartas por número
	if numero == 3:
		return 10
	if numero == 2:
		return 9
	if numero == 1:  # Ases falsos (oro y copa)
		return 8
	if numero == 12:  # Rey
		return 7
	if numero == 11:  # Caballo
		return 6
	if numero == 10:  # Sota
		return 5
	if numero == 7:  # Sietes falsos (copa y basto)
		return 4
	if numero == 6:
		return 3
	if numero == 5:
		return 2
	if numero == 4:
		return 1

	return 0

func obtener_valor_envido() -> int:
	# Figuras valen 0 para el envido
	if numero >= 10:
		return 0
	# Las demás cartas valen su número
	return numero
#endregion

#region INTERACCION
func hacer_clickeable(clickeable: bool):
	if boton:
		boton.disabled = not clickeable
		boton.mouse_filter = Control.MOUSE_FILTER_STOP if clickeable else Control.MOUSE_FILTER_IGNORE

func _on_carta_pressed():
	if boca_arriba:
		carta_clickeada.emit(self)
#endregion

#region UTILIDAD
func obtener_nombre_completo() -> String:
	return "%d de %s" % [numero, obtener_simbolo_palo()]

func es_mismo_palo(otra_carta: Carta) -> bool:
	return palo == otra_carta.palo
#endregion
