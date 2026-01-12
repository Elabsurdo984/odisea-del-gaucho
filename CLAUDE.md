# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**La Odisea del Gaucho** is a Godot 4.5 endless runner game built with GDScript. The game features a player character that runs automatically while jumping over obstacles and collecting mates in a side-scrolling environment. After collecting 100 mates, the player experiences a cinematic transition to a rancho where they face "La Muerte" (Death) in a Truco card game.

## Running the Game

This is a Godot project. Open it in Godot Editor (version 4.5+) and press F5 to run. The main scene is `scenes/menu_principal/menu_principal.tscn`.

## Game Flow

1. **Main Menu** → Player selects "Jugar"
2. **Opening Cinematic** (`cinematica_inicio.tscn`) → Dialogue between Gaucho and La Muerte
3. **Gameplay** (`nivel_pampa.tscn`) → Endless runner with obstacles and mates
4. **Transition Cinematic** (`transicion_rancho.tscn`) → When 100 mates collected
5. **Truco Card Game** (`truco.tscn`) → Final challenge against La Muerte
6. **Victory/Defeat**:
   - **If Player Wins**: Victory Cinematic (`jugador_victoria.tscn`) → "Continuará..." Screen → Main Menu
   - **If Player Loses**: Defeat Cinematic (`muerte_victoria.tscn`) → Game Over Screen

## Project Architecture

### Scene Hierarchy

**Main Menu**: `scenes/menu_principal/menu_principal.tscn`
- Entry point with options: Jugar, Como Jugar, Configuración, Salir
- Styled with pampa-themed visuals
- "Jugar" button loads the opening cinematic

**Opening Cinematic**: `scenes/cinematica/cinematica_inicio.tscn`
- Introduces the story with dialogue between characters
- Features fade-in effects and typewriter text
- Loads dialogues from `data/dialogues/cinematica_inicio.csv`
- Transitions to gameplay after dialogue ends

**Gameplay Scene**: `scenes/nivel_pampa/nivel_pampa.tscn`
- Instantiates the base level scene (`scenes/nivel/nivel.tscn`)
- Adds the player character
- Adds Camera2D for following the action
- Includes pause menu and score UI

**Base Level**: `scenes/nivel/nivel.tscn`
- Contains the scrolling ground (`Suelo`)
- Contains ObstacleSpawner and MateSpawner (independent systems)
- No central coordinator - spawners work independently

**Transition Cinematic**: `scenes/transicion_rancho/transicion_rancho.tscn`
- Triggered when player collects 100 mates
- Rancho appears in background with fade-in
- La Muerte appears during dialogue
- Loads dialogues from `data/dialogues/transicion_rancho.csv`
- Transitions to Truco card game

**Truco Card Game**: `scenes/truco_game/truco.tscn`
- Turn-based card game against "La Muerte"
- Uses Argentine Truco rules
- Victory condition: First to reach `_puntos_ganar` points (default: 30, configurable for testing)
- **Victory Flow**: When player reaches target points → Victory message → Victory cinematic
- **Defeat Flow**: When La Muerte reaches target points → Defeat message → Defeat cinematic

### Core Systems

**1. GameManager (Singleton)** (`scripts/game_manager.gd`)
- Autoloaded singleton managing global game state
- Tracks mates collected and game objective (100 mates)
- **Progressive Difficulty System**:
  - Base velocity: 200 px/s
  - Increases by 10 px/s every 10 mates collected
  - Emits `velocidad_cambiada` signal for synchronized speed updates
  - Emits `mates_cambiados` signal for UI updates
- **Transition Management**:
  - Handles slow-motion effect (Engine.time_scale = 0.3) when reaching 100 mates
  - Emits `iniciar_transicion_rancho` to stop spawners
  - Changes scene to transition cinematic
  - Sets `en_transicion` flag to prevent player death during transition
