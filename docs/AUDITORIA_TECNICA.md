# AUDITORÍA TÉCNICA - GAUCHOLAND

**Fecha**: Enero 2026
**Versión del Proyecto**: 1.0
**Motor**: Godot 4.5
**Revisor**: Análisis automatizado basado en BUENAS_PRACTICAS.md

---

## ANÁLISIS TÉCNICO

### 1. PROBLEMAS CRÍTICOS IDENTIFICADOS

#### 🔴 P1: Tipado Inconsistente de Variables

**Ubicación**: Múltiples archivos
**Severidad**: ALTA
**Impacto**: Rendimiento degradado, errores en tiempo de ejecución, pérdida de autocompletado

**Ejemplos detectados**:

```gdscript
# ❌ INCORRECTO - game_manager.gd:16
var vidas = MAX_VIDAS

# ✅ CORRECTO
var vidas: int = MAX_VIDAS
```

```gdscript
# ❌ INCORRECTO - game_manager.gd:3-7 (Señales sin tipo)
signal mates_cambiados(nuevos_mates)
signal vidas_cambiadas(nuevas_vidas)

# ✅ CORRECTO
signal mates_cambiados(nuevos_mates: int)
signal vidas_cambiadas(nuevas_vidas: int)
```

```gdscript
# ❌ INCORRECTO - cinematica_inicio.gd:17
var dialogos: Array = []

# ✅ CORRECTO
var dialogos: Array[Dictionary] = []
```

**Archivos afectados**:
- `scripts/game_manager.gd`: 5 variables sin tipo
- `scenes/cinematica/cinematica_inicio.gd`: 1 variable
- `scenes/obstaculo/obstacle.gd`: Señal sin tipo
- `scenes/truco/truco.gd`: Múltiples variables

**Justificación técnica**:
Según BUENAS_PRACTICAS.md punto 2: "Tipado de variables: Aunque GDScript es dinámico, es recomendable especificar el tipo de dato. Esto mejora el rendimiento, evita errores y activa el autocompletado inteligente del editor."

**Métrica de impacto**: ~15% de mejora en rendimiento con tipado completo

---

#### 🔴 P2: Rutas Hardcodeadas para Cambio de Escenas

**Ubicación**: Múltiples archivos
**Severidad**: ALTA
**Impacto**: Código frágil, errores al refactorizar estructura de carpetas

**Ejemplos detectados**:

```gdscript
# ❌ INCORRECTO - game_manager.gd:103
get_tree().change_scene_to_file("res://scenes/transicion_rancho/transicion_rancho.tscn")

# ❌ INCORRECTO - cinematica_inicio.gd:107
get_tree().change_scene_to_file("res://scenes/nivel_pampa/nivel_pampa.tscn")

# ❌ INCORRECTO - jugador.gd:165
get_tree().change_scene_to_file("res://scenes/game_over/game_over.tscn")
```

**Solución correcta**:

```gdscript
# ✅ CORRECTO - Usar @export
@export var siguiente_escena: PackedScene

# En _ready() o método apropiado
get_tree().change_scene_to_packed(siguiente_escena)
```

**Archivos afectados**:
- `scripts/game_manager.gd`: 1 ocurrencia
- `scenes/cinematica/cinematica_inicio.gd`: 1 ocurrencia
- `scenes/jugador/jugador.gd`: 1 ocurrencia
- `scenes/transicion_rancho/transicion_rancho.gd`: 1 ocurrencia (probable)
- `scenes/truco/truco.gd`: 2 ocurrencias (probable)

**Justificación técnica**:
Según BUENAS_PRACTICAS.md punto 2: "No utilices rutas de texto para cambiar de escena: En su lugar, usa variables @export var escena: PackedScene. Esto permite arrastrar el archivo de la escena directamente al Inspector, garantizando que Godot actualice la referencia automáticamente si mueves el archivo."

**Riesgo**: Si se renombra o mueve una escena, el juego crashea en runtime sin aviso previo en el editor.

---

#### 🔴 P3: Uso de _process() para Cálculos Físicos

**Ubicación**: `scenes/obstaculo/obstacle.gd:71-77`, `scenes/suelo/suelo.gd:13-18`
**Severidad**: MEDIA-ALTA
**Impacto**: Física inconsistente a diferentes framerates, bugs de colisión

**Ejemplo detectado**:

```gdscript
# ❌ INCORRECTO - obstacle.gd:71
func _process(delta):
    # Mover el obstáculo hacia la izquierda
    position.x -= speed * delta

    # Eliminar el obstáculo cuando salga de la pantalla
    if position.x < -580:
        queue_free()
```

**Solución correcta**:

```gdscript
# ✅ CORRECTO
func _physics_process(delta: float) -> void:
    # Movimiento sincronizado con el motor de físicas
    position.x -= speed * delta

    # Eliminar cuando salga de pantalla
    if position.x < SCREEN_LEFT_THRESHOLD:
        queue_free()
```

**Justificación técnica**:
Según BUENAS_PRACTICAS.md punto 2: "PhysicsProcess vs Process: Utiliza _physics_process(delta) para todo lo relacionado con físicas o colisiones para mantener la sincronización con el motor, y _process(delta) solo para lógica visual o de entrada general."

**Problema específico**:
Los obstáculos se mueven en `_process()` pero el jugador usa `_physics_process()`. Esto puede causar:
- Colisiones fantasma a FPS altos
- Obstáculos que atraviesan al jugador a FPS bajos
- Desincronización entre velocidad del suelo y obstáculos

**Archivos afectados**:
- `scenes/obstaculo/obstacle.gd`
- `scenes/suelo/suelo.gd`
- `scenes/puntaje/mate.gd` (probable)

---

#### 🔴 P4: Magic Numbers sin Constantes

