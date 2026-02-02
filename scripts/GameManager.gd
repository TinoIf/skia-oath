extends Node

# --- Signal untuk UI ---
signal orb_updated(new_amount)
signal hp_updated(new_hp)
signal energy_updated(new_energy)

# --- Variabel Status ---
var orb_count : int = 0
var is_game_over : bool = false
var save_path = "user://savegame.save"

var player = null

func register_player(player_node):
	player = player_node
	
	# Hubungkan signal Player ke Manager (Relay System)
	if not player.hp_change.is_connected(_on_player_hp_changed):
		player.hp_change.connect(_on_player_hp_changed)
	if not player.energy_change.is_connected(_on_player_energy_changed):
		player.energy_change.connect(_on_player_energy_changed)
	
	print("Player berhasil didaftarkan ke GameManager")

func _on_player_hp_changed(new_hp):
	hp_updated.emit(new_hp) # Teruskan ke HUD
	if new_hp <= 0:
		trigger_game_over()

func _on_player_energy_changed(new_energy):
	energy_updated.emit(new_energy) # Teruskan ke HUD

func add_orb():
	orb_count += 1
	orb_updated.emit(orb_count) # Beritahu HUD bahwa orb bertambah
	print("Orb Terkumpul: ", orb_count)

func trigger_game_over():
	if not is_game_over:
		is_game_over = true
		print("GAME OVER!")

# --- SISTEM SAVE & LOAD (Tetap Sama) ---
func save_game():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	var data = {
		"orbs": orb_count,
		"player_pos_x": player.global_position.x if player else 0,
		"player_pos_y": player.global_position.y if player else 0
	}
	file.store_line(JSON.stringify(data))
	print("Game Berhasil Disimpan!")

func load_game():
	if not FileAccess.file_exists(save_path): return
	var file = FileAccess.open(save_path, FileAccess.READ)
	var json_string = file.get_line()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result == OK:
		var data = json.get_data()
		orb_count = data["orbs"]
		# PENTING: Kabari UI setelah data dimuat
		orb_updated.emit(orb_count) 
		
		if player:
			player.global_position = Vector2(data["player_pos_x"], data["player_pos_y"])
			# Update bar juga jika perlu
			hp_updated.emit(player.current_hp)
			
# Tambahkan fungsi ini di dalam GameManager.gd
func reset_game_state():
	# 1. Reset koleksi
	orb_count = 0
	is_game_over = false
	
	# 2. Reset referensi player (penting agar tidak merujuk ke player yang lama)
	player = null 
	
	# 3. Kirim signal update ke UI agar semuanya tampil nol/penuh lagi
	orb_updated.emit(0)
	hp_updated.emit(100.0) # Asumsi max hp kamu 100
	energy_updated.emit(100.0) # Asumsi max energy kamu 100
	
	print("Sistem direset total: Orb 0, HP/Energy Penuh")