- **Configuration Loading**: Applies saved audio and video settings on startup
- **Key Methods**:
  - `agregar_mates(cantidad)`: Adds mates and checks for velocity increase and objective
  - `iniciar_secuencia_transicion()`: Handles the complete transition sequence
  - `aumentar_velocidad()`: Increases game speed based on difficulty tier
  - `reiniciar_mates()`: Resets game state
  - `obtener_velocidad_actual()`: Returns current game speed

**2. Dialogue System** (`scripts/dialogue_*.gd`, `scenes/dialogue_ui/`)

**DialogueManager** (`scripts/dialogue_manager.gd`):
- Manages dialogue flow and presentation
- **Typewriter Effect**: Characters appear one by one at configurable speed
- **State Machine**: IDLE → TYPING → WAITING_INPUT → FINISHED
- Can skip typing by pressing advance key
- Punctuation delay for natural pacing
- Signals: `dialogue_started`, `dialogue_line_started`, `dialogue_line_finished`, `dialogue_ended`
- References: name_label, text_label, continue_indicator

**DialogueLoader** (`scripts/dialogue_loader.gd`):
- Loads dialogues from CSV files
- Format: `character,text` (header row followed by dialogue lines)
- Static methods: `load_from_csv()`, `load_multiple_csvs()`, `save_to_csv()`, `validate_dialogues()`
- Returns Array of Dictionaries: `[{character: String, text: String}, ...]`

**DialogueUI** (`scenes/dialogue_ui/dialogue_ui.tscn`):
- Visual representation of dialogue box
- Contains DialogueManager node
- Methods: `mostrar()`, `ocultar()`, `get_dialogue_manager()`
- Used by both cinematics

**3. Obstacle Spawning System** (`scenes/obstaculo/`)

**Spawner** (`obstacle_spawner.gd`):
- Independent distance-based spawner (no coordinator)
- Spawns obstacles when accumulated distance >= spawn_distance
- Key exports: `obstacle_scene`, `spawn_distance` (300px), `ground_y` (251.0), `speed` (200.0), `spawn_offset` (200px)
- Listens to GameManager signals:
  - `iniciar_transicion_rancho`: Sets `spawning_activo = false`
  - `velocidad_cambiada`: Updates speed
- Camera-based spawning: spawn_x = camera.x + (viewport_width / 2) + spawn_offset
- Sets obstacle type and speed before adding to scene

**Obstacles** (`obstacle.gd`):
- Area2D with four types: CACTUS_ALTO, PIEDRA_BAJA, ARBUSTO_MEDIO, TERO (flying)
- Each type has unique configuration: animation, scale, collision size, y-offset
- `set_tipo_aleatorio()`: Randomly selects obstacle type
- `configurar_tipo()`: Applies type configuration to sprite and collision
- Moves left at synchronized speed
- Auto-deletes when x < -580
- Emits `jugador_muerto` signal on player collision

**4. Collectibles Spawning System** (`scenes/puntaje/`)

**Spawner** (`mate_spawner.gd`):
- Independent spawner with randomized distances
- Spawns when accumulated distance >= next_spawn_distance
- Key exports: `mate_scene`, `spawn_min_distance` (150px), `spawn_max_distance` (400px), `ground_y` (200.0), `speed` (200.0), `spawn_offset` (200px)
- Randomizes `next_spawn_distance` after each spawn for variety
- Listens to `GameManager.iniciar_transicion_rancho`
- Retry logic: max 3 attempts before postponing spawn

**Mates** (`mate.gd`):
- Area2D collectible items
- Awards 1 point to GameManager when collected
- Auto-deletes when off-screen or collected

**5. Infinite Scrolling Ground** (`scenes/suelo/suelo.gd`)
- TileMapLayer that moves left at current game speed
- Implements looping: when position.x <= -loop_width, position.x += loop_width
- Speed synchronized via GameManager's `velocidad_cambiada` signal
- Loop width configurable via `@export var loop_width` (2000px default)

**6. Player Character** (`scenes/jugador/jugador.gd`)
- CharacterBody2D with jump and crouch mechanics
- Automatically added to "player" group in `_ready()`
- Physics: gravity (1000), jump_force (-420)
- Input actions:
  - "salto" (Space/Up): Jump when on floor and not crouching
  - "agacharse" (S/Down): Crouch with reduced collision and animation