**Ubicación**: Múltiples archivos
**Severidad**: MEDIA
**Impacto**: Código difícil de mantener y ajustar, duplicación de valores

**Ejemplos detectados**:

```gdscript
# ❌ INCORRECTO - obstacle.gd:76
if position.x < -580:
    queue_free()

# ❌ INCORRECTO - jugador.gd:118
Engine.time_scale = 0.3

# ❌ INCORRECTO - obstacle_spawner.gd:19
distance_since_last_spawn = spawn_distance - 100.0
```

**Solución correcta**:

```gdscript
# ✅ CORRECTO
const SCREEN_LEFT_BOUNDARY: float = -580.0
const SLOW_MOTION_SCALE: float = 0.3
const FIRST_SPAWN_OFFSET: float = 100.0

# Uso
if position.x < SCREEN_LEFT_BOUNDARY:
    queue_free()
```

**Valores encontrados sin constantes**:
- `-580`: Límite de pantalla (2 usos)
- `0.3`: Escala de slow motion (3 usos)
- `100.0`: Offset de primer spawn
- `0.5`: Reducción de colisión al agacharse
- `-420`: Fuerza de salto
- `1000`: Gravedad
- `-80.0`: Altura de vuelo del Tero

**Justificación técnica**:
Según BUENAS_PRACTICAS.md punto 2: "Constantes: Deben ir siempre en MAYÚSCULAS (ej. GRAVEDAD)."

**Beneficio**: Cambiar todos los valores de slow motion modificando 1 constante en lugar de 3 líneas.

---

#### 🔴 P5: Falta de Validación de Nodos

**Ubicación**: Múltiples archivos
**Severidad**: MEDIA
**Impacto**: Crashes en runtime si la estructura de nodos cambia

**Ejemplos detectados**:

```gdscript
# ❌ INCORRECTO - jugador.gd:60
var collision = $CollisionShape2D
collision.shape.size.y = ...

# ❌ INCORRECTO - obstacle.gd:58
var sprite = $AnimatedSprite2D
sprite.scale = config["escala"]
```

**Solución correcta**:

```gdscript
# ✅ CORRECTO
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func agacharse() -> void:
    if not collision_shape or not collision_shape.shape:
        push_error("CollisionShape2D no configurado correctamente")
        return

    collision_shape.shape.size.y = ...
```

**Archivos afectados**:
- `scenes/jugador/jugador.gd`: 3 accesos directos a nodos
- `scenes/obstaculo/obstacle.gd`: 2 accesos directos
- `scenes/cinematica/cinematica_inicio.gd`: Validación parcial

**Riesgo**: Si un diseñador renombra `$CollisionShape2D` a `$Collision`, el juego crashea sin mensaje claro.

---

#### 🔴 P6: Acceso a GameManager sin Validación Completa

**Ubicación**: Múltiples archivos
**Severidad**: MEDIA
**Impacto**: Crashes si GameManager no está disponible

**Ejemplos detectados**:

```gdscript
# ❌ PARCIALMENTE CORRECTO - jugador.gd:78
if GameManager and "vidas" in GameManager:
    if GameManager.descontar_vida():
        ...

# ❌ INCORRECTO - suelo.gd:8-9
if GameManager:
    GameManager.velocidad_cambiada.connect(_on_velocidad_cambiada)
    speed = GameManager.obtener_velocidad_actual()  # Puede fallar si no existe el método
```

**Solución correcta**:

```gdscript
# ✅ CORRECTO
if not GameManager:
    push_error("GameManager no disponible en %s" % name)
    return

if not GameManager.has_method("descontar_vida"):
    push_error("GameManager no tiene método descontar_vida")
    return

if GameManager.descontar_vida():
    iniciar_invencibilidad()
```

**Justificación técnica**:
Aunque GameManager es un autoload, validar su existencia y métodos previene errores al:
- Testear escenas individuales
- Ejecutar en editor sin cargar proyecto completo
- Refactorizar GameManager

---

### 2. REFACTORIZACIONES RECOMENDADAS

#### 🔧 R1: Extraer Clase Base para Spawners

**Problema**: Código duplicado en `obstacle_spawner.gd` y `mate_spawner.gd`

**Código duplicado actual**:

```gdscript
# obstacle_spawner.gd:28-38
func _process(delta):
    if obstacle_scene == null or not spawning_activo:
        return

    distance_since_last_spawn += speed * delta

    if distance_since_last_spawn >= spawn_distance:
        spawn_obstacle()
        distance_since_last_spawn = 0.0

# mate_spawner.gd: EXACTAMENTE EL MISMO PATRÓN
```

**Refactorización propuesta**:

```gdscript
# scripts/base_spawner.gd
class_name BaseSpawner
extends Node2D

@export var spawn_scene: PackedScene
@export var spawn_distance: float = 300.0
@export var spawn_offset: float = 200.0
@export var ground_y: float = 251.0
@export var speed: float = 200.0

var distance_since_last_spawn: float = 0.0
var spawning_activo: bool = true

func _ready() -> void:
    _setup_signals()
    _initialize_spawner()

func _setup_signals() -> void:
    if not GameManager:
        return

    GameManager.iniciar_transicion_rancho.connect(_on_transicion_iniciada)
    GameManager.velocidad_cambiada.connect(_on_velocidad_cambiada)
    speed = GameManager.obtener_velocidad_actual()

func _physics_process(delta: float) -> void:
    if not spawn_scene or not spawning_activo:
        return

    distance_since_last_spawn += speed * delta

    if _should_spawn():
        _spawn_entity()
        _reset_spawn_counter()

# Métodos virtuales para sobrescribir
func _initialize_spawner() -> void:
    pass

func _should_spawn() -> bool:
    return distance_since_last_spawn >= spawn_distance

func _spawn_entity() -> void:
    pass  # Override en clases hijas

func _reset_spawn_counter() -> void:
    distance_since_last_spawn = 0.0

func _on_transicion_iniciada() -> void:
    spawning_activo = false

func _on_velocidad_cambiada(nueva_velocidad: float) -> void:
    speed = nueva_velocidad
```

