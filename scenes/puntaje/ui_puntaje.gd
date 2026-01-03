extends Control

@export var contador: Label

func _ready() -> void:
    if GameManager:
        GameManager.mates_cambiados.connect(_on_mates_cambiados)
        
        _on_mates_cambiados(GameManager.obtener_mates())

func _on_mates_cambiados(nuevos_mates: int):
    contador.text = "Mates: " + str(nuevos_mates)
