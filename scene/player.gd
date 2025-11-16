extends CharacterBody2D

# --- Sinyal untuk UI (BARU) ---


# --- Variabel HP (BARU) ---
const MAX_HP = 1000
var current_hp = MAX_HP

# --- Variabel Energi (BARU) ---
const MAX_ENERGY = 5
var current_energy = MAX_ENERGY
const MAX_FIRE = 10
var current_fire = 0

# --- Variabel Dash ---
const DASH_SPEED = 350.0   # Seberapa cepat dash-nya
const DASH_DURATION = 0.3  # Seberapa lama dash-nya (dalam detik)
var is_dashing = false     # Untuk melacak state dash
var dash_timer = 0.0       # Timer untuk durasi dash

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 1000.0

var is_hit = false
var is_dead = false

# --- Variabel Double Jump ---
const MAX_JUMPS = 1       # Atur ke 2 untuk double jump (1 = lompat biasa)
var jumps_remaining = 0   # Penghitung sisa lompatan

var rock_hancur_scene = preload("res://scene/falling_rock.tscn")
@onready var tilemap : TileMapLayer = get_node("/root/WorldLv1/AwakenedCavern/Floor")

# Seberapa kuat kontrol horizontal saat di udara (0.0 = tanpa kontrol, 1.0 = kontrol penuh)
const AIR_CONTROL := 0.6
@onready var anim: AnimatedSprite2D = $Sprite
@onready var fire_pickup_sfx: AudioStreamPlayer2D = $FirePickupSFX
@onready var death_sfx : AudioStreamPlayer2D = $Death_SFX
@onready var darkness_mask: TextureRect = get_node("/root/WorldLv1/Darkness/Mask")
const VISION_SCALE_START = 1.0 
const VISION_SCALE_END = 7.0   

func _ready() -> void:
	GlobalSignal.hp_updated.emit(current_hp)
	GlobalSignal.energy_updated.emit(current_energy, MAX_ENERGY)
	GlobalSignal.fire_updated.emit(current_fire, MAX_FIRE)
	update_vision_scale()

func _physics_process(delta: float) -> void:
	
	# 1. Cek Kematian (Prioritas Tertinggi)
	if is_dead:
		return 
	
	# 2. (BARU) Cek Kena Hit (Stun)
	if is_hit:
		# Saat kena hit, kita hanya terapkan fisika (gravitasi/pentalan)
		# tapi kita lewati (return) semua input dan logika animasi normal.
		move_and_slide()
		return
	
	# 2. Cek jika SEDANG Dashing (Prioritas Kedua)
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity.x = 0
		else:
			velocity.y = 0 
			anim.play("Dash") 
			move_and_slide()
			return 

	# 3. LOGIKA NORMAL (Hanya berjalan jika tidak mati DAN tidak dashing)

	# Gravity manual (lebih stabil)
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Input arah (-1 .. 1)
	var direction := Input.get_axis("left_mov", "right_mov")
	

	move_and_slide()
	
	if is_on_floor():
		# Ambil data tabrakan
		var collision = get_last_slide_collision()
		
		# Cek apakah kita berdiri di atas tilemap yang benar
		if collision and collision.get_collider() == tilemap:
			
			# Dapatkan posisi tile TEPAT DI BAWAH kaki kita
			var tile_pos_below = tilemap.local_to_map(global_position + Vector2(0, 32))
			
			# Dapatkan data dari tile itu
			var tile_data = tilemap.get_cell_tile_data(tile_pos_below)
			
			# Cek "label rahasia" (hancur)
			if tile_data and tile_data.get_custom_data("hancur"):
				
				print("DEBUG: SUKSES! Berdiri di atas tile hancur!")
				
				# HANCURKAN!
				hancurkan_batu(tile_pos_below)
			
				
			# (Tidak perlu 'else' atau 'print GAGAL', agar tidak spam di console)
# --- Cek Trigger Dash ---
	# (BERUBAH: Tambahkan cek 'current_energy > 0')
	if Input.is_action_just_pressed("dash") and not is_dashing and current_energy > 0:
		
		# (BARU) Kurangi energi dan update UI
		current_energy -= 1
		GlobalSignal.energy_updated.emit(current_energy, MAX_ENERGY) # Kirim sinyal
		
		# Sisa logika dash Anda...
		is_dashing = true
		dash_timer = DASH_DURATION
		
		var dash_direction = 1.0
		if anim.flip_h:
			dash_direction = -1.0
			
		velocity.x = dash_direction * DASH_SPEED
		velocity.y = 0 
		anim.play("Dash")

	else:
		# --- Gerakan Normal & Animasi (Hanya jika TIDAK baru saja menekan dash) ---
		
		# Flip sprite
		if direction < 0:
			anim.flip_h = true
		elif direction > 0:
			anim.flip_h = false

		# Akselerasi
		var target_speed := direction * SPEED
		var accel := SPEED * 12.0 if is_on_floor() else SPEED * 8.0 * AIR_CONTROL
		velocity.x = move_toward(velocity.x, target_speed, accel * delta)

		# Jump (BERUBAH: Logika Double Jump)
		# Kita tidak lagi cek is_on_floor() di sini
		if Input.is_action_just_pressed("jump"):
			if jumps_remaining > 0:
				velocity.y = JUMP_VELOCITY
				jumps_remaining -= 1 # Kurangi sisa lompatan setiap kali lompat

		# Animasi & Reset Lompatan (BERUBAH)
		if not is_on_floor():
			if velocity.y < 0:
				anim.play("Jump")
			else:
				anim.play("Fall")
		else:
			# (BARU) Saat di lantai, reset sisa lompatan
			jumps_remaining = MAX_JUMPS
			
			# Animasi di lantai
			if abs(direction) > 0:
				anim.play("Run")
			else:
				anim.play("Idle")

	
	