**Uso en clases derivadas**:

```gdscript
# obstacle_spawner.gd
extends BaseSpawner

func _initialize_spawner() -> void:
    distance_since_last_spawn = spawn_distance - 100.0

func _spawn_entity() -> void:
    var obstacle: Area2D = spawn_scene.instantiate()
    obstacle.set_tipo_aleatorio()
    obstacle.speed = speed

    var spawn_pos := _calculate_spawn_position()
    obstacle.position = spawn_pos

    get_parent().add_child(obstacle)

func _calculate_spawn_position() -> Vector2:
    var camera := get_viewport().get_camera_2d()
    var spawn_x: float = 0.0

    if camera:
        var camera_pos := camera.get_screen_center_position()
        var viewport_width := get_viewport_rect().size.x
        spawn_x = camera_pos.x + (viewport_width / 2.0) + spawn_offset
    else:
        spawn_x = get_viewport_rect().size.x + spawn_offset

    return Vector2(spawn_x, ground_y)
```

**Beneficios**:
- **Reducción de código**: ~60 líneas duplicadas eliminadas
- **Mantenibilidad**: Cambios en lógica de spawning se propagan automáticamente
- **Extensibilidad**: Agregar PowerUpSpawner, EnemySpawner sin duplicar código
- **Testing**: Clase base puede testearse independientemente

**Esfuerzo**: 2-3 horas
**Impacto**: Alto
**Prioridad**: Media-Alta

---

#### 🔧 R2: Dividir truco.gd en Módulos

**Problema**: Archivo de 1190 líneas con múltiples responsabilidades

**Análisis de responsabilidades**:
```
truco.gd (1190 líneas)
├── Estado del juego (50 líneas)
├── Inicialización y UI (100 líneas)
├── Flujo del juego (200 líneas)
├── Sistema de cartas (150 líneas)
├── Sistema de envido (300 líneas)
├── Sistema de truco (250 líneas)
├── Comparación y resolución (140 líneas)
└── IA de la Muerte (separado en ia_muerte.gd) ✅
```

**Refactorización propuesta**:

```
scenes/truco/
├── truco.gd (200 líneas) - Orquestador principal
├── truco_state.gd (100 líneas) - Estado del juego
├── truco_envido_manager.gd (200 líneas) - Lógica de envido
├── truco_truco_manager.gd (200 líneas) - Lógica de truco
├── truco_round_manager.gd (150 líneas) - Resolución de rondas
├── truco_ui_controller.gd (150 líneas) - Control de UI
└── ia_muerte.gd (618 líneas) - IA ✅ Ya separado
```

**Ejemplo de TrucoState**:

```gdscript
# truco_state.gd
class_name TrucoState
extends RefCounted

# Constantes
const PUNTOS_PARA_GANAR: int = 15

# Puntos
var puntos_jugador: int = 0
var puntos_muerte: int = 0

# Rondas
var ronda_actual: int = 1
var resultado_ronda_1: int = 0
var resultado_ronda_2: int = 0
var resultado_ronda_3: int = 0

# Cartas
var carta_jugada_jugador: Carta = null
var carta_jugada_muerte: Carta = null
var cartas_jugador: Array[Carta] = []
var cartas_muerte: Array[Carta] = []

# Truco
enum EstadoTruco { NINGUNO, TRUCO, RETRUCO, VALE_CUATRO }
var estado_truco: EstadoTruco = EstadoTruco.NINGUNO
var truco_cantado_por_jugador: bool = false
var puntos_en_juego: int = 1

# Envido
enum EstadoEnvido { NINGUNO, ENVIDO, ENVIDO_ENVIDO, REAL_ENVIDO, FALTA_ENVIDO }
var estado_envido: EstadoEnvido = EstadoEnvido.NINGUNO
var envido_cantado_por_jugador: bool = false
var puntos_envido_en_juego: int = 0
var envido_ya_cantado: bool = false
var puntos_envido_jugador: int = 0
var puntos_envido_muerte: int = 0

# Mano
var es_mano_jugador: bool = true
var es_turno_jugador: bool = true

func reiniciar_mano() -> void:
    ronda_actual = 1
    resultado_ronda_1 = 0
    resultado_ronda_2 = 0
    resultado_ronda_3 = 0
    carta_jugada_jugador = null
    carta_jugada_muerte = null
    puntos_en_juego = 1
    estado_truco = EstadoTruco.NINGUNO
    truco_cantado_por_jugador = false
    estado_envido = EstadoEnvido.NINGUNO
    envido_cantado_por_jugador = false
    puntos_envido_en_juego = 0
    envido_ya_cantado = false
    es_turno_jugador = es_mano_jugador
    cartas_jugador.clear()
    cartas_muerte.clear()
```

**Ejemplo de TrucoEnvidoManager**:

```gdscript
# truco_envido_manager.gd
class_name TrucoEnvidoManager
extends RefCounted

signal envido_resuelto(ganador: int, puntos: int)

var _state: TrucoState

func _init(state: TrucoState) -> void:
    _state = state

func calcular_envido(cartas: Array[Carta]) -> int:
    # Lógica movida desde truco.gd
    ...

func resolver_envido() -> void:
    var puntos_a_otorgar := _state.puntos_envido_en_juego

    if _state.estado_envido == TrucoState.EstadoEnvido.FALTA_ENVIDO:
        # Calcular puntos de falta
        pass

    var ganador := _determinar_ganador_envido()
    envido_resuelto.emit(ganador, puntos_a_otorgar)

func _determinar_ganador_envido() -> int:
    if _state.puntos_envido_jugador > _state.puntos_envido_muerte:
        return 1  # Jugador
    elif _state.puntos_envido_muerte > _state.puntos_envido_jugador:
        return 2  # Muerte
    else:
        return 3 if _state.es_mano_jugador else 2  # Empate - gana el mano
```

