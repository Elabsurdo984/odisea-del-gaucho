# spawn_coordinator.gd
# Singleton para coordinar spawns y evitar superposiciones
extends Node

signal spawn_permitido(tipo: String, posicion_x: float)

# Distancia mínima entre diferentes tipos de objetos
@export var distancia_seguridad := 200.0

# Registro de últimos spawns
var ultimo_spawn_obstaculo := -999999.0
var ultimo_spawn_mate := -999999.0

func puede_spawnear_obstaculo(posicion_x: float) -> bool:
	# Verificar si hay suficiente distancia desde el último mate
	if posicion_x - ultimo_spawn_mate < distancia_seguridad:
		return false
	return true

func puede_spawnear_mate(posicion_x: float) -> bool:
	# Verificar si hay suficiente distancia desde el último obstáculo
	if posicion_x - ultimo_spawn_obstaculo < distancia_seguridad:
		return false
	return true

func registrar_spawn_obstaculo(posicion_x: float):
	ultimo_spawn_obstaculo = posicion_x

func registrar_spawn_mate(posicion_x: float):
	ultimo_spawn_mate = posicion_x

func reiniciar():
	ultimo_spawn_obstaculo = -999999.0
	ultimo_spawn_mate = -999999.0
