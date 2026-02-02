extends CanvasLayer

func _ready():
	hide() # Sembunyikan saat start
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(_event):
	if Input.is_action_just_pressed("pause"): 
		toggle_pause()

func toggle_pause():
	var new_state = !get_tree().paused
	get_tree().paused = new_state
	visible = new_state
	
	# Opsional: Jika menu muncul, bebaskan kursor mouse
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Hubungkan signal 'pressed()' dari tiap TextureButton
func _on_resume_btn_pressed():
	toggle_pause()

func _on_restart_btn_pressed():
	# 1. Jalankan waktu dulu (penting!)
	get_tree().paused = false
	
	# 2. Reset data di Manager
	GameManager.reset_game_state()
	
	# 3. Baru reload scene
	get_tree().reload_current_scene()


func _on_exit_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