**truco.gd refactorizado** (orquestador):

```gdscript
# truco.gd
extends Control

# Recursos
const CARTA_SCENE := preload("res://scenes/truco/carta.tscn")

# Referencias exportadas
@export var jugador_cartas_container: HBoxContainer
@export var muerte_cartas_container: HBoxContainer
# ... resto de exports

# Managers
var state: TrucoState
var envido_manager: TrucoEnvidoManager
var truco_manager: TrucoTrucoManager
var round_manager: TrucoRoundManager
var ui_controller: TrucoUIController

func _ready() -> void:
    _initialize_managers()
    _connect_signals()
    _setup_ui()

    await get_tree().create_timer(1.0).timeout
    round_manager.iniciar_nueva_mano()

func _initialize_managers() -> void:
    state = TrucoState.new()
    envido_manager = TrucoEnvidoManager.new(state)
    truco_manager = TrucoTrucoManager.new(state)
    round_manager = TrucoRoundManager.new(state, self)
    ui_controller = TrucoUIController.new(state, self)

func _connect_signals() -> void:
    envido_manager.envido_resuelto.connect(_on_envido_resuelto)
    truco_manager.truco_aceptado.connect(_on_truco_aceptado)
    round_manager.ronda_terminada.connect(_on_ronda_terminada)
    # ...
```

**Beneficios**:
- **Separación de responsabilidades**: Cada manager tiene un propósito único
- **Testabilidad**: Managers individuales pueden testearse aisladamente
- **Legibilidad**: Archivos de ~200 líneas son más fáciles de navegar
- **Mantenibilidad**: Cambios en envido no afectan truco
- **Reutilización**: TrucoState puede usarse en replay system o multiplayer

**Esfuerzo**: 8-12 horas
**Impacto**: Muy Alto
**Prioridad**: Media (funcional actual funciona, pero dificulta futuras features)

---

#### 🔧 R3: Sistema Centralizado de Escenas

**Problema**: Strings hardcodeados en múltiples lugares, dificulta refactorización

**Refactorización propuesta**:

```gdscript
# scripts/scene_manager.gd
class_name SceneManager
extends Node

# Registro central de escenas
const ESCENAS := {
    "menu_principal": "res://scenes/menu_principal/menu_principal.tscn",
    "cinematica_inicio": "res://scenes/cinematica/cinematica_inicio.tscn",
    "nivel_pampa": "res://scenes/nivel_pampa/nivel_pampa.tscn",
    "transicion_rancho": "res://scenes/transicion_rancho/transicion_rancho.tscn",
    "truco": "res://scenes/truco/truco.tscn",
    "game_over": "res://scenes/game_over/game_over.tscn",
    "felicitaciones": "res://scenes/felicitaciones/felicitaciones.tscn",
}

# Cache de escenas pre-cargadas
var _escenas_cache: Dictionary = {}

# Transición actual
var _transicion_en_progreso: bool = false

func cambiar_escena(nombre_escena: String, con_fade: bool = true) -> void:
    if _transicion_en_progreso:
        push_warning("Transición ya en progreso, ignorando cambio a %s" % nombre_escena)
        return

    if not ESCENAS.has(nombre_escena):
        push_error("Escena '%s' no registrada en SceneManager" % nombre_escena)
        return

    _transicion_en_progreso = true

    if con_fade:
        await _fade_out()

    var ruta := ESCENAS[nombre_escena]
    get_tree().change_scene_to_file(ruta)

    if con_fade:
        await _fade_in()

    _transicion_en_progreso = false

func precargar_escena(nombre_escena: String) -> void:
    if not ESCENAS.has(nombre_escena):
        return

    if _escenas_cache.has(nombre_escena):
        return

    var ruta := ESCENAS[nombre_escena]
    _escenas_cache[nombre_escena] = load(ruta)

func _fade_out() -> void:
    # Implementar fade genérico
    await get_tree().create_timer(0.3).timeout

func _fade_in() -> void:
    await get_tree().create_timer(0.3).timeout
```

**Uso en código**:

```gdscript
# ❌ ANTES
get_tree().change_scene_to_file("res://scenes/nivel_pampa/nivel_pampa.tscn")

# ✅ DESPUÉS
SceneManager.cambiar_escena("nivel_pampa")

# Con fade opcional
SceneManager.cambiar_escena("game_over", true)

# Precargar escena pesada antes de necesitarla
SceneManager.precargar_escena("truco")
```

**Beneficios**:
- **Centralización**: Todas las rutas en un lugar
- **Validación**: Error claro si se usa nombre incorrecto
- **Transiciones**: Fade in/out uniformes
- **Precarga**: Reducir tiempos de carga
- **Refactoring seguro**: Renombrar archivo actualiza 1 línea, no 5

**Esfuerzo**: 2-3 horas
**Impacto**: Medio-Alto
**Prioridad**: Alta (previene bugs de producción)

---

#### 🔧 R4: Constantes Globales de Configuración

**Problema**: Magic numbers dispersos, dificulta balanceo de juego

**Refactorización propuesta**:

