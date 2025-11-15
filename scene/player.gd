extends CharacterBody2D

# --- Sinyal untuk UI (BARU) ---
# Sinyal ini akan mengirim "pesan" ke UI kita
signal hp_updated(new_hp)
signal energy_updated(new_energy, max_energy)

# --- Variabel HP (BARU) ---
const MAX_HP = 1000
var current_hp = MAX_HP

# --- Variabel Energi (BARU) ---
const MAX_ENERGY = 5
var current_energy = MAX_ENERGY

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

# Seberapa kuat kontrol horizontal saat di udara (0.0 = tanpa kontrol, 1.0 = kontrol penuh)
const AIR_CONTROL := 0.6
@onready var anim: AnimatedSprite2D = $Sprite

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
	var direction := Input.get_axis("ui_left", "ui_right")

# --- Cek Trigger Dash ---
	# (BERUBAH: Tambahkan cek 'current_energy > 0')
	if Input.is_action_just_pressed("dash") and not is_dashing and current_energy > 0:
		
		# (BARU) Kurangi energi dan update UI
		current_energy -= 1
		energy_updated.emit(current_energy, MAX_ENERGY) # Kirim sinyal
		
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
		if Input.is_action_just_pressed("ui_accept"):
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

	move_and_slide()
	
func die():
	# Cek agar fungsi ini tidak terpicu berkali-kali
	if is_dead:
		return
	is_dead = true
	# Ganti "AnimationPlayer" dengan nama node AnimationPlayer Anda
	# Ganti "death" dengan nama animasi kematian Anda
	anim.play("Death")
	# Kode akan "menunggu" di baris ini selama 2.0 detik
	await anim.animation_finished
	# Setelah 2 detik, baru reload scene
	get_tree().reload_current_scene()


func _on_energy_regen_timer_timeout() -> void:
	if current_energy < MAX_ENERGY:
		current_energy += 1
		# Kirim sinyal ke UI bahwa energi sudah di-update
		energy_updated.emit(current_energy, MAX_ENERGY)
		
func take_damage(amount):
	# Jangan ambil damage jika sudah mati ATAU sudah sedang kena hit
	if is_dead or is_hit:
		return

	# 1. Kunci Player
	is_hit = true
	
	# 2. Kurangi HP & Update UI
	current_hp -= amount
	hp_updated.emit(current_hp) # Kirim sinyal ke UI
	
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
