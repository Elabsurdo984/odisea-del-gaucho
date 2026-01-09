# chapter_transition.gd
# Pantalla de transición profesional entre capítulos
extends Control

#region REFERENCIAS UI
@export_group("Texto")
@export var lbl_capitulo: Label
@export var lbl_nombre: Label

@export_group("Efectos Visuales")
@export var background: Control  # Fondo de pampa (puede ser TextureRect o ColorRect)
@export var vignette: ColorRect  # Viñeta oscura en los bordes
@export var particles_container: Control  # Contenedor de partículas de mates
@export var gaucho_silhouette: TextureRect  # Silueta del gaucho

@export_group("Overlay de Fundido")
@export var fade_overlay: ColorRect  # Para fundidos suaves
#endregion

#region CONFIGURACIÓN
@export_group("Capítulo")
@export var numero_capitulo: int = 1
@export var nombre_capitulo: String = "La Pampa Eterna"
@export var escena_siguiente: String = "res://scenes/cinematics/intro_cinematic/cinematica_inicio.tscn"

@export_group("Tiempos (segundos)")
@export var duracion_fade_in_inicial: float = 0.8
@export var duracion_animacion_entrada: float = 1.2
@export var duracion_texto_visible: float = 2.8
@export var duracion_fade_out_final: float = 1.0
#endregion

#region VARIABLES INTERNAS
var mate_particles: Array = []
const MAX_PARTICLES = 40
#endregion

#region LIFECYCLE
func _ready() -> void:
	# Configurar textos
	if lbl_capitulo:
		lbl_capitulo.text = "CAPÍTULO %d" % numero_capitulo
		lbl_capitulo.modulate.a = 0.0  # Empezar invisible

		# Estilo profesional para el texto
		lbl_capitulo.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl_capitulo.add_theme_constant_override("outline_size", 3)

	if lbl_nombre:
		lbl_nombre.text = nombre_capitulo.to_upper()
		lbl_nombre.modulate.a = 0.0  # Empezar invisible

		# Estilo con outline para mejor legibilidad
		lbl_nombre.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl_nombre.add_theme_constant_override("outline_size", 4)

	# Configurar fade overlay
	if fade_overlay:
		fade_overlay.color = Color.BLACK
		fade_overlay.modulate.a = 1.0  # Empezar completamente negro

	# Configurar background con paralaje sutil
	if background:
		background.modulate.a = 0.0
		# Si es TextureRect y no tiene textura, crear un gradiente de pampa
		if background is TextureRect and not background.texture:
			crear_gradiente_pampa()
		# Si directamente es un ColorRect vacío, crear gradiente
		elif background is ColorRect:
			crear_gradiente_pampa()

	# Configurar viñeta
	if vignette:
		vignette.color = Color(0, 0, 0, 0.6)  # Negro semi-transparente
		vignette.modulate.a = 0.0

	# Configurar silueta del gaucho
	if gaucho_silhouette:
		gaucho_silhouette.modulate = Color(0, 0, 0, 0.8)  # Silueta oscura
		gaucho_silhouette.pivot_offset = gaucho_silhouette.size / 2
		gaucho_silhouette.scale = Vector2(0.8, 0.8)
		gaucho_silhouette.modulate.a = 0.0

	# Crear partículas de mates flotantes
	if particles_container:
		crear_particulas_mates()

	# Iniciar secuencia de transición
	await get_tree().process_frame
	iniciar_secuencia_completa()

func _process(delta: float) -> void:
	# Animar partículas de mates
	animar_particulas_mates(delta)

	# Efecto de paralaje sutil en el fondo
	if background:
		background.position.x = sin(Time.get_ticks_msec() / 2000.0) * 5.0
#endregion

#region SECUENCIA PRINCIPAL
func iniciar_secuencia_completa() -> void:
	# 1. Fade in inicial - Revelar escena desde negro
	await fade_in_inicial()

	# 2. Animación de entrada - Elementos aparecen con estilo
	await animacion_entrada_elementos()

	# 3. Mantener visible - Dar tiempo para leer
	await get_tree().create_timer(duracion_texto_visible).timeout

	# 4. Animación de salida - Elementos desaparecen
	await animacion_salida_elementos()

	# 5. Fade out final - Transición a negro
	await fade_out_final()

	# 6. Cambiar a la siguiente escena
	get_tree().change_scene_to_file(escena_siguiente)
#endregion

