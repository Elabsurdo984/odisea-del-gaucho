extends GutTest

var deck: Deck

func before_each():
	deck = autofree(Deck.new())

func test_mazo_tiene_40_cartas():
	assert_eq(deck.cards.size(), 40, "El mazo de truco debe tener 40 cartas")

func test_no_hay_ochos_ni_nueves():
	for carta in deck.cards:
		assert_ne(carta.numero, 8, "No debe haber ochos")
		assert_ne(carta.numero, 9, "No debe haber nueves")

func test_repartir_cartas():
	var mano = deck.repartir(3)
	assert_eq(mano.size(), 3, "Debe repartir 3 cartas")
	assert_eq(deck.cards.size(), 37, "Deben quedar 37 cartas en el mazo")

func test_barajar_cambia_orden():
	var orden_inicial = deck.cards.duplicate()
	deck.barajar()
	var orden_nuevo = deck.cards
	
	# Es estadísticamente improbable que el orden sea idéntico tras barajar 40 cartas
	assert_ne(orden_inicial, orden_nuevo, "El mazo debe estar barajado")

func test_repartir_mas_de_lo_que_hay():
	deck.repartir(38)
	var ultima_mano = deck.repartir(5)
	assert_eq(ultima_mano.size(), 2, "Solo debe repartir las cartas que quedan")
	assert_eq(deck.cards.size(), 0)

func test_reiniciar_mazo():
	deck.repartir(10)
	deck.reiniciar()
	assert_eq(deck.cards.size(), 40, "Al reiniciar debe volver a tener 40 cartas")