- Crouch mechanics:
  - Plays "agacharse" animation (non-looping)
  - Reduces collision height by 50%
  - Adjusts collision position to keep player on ground
  - Cannot jump while crouching
- Death sequence:
  - Checks `GameManager.en_transicion` flag - ignores death during transition
  - Red tint, pause game, reload scene after 1 second
  - Plays death sound
- Must be in collision layer 2 ("Jugador") to interact with obstacles

**7. Cinematics** (`scenes/cinematics/`)

**Opening Cinematic** (`intro_cinematic/cinematica_inicio.gd`):
- Loads dialogues from `res://data/dialogues/cinematica_inicio.csv`
- Sequence: Wait → Fade in La Muerte → Show dialogue UI → Start dialogue
- On dialogue end: transitions to `nivel_pampa.tscn`
- Ensures Engine.time_scale = 1.0 on startup

**Transition Cinematic** (`rancho_transition/transicion_rancho.gd`):
- Triggered by GameManager when 100 mates collected
- Loads dialogues from `res://data/dialogues/transicion_rancho.csv`
- Sequence: Wait → Fade in Rancho → Show dialogue → Fade in La Muerte
- On dialogue end: fade out → transition to `truco.tscn`

**Victory Cinematic** (`jugador_victoria/jugador_victoria.gd`):
- Triggered when player wins Truco game (reaches target points first)
- Loads dialogues from `res://data/dialogues/jugador_gana_truco.csv`
- **Epic Dialogue**: La Muerte acknowledges defeat and warns the journey continues
- Visual: Nocturnal scene with moon, stars, Gaucho and La Muerte face-to-face
- Sequence: Wait → Show dialogue UI → Start dialogue → Fade out
- On dialogue end: transitions to "Continuará..." screen

**Defeat Cinematic** (`muerte_victoria/muerte_victoria.gd`):
- Triggered when La Muerte wins Truco game
- Loads dialogues from `res://data/dialogues/muerte_gana_truco.csv`
- On dialogue end: transitions to Game Over screen

**8. TransitionManager** (`systems/transitions/transition_manager.gd`)
- Centralized utility class for scene transitions and fade effects
- Eliminates code duplication across cinematics and UI screens
- **Static Methods**:
  - `transition_to_scene()`: Complete transition (hide UI → wait → fade out → change scene)
  - `quick_fade_to_scene()`: Fast fade for skipping screens
  - `fade_in_sprite()`: Fade in a sprite with configurable duration and alpha values
  - `fade_out_sprite()`: Fade out a sprite
- **Usage**: All cinematics and UI screens use TransitionManager for consistent transitions
- **Benefits**: Single source of truth, easier maintenance, consistent timing

**9. UI Systems**
- **Pause Menu** (`scenes/pause_menu/`): ESC to pause, options to resume/restart/quit
- **Score UI** (`scenes/puntaje/ui_puntaje.tscn`): Displays mates collected
- **Configuration** (`scenes/configuracion/`): Audio/video settings with persistent save
- **How to Play** (`scenes/como_jugar/`): Game instructions and Truco rules
- **"Continuará..." Screen** (`ui/screens/continuara/`):
  - Epic ending screen shown after victory cinematic
  - Displays "CONTINUARÁ..." with dramatic fade effects and pulsing animation
  - Stars background for atmospheric effect
  - Auto-advances to main menu after 5 seconds
  - Can be skipped by pressing any key or clicking
  - Indicates this is a demo and the story will continue

### Physics Layers

Defined in `project.godot`:
- **Layer 1**: "Suelo" (Ground)
- **Layer 2**: "Jugador" (Player)

Obstacles and mates use `collision_layer = 0` and `collision_mask = 2` to only detect player.

### Input Actions

Defined in `project.godot`:
- **salto**: Space, Up Arrow - Player jump
- **agacharse**: S, Down Arrow - Player crouch
- **skipear**: Escape, Space - Skip/advance dialogue

### Critical Implementation Details

