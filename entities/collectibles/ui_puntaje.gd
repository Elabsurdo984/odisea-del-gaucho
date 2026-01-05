extends Control

@export var contador: Label
@export var hearts_container: HBoxContainer
@export var heart_full: Texture2D = preload("res://assets/kenney_pixel-platformer/Tiles/tile_0044.png")
@export var heart_empty: Texture2D = preload("res://assets/kenney_pixel-platformer/Tiles/tile_0046.png")

func _ready() -> void:
    if GameManager:
        GameManager.mates_cambiados.connect(_on_mates_cambiados)
        GameManager.vidas_cambiadas.connect(_on_vidas_cambiadas)
        
        _on_mates_cambiados(GameManager.obtener_mates())
        
        # Inicializar contenedor si está vacío
        if hearts_container and hearts_container.get_child_count() == 0:
            configurar_corazones_iniciales()
            
        if "vidas" in GameManager:
            _on_vidas_cambiadas(GameManager.vidas)

func configurar_corazones_iniciales():
    # Limpiar
    for child in hearts_container.get_children():
        child.queue_free()
        
    # Crear corazones basados en MAX_VIDAS del GameManager (o 3 por defecto)
    var max_vidas = 3
    if "MAX_VIDAS" in GameManager:
        max_vidas = GameManager.MAX_VIDAS
        
    for i in range(max_vidas):
        var rect = TextureRect.new()
        rect.texture = heart_full
        # Escalar x3 para que se vean bien (pixel art)
        rect.custom_minimum_size = Vector2(48, 48) 
        rect.stretch_mode = TextureRect.STRETCH_SCALE
        hearts_container.add_child(rect)

func _on_mates_cambiados(nuevos_mates: int):
    contador.text = "Mates: " + str(nuevos_mates)

func _on_vidas_cambiadas(nuevas_vidas: int):
    if not hearts_container:
        return
        
    var corazones = hearts_container.get_children()
    for i in range(corazones.size()):
        if corazones[i] is TextureRect:
            if i < nuevas_vidas:
                corazones[i].texture = heart_full
            else:
                corazones[i].texture = heart_empty
