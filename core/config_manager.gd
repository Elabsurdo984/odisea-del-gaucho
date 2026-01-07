# config_manager.gd
# Gestión de configuración del juego (audio, video, etc.)
extends Node

# ============================================================
# SIGNALS
# ============================================================
signal configuracion_cargada()
signal configuracion_guardada()
signal volumen_cambiado(volumen: int)
signal pantalla_completa_cambiada(activa: bool)

# ============================================================
# CONSTANTES
# ============================================================
const CONFIG_FILE: String = "user://settings.cfg"

# ============================================================
# VARIABLES
# ============================================================
var config: ConfigFile = ConfigFile.new()

# ============================================================
# LIFECYCLE
# ============================================================
func _ready() -> void:
	cargar_y_aplicar_configuracion()

# ============================================================
# PUBLIC METHODS
# ============================================================

## Carga la configuración desde el archivo y la aplica
func cargar_y_aplicar_configuracion() -> void:
	var err: Error = config.load(CONFIG_FILE)

	if err == OK:
		aplicar_audio()
		aplicar_video()
		print("✅ Configuración aplicada desde ConfigManager")
		configuracion_cargada.emit()
	else:
		print("📝 No se encontró configuración guardada, usando valores por defecto")

## Guarda la configuración actual al archivo
func guardar_configuracion() -> void:
	var err: Error = config.save(CONFIG_FILE)

	if err == OK:
		print("💾 Configuración guardada")
		configuracion_guardada.emit()
	else:
		print("❌ Error al guardar configuración")

## Establece el volumen de la música (0-100)
func establecer_volumen_musica(volumen: int) -> void:
	volumen = clampi(volumen, 0, 100)
	config.set_value("audio", "volumen_musica", volumen)
	aplicar_audio()
	volumen_cambiado.emit(volumen)

## Establece el modo de pantalla completa
func establecer_pantalla_completa(activa: bool) -> void:
	config.set_value("video", "pantalla_completa", activa)
	aplicar_video()
	pantalla_completa_cambiada.emit(activa)

## Obtiene el volumen actual de la música
func obtener_volumen_musica() -> int:
	return config.get_value("audio", "volumen_musica", 80)

## Obtiene si está en modo pantalla completa
func obtener_pantalla_completa() -> bool:
	return config.get_value("video", "pantalla_completa", false)

# ============================================================
# PRIVATE METHODS
# ============================================================

## Aplica la configuración de audio
func aplicar_audio() -> void:
	var volumen_musica: int = config.get_value("audio", "volumen_musica", 80)
	var db_musica: float = linear_to_db(volumen_musica / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db_musica)

## Aplica la configuración de video
func aplicar_video() -> void:
	var pantalla_completa: bool = config.get_value("video", "pantalla_completa", false)

	if pantalla_completa:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
