# dialogue_loader.gd
# Utilidad profesional para cargar diálogos desde archivos CSV
# Permite separación de datos y código para fácil edición

class_name DialogueLoader
extends RefCounted

#region MÉTODOS PÚBLICOS

## Carga diálogos desde un archivo CSV
## Formato esperado: character,text
## Retorna: Array de Dictionaries [{character: String, text: String}, ...]
static func load_from_csv(file_path: String) -> Array:
    var dialogues: Array = []

    # Verificar que el archivo existe
    if not FileAccess.file_exists(file_path):
        push_error("❌ DialogueLoader: Archivo no encontrado: " + file_path)
        return dialogues

    # Abrir archivo
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        push_error("❌ DialogueLoader: No se pudo abrir el archivo: " + file_path)
        return dialogues

    # Leer header (primera línea)
    var header = file.get_csv_line()
    if header.size() < 2:
        push_error("❌ DialogueLoader: Formato CSV inválido en: " + file_path)
        file.close()
        return dialogues

    # Leer líneas de diálogo
    var line_number = 1
    while not file.eof_reached():
        var line = file.get_csv_line()
        line_number += 1

        # Ignorar líneas vacías
        if line.size() < 2 or (line[0].is_empty() and line[1].is_empty()):
            continue

        # Validar datos
        if line[0].is_empty():
            push_warning("⚠️ DialogueLoader: Línea " + str(line_number) + " sin personaje, ignorando...")
            continue

        if line[1].is_empty():
            push_warning("⚠️ DialogueLoader: Línea " + str(line_number) + " sin texto, ignorando...")
            continue

        # Crear entrada de diálogo
        var dialogue_entry = {
            "character": line[0].strip_edges(),  # Eliminar espacios
            "text": line[1].strip_edges()
        }

        dialogues.append(dialogue_entry)

    file.close()

    print("✅ DialogueLoader: ", dialogues.size(), " líneas cargadas desde ", file_path)
    return dialogues

## Carga diálogos desde múltiples archivos CSV
## Útil para conversaciones grandes divididas en partes
static func load_multiple_csvs(file_paths: Array[String]) -> Array:
    var all_dialogues: Array = []

    for path in file_paths:
        var dialogues = load_from_csv(path)
        all_dialogues.append_array(dialogues)

    return all_dialogues

## Guarda diálogos a un archivo CSV
## Útil para exportar o crear diálogos programáticamente
static func save_to_csv(file_path: String, dialogues: Array) -> bool:
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if file == null:
        push_error("❌ DialogueLoader: No se pudo crear el archivo: " + file_path)
        return false

    # Escribir header
    file.store_csv_line(["character", "text"])

    # Escribir diálogos
    for dialogue in dialogues:
        if dialogue is Dictionary and dialogue.has("character") and dialogue.has("text"):
            file.store_csv_line([dialogue["character"], dialogue["text"]])

    file.close()
    print("✅ DialogueLoader: Diálogos guardados en ", file_path)
    return true

## Valida que un array de diálogos tenga el formato correcto
static func validate_dialogues(dialogues: Array) -> bool:
    if dialogues.is_empty():
        push_warning("⚠️ DialogueLoader: Array de diálogos está vacío")
        return false

    for i in range(dialogues.size()):
        var dialogue = dialogues[i]

        if not dialogue is Dictionary:
            push_error("❌ DialogueLoader: Entrada " + str(i) + " no es un Dictionary")
            return false

        if not dialogue.has("character"):
            push_error("❌ DialogueLoader: Entrada " + str(i) + " no tiene 'character'")
            return false

        if not dialogue.has("text"):
            push_error("❌ DialogueLoader: Entrada " + str(i) + " no tiene 'text'")
            return false

    return true
#endregion