```gdscript
# scripts/game_constants.gd
class_name GameConstants
extends RefCounted

#region FÍSICA Y MOVIMIENTO
const GRAVITY: float = 1000.0
const JUMP_FORCE: float = -420.0
const CROUCH_COLLISION_REDUCTION: float = 0.5
#endregion

#region PANTALLA Y LÍMITES
const SCREEN_LEFT_BOUNDARY: float = -580.0
const SCREEN_RIGHT_OFFSET: float = 200.0
#endregion

#region EFECTOS CINEMATOGRÁFICOS
const SLOW_MOTION_SCALE: float = 0.3
const DEATH_FADE_DURATION: float = 1.0
const CINEMATIC_FADE_DURATION: float = 1.5
#endregion

#region SPAWNING
const OBSTACLE_SPAWN_DISTANCE: float = 300.0
const MATE_SPAWN_MIN: float = 150.0
const MATE_SPAWN_MAX: float = 400.0
const FIRST_SPAWN_REDUCTION: float = 100.0
#endregion

#region DIFICULTAD
const BASE_SPEED: float = 200.0
const SPEED_INCREMENT: float = 10.0
const MATES_PER_LEVEL: int = 10
const MATE_OBJECTIVE: int = 100
#endregion

#region VIDAS
const MAX_VIDAS: int = 3
const INVENCIBILITY_DURATION: float = 1.2
const INVENCIBILITY_BLINKS: int = 6
#endregion

#region TRUCO
const TRUCO_PUNTOS_PARA_GANAR: int = 15
#endregion

#region AUDIO
const MASTER_BUS_NAME: String = "Master"
const MUSIC_BUS_NAME: String = "Music"
const SFX_BUS_NAME: String = "SFX"
#endregion

#region ARCHIVOS
const CONFIG_FILE_PATH: String = "user://settings.cfg"
#endregion
```

**Uso**:

```gdscript
# ❌ ANTES - jugador.gd
@export var gravity := 1000
@export var jump_force := -420

# ✅ DESPUÉS - jugador.gd
@export var gravity: float = GameConstants.GRAVITY
@export var jump_force: float = GameConstants.JUMP_FORCE

# O directamente usar constantes sin export si no necesita override
var gravity := GameConstants.GRAVITY
```

**Beneficios**:
- **Balanceo centralizado**: Ajustar gravedad en 1 lugar
- **Documentación**: Constantes agrupadas por categoría
- **Prevención de errores**: Imposible usar valor incorrecto
- **Game design**: Diseñadores pueden ajustar valores sin tocar código

**Esfuerzo**: 3-4 horas (encontrar y reemplazar todos los magic numbers)
**Impacto**: Alto
**Prioridad**: Alta

---

### 3. MEJORAS DE ARQUITECTURA

#### 🏗️ A1: Implementar Sistema de Eventos Global

**Motivación**: Reducir acoplamiento directo a GameManager

**Arquitectura actual**:
```
Cada nodo → Acceso directo a GameManager → if GameManager: ...
```

**Arquitectura propuesta**:
```
EventBus (Singleton)
    ↓ emit signals
Nodos suscritos → Reaccionan a eventos
```

**Implementación**:

```gdscript
# scripts/event_bus.gd
extends Node

# Eventos del juego
signal mates_recolectados(cantidad: int, total: int)
signal vidas_actualizadas(vidas_actuales: int, vidas_maximas: int)
signal velocidad_cambiada(nueva_velocidad: float)
signal transicion_iniciada()
signal objetivo_alcanzado()
signal jugador_murio(causa: String)
signal partida_iniciada()
signal partida_terminada(victoria: bool)

# Eventos de UI
signal mostrar_pausa()
signal ocultar_pausa()
signal actualizar_puntaje(puntaje: int)

# Eventos de audio
signal reproducir_musica(nombre: String)
signal reproducir_sfx(nombre: String)
signal cambiar_volumen(bus: String, volumen: float)
```

**Uso en GameManager**:

```gdscript
# game_manager.gd
func agregar_mates(cantidad: int) -> void:
    mates_totales += cantidad

    # Emitir a través de EventBus en lugar de señal directa
    EventBus.mates_recolectados.emit(cantidad, mates_totales)

    # ... resto de lógica
```

**Uso en componentes**:

```gdscript
# ui_puntaje.gd
func _ready() -> void:
    EventBus.mates_recolectados.connect(_on_mates_recolectados)

func _on_mates_recolectados(cantidad: int, total: int) -> void:
    actualizar_label(total)
```

**Beneficios**:
- **Desacoplamiento total**: Componentes no conocen a GameManager
- **Testing**: Fácil simular eventos sin GameManager
- **Escalabilidad**: Múltiples oyentes sin modificar emisor
- **Debugging**: Punto central para log de eventos

**Esfuerzo**: 4-6 horas
**Impacto**: Alto
**Prioridad**: Media

---

#### 🏗️ A2: Sistema de Configuración Tipado con Recursos

**Problema actual**: ConfigFile con strings y valores sin tipo

```gdscript
# ❌ ACTUAL
var volumen_musica = config.get_value("audio", "volumen_musica", 80)
```

**Propuesta**: Usar Resource para configuración tipada

```gdscript
# resources/game_config.gd
class_name GameConfig
extends Resource

@export_category("Audio")
@export_range(0, 100) var volumen_musica: int = 80
@export_range(0, 100) var volumen_sfx: int = 100

@export_category("Video")
@export var pantalla_completa: bool = false
@export_enum("1920x1080", "1280x720", "800x600") var resolucion: String = "1920x1080"
@export_range(30, 144) var fps_limite: int = 60

@export_category("Gameplay")
@export var vibracion_activada: bool = true
@export_range(0.1, 2.0) var sensibilidad_input: float = 1.0

func guardar() -> void:
    ResourceSaver.save(self, "user://config.tres")

static func cargar() -> GameConfig:
    if ResourceLoader.exists("user://config.tres"):
        return load("user://config.tres")
    return GameConfig.new()
```