func die():
	# Cek agar fungsi ini tidak terpicu berkali-kali
	if is_dead:
		return
	is_dead = true
	# Ganti "AnimationPlayer" dengan nama node AnimationPlayer Anda
	# Ganti "death" dengan nama animasi kematian Anda
	death_sfx.play()
	anim.play("Death")
	# Kode akan "menunggu" di baris ini selama 2.0 detik
	await anim.animation_finished
	# Setelah 2 detik, baru reload scene
	get_tree().reload_current_scene()


func _on_energy_regen_timer_timeout() -> void:
	if current_energy < MAX_ENERGY:
		current_energy += 1
		# Kirim sinyal ke UI bahwa energi sudah di-update
		GlobalSignal.energy_updated.emit(current_energy, MAX_ENERGY)
		
func take_damage(amount):
	# Jangan ambil damage jika sudah mati ATAU sudah sedang kena hit
	if is_dead or is_hit:
		return

	# 1. Kunci Player
	is_hit = true
	
	# 2. Kurangi HP & Update UI
	current_hp -= amount
	GlobalSignal.hp_updated.emit(current_hp) # Kirim sinyal ke UI
	
	# 3. Mainkan Animasi Hit
	# (Pastikan Anda punya animasi bernama "Hit" di AnimatedSprite2D)
	anim.play("Hit")
	
	# 4. Tunggu sampai animasi "Hit" selesai
	await anim.animation_finished
	
	# 5. Setelah animasi selesai, baru cek apakah player mati
	if current_hp <= 0:
		current_hp = 0 # Jangan sampai minus
		die() # Panggil fungsi kematian
	else:
		# 6. Jika masih hidup, kembalikan kontrol ke player
		is_hit = false
		# (Opsional) Paksa kembali ke 'Idle' agar tidak 'stuck'
		anim.play("Idle")
		
# (FUNGSI BARU)
# 'map_pos' adalah koordinat tile yang ingin kita hancurkan (misal: (5, 11))
func hancurkan_batu(map_pos):
	
	# 1. HAPUS TILE DARI TILEMAP
	# Parameter: (posisi_grid, layer_tilemap, id_tile)
	# -1 berarti "sel kosong"
	tilemap.set_cell(map_pos, -1) 
	
	# 2. MUNCULKAN "AKTOR" ANIMASI KITA
	var rock = rock_hancur_scene.instantiate()
	# Kita ubah koordinat grid (5, 11) kembali ke posisi dunia (pixel)
	# Kita tambah setengah ukuran tile agar animasinya pas di tengah
	rock.global_position = tilemap.map_to_local(map_pos)
	
	# 4. TAMBAHKAN ANIMASI KE LEVEL
	# get_parent() akan menambahkan 'rock' ke scene 'WorldLv1' (induk dari Player)
	get_parent().add_child(rock)

func collect_fire():
	if current_fire < MAX_FIRE:
		current_fire += 1
		
		# Umumkan ke Papan Pengumuman
		GlobalSignal.fire_updated.emit(current_fire, MAX_FIRE)
		fire_pickup_sfx.play()
		print("Api diambil! Total: ", current_fire) # Untuk debug
		update_vision_scale()
		
# (FUNGSI BARU) - Untuk meng-update skala 'Topeng'
# (FUNGSI BARU) - Untuk meng-update skala 'Topeng'
func update_vision_scale():
	# 1. Hitung progres (angka dari 0.0 s/d 1.0)
	var progress = float(current_fire) / float(MAX_FIRE)
	
	# 2. Hitung skala baru (interpolasi dari 1.0 ke 10.0)
	var new_scale = lerp(VISION_SCALE_START, VISION_SCALE_END, progress)
	
	# (PRINT DEBUG) Cek nilainya
	print("Api: ", current_fire, " Progress: ", progress, " New Scale: ", new_scale)
	
	# 3. Terapkan skala baru ke 'Topeng'
	if darkness_mask:
		darkness_mask.scale = Vector2(new_scale, new_scale)
		
		# (HAPUS) Kita tidak perlu mengatur alpha lagi
		# darkness_mask.modulate.a = new_alpha
