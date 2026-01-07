extends Node
class_name Deck

var cards: Array = []

func _init():
	_crear_mazo()

func _crear_mazo() -> void:
	cards.clear()
	var palos = [Carta.Palo.ORO, Carta.Palo.COPA, Carta.Palo.ESPADA, Carta.Palo.BASTO]
	var numeros = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12]
	
	for palo in palos:
		for numero in numeros:
			var carta_data = {
				"numero": numero,
				"palo": palo
			}
			cards.append(carta_data)

func barajar() -> void:
	cards.shuffle()

func repartir(cantidad: int) -> Array:
	var mano = []
	for i in range(cantidad):
		if cards.size() > 0:
			mano.append(cards.pop_back())
	return mano

func reiniciar() -> void:
	_crear_mazo()
