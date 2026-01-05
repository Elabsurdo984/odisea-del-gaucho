# ia_muerte.gd
# Sistema de IA para que La Muerte juegue inteligentemente al Truco
class_name IAMuerte
extends Node

#region NIVEL 1: EVALUACIÓN BÁSICA

# Evalúa qué tan fuerte es una carta individual (0-100)
static func evaluar_fuerza_carta(carta: Carta) -> float:
    var valor_truco = carta.obtener_valor_truco()
    # Normalizar el valor de truco (1-14) a escala 0-100
    # 14 (ancho espadas) = 100
    # 1 (4 de cualquier palo) = 7
    return (valor_truco / 14.0) * 100.0

# Evalúa qué tan fuerte es la mano completa (0-100)
static func evaluar_fuerza_mano(cartas: Array) -> float:
    if cartas.is_empty():
        return 0.0

    var fuerzas = []
    for carta in cartas:
        fuerzas.append(evaluar_fuerza_carta(carta))

    # Ordenar de mayor a menor
    fuerzas.sort()
    fuerzas.reverse()

    # Evaluación ponderada:
    # - Carta más fuerte: 50% del peso
    # - Segunda carta: 30% del peso
    # - Tercera carta: 20% del peso
    var fuerza_total: float = 0.0

    if fuerzas.size() >= 1:
        fuerza_total += fuerzas[0] * 0.5
    if fuerzas.size() >= 2:
        fuerza_total += fuerzas[1] * 0.3
    if fuerzas.size() >= 3:
        fuerza_total += fuerzas[2] * 0.2

    return fuerza_total

# Categoriza la mano según su fuerza
static func categorizar_mano(fuerza: float) -> String:
    if fuerza >= 75:
        return "excelente"  # Tiene al menos una carta muy fuerte
    elif fuerza >= 55:
        return "buena"      # Mano sólida
    elif fuerza >= 35:
        return "regular"    # Mano promedio
    else:
        return "mala"       # Mano débil

#endregion

#region UTILIDADES DE SELECCIÓN

# Obtiene la mejor carta del array
static func obtener_mejor_carta(cartas: Array) -> Carta:
    if cartas.is_empty():
        return null

    var mejor = cartas[0]
    var mejor_valor = mejor.obtener_valor_truco()

    for carta in cartas:
        var valor = carta.obtener_valor_truco()
        if valor > mejor_valor:
            mejor = carta
            mejor_valor = valor

    return mejor

# Obtiene la peor carta del array
static func obtener_peor_carta(cartas: Array) -> Carta:
    if cartas.is_empty():
        return null

    var peor = cartas[0]
    var peor_valor = peor.obtener_valor_truco()

    for carta in cartas:
        var valor = carta.obtener_valor_truco()
        if valor < peor_valor:
            peor = carta
            peor_valor = valor

    return peor

# Obtiene una carta de fuerza media
static func obtener_carta_media(cartas: Array) -> Carta:
    if cartas.is_empty():
        return null
    if cartas.size() == 1:
        return cartas[0]
    if cartas.size() == 2:
        # Entre 2 cartas, devolver la más débil como "media"
        return obtener_peor_carta(cartas)

    # Con 3 cartas, ordenar y tomar la del medio
    var cartas_ordenadas = cartas.duplicate()
    cartas_ordenadas.sort_custom(func(a, b): return a.obtener_valor_truco() < b.obtener_valor_truco())

    return cartas_ordenadas[1]  # La del medio

# Obtiene una carta aleatoria (para variabilidad)
static func obtener_carta_aleatoria(cartas: Array) -> Carta:
    if cartas.is_empty():
        return null
    return cartas[randi() % cartas.size()]

#endregion

#region NIVEL 1: SELECTOR BÁSICO