#region ANIMACIONES DE FUNDIDO
func fade_in_inicial() -> void:
	var tween = create_tween().set_parallel(true)

	# Fade del overlay negro
	if fade_overlay:
		tween.tween_property(fade_overlay, "modulate:a", 0.0, duracion_fade_in_inicial)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Fade del background
	if background:
		tween.tween_property(background, "modulate:a", 1.0, duracion_fade_in_inicial)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Fade de la viñeta
	if vignette:
		tween.tween_property(vignette, "modulate:a", 1.0, duracion_fade_in_inicial)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	await tween.finished

func fade_out_final() -> void:
	var tween = create_tween().set_parallel(true)

	# Fade a negro del overlay
	if fade_overlay:
		tween.tween_property(fade_overlay, "modulate:a", 1.0, duracion_fade_out_final)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	await tween.finished
#endregion

#region ANIMACIONES DE ELEMENTOS
func animacion_entrada_elementos() -> void:
	# 1. Silueta del gaucho aparece desde abajo
	if gaucho_silhouette:
		var original_y = gaucho_silhouette.position.y
		gaucho_silhouette.position.y += 100

		var tween1 = create_tween().set_parallel(true)
		tween1.tween_property(gaucho_silhouette, "modulate:a", 1.0, 0.5)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween1.tween_property(gaucho_silhouette, "position:y", original_y, 0.5)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 2. Texto "CAPÍTULO X" aparece con slide desde arriba
	if lbl_capitulo:
		var original_pos_y = lbl_capitulo.position.y
		lbl_capitulo.position.y -= 50

		var tween2 = create_tween().set_parallel(true)
		tween2.tween_property(lbl_capitulo, "modulate:a", 1.0, 0.6)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween2.tween_property(lbl_capitulo, "position:y", original_pos_y, 0.6)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 3. Pequeño delay antes del nombre del capítulo
	await get_tree().create_timer(0.3).timeout

	# 4. Nombre del capítulo aparece con efecto de escalado
	if lbl_nombre:
		lbl_nombre.scale = Vector2(0.8, 0.8)

		var tween3 = create_tween().set_parallel(true)
		tween3.tween_property(lbl_nombre, "modulate:a", 1.0, 0.7)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween3.tween_property(lbl_nombre, "scale", Vector2(1.0, 1.0), 0.7)\
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

		await tween3.finished

	# 5. Activar partículas de mates
	activar_particulas_mates()

func animacion_salida_elementos() -> void:
	var tween = create_tween().set_parallel(true)

	# Todo se desvanece suavemente
	if lbl_capitulo:
		tween.tween_property(lbl_capitulo, "modulate:a", 0.0, 0.6)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	if lbl_nombre:
		tween.tween_property(lbl_nombre, "modulate:a", 0.0, 0.6)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	if gaucho_silhouette:
		tween.tween_property(gaucho_silhouette, "modulate:a", 0.0, 0.6)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Desactivar partículas
	desactivar_particulas_mates()

	await tween.finished
#endregion

#region SISTEMA DE PARTÍCULAS DE MATES
func crear_particulas_mates() -> void:
	if not particles_container:
		return

	for i in range(MAX_PARTICLES):
		var mate = TextureRect.new()
		mate.texture = load("res://assets/mate/mate.png")
		mate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mate.custom_minimum_size = Vector2(64, 64)
		mate.size = Vector2(64, 64)
		mate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mate.modulate.a = 0.0
		mate.scale = Vector2(1, 1)  # Reducir a 30% del tamaño

		# Posición aleatoria
		mate.position = Vector2(
			randf_range(0, get_viewport_rect().size.x),
			randf_range(0, get_viewport_rect().size.y)
		)

		# Datos de movimiento aleatorios
		mate.set_meta("velocity", Vector2(randf_range(-20, 20), randf_range(-30, -10)))
		mate.set_meta("rotation_speed", randf_range(-1, 1))
		mate.set_meta("base_scale", 1)  # Escala base para el efecto pulsante

		particles_container.add_child(mate)
		mate_particles.append(mate)