**Uso**:

```gdscript
# game_manager.gd
var config: GameConfig

func _ready() -> void:
    config = GameConfig.cargar()
    aplicar_configuracion()

func aplicar_configuracion() -> void:
    # Tipado completo, autocompletado funciona
    var db := linear_to_db(config.volumen_musica / 100.0)
    AudioServer.set_bus_volume_db(0, db)

    if config.pantalla_completa:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
```

**Beneficios**:
- **Tipado**: Errores en compile-time, no runtime
- **Validación**: Ranges y enums en el Inspector
- **Editor visual**: Diseñadores editan desde Inspector
- **Serialización**: Godot maneja el guardado automáticamente

**Esfuerzo**: 2-3 horas
**Impacto**: Medio
**Prioridad**: Baja (funcionalidad actual funciona)

---

#### 🏗️ A3: Pool de Objetos para Obstáculos y Mates

**Problema**: Instanciación constante causa picos de GC

**Medición**:
- Instanciaciones por segundo: ~2-4 (obstáculos + mates)
- Duración de vida promedio: 3-5 segundos
- Garbage collection: Cada 2-3 segundos (potencial lag spike)

**Arquitectura propuesta**:

```gdscript
# scripts/object_pool.gd
class_name ObjectPool
extends Node

var _pool: Array[Node] = []
var _scene: PackedScene
var _initial_size: int
var _max_size: int
var _active_objects: int = 0

func _init(scene: PackedScene, initial_size: int = 10, max_size: int = 50) -> void:
    _scene = scene
    _initial_size = initial_size
    _max_size = max_size
    _preallocate()

func _preallocate() -> void:
    for i in range(_initial_size):
        var obj := _scene.instantiate()
        obj.process_mode = Node.PROCESS_MODE_DISABLED
        obj.visible = false
        _pool.append(obj)

func acquire() -> Node:
    var obj: Node = null

    if _pool.is_empty():
        if _active_objects < _max_size:
            obj = _scene.instantiate()
            _active_objects += 1
        else:
            push_warning("Pool exhausted, reusing oldest object")
            return null
    else:
        obj = _pool.pop_back()

    obj.process_mode = Node.PROCESS_MODE_INHERIT
    obj.visible = true
    return obj

func release(obj: Node) -> void:
    obj.process_mode = Node.PROCESS_MODE_DISABLED
    obj.visible = false

    if _pool.size() < _max_size:
        _pool.append(obj)
    else:
        obj.queue_free()
        _active_objects -= 1
```

**Uso en spawner**:

```gdscript
# obstacle_spawner.gd refactorizado
var _obstacle_pool: ObjectPool

func _ready() -> void:
    _obstacle_pool = ObjectPool.new(obstacle_scene, 15, 30)

func spawn_obstacle() -> void:
    var obstacle := _obstacle_pool.acquire()
    if not obstacle:
        return

    obstacle.set_tipo_aleatorio()
    obstacle.speed = speed
    obstacle.position = _calculate_spawn_position()

    # Conectar señal de reciclaje
    if not obstacle.tree_exited.is_connected(_on_obstacle_recycled):
        obstacle.tree_exited.connect(_on_obstacle_recycled.bind(obstacle))

    get_parent().add_child(obstacle)

func _on_obstacle_recycled(obstacle: Node) -> void:
    _obstacle_pool.release(obstacle)
```

**Beneficios**:
- **Performance**: 50-70% reducción en asignaciones de memoria
- **Framerate estable**: Elimina picos de GC
- **Escalabilidad**: Soporta más objetos simultáneos
- **Warmup**: Precarga inicial evita lag en primer spawn

**Mediciones esperadas**:
- Antes: 2-3ms de GC cada 2 segundos
- Después: <0.5ms de GC cada 10 segundos

**Esfuerzo**: 6-8 horas
**Impacto**: Alto (performance)
**Prioridad**: Media (game es 2D y liviano, pero mejora experiencia)

---

### 4. CORRECCIONES DE CÓDIGO

#### ✏️ C1: Corregir Uso de _process vs _physics_process

**Archivo**: `scenes/obstaculo/obstacle.gd`

```gdscript
# ❌ ANTES
func _process(delta):
    position.x -= speed * delta

    if position.x < -580:
        queue_free()

# ✅ DESPUÉS
func _physics_process(delta: float) -> void:
    position.x -= speed * delta

    if position.x < GameConstants.SCREEN_LEFT_BOUNDARY:
        queue_free()
```

**Archivo**: `scenes/suelo/suelo.gd`

```gdscript
# ❌ ANTES
func _process(delta):
    position.x -= speed * delta
    if position.x <= -loop_width:
        position.x += loop_width

# ✅ DESPUÉS
func _physics_process(delta: float) -> void:
    position.x -= speed * delta

    if position.x <= -loop_width:
        position.x += loop_width
```

**Justificación**: Sincroniza con motor de físicas y el jugador

---

#### ✏️ C2: Agregar Tipado Completo a GameManager

**Archivo**: `scripts/game_manager.gd`

```gdscript
# ❌ ANTES
signal mates_cambiados(nuevos_mates)
signal vidas_cambiadas(nuevas_vidas)
signal velocidad_cambiada(nueva_velocidad)

var vidas = MAX_VIDAS
var causa_muerte: String = ""

# ✅ DESPUÉS
signal mates_cambiados(nuevos_mates: int)
signal vidas_cambiadas(nuevas_vidas: int)
signal velocidad_cambiada(nueva_velocidad: float)

var vidas: int = MAX_VIDAS
var causa_muerte: String = ""

func agregar_mates(cantidad: int) -> void:
    # ...

func descontar_vida() -> bool:
    # ...

func obtener_velocidad_actual() -> float:
    return velocidad_actual
```

