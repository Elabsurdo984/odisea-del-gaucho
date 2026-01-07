extends Node
class_name AIMuerte

@onready var strategy: AIStrategy = $AIStrategy
@onready var decision: AIDecision = $AIDecision

# Referencias externas (se inyectan o buscan)
var truco_state: TrucoState
var truco_betting: TrucoBetting

signal accion_tomada(accion: Dictionary)

func _ready():
	# Si no están como hijos (ej: instanciados por código en test), crearlos
	if not strategy:
		strategy = AIStrategy.new()
		add_child(strategy)
	if not decision:
		decision = AIDecision.new()
		add_child(decision)

func ejecutar_turno() -> void:
	if not truco_state or not truco_betting:
		push_error("AIMuerte: Faltan referencias a State o Betting")
		return
		
	var evaluacion = decision.evaluar_mano(truco_state.cartas_muerte)
	var estrategia_actual = strategy.elegir_estrategia(evaluacion, truco_state)
	
	var accion = decision.decidir_accion_turno(
		estrategia_actual, 
		truco_state, 
		evaluacion, 
		truco_betting
	)
	
	accion_tomada.emit(accion)
