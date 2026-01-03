# como_jugar.gd
# Pantalla de instrucciones del juego
extends Control

# ==================== REFERENCIAS ====================
@onready var btn_volver = $BtnVolver

# ==================== INICIALIZACIÓN ====================
func _ready():
    # Conectar botón volver
    if btn_volver:
        btn_volver.pressed.connect(_on_volver_pressed)

    print("📖 Pantalla Como Jugar cargada")

# ==================== CALLBACKS ====================
func _on_volver_pressed():
    print("🏠 Volviendo al menú principal...")
    get_tree().change_scene_to_file("res://scenes/menu_principal/menu_principal.tscn")
