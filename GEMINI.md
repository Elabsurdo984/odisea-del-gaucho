# GEMINI.md

This file provides context and guidance for the Gemini AI agent when working on the **Gaucholand** project.

## Project Overview

**Gaucholand** is a Godot 4.5 2D endless runner game. The player controls a Gaucho character who runs automatically, jumping over obstacles (cacti, rocks, bushes) and collecting "mates".

**Core Loop:**
1.  **Run & Collect:** The player runs through the "Pampa", avoiding obstacles and collecting mates.
2.  **Progressive Difficulty:** Speed increases every 10 mates collected.
3.  **Transition:** Upon collecting 100 mates, the game transitions to a "Rancho" scene.
4.  **Final Challenge:** The player faces "La Muerte" (Death) in a game of Truco (an Argentine card game).

**Tech Stack:**
*   **Engine:** Godot 4.5 (GL Compatibility mode)
*   **Language:** GDScript
*   **Assets:** Pixel art style (Kenney assets + custom)

## Building and Running

*   **Editor:** Open the project `project.godot` in Godot Engine 4.5+.
*   **Run Game:** Press `F5` or click the "Play" button in the editor.
*   **Main Scene:** `res://scenes/menu_principal/menu_principal.tscn` is the entry point.
*   **Debug:** `print()` statements output to the Godot Output console.

## Project Architecture & Key Systems

The project follows a component-based architecture with a global manager.

### 1. Global Management
*   **GameManager (`scripts/game_manager.gd`):** A Singleton (Autoload) that handles:
    *   Global state (mates collected, lives, current speed).
    *   Game flow (transitions between menu, gameplay, cinematic, truco).
    *   Difficulty progression (velocity increases).
    *   Configuration loading (audio/video).

### 2. Scene Hierarchy
*   **Main Menu (`scenes/menu_principal/`):** UI for "Jugar", "Como Jugar", "Configuración".
*   **Cinematics (`scenes/cinematica/`, `scenes/transicion_rancho/`):** Narrative scenes using the Dialogue System.
*   **Gameplay (`scenes/nivel_pampa/nivel_pampa.tscn`):**
    *   **Player (`scenes/jugador/`):** Handles physics (jump, crouch), input, and death logic.
    *   **Level (`scenes/nivel/`):** Contains the scrolling ground and spawners.
    *   **Spawners (`scenes/obstaculo/`, `scenes/puntaje/`):** Independent systems for spawning obstacles and mates based on distance traveled.
*   **Truco (`scenes/truco/`):** A standalone scene for the card game mechanic.

### 3. Core Mechanics
*   **Infinite Scrolling:** `scenes/suelo/suelo.gd` moves the ground texture and loops it.
*   **Obstacle Spawning:** `obstacle_spawner.gd` spawns `obstacle.tscn` (Area2D) based on distance.
*   **Life System:**
    *   Player has 3 lives (managed by `GameManager`).
    *   **UI:** Displayed as hearts (`ui_puntaje.gd`) using texture assets.
    *   **Invincibility:** Player blinks and is invincible for 1.5s after taking damage.
*   **Dialogue System:**
    *   `DialogueManager` (`scripts/dialogue_manager.gd`): Handles text display, typewriter effect, and state.
    *   `DialogueLoader` (`scripts/dialogue_loader.gd`): Loads text from CSV files in `data/dialogues/`.

## Development Conventions

*   **Naming:**
    *   Files and folders: `snake_case` (e.g., `game_manager.gd`, `menu_principal.tscn`).
    *   Classes/Types: `PascalCase` (e.g., `GameManager`, `DialogueLoader`).
    *   Variables/Functions: `snake_case` (e.g., `velocidad_actual`, `_ready()`).
    *   Constants: `UPPER_CASE` (e.g., `INCREMENTO_VELOCIDAD`).
*   **File Structure:**
    *   `assets/`: Art and sound resources.
    *   `scenes/`: `tscn` files and their attached scripts, organized by component.
    *   `scripts/`: General purpose scripts and singletons.
    *   `data/`: Data files (CSVs for dialogue).
    *   `addons/`: Plugins (e.g., `kanban_tasks`).
*   **Input Map:**
    *   `salto`: Space, Up Arrow.
    *   `agacharse`: S, Down Arrow.
    *   `skipear`: Escape, Space (for dialogues).
*   **Physics Layers:**
    *   Layer 1: "Suelo" (Ground)
    *   Layer 2: "Jugador" (Player)

## Key Files Summary

| File Path | Description |
| :--- | :--- |
| `project.godot` | Main configuration, Autoloads (`GameManager`), Input Map. |
| `scripts/game_manager.gd` | Core logic singleton. **Read this first for game state.** |
| `scenes/jugador/jugador.gd` | Player movement and state machine. |
| `scenes/obstaculo/obstacle_spawner.gd` | Logic for obstacle generation. |
| `data/dialogues/*.csv` | Dialogue text data. |

## Buenas Practicas
Siempre utiliza el archivo BUENAS_PRACTICAS.md en docs/BUENAS_PRACTICAS.md para hacer cualquier cosa en el proyecto