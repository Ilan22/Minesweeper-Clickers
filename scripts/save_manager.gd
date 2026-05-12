# SaveManager.gd
# AutoLoad

extends Node

const SAVE_PATH := "user://save.dat"
const SECRET := "4d6cb35d00e610b4e15dc64197da5278"

# =========================
# SAVE
# =========================

func save_game(game_data: Dictionary):
	var json := JSON.stringify(game_data)

	var final_save := {
		"data": json,
		"signature": create_signature(json)
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file:
		file.store_string(JSON.stringify(final_save))
		file.close()

		print("Game Saved")


# =========================
# LOAD
# =========================

func load_game():
	if !FileAccess.file_exists(SAVE_PATH):
		print("No save found")
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)

	if !file:
		print("Failed to open save")
		return

	var content = file.get_as_text()
	file.close()

	var json = JSON.new()

	if json.parse(content) != OK:
		print("Invalid save format")
		return
	var loaded = json.data

	if !loaded.has("data") or !loaded.has("signature"):
		print("Corrupted save")
		return
		
	var data_string: String = loaded["data"]
	var signature: String = loaded["signature"]

	if signature != create_signature(data_string):
		print("SAVE HACKED OR CORRUPTED")
		return

	var data_json = JSON.new()
	if data_json.parse(data_string) != OK:
		print("Invalid data format")
		return null

	print("Game Loaded")
	return data_json.data

# =========================
# SIGNATURE
# =========================

func create_signature(content: String) -> String:
	return (content + SECRET).sha256_text()