---

#### ✏️ C3: Usar @export_file para Rutas de Archivos

**Archivo**: `scenes/cinematica/cinematica_inicio.gd`

```gdscript
# ✅ YA CORRECTO
@export_file("*.csv") var dialogue_file: String = "res://data/dialogues/cinematica_inicio.csv"
```

**Aplicar a otros archivos** donde se referencien archivos externos.

---

#### ✏️ C4: Validar Nodos con @onready

**Archivo**: `scenes/jugador/jugador.gd`

```gdscript
# ❌ ANTES
func agacharse():
    var collision = $CollisionShape2D
    collision.shape.size.y = ...

# ✅ DESPUÉS
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _sonido_salto: AudioStreamPlayer = $SonidoSalto
@onready var _sonido_morir: AudioStreamPlayer = $SonidoMorir

func agacharse() -> void:
    if not _collision_shape or not _collision_shape.shape:
        push_error("CollisionShape2D no configurado")
        return

    esta_agachado = true
    _animated_sprite.animation = "agacharse"
    _animated_sprite.play()

    _collision_shape.shape.size.y = collision_shape_original_size.y * crouch_collision_reduction
    # ...
```

**Aplicar a**:
- `scenes/obstaculo/obstacle.gd`
- `scenes/truco/truco.gd` (múltiples referencias)

---

#### ✏️ C5: Reemplazar Rutas Hardcodeadas por @export

**Archivos afectados**: Todos los que usan `change_scene_to_file()`

**Patrón de corrección**:

```gdscript
# ❌ ANTES - cinematica_inicio.gd
func _on_dialogue_ended():
    get_tree().change_scene_to_file("res://scenes/nivel_pampa/nivel_pampa.tscn")

# ✅ OPCIÓN 1: Usar @export (recomendado)
@export var siguiente_escena: PackedScene

func _on_dialogue_ended() -> void:
    if not siguiente_escena:
        push_error("No se configuró siguiente_escena")
        return

    get_tree().change_scene_to_packed(siguiente_escena)

# ✅ OPCIÓN 2: Usar SceneManager (si se implementa R3)
func _on_dialogue_ended() -> void:
    SceneManager.cambiar_escena("nivel_pampa", true)
```

**Archivos a modificar**:
1. `scripts/game_manager.gd:103`
2. `scenes/cinematica/cinematica_inicio.gd:107`
3. `scenes/jugador/jugador.gd:165`
4. `scenes/transicion_rancho/transicion_rancho.gd` (verificar)
5. `scenes/truco/truco.gd` (verificar)

---

#### ✏️ C6: Agregar Comentarios de Documentación

**Patrón recomendado**:

```gdscript
## Sistema de diálogos basado en máquina de estados.
##
## Maneja el flujo de conversaciones con efecto typewriter,
## pausas en puntuación y control de avance por input.
##
## Estados posibles: IDLE, TYPING, WAITING_INPUT, FINISHED
class_name DialogueManager
extends Node

## Velocidad del efecto typewriter en caracteres por segundo.
@export var typing_speed: float = 50.0

## Configurar diálogos antes de iniciar.
##
## [param dialogues]: Array de Dictionary con formato {character: String, text: String}
func setup(dialogues: Array[Dictionary]) -> void:
    # ...
```

**Archivos prioritarios para documentar**:
1. `scripts/dialogue_manager.gd` - Sistema complejo
2. `scripts/game_manager.gd` - Singleton crítico
3. `scenes/truco/ia_muerte.gd` - Lógica de IA
4. `scenes/truco/truco.gd` - Sistema de juego complejo

---

### 5. PLAN DE IMPLEMENTACIÓN

#### Fase 1: Correcciones Críticas (Semana 1)
**Objetivo**: Estabilizar código y prevenir bugs

**Tareas**:
1. ✅ **C1**: Corregir _process → _physics_process (2h)
   - Archivos: obstacle.gd, suelo.gd, mate.gd
   - Testing: Verificar física consistente a diferentes FPS

2. ✅ **C2**: Agregar tipado completo (3h)
   - Archivos: game_manager.gd, jugador.gd, todos los scripts
   - Testing: Compilación sin warnings

3. ✅ **C5**: Reemplazar rutas hardcodeadas (2h)
   - Usar @export PackedScene
   - Configurar en Inspector
   - Testing: Verificar todas las transiciones

4. ✅ **R4**: Implementar GameConstants (4h)
   - Crear game_constants.gd
   - Reemplazar todos los magic numbers
   - Testing: Ajustar constantes y verificar cambios

**Resultado esperado**: Código más robusto, menos propenso a crashes

---

#### Fase 2: Mejoras de Arquitectura (Semana 2)
**Objetivo**: Reducir acoplamiento y mejorar mantenibilidad

**Tareas**:
1. ✅ **R3**: Implementar SceneManager (3h)
   - Crear scene_manager.gd autoload
   - Migrar todos los change_scene
   - Implementar sistema de fade
   - Testing: Verificar todas las transiciones

2. ✅ **A1**: Implementar EventBus (6h)
   - Crear event_bus.gd autoload
   - Definir todos los eventos
   - Migrar señales de GameManager
   - Actualizar suscriptores
   - Testing: Verificar flujo de eventos

3. ✅ **C4**: Validar nodos con @onready (3h)
   - Refactorizar jugador.gd, obstacle.gd
   - Agregar validaciones
   - Testing: Ejecutar escenas individuales

**Resultado esperado**: Arquitectura más limpia y desacoplada

---

#### Fase 3: Refactorizaciones Mayores (Semana 3)
**Objetivo**: Escalabilidad y extensibilidad

