extends Area2D

@export var required_orbs : int = 10
@export var hold_duration : float = 5.0
@export var transition_duration : float = 2.0 # Durasi layar memutih

@onready var prompt = $CanvasLayer/VisualPrompt
@onready var progress_bar = $CanvasLayer/VisualPrompt/InteractionBar
@onready var label = $CanvasLayer/VisualPrompt/Label

# Referensi baru untuk Dialog dan Suara
@onready var white_flash_rect = $TransitionLayer/WhiteFlashRect
@onready var dialogue_label = $TransitionLayer/DialogueLabel
@onready var dialogue_player = $TransitionLayer/DialoguePlayer

var is_player_inside : bool = false
var current_hold_time : float = 0.0
var level_finished : bool = false 

func _ready():
	prompt.hide()
	progress_bar.max_value = hold_duration
	if white_flash_rect:
		white_flash_rect.modulate.a = 0.0
	if dialogue_label:
		dialogue_label.visible_ratio = 0.0

func _process(delta):
	if level_finished:
		return

	if is_player_inside:
		if GameManager.orb_count >= required_orbs:
			label.text = "Tahan [E] untuk Selesai"
			handle_holding(delta)
		else:
			label.text = "Butuh " + str(required_orbs - GameManager.orb_count) + " Orb lagi!"
			progress_bar.hide()

func handle_holding(delta):
	if Input.is_action_pressed("interact"):
		current_hold_time += delta
		# Efek denyut halus pada bar
		progress_bar.tint_progress.a = 0.8 + (sin(Time.get_ticks_msec() * 0.005) * 0.2)
		progress_bar.show()
		progress_bar.value = current_hold_time
		
		if current_hold_time >= hold_duration:
			finish_level_sequence()
	else:
		current_hold_time = move_toward(current_hold_time, 0, delta * 2)
		progress_bar.value = current_hold_time
		if current_hold_time <= 0:
			progress_bar.hide()

# --- URUTAN AKHIR DENGAN DIALOG & CAHAYA ---
func finish_level_sequence():
	level_finished = true 
	prompt.hide()
	
	# 1. Matikan kontrol player agar tidak bisa gerak saat narasi
	if GameManager.player:
		GameManager.player.set_physics_process(false)

	# 2. Putar Suara
	if dialogue_player:
		dialogue_player.play()

	# 3. Buat Tween
	var tween = create_tween()
	
	# --- BAGIAN PARALLEL (Jalan Bersamaan) ---
	# Kita gunakan set_parallel agar cahaya dan teks muncul bareng
	tween.set_parallel(true)
	
	# Animasikan Cahaya Putih (2 detik)
	tween.tween_property(white_flash_rect, "modulate:a", 1.0, 7.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Animasikan Teks Typewriter (3.5 detik)
	dialogue_label.visible_ratio = 0.0
	dialogue_label.show()
	tween.tween_property(dialogue_label, "visible_ratio", 1.0, 7.0)
	
	# --- BAGIAN SEQUENCE (Menunggu yang di atas selesai) ---
	# Gunakan chain() agar interval ini dihitung SETELAH parallel di atas kelar
	tween.chain().tween_interval(8.0) # Jeda agar pemain bisa membaca teks utuh
	
	# 4. Baru pindah scene setelah semua jeda selesai
	tween.finished.connect(_on_transition_complete)
func _on_transition_complete():
	# Kembali ke Main Menu untuk sementara
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_body_entered(body):
	if body.is_in_group("player") and not level_finished:
		is_player_inside = true
		prompt.show()

func _on_body_exited(body):
	if body.is_in_group("player"):
		is_player_inside = false
		prompt.hide()
		current_hold_time = 0
