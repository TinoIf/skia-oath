extends Control

# Pastikan path ke scene World kamu benar
@export_file("*.tscn") var world_scene_path: String = "res://scenes/World1.tscn"

func _ready():
	# Pastikan mouse muncul karena di game mungkin kita 'capture' mousenya
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Di dalam main_menu.gd
func _on_start_btn_pressed():
	# Selalu reset state lewat GameManager sebelum mulai baru
	GameManager.reset_game_state() 
	
	# Perintah untuk pindah ke scene level 1
	get_tree().change_scene_to_file("res://scenes/world_1.tscn")

func _on_exit_btn_pressed():
	# Keluar dari game
	get_tree().quit()