func activar_particulas_mates() -> void:
	for mate in mate_particles:
		if mate:
			var tween = create_tween()
			tween.tween_property(mate, "modulate:a", randf_range(0.3, 0.6), randf_range(0.5, 1.5))\
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func desactivar_particulas_mates() -> void:
	for mate in mate_particles:
		if mate:
			var tween = create_tween()
			tween.tween_property(mate, "modulate:a", 0.0, 0.5)\
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func animar_particulas_mates(delta: float) -> void:
	for mate in mate_particles:
		if mate and mate.modulate.a > 0:
			# Movimiento flotante
			var velocity = mate.get_meta("velocity")
			mate.position += velocity * delta

			# Rotación sutil
			var rotation_speed = mate.get_meta("rotation_speed")
			mate.rotation += rotation_speed * delta

			# Efecto de escala pulsante
			var base_scale = mate.get_meta("base_scale")
			var pulse = sin(Time.get_ticks_msec() / 1000.0) * 0.05  # Pulso sutil de ±5%
			var scale_factor = base_scale + pulse
			mate.scale = Vector2(scale_factor, scale_factor)

			# Wrap around (volver al inicio si sale de pantalla)
			var viewport_size = get_viewport_rect().size
			if mate.position.y < -50:
				mate.position.y = viewport_size.y + 50
			if mate.position.x < -50:
				mate.position.x = viewport_size.x + 50
			elif mate.position.x > viewport_size.x + 50:
				mate.position.x = -50
#endregion

#region GRADIENTE DE FONDO
func crear_gradiente_pampa() -> void:
	# Crear un ColorRect con gradiente de atardecer de pampa
	var gradient_rect = ColorRect.new()
	gradient_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Crear shader de gradiente avanzado con efectos
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

// Función de ruido mejorada
float noise(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Ruido fractal para nubes
float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for(int i = 0; i < 4; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// === GRADIENTE BASE ===
	// Colores de atardecer pampa argentino
	vec3 color_sky_top = vec3(0.95, 0.45, 0.25);      // Naranja rojizo
	vec3 color_sky_mid = vec3(1.0, 0.65, 0.35);       // Naranja dorado
	vec3 color_horizon = vec3(1.0, 0.75, 0.5);        // Amarillo cálido
	vec3 color_ground = vec3(0.7, 0.5, 0.25);         // Tierra pampa

	// Gradiente suave en 3 capas
	vec3 color;
	if (uv.y < 0.3) {
		// Cielo superior
		color = mix(color_sky_top, color_sky_mid, uv.y / 0.3);
	} else if (uv.y < 0.5) {
		// Cerca del horizonte
		color = mix(color_sky_mid, color_horizon, (uv.y - 0.3) / 0.2);
	} else {
		// Tierra/pampa
		color = mix(color_horizon, color_ground, (uv.y - 0.5) / 0.5);
	}

	// === NUBES SUTILES ===
	float clouds = fbm(vec2(uv.x * 3.0 + TIME * 0.02, uv.y * 2.0)) * 0.15;
	if (uv.y < 0.4) {
		// Solo en el cielo
		color += clouds * vec3(0.1, 0.05, 0.02);
	}

	// === LÍNEAS HORIZONTALES (horizonte pampa) ===
	float horizon_band = smoothstep(0.45, 0.5, uv.y) * smoothstep(0.55, 0.5, uv.y);
	float horizon_detail = sin(uv.y * 50.0 + TIME * 0.1) * 0.02 * horizon_band;
	color += horizon_detail;

	// === TEXTURA DE PASTO (abajo) ===
	if (uv.y > 0.6) {
		float grass_noise = fbm(vec2(uv.x * 8.0, uv.y * 12.0));
		float grass_intensity = (uv.y - 0.6) / 0.4; // Más intenso hacia abajo
		color -= grass_noise * 0.08 * grass_intensity;
	}

	// === RUIDO GENERAL SUTIL ===
	float grain = noise(uv * 500.0 + TIME * 0.5) * 0.015;
	color += grain;

	// === VIÑETA SUTIL INTEGRADA ===
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(uv, center);
	float vignette = smoothstep(0.8, 0.3, dist);
	color *= (0.85 + vignette * 0.15);

	// === BRILLO CÁLIDO ===
	// Añadir un toque de luz cálida en el centro-superior
	float glow_y = 0.35;
	float glow = exp(-20.0 * pow(uv.y - glow_y, 2.0)) * exp(-2.0 * pow(uv.x - 0.5, 2.0));
	color += glow * vec3(0.15, 0.1, 0.05);

	COLOR = vec4(color, 1.0);
}
"""

	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	gradient_rect.material = shader_material

	# Reemplazar el background con el gradiente
	if background and background.get_parent():
		var parent = background.get_parent()
		var index = background.get_index()
		parent.remove_child(background)
		parent.add_child(gradient_rect)
		parent.move_child(gradient_rect, index)
		background = gradient_rect
#endregion