# Selecciona qué carta jugar (versión básica)
static func seleccionar_carta_basico(cartas: Array) -> Carta:
    if cartas.is_empty():
        return null

    # Evaluación básica: juega según la fuerza de la mano
    var fuerza = evaluar_fuerza_mano(cartas)
    var categoria = categorizar_mano(fuerza)

    match categoria:
        "excelente":
            # Mano muy fuerte: jugar carta media primero (tantear)
            return obtener_carta_media(cartas)
        "buena":
            # Mano buena: jugar carta media o mejor según probabilidad
            if randf() < 0.6:
                return obtener_carta_media(cartas)
            else:
                return obtener_mejor_carta(cartas)
        "regular":
            # Mano regular: jugar mejor carta para intentar ganar
            return obtener_mejor_carta(cartas)
        "mala":
            # Mano mala: sacrificar la peor
            return obtener_peor_carta(cartas)

    # Fallback
    return cartas[0]

#endregion

#region NIVEL 2: ESTRATEGIA POR RONDA

# Selecciona carta con estrategia según la ronda y situación
# Contexto esperado:
# {
#     "ronda_actual": int,
#     "resultado_ronda_1": int,  # 0=no jugada, 1=jugador, 2=muerte, 3=empate
#     "resultado_ronda_2": int,
#     "es_mano": bool,
#     "carta_jugador": Carta o null
# }
static func seleccionar_carta_estrategico(cartas: Array, contexto: Dictionary) -> Carta:
    if cartas.is_empty():
        return null

    var ronda = contexto.get("ronda_actual", 1)
    var resultado_r1 = contexto.get("resultado_ronda_1", 0)
    var resultado_r2 = contexto.get("resultado_ronda_2", 0)
    var es_mano = contexto.get("es_mano", true)
    var carta_jugador = contexto.get("carta_jugador", null)

    # ESTRATEGIA RONDA 1
    if ronda == 1:
        return estrategia_ronda_1(cartas, es_mano, carta_jugador)

    # ESTRATEGIA RONDA 2
    elif ronda == 2:
        return estrategia_ronda_2(cartas, resultado_r1, es_mano, carta_jugador)

    # ESTRATEGIA RONDA 3
    elif ronda == 3:
        return estrategia_ronda_3(cartas, resultado_r1, resultado_r2, es_mano, carta_jugador)

    # Fallback
    return seleccionar_carta_basico(cartas)

# Estrategia para la primera ronda
static func estrategia_ronda_1(cartas: Array, es_mano: bool, carta_jugador: Carta) -> Carta:
    if es_mano:
        # SOY MANO: juego primero, tanteo con carta media
        # Excepción: si tengo mano MUY mala, juego la peor directamente
        var fuerza = evaluar_fuerza_mano(cartas)
        if fuerza < 25:
            return obtener_peor_carta(cartas)
        else:
            return obtener_carta_media(cartas)
    else:
        # SOY PIE: respondo a lo que jugó el oponente
        if carta_jugador == null:
            return obtener_carta_media(cartas)

        var valor_jugador = carta_jugador.obtener_valor_truco()

        # Buscar la carta más débil que le gane
        var carta_para_ganar = null
        var menor_diferencia = 999

        for carta in cartas:
            var valor = carta.obtener_valor_truco()
            if valor > valor_jugador:
                var diferencia = valor - valor_jugador
                if diferencia < menor_diferencia:
                    menor_diferencia = diferencia
                    carta_para_ganar = carta

        # Si encontré una carta que le gana sin "desperdiciar" mucho
        if carta_para_ganar != null and menor_diferencia <= 5:
            return carta_para_ganar

        # Si no puedo ganar fácilmente, sacrifico la peor
        return obtener_peor_carta(cartas)