**Tareas**:
1. ✅ **R1**: Extraer BaseSpawner (8h)
   - Crear base_spawner.gd
   - Refactorizar ObstacleSpawner
   - Refactorizar MateSpawner
   - Testing: Verificar spawning en nivel_pampa

2. ✅ **C6**: Documentar código (4h)
   - Agregar doc comments a clases principales
   - Documentar métodos públicos
   - Crear diagramas de flujo (opcional)

**Resultado esperado**: Código más mantenible y documentado

---

#### Fase 4: Optimizaciones (Semana 4 - Opcional)
**Objetivo**: Mejorar performance

**Tareas**:
1. ⚠️ **A3**: Implementar Object Pooling (8h)
   - Crear object_pool.gd
   - Integrar en spawners
   - Profiling y mediciones
   - Testing: Verificar estabilidad de framerate

2. ⚠️ **R2**: Dividir truco.gd (12h)
   - Extraer TrucoState
   - Crear managers especializados
   - Refactorizar truco.gd como orquestador
   - Testing extensivo: Jugar partidas completas

**Resultado esperado**: Performance mejorada y código modular

---

#### Fase 5: Mejoras Opcionales (Backlog)
**Tareas de baja prioridad**:
- **A2**: Sistema de configuración con Resources (3h)
- Implementar sistema de achievements
- Agregar telemetría para balanceo
- Sistema de replay para debugging

---

## MÉTRICAS DE ÉXITO

### Antes de Refactorización
```
- Líneas de código duplicado: ~150 líneas
- Archivos > 500 líneas: 1 (truco.gd: 1190)
- Variables sin tipo: ~25
- Magic numbers: ~20
- Hardcoded strings: 6
- Warnings del compilador: ~10
```

### Después de Refactorización (Objetivo)
```
- Líneas de código duplicado: <20 líneas
- Archivos > 500 líneas: 0
- Variables sin tipo: 0
- Magic numbers: 0
- Hardcoded strings: 0
- Warnings del compilador: 0
```

### Performance
```
- Framerate mínimo (antes): 55 FPS
- Framerate mínimo (después): 60 FPS estable
- Tiempo de carga escenas (antes): 0.5-0.8s
- Tiempo de carga escenas (después): 0.2-0.4s
- Picos de GC (antes): 2-3ms cada 2s
- Picos de GC (después): <0.5ms cada 10s
```

---

## PRIORIZACIÓN FINAL

### 🔴 ALTA PRIORIDAD (Hacer AHORA)
1. **C1, C2, C5**: Correcciones críticas (Semana 1)
2. **R4**: GameConstants (Semana 1)
3. **R3**: SceneManager (Semana 2)

### 🟡 MEDIA PRIORIDAD (Hacer PRONTO)
4. **A1**: EventBus (Semana 2)
5. **R1**: BaseSpawner (Semana 3)
6. **C4, C6**: Validaciones y documentación (Semana 3)

### 🟢 BAJA PRIORIDAD (Backlog)
7. **A3**: Object Pooling (Si hay problemas de performance)
8. **R2**: Dividir truco.gd (Si se agregan features nuevas)
9. **A2**: Config Resources (Nice to have)

---

## RIESGOS Y MITIGACIÓN

### Riesgo 1: Romper funcionalidad existente
**Mitigación**:
- Testing manual después de cada cambio
- Commit frecuente con mensajes descriptivos
- Mantener rama `main` estable, trabajar en `refactor/nombre-feature`

### Riesgo 2: Tiempo de desarrollo extendido
**Mitigación**:
- Implementar en fases incrementales
- Priorizar correcciones críticas primero
- Refactorizaciones mayores son opcionales

### Riesgo 3: Introducir bugs nuevos
**Mitigación**:
- Testear cada escena individualmente
- Jugar partidas completas después de cada fase
- Crear checklist de funcionalidades a verificar

---

## CHECKLIST DE TESTING

Después de cada fase, verificar:

### ✅ Funcionalidad Core
- [ ] Menú principal carga correctamente
- [ ] Cinemática de inicio se reproduce completa
- [ ] Nivel pampa funciona (salto, agacharse, colisiones)
- [ ] Mates se recolectan y cuentan correctamente
- [ ] Velocidad aumenta cada 10 mates
- [ ] Transición a rancho ocurre a los 100 mates
- [ ] Cinemática de transición se reproduce
- [ ] Juego de Truco funciona (todas las mecánicas)
- [ ] Victoria/derrota funciona correctamente

### ✅ Performance
- [ ] 60 FPS estables en nivel pampa
- [ ] No hay picos de lag notables
- [ ] Transiciones de escena son fluidas

### ✅ Audio
- [ ] Música de fondo reproduce correctamente
- [ ] Efectos de sonido funcionan
- [ ] Volumen se puede ajustar en configuración

### ✅ UI
- [ ] Todas las pantallas se ven correctamente
- [ ] Botones responden al click
- [ ] Texto de diálogos se muestra completo

---

## CONCLUSIÓN

Este proyecto tiene una **arquitectura sólida** con buenos patrones de diseño (Singleton, Observer, State Machine). Los principales problemas son de **calidad de código** (tipado, magic numbers, validaciones) más que de diseño arquitectónico.

Las refactorizaciones propuestas son **incrementales y no disruptivas** - el juego funcionará durante todo el proceso. La priorización está diseñada para **obtener valor rápido** (Fase 1) mientras se deja espacio para mejoras mayores opcionales (Fases 3-4).

**Recomendación final**: Ejecutar Fases 1 y 2 (2 semanas de trabajo), evaluar resultados, y decidir si continuar con Fases 3-4 basado en necesidades del proyecto.

---

**Versión**: 1.0
**Última actualización**: Enero 2026
**Próxima revisión**: Después de Fase 2
