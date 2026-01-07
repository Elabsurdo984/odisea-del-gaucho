# obstacle_types.gd
# Configuración de tipos de obstáculos
class_name ObstacleTypes
extends Resource

# ============================================================
# ENUMS
# ============================================================
enum Tipo { CACTUS_ALTO, PIEDRA_BAJA, ARBUSTO_MEDIO, TERO }

# ============================================================
# CONFIGURACIÓN DE TIPOS
# ============================================================

## Obtiene la configuración de un tipo de obstáculo
static func get_config(tipo: Tipo) -> Dictionary:
	var config_obstaculos: Dictionary = {
		Tipo.CACTUS_ALTO: {
			"animacion": "cactus",
			"escala": Vector2(3.22, 3.28),
			"colision_size": Vector2(16, 58),
			"offset_y": -9.5,
			"nombre": "cactus"
		},
		Tipo.PIEDRA_BAJA: {
			"animacion": "piedra",
			"escala": Vector2(1, 1),
			"colision_size": Vector2(14, 30),
			"offset_y": 2.0,
			"nombre": "piedra"
		},
		Tipo.ARBUSTO_MEDIO: {
			"animacion": "arbusto",
			"escala": Vector2(3.0, 3.0),
			"colision_size": Vector2(16, 45),
			"offset_y": -5.0,
			"nombre": "arbusto"
		},
		Tipo.TERO: {
			"animacion": "tero",
			"escala": Vector2(1, 1),
			"colision_size": Vector2(20, 16),
			"offset_y": -80.0,  # Vuela más alto
			"nombre": "tero"
		}
	}

	return config_obstaculos.get(tipo, config_obstaculos[Tipo.CACTUS_ALTO])

## Obtiene un tipo aleatorio
static func get_random_tipo() -> Tipo:
	var tipos: Array[Tipo] = [Tipo.CACTUS_ALTO, Tipo.PIEDRA_BAJA, Tipo.ARBUSTO_MEDIO, Tipo.TERO]
	return tipos[randi() % tipos.size()]

## Obtiene el nombre del obstáculo (para causa de muerte)
static func get_nombre(tipo: Tipo) -> String:
	var config: Dictionary = get_config(tipo)
	return config.get("nombre", "desconocido")
