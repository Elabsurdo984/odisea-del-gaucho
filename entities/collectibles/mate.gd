extends Area2D

signal mate_recolectado

@export var speed := 200.0
@export var puntos_valor := 1

func _ready() -> void:
    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
    position.x -= speed * delta
    
    if position.x < -700:
        queue_free()

 


func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        
        mate_recolectado.emit()
        
        if GameManager:
            GameManager.agregar_mates(puntos_valor)
        
        $Sprite2D.modulate = Color(0, 0, 0)
        
        queue_free()
