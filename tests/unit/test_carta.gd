extends GutTest

func todas_las_cartas_tienen_valor_truco():
    var palos = [Carta.Palo.ESPADA, Carta.Palo.BASTO, Carta.Palo.ORO, Carta.Palo.COPA]
    var numeros = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12]
    
    for palo in palos:
        for numero in numeros:
            var carta = Carta.new()
            carta.setup(numero, palo)
            var valor = carta.obtener_valor_truco()
            
            assert_between(valor, 1, 14, 
                "Carta %d de %s debe tener valor entre 1-14" % [numero, palo])

func test_jerarquia_cartas_especiales():
    # Las 4 cartas mas fuertes
    var cartas: Dictionary = {
        "1_espada": 14,
        "1_basto": 13,
        "7_espada": 12,
        "7_oro": 11
    }
    
    for key in cartas.keys():
        var partes = key.split("_")
        var numero = int(partes[0])
        var palo = _string_a_palo(partes[1])
        
        var carta = Carta.new()
        carta.setup(numero, palo)
        
        assert_eq(carta.obtener_valor_truco(), cartas[key],
            "%s debe valer %d" % [key, cartas[key]])
        
func _string_a_palo(palo_str: String) -> Carta.Palo:
    match palo_str:
        "espada": return Carta.Palo.ESPADA
        "basto": return Carta.Palo.BASTO
        "oro": return Carta.Palo.ORO
        "copa": return Carta.Palo.COPA
    return Carta.Palo.ESPADA
    
        
        
        
        
        
        
        
