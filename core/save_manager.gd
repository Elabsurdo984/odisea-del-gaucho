extends Node

# ============================================================
# CONSTANTES
# ============================================================
const SAVE_PATH: String = "user://savegame.json"

# ============================================================
# LIFECYCLE
# ============================================================
func _ready() -> void:
	# Asegurarnos de recibir notificaciones de cierre
	get_tree().set_auto_accept_quit(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Solo guardar si estamos en una escena jugable (no menú principal)
		if _es_escena_jugable():
			save_game()
		
		# Cerrar el juego
		get_tree().quit()

# ============================================================
# PUBLIC METHODS
# ============================================================

## Guarda el estado actual del juego
func save_game() -> void:
	print("💾 Guardando partida...")
	
	var save_data: Dictionary = {
		"timestamp": Time.get_datetime_string_from_system(),
		"scene": get_tree().current_scene.scene_file_path,
		"score": {},
		"lives": {},
		"difficulty": {}
	}
	
	# 1. Guardar Score
	if ScoreManager:
		save_data["score"] = {
			"mates": ScoreManager.obtener_mates(),
			"objetivo_alcanzado": ScoreManager.objetivo_fue_alcanzado()
		}
	
	# 2. Guardar Vidas
	if LivesManager:
		save_data["lives"] = {
			"vidas": LivesManager.obtener_vidas(),
			"causa_muerte": LivesManager.obtener_causa_muerte()
		}
	
	# 3. Guardar Dificultad
	if DifficultyManager:
		save_data["difficulty"] = {
			"velocidad": DifficultyManager.obtener_velocidad_actual(),
			"nivel": DifficultyManager.obtener_nivel_actual()
		}
		
	# Guardar en disco
	var json_string = JSON.stringify(save_data)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("✅ Partida guardada exitosamente en: ", SAVE_PATH)
	else:
		printerr("❌ Error al guardar la partida: ", FileAccess.get_open_error())

## Carga la partida guardada
func load_game() -> void:
	if not has_save():
		print("⚠️ No hay partida guardada para cargar.")
		return
		
	print("📂 Cargando partida...")
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		printerr("❌ Error al leer archivo de guardado.")
		return
		
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		printerr("❌ Error al parsear JSON de guardado: ", json.get_error_message())
		return
		
	var save_data = json.get_data()
	
	# 1. Restaurar Datos (Managers)
	_restaurar_datos(save_data)
	
	# 2. Cambiar Escena
	if save_data.has("scene"):
		var scene_path = save_data["scene"]
		if SceneManager:
			# Usamos SceneManager para la transición, pero necesitamos asegurarnos
			# de que los datos persistan después de la carga.
			# Como los managers son Autoloads, sus datos persisten entre escenas.
			SceneManager.cambiar_escena(scene_path)
		else:
			get_tree().change_scene_to_file(scene_path)
	
	print("✅ Partida cargada exitosamente.")

## Verifica si existe un archivo de guardado
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## Borra el archivo de guardado (opcional, ej: al morir o ganar si fuera roguelike estricto)
func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
		print("🗑️ Archivo de guardado eliminado.")

# ============================================================
# PRIVATE METHODS
# ============================================================

func _restaurar_datos(data: Dictionary) -> void:
	# Restaurar Score
	if ScoreManager and data.has("score"):
		# No tenemos setters directos en ScoreManager para "setear" un valor arbitrario
		# pero podemos reiniciar y agregar.
		ScoreManager.reiniciar()
		var mates = data["score"].get("mates", 0)
		ScoreManager.agregar_mates(mates)
		# Nota: agregar_mates dispara eventos, podría ser ruidoso al cargar.
		# Idealmente ScoreManager debería tener un método 'cargar_estado(mates)' silencioso.
		# Por ahora usamos lo que hay.
	
	# Restaurar Vidas
	if LivesManager and data.has("lives"):
		LivesManager.reiniciar() # Resetea a MAX
		var target_lives = data["lives"].get("vidas", 3)
		var current = LivesManager.obtener_vidas()
		
		# Ajustar vidas descontando hasta llegar al target
		while current > target_lives:
			LivesManager.descontar_vida()
			current = LivesManager.obtener_vidas()
			
	# Restaurar Dificultad
	if DifficultyManager and data.has("difficulty"):
		# DifficultyManager tampoco tiene setters públicos directos para velocidad arbitraria
		# excepto a través de 'verificar_aumento_velocidad' que depende de mates.
		# Como ya restauramos los mates arriba, si DifficultyManager reacciona a los mates,
		# la velocidad debería ajustarse sola.
		# Sin embargo, si queremos forzar el nivel:
		pass
		
func _es_escena_jugable() -> bool:
	var current_scene = get_tree().current_scene
	if not current_scene:
		return false
		
	# Lista negra de escenas donde NO guardar (menús, transiciones)
	var scene_path = current_scene.scene_file_path
	if "menu" in scene_path or "transition" in scene_path:
		return false
		
	return true
