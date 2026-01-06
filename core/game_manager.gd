# game_manager.gd
# Gestión del estado global del juego
# NOTA: Este manager ahora delega la mayoría de funcionalidades
# a managers especializados (ScoreManager, LivesManager, etc.)
extends Node

# ============================================================
# SEÑALES (Ahora solo redireccionan)
# ============================================================
# Estas señales se mantienen por compatibilidad pero redireccionan
# a los managers especializados

# ============================================================
# VARIABLES DE COMPATIBILIDAD
# ============================================================
# Propiedades de solo lectura que delegan a otros managers
var mates_totales: int:
    get: return ScoreManager.obtener_mates() if ScoreManager else 0

var vidas: int:
    get: return LivesManager.obtener_vidas() if LivesManager else 0

var causa_muerte: String:
    get: return LivesManager.obtener_causa_muerte() if LivesManager else ""
    set(value): LivesManager.establecer_causa_muerte(value) if LivesManager else null

# ============================================================
# REFERENCIAS A OTROS MANAGERS
# ============================================================
# Estos se acceden como autoloads:
# - DifficultyManager
# - ConfigManager
# - SceneManager
# - ScoreManager
# - LivesManager

# ============================================================
# LIFECYCLE
# ============================================================
func _ready() -> void:
    # Conectar señales de los managers especializados a las propias
    # para mantener compatibilidad con código existente
    if ScoreManager:
        ScoreManager.mates_cambiados.connect(_reenviar_mates_cambiados)
        ScoreManager.objetivo_alcanzado.connect(_reenviar_objetivo_alcanzado)

    if LivesManager:
        LivesManager.vidas_cambiadas.connect(_reenviar_vidas_cambiadas)

# ============================================================
# PUBLIC METHODS (COMPATIBILIDAD)
# ============================================================

## Agrega mates recolectados (delega a ScoreManager)
func agregar_mates(cantidad: int) -> void:
    if ScoreManager:
        ScoreManager.agregar_mates(cantidad)

## Descuenta una vida (delega a LivesManager)
func descontar_vida() -> bool:
    if LivesManager:
        return LivesManager.descontar_vida()
    return false

## Reinicia el estado del juego (delega a todos los managers)
func reiniciar_juego() -> void:
    if ScoreManager:
        ScoreManager.reiniciar()
    if LivesManager:
        LivesManager.reiniciar()
    if DifficultyManager:
        DifficultyManager.reiniciar()

    print("🔄 Juego reiniciado (GameManager)")

## Obtiene los mates recolectados (delega a ScoreManager)
func obtener_mates() -> int:
    return ScoreManager.obtener_mates() if ScoreManager else 0

## Obtiene las vidas restantes (delega a LivesManager)
func obtener_vidas() -> int:
    return LivesManager.obtener_vidas() if LivesManager else 0

## Verifica si el objetivo fue alcanzado (delega a ScoreManager)
func objetivo_fue_alcanzado() -> bool:
    return ScoreManager.objetivo_fue_alcanzado() if ScoreManager else false

## Obtiene la velocidad actual del juego (delega a DifficultyManager)
func obtener_velocidad_actual() -> float:
    return DifficultyManager.obtener_velocidad_actual() if DifficultyManager else 200.0

## Verifica si está en transición (delega a SceneManager)
func en_transicion() -> bool:
    return SceneManager.esta_en_transicion() if SceneManager else false

# ============================================================
# SIGNAL HANDLERS (REENVÍO DE SEÑALES)
# ============================================================

func _reenviar_mates_cambiados(_nuevos_mates: int) -> void:
    # Reenviar señal para compatibilidad
    pass  # Las escenas deben conectarse directamente a ScoreManager.mates_cambiados

func _reenviar_vidas_cambiadas(_nuevas_vidas: int) -> void:
    # Reenviar señal para compatibilidad
    pass  # Las escenas deben conectarse directamente a LivesManager.vidas_cambiadas

func _reenviar_objetivo_alcanzado() -> void:
    # Reenviar señal para compatibilidad
    pass  # Las escenas deben conectarse directamente a ScoreManager.objetivo_alcanzado
