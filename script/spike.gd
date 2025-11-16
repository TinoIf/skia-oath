extends CharacterBody2D

# --- Konfigurasi Trap ---
@export var fall_speed = 300.0
@export var shake_duration = 0.7  # Berapa lama bergetar (detik)
@export var shake_intensity = 4.0 # Seberapa kuat getarannya (pixel)

# --- Variabel Internal ---
enum State { IDLE, SHAKING, FALLING, LANDED }
var current_state = State.IDLE

@onready var sprite = $Sprite2D # Pastikan nama node sprite Anda "Sprite2D"
@onready var hitbox_shape = $Hitbox/CollisionPolygon2D # Sesuaikan jika namanya beda
@onready var detect_zone_shape = $PlayerDetectZone/CollisionShape2D
@onready var fall_sfx: AudioStreamPlayer2D = $TrapSFX
var original_sprite_position: Vector2

func _ready():
	# Simpan posisi awal sprite untuk animasi getar
	original_sprite_position = sprite.position

func _process(delta: float):
	# Setel ulang velocity.y setiap frame, kecuali saat jatuh
	velocity.y = 0
	
	match current_state:
		State.IDLE:
			pass # Diam
			
		State.SHAKING:
			_do_shake_animation()
			
		State.FALLING:
			# Jangan panggil _do_fall, tapi setel velocity
			velocity.y = fall_speed
			
		State.LANDED:
			pass # Berhenti bergerak
	
	# Panggil move_and_slide() di AKHIR _process
	# Ini akan menggerakkan CharacterBody2D
	move_and_slide()

# --- Logika Animasi Getar ---
func _do_shake_animation():
	# Buat offset acak di sekitar posisi asli sprite
	var random_offset = Vector2(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity)
	)
	# Terapkan getaran ke sprite, BUKAN ke seluruh node
	sprite.position = original_sprite_position + random_offset

# --- Fungsi Sinyal (Otomatis dibuat Godot) ---

# Sinyal ini terpicu saat player masuk ke Area DETEKSI
# Kita buat 'async' agar bisa menggunakan 'await' (timer)
func _on_player_detect_zone_body_entered(body):
	if body.is_in_group("player") and current_state == State.IDLE:
		
		current_state = State.SHAKING
		
		await get_tree().create_timer(shake_duration).timeout
		
		if current_state != State.SHAKING:
			return 
			
		current_state = State.FALLING
		
		sprite.position = original_sprite_position
		
		# Aktifkan hitbox (ini aman, tidak perlu deferred)
		hitbox_shape.disabled = false 
		
		# 8. (Opsional) Nonaktifkan zona deteksi (MENGGUNAKAN SET_DEFERRED)
		detect_zone_shape.set_deferred("disabled", true)


# Sinyal ini terpicu saat HITBOX menyentuh sesuatu
func _on_hitbox_body_entered(body):
# 1. Abaikan jika trap sedang menunggu hancur (LANDED)
	if current_state == State.LANDED:
		return

	# 2. Cek jika itu player, SELALU beri damage
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			# Fungsi take_damage() di Player Anda sudah punya
			# 'is_hit' (cooldown), jadi aman untuk dipanggil di sini
			body.take_damage(200)

	# 3. HANYA jika trap sedang JATUH, jalankan logika hancur
	if current_state == State.FALLING:
		fall_sfx.play()
		# Trap menabrak sesuatu (player ATAU lantai) saat jatuh
		current_state = State.LANDED # Berhenti jatuh
		
		# Matikan hitbox (pakai deferred)
		hitbox_shape.set_deferred("disabled", true)
		
		# Tunggu 1 detik
		await get_tree().create_timer(0.7).timeout
		
		# Hancurkan diri
		queue_free()
