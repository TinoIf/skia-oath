extends CharacterBody2D

# --- Konfigurasi ---
@export_group("Movement")
@export var speed = 60.0
@export var knockback_force = 300.0
@export var max_hp = 50.0

# --- Status Internal ---
var current_hp: float
var direction = 1
var is_stunned = false
var is_dead = false # Tambahkan flag untuk mencegah damage ganda saat mati

# --- Referensi Node ---
@onready var sprite = $Sprite2D
@onready var floor_ray = $RayCast2D
@onready var ledge_ray = $RayCast2D2
@onready var particles = $GPUParticles2D
@onready var anim = $AnimationPlayer
@onready var hurtbox = $Hurtbox 
@onready var main_collision = $CollisionShape2D # Pastikan nama node collision utama benar

var orb_scene = preload("res://scenes/orb_cahaya.tscn")

func _ready():
	current_hp = max_hp
	if sprite.material:
		sprite.material = sprite.material.duplicate()

func _physics_process(delta):
	if is_dead: return # Jika mati, hentikan semua logika

	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_stunned:
		velocity.x = move_toward(velocity.x, 0, 500 * delta)
		move_and_slide()
		return 

	if is_on_floor():
		if not ledge_ray.is_colliding() or floor_ray.is_colliding():
			flip_direction()
		
		velocity.x = direction * speed
		anim.play("walk")

	move_and_slide()

func flip_direction():
	direction *= -1
	sprite.scale.x = abs(sprite.scale.x) * direction
	floor_ray.position.x = abs(floor_ray.position.x) * direction
	ledge_ray.position.x = abs(ledge_ray.position.x) * direction
	floor_ray.target_position.x = abs(floor_ray.target_position.x) * direction
	ledge_ray.target_position.x = abs(ledge_ray.target_position.x) * direction

func take_damage(amount: float, source_pos: Vector2 = Vector2.ZERO):
	if is_dead: return # Mencegah menerima damage saat sudah mati
	
	current_hp = clamp(current_hp - amount, 0, max_hp)
	is_stunned = true
	
	# Animasi Hit & Squash
	if anim.has_animation("hit"):
		anim.play("hit")
		anim.speed_scale = 1.0 / Engine.time_scale 

	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_speed_scale(1.0 / Engine.time_scale)
	tween.tween_property(sprite, "scale", Vector2(abs(sprite.scale.x) * 1.2, 0.8), 0.05)
	tween.tween_property(sprite, "scale", Vector2(abs(sprite.scale.x), 1.0), 0.1)
	
	if sprite.material:
		sprite.material.set_shader_parameter("active", true)
	particles.restart()
	particles.emitting = true

	var knockback_dir = (global_position - source_pos).normalized()
	velocity = Vector2(knockback_dir.x * knockback_force, -180)

	# Reset Timers
	get_tree().create_timer(0.1, true, false, true).timeout.connect(func():
		if sprite.material: sprite.material.set_shader_parameter("active", false)
	)
	
	get_tree().create_timer(0.25, true, false, true).timeout.connect(func():
		if not is_dead:
			is_stunned = false
			anim.speed_scale = 1.0
			anim.play("walk")
	)

	if current_hp <= 0:
		_perform_death()

func _perform_death():
	is_dead = true
	velocity = Vector2.ZERO
	
	# Matikan collision agar player bisa lewat
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	# Panggil fungsi spawn orb
	spawn_orb()
	
	if anim.has_animation("dead"):
		anim.play("dead")
		await anim.animation_finished
	
	die()
	
	# 1. MATIKAN SEMUA COLLISION SEGERA (Solusi agar tidak ada 'hantu' monster)
	# Mematikan layer & mask fisik agar player bisa tembus
	set_collision_layer_value(1, false) 
	set_collision_mask_value(1, false)
	
	# Mematikan Hurtbox & Area Damage
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	
	# 2. LOGIKA VISUAL (Tanpa Delay Lama)
	if anim.has_animation("dead"):
		anim.play("dead")
		# Jika ingin langsung hilang setelah animasi, gunakan await singkat
		await anim.animation_finished
	
	die()

func die():
	# Jika ingin efek menghilang halus tapi cepat (0.1 detik saja agar tidak terasa delay)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0, 0.1) 
	await tween.finished
	queue_free()

func _on_damage_area_body_entered(body: Node2D) -> void:
	if is_dead: return
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(10, global_position)
			
func spawn_orb():
	# 1. Buat 'copy' atau instansi dari scene orb
	var orb = orb_scene.instantiate()
	
	# 2. Atur posisi orb agar sama dengan posisi monster saat ini
	orb.global_position = global_position
	
	# 3. Masukkan orb ke dalam 'World' agar dia tetap ada meskipun monster dihapus
	# get_parent() biasanya merujuk ke scene World tempat monster diletakkan
	get_parent().call_deferred("add_child", orb)