# Estrategia para la segunda ronda
static func estrategia_ronda_2(cartas: Array, resultado_r1: int, es_mano: bool, carta_jugador: Carta) -> Carta:
    # Si GANÉ la primera: puedo jugar más conservador
    if resultado_r1 == 2:  # Muerte ganó
        # Si soy mano, puedo tantear de nuevo
        if es_mano:
            return obtener_carta_media(cartas)
        # Si soy pie, respondo estratégicamente
        else:
            if carta_jugador == null:
                return obtener_peor_carta(cartas)
            # Similar a ronda 1 pero más conservador
            var valor_jugador = carta_jugador.obtener_valor_truco()
            for carta in cartas:
                if carta.obtener_valor_truco() > valor_jugador:
                    return carta  # Juego la primera que le gane
            return obtener_peor_carta(cartas)

    # Si PERDÍ la primera: DEBO ganar esta ronda o pierdo la mano
    elif resultado_r1 == 1:  # Jugador ganó
        # Jugar la mejor carta disponible
        return obtener_mejor_carta(cartas)

    # Si EMPATÉ la primera: esta ronda es decisiva
    else:
        # Jugar carta fuerte
        if cartas.size() == 1:
            return cartas[0]
        # Jugar la mejor de las que quedan
        return obtener_mejor_carta(cartas)

# Estrategia para la tercera ronda
static func estrategia_ronda_3(cartas: Array, _resultado_r1: int, _resultado_r2: int, _es_mano: bool, _carta_jugador: Carta) -> Carta:
    # En la tercera ronda solo queda una carta, pero igual aplicamos lógica

    if cartas.is_empty():
        return null

    # Solo tengo una carta, la juego
    var mi_carta = cartas[0]

    # Evaluar si vale la pena jugar o irse al mazo
    # (esto se puede expandir con decisiones de mazo en el futuro)

    return mi_carta

#endregion

#region NIVEL 3: DECISIONES DE TRUCO

# Decide si La Muerte debe cantar TRUCO
# Contexto adicional necesario:
# {
#     "puntos_jugador": int,
#     "puntos_muerte": int,
#     "puntos_para_ganar": int,
#     "estado_truco": int,  # 0=ninguno, 1=truco, 2=retruco, 3=vale4
#     ... contexto de ronda ...
# }
static func debe_cantar_truco(cartas: Array, contexto: Dictionary) -> bool:
    var fuerza = evaluar_fuerza_mano(cartas)
    var puntos_muerte = contexto.get("puntos_muerte", 0)
    var puntos_jugador = contexto.get("puntos_jugador", 0)
    var puntos_para_ganar = contexto.get("puntos_para_ganar", 30)
    var ronda = contexto.get("ronda_actual", 1)
    var _resultado_r1 = contexto.get("resultado_ronda_1", 0)
    var estado_truco = contexto.get("estado_truco", 0)

    # No cantar si ya hay truco activo
    if estado_truco != 0:
        return false

    # Solo cantar en ronda 1 o 2 (en ronda 3 ya no tiene sentido)
    if ronda > 2:
        return false

    # Evaluar situación de puntos
    var puntos_faltantes_muerte = puntos_para_ganar - puntos_muerte
    var _puntos_faltantes_jugador = puntos_para_ganar - puntos_jugador
    var esta_cerca_de_ganar = puntos_faltantes_muerte <= 5
    var esta_perdiendo_mucho = puntos_jugador > puntos_muerte + 5

    # ESTRATEGIA SEGÚN FUERZA Y SITUACIÓN

    # Mano excelente (75+): cantar truco frecuentemente
    if fuerza >= 75:
        return randf() < 0.7  # 70% de probabilidad

    # Mano buena (55-75): cantar si estoy cerca de ganar o perdiendo
    elif fuerza >= 55:
        if esta_cerca_de_ganar or esta_perdiendo_mucho:
            return randf() < 0.5
        return randf() < 0.3

    # Mano regular (35-55): solo si estoy desesperada (perdiendo mucho)
    elif fuerza >= 35:
        if esta_perdiendo_mucho:
            return randf() < 0.3  # Bluffing desesperado
        return false

    # Mano mala (<35): casi nunca cantar (excepto bluff muy raro)
    else:
        return randf() < 0.05  # 5% de bluff

