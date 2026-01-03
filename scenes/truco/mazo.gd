# mazo.gd
# Clase para manejar el mazo de 40 cartas españolas
class_name Mazo
extends RefCounted

# ==================== VARIABLES ====================
var cartas_disponibles: Array = []

# ==================== INICIALIZACIÓN ====================
func _init():
    crear_mazo()
    barajar()

func crear_mazo():
    cartas_disponibles.clear()

    # Para cada palo
    for palo in [Carta.Palo.ORO, Carta.Palo.COPA, Carta.Palo.ESPADA, Carta.Palo.BASTO]:
        # Números 1-7 (no hay 8 ni 9)
        for num in range(1, 8):
            cartas_disponibles.append({"numero": num, "palo": palo})

        # Figuras 10-12 (sota, caballo, rey)
        for num in range(10, 13):
            cartas_disponibles.append({"numero": num, "palo": palo})

    print("🃏 Mazo creado: ", cartas_disponibles.size(), " cartas")

func barajar():
    cartas_disponibles.shuffle()
    print("🔀 Mazo barajado")

# ==================== REPARTIR ====================
func repartir_cartas(cantidad: int) -> Array:
    var cartas_repartidas: Array = []

    for i in range(cantidad):
        if cartas_disponibles.is_empty():
            push_error("❌ No hay más cartas en el mazo!")
            break

        var carta_data = cartas_disponibles.pop_front()
        cartas_repartidas.append(carta_data)

    return cartas_repartidas

func cartas_restantes() -> int:
    return cartas_disponibles.size()

# ==================== RESETEAR ====================
func resetear():
    crear_mazo()
    barajar()
