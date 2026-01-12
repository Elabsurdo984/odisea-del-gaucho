# continuara.gd
# Pantalla final épica de "Continuará..."
extends Control

#region REFERENCIAS
@onready var texto_label: Label = $CenteredContainer/TextoLabel
@onready var fade_rect: ColorRect = $FadeRect
#endregion

#region INICIALIZACIÓN
func _ready():
	# Asegurar que el tiempo esté normal
	Engine.time_scale = 1.0
	get_tree().paused = false

	# Configurar visibilidad inicial
	if texto_label:
		texto_label.modulate.a = 0.0

	if fade_rect:
		fade_rect.color.a = 1.0

	# Iniciar secuencia épica
	iniciar_secuencia()
#endregion

#region SECUENCIA ÉPICA
func iniciar_secuencia():
	# Fade in del fondo
	if fade_rect:
		var tween_fade = create_tween()
		tween_fade.tween_property(fade_rect, "color:a", 0.0, 2.0)

	# Esperar un momento
	await get_tree().create_timer(3.0).timeout

	# Hacer aparecer el texto con efecto dramático
	if texto_label:
		var tween_text = create_tween()
		tween_text.tween_property(texto_label, "modulate:a", 1.0, 2.5)

		# Efecto de escala pulsante
		tween_text.parallel().tween_property(texto_label, "scale", Vector2(1.1, 1.1), 1.0)
		tween_text.tween_property(texto_label, "scale", Vector2(1.0, 1.0), 0.5)

	# Esperar que el usuario vea el mensaje
	await get_tree().create_timer(5.0).timeout

	# Transición al menú principal usando TransitionManager
	await TransitionManager.transition_to_scene(
		self,
		"res://ui/menus/main_menu/menu_principal.tscn",
		null,
		2.0,
		0.0
	)
#endregion

#region INPUT
func _input(event):
	# Permitir saltear con cualquier tecla/click
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed():
			# Fade out rápido y salir usando TransitionManager
			await TransitionManager.quick_fade_to_scene(
				self,
				"res://ui/menus/main_menu/menu_principal.tscn",
				0.5
			)
#endregion