**Independent Spawn System**:
- ObstacleSpawner and MateSpawner work independently
- No central coordination or balancing
- Distance-based spawning: accumulate distance traveled, spawn when threshold reached
- Both respect GameManager's transition signal to stop spawning

**Obstacle Positioning**:
- Obstacles are positioned by the spawner at the Area2D root level
- Visual elements (AnimatedSprite2D) and CollisionShape2D have y-offsets configured per type
- The spawner sets `obstacle.position.x` and `obstacle.position.y` directly on the root node
- Type configuration applied via `set_tipo_aleatorio()` before adding to scene

**Speed Synchronization**:
- All moving elements listen to GameManager's `velocidad_cambiada` signal
- Ground, obstacles, and spawners update speed simultaneously
- Maintains consistent game feel across all difficulty levels
- Speed increases every 10 mates collected

**Camera-Based Spawning**:
- Both spawners use `get_viewport().get_camera_2d()` to find camera position
- Spawn X = camera center X + (viewport width / 2) + spawn_offset
- This ensures objects always spawn just outside the visible area to the right
- Fallback to viewport width if camera not found

**Progressive Difficulty**:
- Current values:
  - `GameManager.objetivo = 100` (production value)
  - `GameManager.MATES_POR_NIVEL = 10` (production value)
  - `GameManager.INCREMENTO_VELOCIDAD = 10.0` (increases 10 px/s per level)
- Velocity increases every 10 mates
- No difficulty tiers or spawn balancing - pure independent spawning

**Configuration System**:
- Settings saved to `user://settings.cfg` using ConfigFile
- Loaded automatically by GameManager on startup
- Includes: music volume (Master bus), fullscreen mode
- Applied in `cargar_y_aplicar_configuracion()`

**Dialogue Data Storage**:
- Dialogues stored in CSV files in `data/dialogues/`
- Format: `character,text` with header row
- Allows easy editing without touching code
- Loaded at runtime by DialogueLoader

**Transition Protection**:
- Player cannot die when `GameManager.en_transicion == true`
- Prevents death during slow-motion sequence
- Flag set when 100 mates reached, cleared before scene change
- Checked in `jugador.gd::morir()`

## File Naming Conventions

- Scripts: lowercase with underscores (e.g., `obstacle_spawner.gd`)
- Scenes: lowercase with underscores (e.g., `obstacle_spawner.tscn`)
- Scene folders: named after the component (jugador, obstaculo, suelo, nivel, cinematica, etc.)
- CSV files: lowercase with underscores in `data/dialogues/`

## Key Signals

**GameManager**:
- `mates_cambiados(nuevos_mates)` - Emitted when mate count changes
- `objetivo_alcanzado` - Emitted when 100 mates collected
- `iniciar_transicion_rancho` - Signals spawners to stop
- `velocidad_cambiada(nueva_velocidad)` - Emitted on difficulty increase (every 10 mates)

**DialogueManager**:
- `dialogue_started()` - Conversation begins
- `dialogue_line_started(character_name, text)` - New line starts
- `dialogue_line_finished()` - Line typing complete
- `dialogue_ended()` - Entire conversation finished
- `typing_started()` - Typewriter effect begins
- `typing_finished()` - Typewriter effect complete

**Obstacles/Mates**:
- `jugador_muerto` - Emitted on player collision with obstacle
- `mate_recolectado` - Emitted when mate collected (if used)

## Project Structure

