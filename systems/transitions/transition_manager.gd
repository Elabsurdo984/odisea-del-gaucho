# transition_manager.gd
# Sistema centralizado para manejar transiciones entre escenas
# Evita duplicación de código en cinemáticas y pantallas

class_name TransitionManager
extends RefCounted

## Realiza una transición completa: ocultar UI → esperar → fade out → cambiar escena
##
## Parámetros:
##   - node: Nodo que ejecuta la transición (típicamente self desde una cinemática)
##   - target_scene: Ruta de la escena de destino
##   - ui_to_hide: (Opcional) Nodo de UI para ocultar antes del fade
##   - fade_duration: Duración del fade out en segundos (default: 1.0)
##   - pre_fade_wait: Tiempo de espera antes del fade en segundos (default: 0.5)
static func transition_to_scene(
	node: Node,
	target_scene: String,
	ui_to_hide: Node = null,
	fade_duration: float = 1.0,
	pre_fade_wait: float = 0.5
) -> void:
	# 1. Ocultar UI si se proporciona
	if ui_to_hide and is_instance_valid(ui_to_hide):
		if ui_to_hide.has_method("ocultar"):
			ui_to_hide.ocultar()

	# 2. Esperar antes del fade (pausa dramática)
	if pre_fade_wait > 0.0:
		await node.get_tree().create_timer(pre_fade_wait).timeout

	# 3. Fade out
	var tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, fade_duration)
	await tween.finished

	# 4. Cambiar escena
	node.get_tree().change_scene_to_file(target_scene)

## Fade out rápido para skip de pantallas
##
## Parámetros:
##   - node: Nodo que ejecuta el fade
##   - target_scene: Ruta de la escena de destino
##   - fade_duration: Duración del fade (default: 0.5)
static func quick_fade_to_scene(
	node: Node,
	target_scene: String,
	fade_duration: float = 0.5
) -> void:
	var tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, fade_duration)
	await tween.finished
	node.get_tree().change_scene_to_file(target_scene)

## Fade in de un sprite
##
## Parámetros:
##   - sprite: Sprite a hacer aparecer
##   - duration: Duración del fade in (default: 1.5)
##   - from_alpha: Alpha inicial (default: 0.0)
##   - to_alpha: Alpha final (default: 1.0)
static func fade_in_sprite(
	sprite: Node,
	duration: float = 1.5,
	from_alpha: float = 0.0,
	to_alpha: float = 1.0
) -> void:
	if not sprite or not is_instance_valid(sprite):
		return

	sprite.modulate.a = from_alpha
	var tween = sprite.create_tween()
	tween.tween_property(sprite, "modulate:a", to_alpha, duration)
	await tween.finished

## Fade out de un sprite
##
## Parámetros:
##   - sprite: Sprite a hacer desaparecer
##   - duration: Duración del fade out (default: 1.5)
static func fade_out_sprite(
	sprite: Node,
	duration: float = 1.5
) -> void:
	if not sprite or not is_instance_valid(sprite):
		return

	var tween = sprite.create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, duration)
	await tween.finished
