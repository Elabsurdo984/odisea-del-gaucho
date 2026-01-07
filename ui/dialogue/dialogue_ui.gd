# dialogue_ui.gd
# Escena reutilizable de UI de diálogo
# Contiene el panel visual y el DialogueManager
extends CanvasLayer

#region REFERENCIAS
@export var panel_dialogo: Panel
@export var nombre_label: Label
@export var texto_label: Label
@export var continuar_indicador: Label
@export var dialogue_manager: Node
#endregion

#region MÉTODOS PÚBLICOS

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
#endregion