# Decide cómo responder al TRUCO del jugador
# Retorna: "quiero", "retruco", "no_quiero"
static func responder_truco(cartas: Array, contexto: Dictionary) -> String:
    var fuerza = evaluar_fuerza_mano(cartas)
    var puntos_muerte = contexto.get("puntos_muerte", 0)
    var puntos_jugador = contexto.get("puntos_jugador", 0)
    var puntos_para_ganar = contexto.get("puntos_para_ganar", 30)
    var estado_truco = contexto.get("estado_truco", 0)
    var _ronda = contexto.get("ronda_actual", 1)
    var _resultado_r1 = contexto.get("resultado_ronda_1", 0)
    var puntos_en_juego = contexto.get("puntos_en_juego", 1)

    # Evaluar situación
    var puntos_faltantes_muerte = puntos_para_ganar - puntos_muerte
    var esta_cerca_de_ganar = puntos_faltantes_muerte <= puntos_en_juego + 2
    var esta_perdiendo_mucho = puntos_jugador > puntos_muerte + 7

    # Si estoy MUY cerca de ganar y tengo mano decente, ser más agresiva
    if esta_cerca_de_ganar and fuerza >= 45:
        if fuerza >= 70:
            return "retruco" if estado_truco == 1 else "quiero"
        return "quiero"

    # DECISIÓN SEGÚN FUERZA

    # Mano excelente (75+)
    if fuerza >= 75:
        # Alta probabilidad de subir la apuesta
        if estado_truco == 1 and randf() < 0.7:  # Truco → Retruco
            return "retruco"
        elif estado_truco == 2 and randf() < 0.5:  # Retruco → Vale 4
            return "vale_cuatro"
        return "quiero"

    # Mano buena (55-75)
    elif fuerza >= 55:
        # Acepta, rara vez sube
        if estado_truco == 1 and randf() < 0.3:
            return "retruco"
        return "quiero"

    # Mano regular (35-55)
    elif fuerza >= 35:
        # Depende de la situación
        if esta_perdiendo_mucho:
            return "quiero"  # Desesperación
        elif fuerza >= 45 and randf() < 0.5:
            return "quiero"
        return "no_quiero"

    # Mano mala (<35)
    else:
        # Generalmente rechazar
        if esta_cerca_de_ganar and fuerza >= 25:
            return "quiero"  # Último intento
        return "no_quiero"

# Evalúa si vale la pena irse al mazo
static func debe_irse_al_mazo(cartas: Array, contexto: Dictionary) -> bool:
    var fuerza = evaluar_fuerza_mano(cartas)
    var ronda = contexto.get("ronda_actual", 1)
    var resultado_r1 = contexto.get("resultado_ronda_1", 0)
    var _resultado_r2 = contexto.get("resultado_ronda_2", 0)
    var puntos_en_juego = contexto.get("puntos_en_juego", 1)
    var puntos_muerte = contexto.get("puntos_muerte", 0)
    var puntos_para_ganar = contexto.get("puntos_para_ganar", 30)

    # Nunca irse al mazo con puntos en juego <= 1
    if puntos_en_juego <= 1:
        return false

    # Si estoy muy cerca de ganar, no irse al mazo
    var puntos_faltantes = puntos_para_ganar - puntos_muerte
    if puntos_faltantes <= 3:
        return false

    # Evaluar según ronda
    if ronda == 1:
        # Ronda 1: irse al mazo si mano es HORRIBLE y hay mucho en juego
        if fuerza < 20 and puntos_en_juego >= 3:
            return randf() < 0.4
        return false

    elif ronda == 2:
        # Ronda 2: si perdí la 1ª y tengo mano mala
        if resultado_r1 == 1 and fuerza < 30 and puntos_en_juego >= 3:
            return randf() < 0.5
        return false

    else:
        # Ronda 3: casi nunca irse (ya invertiste 2 cartas)
        return false

#endregion

#region NIVEL 4: DECISIONES DE ENVIDO