```
gaucholand/
├── addons/
│   └── kanban_tasks/          # Godot plugin for task management
├── data/
│   └── dialogues/
│       ├── cinematica_inicio.csv
│       ├── transicion_rancho.csv
│       ├── jugador_gana_truco.csv  # Victory dialogues
│       └── muerte_gana_truco.csv   # Defeat dialogues
├── scenes/
│   ├── cinematics/
│   │   ├── intro_cinematic/
│   │   │   ├── cinematica_inicio.tscn
│   │   │   └── cinematica_inicio.gd
│   │   ├── rancho_transition/
│   │   │   ├── transicion_rancho.tscn
│   │   │   └── transicion_rancho.gd
│   │   ├── jugador_victoria/      # NEW: Victory cinematic
│   │   │   ├── jugador_victoria.tscn
│   │   │   └── jugador_victoria.gd
│   │   └── muerte_victoria/       # Defeat cinematic
│   │       ├── muerte_victoria.tscn
│   │       └── muerte_victoria.gd
│   ├── jugador/
│   │   ├── jugador.tscn
│   │   └── jugador.gd
│   ├── nivel/
│   │   └── nivel.tscn
│   ├── nivel_pampa/
│   │   └── nivel_pampa.tscn
│   ├── obstaculo/
│   │   ├── obstacle.tscn
│   │   ├── obstacle.gd
│   │   ├── obstacle_spawner.tscn
│   │   └── obstacle_spawner.gd
│   ├── puntaje/
│   │   ├── mate.tscn
│   │   ├── mate.gd
│   │   ├── mate_spawner.tscn
│   │   ├── mate_spawner.gd
│   │   └── ui_puntaje.tscn
│   ├── suelo/
│   │   ├── suelo.tscn
│   │   └── suelo.gd
│   └── truco_game/
│       ├── truco.tscn
│       ├── truco_controller.gd
│       ├── truco_state.gd
│       ├── truco_rules.gd
│       ├── truco_ui.gd
│       └── ... (other Truco components)
├── ui/
│   ├── screens/
│   │   └── continuara/           # NEW: "To be continued" screen
│   │       ├── continuara.tscn
│   │       └── continuara.gd
│   └── menus/
│       └── main_menu/
│           └── menu_principal.tscn
└── systems/
    ├── dialogue/
    │   ├── dialogue_ui.tscn
    │   ├── dialogue_manager.gd
    │   └── dialogue_loader.gd (class_name)
    ├── transitions/
    │   └── transition_manager.gd  (NEW: Centralized transition utility)
    └── ... (other systems)
```
## Testing y Debug

### Debug Menu (F12)
Sistema completo para testing rápido sin jugar todo el juego desde el inicio.

**Acceso:** Presionar F12 en cualquier momento (solo modo debug)

**Características:**
- Saltar a cualquier cinemática instantáneamente
- Cargar nivel de gameplay o Truco directamente
- Ver estado del GameManager
- Reset del GameManager
- Test del TransitionManager

**Archivo:** `systems/debug/debug_menu.tscn` (autoload)

### Test Cinematics Runner
Escena especial para testing de cinemáticas.

**Uso:**
1. Abrir `scenes/cinematics/test_scenes/test_cinematics_runner.tscn`
2. Presionar F6 (Play Scene)
3. Usar teclas numéricas [1-5] para cargar cinemáticas

**Ventajas:**
- Configura automáticamente el GameManager
- No requiere jugar el juego completo
- Ideal para revisar diálogos y timing

### Comandos Debug en Truco
Comandos especiales durante el juego de Truco (solo modo debug):

- **F9** - Ganar instantáneamente → Cinemática de victoria
- **F10** - Perder instantáneamente → Cinemática de derrota
- **F11** - +10 puntos al jugador

**Implementación:** `scenes/truco_game/truco_controller.gd` (líneas 417-450)

### Ejecutar Escenas Directamente
Método profesional de Godot para testing:

1. Abrir la escena a testear en el editor
2. Presionar F6 (Play Scene) en lugar de F5
3. La escena se ejecuta inmediatamente

**Escenas útiles:**
- `scenes/cinematics/*/[nombre].tscn` - Cinemáticas
- `scenes/truco_game/truco.tscn` - Truco
- `ui/screens/continuara/continuara.tscn` - Pantalla final

### Notas Importantes
- Todo el sistema de debug se desactiva automáticamente en builds de release
- `OS.is_debug_build()` controla la disponibilidad de comandos
- Los comandos debug NO aparecen en el build final del juego

## Buenas Practicas
Siempre utiliza el archivo BUENAS_PRACTICAS.md en docs/BUENAS_PRACTICAS.md para hacer cualquier cosa en el proyecto