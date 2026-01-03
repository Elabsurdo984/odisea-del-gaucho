# dialogue_ui.gd
# Escena reutilizable de UI de diálogo
# Contiene el panel visual y el DialogueManager
extends CanvasLayer

# ==================== REFERENCIAS ====================
@onready var panel_dialogo = $PanelDialogo
@onready var nombre_label = $PanelDialogo/MarginContainer/VBoxContainer/NombreLabel
@onready var texto_label = $PanelDialogo/MarginContainer/VBoxContainer/TextoLabel
@onready var continuar_indicador = $PanelDialogo/ContinuarIndicador
@onready var dialogue_manager = $DialogueManager

# ==================== MÉTODOS PÚBLICOS ====================

## Obtiene el DialogueManager
func get_dialogue_manager() -> Node:
    return dialogue_manager

## Muestra el panel de diálogo
func mostrar() -> void:
    panel_dialogo.visible = true

## Oculta el panel de diálogo
func ocultar() -> void:
    panel_dialogo.visible = false

## Verifica si el panel está visible
func esta_visible() -> bool:
    return panel_dialogo.visible