# Decide si La Muerte debe cantar ENVIDO
# Contexto esperado:
# {
#     "puntos_envido_muerte": int,
#     "puntos_envido_jugador": int (estimado si no se sabe),
#     "puntos_muerte": int,
#     "puntos_jugador": int,
#     "puntos_para_ganar": int,
#     "ronda_actual": int,
#     "fuerza_mano": float
# }
static func debe_cantar_envido(contexto: Dictionary) -> bool:
    var puntos_envido = contexto.get("puntos_envido_muerte", 0)
    var puntos_muerte = contexto.get("puntos_muerte", 0)
    var puntos_jugador = contexto.get("puntos_jugador", 0)
    var puntos_para_ganar = contexto.get("puntos_para_ganar", 30)
    var _fuerza_mano = contexto.get("fuerza_mano", 50.0)
    var ronda = contexto.get("ronda_actual", 1)

    # Solo cantar en primera ronda (antes de jugar carta)
    if ronda > 1:
        return false

    # Evaluar situación de partida
    var puntos_faltantes_muerte = puntos_para_ganar - puntos_muerte
    var esta_cerca_de_ganar = puntos_faltantes_muerte <= 5
    var esta_perdiendo = puntos_jugador > puntos_muerte + 3

    # ESTRATEGIA SEGÚN PUNTOS DE ENVIDO

    # Envido excelente (28+): Casi siempre cantar
    if puntos_envido >= 28:
        if esta_cerca_de_ganar:
            return randf() < 0.9  # 90% - puede definir la partida
        return randf() < 0.8  # 80%

    # Envido muy bueno (25-27): Cantar frecuentemente
    elif puntos_envido >= 25:
        if esta_cerca_de_ganar or esta_perdiendo:
            return randf() < 0.7
        return randf() < 0.5

    # Envido bueno (22-24): Cantar a veces
    elif puntos_envido >= 22:
        if esta_cerca_de_ganar:
            return randf() < 0.5
        elif esta_perdiendo:
            return randf() < 0.4
        return randf() < 0.3

    # Envido regular (18-21): Rara vez cantar (bluff)
    elif puntos_envido >= 18:
        if esta_perdiendo and randf() < 0.2:
            return true  # Bluff desesperado
        return false

    # Envido bajo (<18): Casi nunca
    else:
        return randf() < 0.05  # 5% bluff extremo

# Decide cómo responder al ENVIDO del jugador
# Retorna: "envido", "real_envido", "falta_envido", "quiero", "no_quiero"
static func responder_envido(contexto: Dictionary) -> String:
    var puntos_envido = contexto.get("puntos_envido_muerte", 0)
    var puntos_muerte = contexto.get("puntos_muerte", 0)
    var puntos_jugador = contexto.get("puntos_jugador", 0)
    var puntos_para_ganar = contexto.get("puntos_para_ganar", 30)
    var estado_envido = contexto.get("estado_envido", 0)  # 0=ninguno, 1=envido, 2=envido-envido, 3=real, 4=falta
    var puntos_en_juego = contexto.get("puntos_envido_en_juego", 2)
    var _fuerza_mano = contexto.get("fuerza_mano", 50.0)

    # Evaluar situación
    var puntos_faltantes_muerte = puntos_para_ganar - puntos_muerte
    var puntos_faltantes_jugador = puntos_para_ganar - puntos_jugador
    var esta_cerca_de_ganar = puntos_faltantes_muerte <= puntos_en_juego + 3
    var esta_perdiendo_mucho = puntos_jugador > puntos_muerte + 8

    # LÓGICA SEGÚN PUNTOS DE ENVIDO

    # Envido excelente (28+)
    if puntos_envido >= 28:
        # Subir la apuesta si es posible
        if estado_envido == 1:  # ENVIDO → subir
            if randf() < 0.6:
                return "real_envido"
            elif randf() < 0.3:
                return "envido"  # Envido-envido
            return "quiero"
        elif estado_envido == 2:  # ENVIDO-ENVIDO → subir
            if randf() < 0.5:
                return "real_envido"
            return "quiero"
        elif estado_envido == 3:  # REAL ENVIDO
            # Considerar falta envido si conviene
            if esta_cerca_de_ganar and puntos_faltantes_jugador > puntos_en_juego:
                return "falta_envido" if randf() < 0.4 else "quiero"
            return "quiero"
        else:  # FALTA ENVIDO
            return "quiero"

    # Envido muy bueno (25-27)
    elif puntos_envido >= 25:
        if estado_envido == 1:  # ENVIDO
            if randf() < 0.3:
                return "envido"  # A veces sube
            return "quiero"
        elif estado_envido == 2:  # ENVIDO-ENVIDO
            return "quiero"
        elif estado_envido == 3:  # REAL ENVIDO
            if randf() < 0.7:
                return "quiero"
            return "no_quiero"
        else:  # FALTA ENVIDO
            if esta_cerca_de_ganar:
                return "quiero"
            return "no_quiero" if randf() < 0.4 else "quiero"

    # Envido bueno (22-24)
    elif puntos_envido >= 22:
        if estado_envido == 1:  # ENVIDO simple
            return "quiero" if randf() < 0.6 else "no_quiero"
        elif estado_envido == 2:  # ENVIDO-ENVIDO
            return "quiero" if randf() < 0.4 else "no_quiero"
        else:  # REAL o FALTA
            return "no_quiero"

    # Envido regular (18-21)
    elif puntos_envido >= 18:
        if estado_envido == 1:  # ENVIDO simple
            # Depende de situación
            if esta_perdiendo_mucho:
                return "quiero"  # Desesperación
            return "no_quiero" if randf() < 0.6 else "quiero"
        else:  # Cualquier otra cosa
            return "no_quiero"

    # Envido bajo (<18)
    else:
        # Casi siempre rechazar
        if estado_envido == 1 and esta_cerca_de_ganar and randf() < 0.3:
            return "quiero"  # Último intento
        return "no_quiero"

# Decide si cantar Falta Envido directamente
static func debe_cantar_falta_envido(contexto: Dictionary) -> bool:
    var puntos_envido = contexto.get("puntos_envido_muerte", 0)
    var puntos_muerte = contexto.get("puntos_muerte", 0)
    var puntos_jugador = contexto.get("puntos_jugador", 0)
    var puntos_para_ganar = contexto.get("puntos_para_ganar", 30)

    # Solo si tengo envido muy alto
    if puntos_envido < 28:
        return false

    # Calcular lo que ganaría con falta envido
    var puntos_falta = puntos_para_ganar - puntos_jugador

    # Si con falta envido puedo ganar la partida
    if puntos_muerte + puntos_falta >= puntos_para_ganar:
        return randf() < 0.4  # 40% de probabilidad (movimiento arriesgado)

    return false

# Evalúa si el envido es coherente con la mano de truco
# (Mano fuerte en envido suele ser débil en truco y viceversa)
static func envido_coherente_con_truco(puntos_envido: int, fuerza_truco: float) -> String:
    # Figuras (10, 11, 12) valen 0 en envido pero pueden ser fuertes en truco
    # Cartas bajas (4, 5, 6) valen poco en truco pero suman en envido

    if puntos_envido >= 25 and fuerza_truco >= 70:
        return "excelente"  # Mano completa (poco común)
    elif puntos_envido >= 25 and fuerza_truco < 40:
        return "envido_fuerte_truco_debil"  # Común
    elif puntos_envido < 20 and fuerza_truco >= 70:
        return "truco_fuerte_envido_debil"  # Común
    else:
        return "regular"

#endregion

#region DEBUG

# Imprime información de debug sobre la mano
static func debug_mano(cartas: Array):
    print("\n=== DEBUG IA MUERTE ===")
    print("Cartas en mano:")
    for carta in cartas:
        var valor = carta.obtener_valor_truco()
        var fuerza = evaluar_fuerza_carta(carta)
        print("  - %s | Valor: %d | Fuerza: %.1f" % [carta.obtener_nombre_completo(), valor, fuerza])

    var fuerza_mano = evaluar_fuerza_mano(cartas)
    var categoria = categorizar_mano(fuerza_mano)
    print("Fuerza de mano: %.1f (%s)" % [fuerza_mano, categoria])
    print("=======================\n")

#endregion
