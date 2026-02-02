extends CharacterBody2D

# --- Konfigurasi ---
@export_group("Status")
@export var max_hp : float = 100.0
@export var current_hp : float = 100.0
@export var max_energy : float = 100.0
@export var current_energy : float = 100.0
@export var energy_regen_speed : float = 5.0
@export var dash_cost : float = 30.0

@export_group("Movement")
@export var speed = 180.0
@export var acceleration = 1000.0 
@export var friction = 2000.0

@export_group("Jump")
@export var jump_velocity = -475.0
@export var jump_cut_multiplier = 0.4
@export var fall_gravity_multiplier = 1.8

@export_group("Dash")
@export var dash_speed = 300.0

@export_group("Timers")
@export var coyote_duration = 0.15
@export var jump_buffer_duration = 0.1

# --- Signal ----
signal hp_change(new_hp)
signal energy_change(new_energy)

# --- State ---
enum State { IDLE, RUN, JUMP, FALL, ATTACK, DEATH, DASH, HIT }
var current_state : State = State.IDLE

# --- Variabel Internal ---
var jump_buffer_timer : float = 0.0
var was_on_floor : bool = false

@onready var visuals : Node2D = $Visuals
@onready var sprite : Sprite2D = $Visuals/Sprite2D
@onready var anim : AnimationPlayer = $AnimationPlayer
@onready var coyote_timer : Timer = $CoyoteTimer
@onready var dust_particles : GPUParticles2D = $DustParticle
@onready var sword_area : Area2D = $Visuals/SwordArea
@onready var sfx_death : AudioStreamPlayer2D = $DeathSFX
@onready var sfx_attack : AudioStreamPlayer2D = $AttackSFX
@onready var sfx_jump : AudioStreamPlayer2D = $Jump_SFX
@onready var camera = get_viewport().get_camera_2d()

func _ready():
	GameManager.register_player(self)
	# Pastikan player masuk ke group agar DeadZone bisa mendeteksi
	add_to_group("player")

func _physics_process(delta: float) -> void:
	# Kunci logika jika sudah mati
	if current_state == State.DEATH:
		apply_gravity(delta)
		move_and_slide()
		return

	var was_on_floor_before = is_on_floor()
	
	if current_energy < max_energy:
		current_energy += energy_regen_speed * delta
		current_energy = clamp(current_energy, 0, max_energy)
		energy_change.emit(current_energy)

	jump_buffer_timer -= delta
	
	update_state()
	handle_state_logic(delta)
	play_state_animation()
	
	move_and_slide()
	
	if not was_on_floor_before and is_on_floor():
		spawn_dust()
		if jump_buffer_timer > 0:
			execute_jump()

	if was_on_floor_before and not is_on_floor() and velocity.y >= 0:
		coyote_timer.start(coyote_duration)

func update_state():
	if current_state in [State.ATTACK, State.DASH, State.HIT, State.DEATH]: 
		return
	
	if Input.is_action_just_pressed("dash") and current_energy >= dash_cost:
		change_state(State.DASH)
		return
			
	var direction = Input.get_axis("left_mov", "right_mov")
	if is_on_floor():
		if Input.is_action_just_pressed("attack"):
			sfx_attack.play()
			change_state(State.ATTACK)
		elif direction != 0:
			change_state(State.RUN)
		else:
			change_state(State.IDLE)
	else:
		if velocity.y < 0:
			change_state(State.JUMP)
		else:
			change_state(State.FALL)

func handle_state_logic(delta):
	if current_state == State.DEATH: return
	
	apply_gravity(delta)
	
	if Input.is_action_just_pressed("jump"):
		if sfx_jump:
			sfx_jump.play()
		
		jump_buffer_timer = jump_buffer_duration
		if is_on_floor() or not coyote_timer.is_stopped():
			execute_jump()
			
	if current_state == State.DASH:
		velocity.x = visuals.scale.x * dash_speed
		velocity.y = 0
		return
		
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= jump_cut_multiplier

	var direction = Input.get_axis("left_mov", "right_mov")
	if current_state not in [State.ATTACK, State.HIT]:
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
			visuals.scale.x = direction
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func apply_gravity(delta):
	if current_state == State.DASH: return
	if not is_on_floor():
		var gravity = get_gravity()
		if velocity.y > 0:
			velocity += gravity * fall_gravity_multiplier * delta
		else:
			velocity += gravity * delta

func execute_jump():
	velocity.y = jump_velocity
	jump_buffer_timer = 0
	coyote_timer.stop()
	spawn_dust()

func change_state(new_state):
	if current_state == new_state: return
	
	# Cegah perpindahan state jika sudah mati
	if current_state == State.DEATH: return
	
	if new_state == State.DASH:
		current_energy -= dash_cost
		energy_change.emit(current_energy)
	current_state = new_state

func play_state_animation():
	match current_state:
		State.IDLE: anim.play("idle")
		State.RUN: anim.play("run")
		State.JUMP: anim.play("jump")
		State.FALL: anim.play("fall")
		State.ATTACK: anim.play("simple_attack")
		State.DASH: anim.play("dash")
		State.HIT: anim.play("hit")
		State.DEATH: anim.play("death")

func spawn_dust():
	if dust_particles:
		dust_particles.emitting = true

# --- LOGIKA KEMATIAN & RESPAWN ---
func die():
	if current_state == State.DEATH: return
	if sfx_death:
		sfx_death.play()
	current_state = State.DEATH
	collision_layer = 0
	velocity = Vector2.ZERO # Stop gerakan saat mati
	
	if anim.has_animation("death"):
		anim.play("death")
	
	await get_tree().create_timer(2.0).timeout
	if get_tree(): # Cek jika tree masih ada
		get_tree().reload_current_scene()

func take_damage(jumlah: float, source_pos: Vector2 = Vector2.ZERO):
	if current_state == State.DEATH: return
	if sfx_death:
		sfx_death.play()
	current_hp = clamp(current_hp - jumlah, 0, max_hp)
	hp_change.emit(current_hp)
	
	if current_hp <= 0:
		die()
	else:
		change_state(State.HIT)
		var knockback_dir = (global_position - source_pos).normalized()
		velocity = Vector2(knockback_dir.x * 250, -200)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "death":
		# Tunggu sebentar agar player bisa melihat animasinya selesai
		await get_tree().create_timer(0.6).timeout
		get_tree().reload_current_scene()
		
	if anim_name in ["simple_attack", "dash", "hit"]:
		current_state = State.IDLE

# --- INTERAKSI ---
func _on_sword_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		var monster = area.get_parent()
		if monster and monster.has_method("take_damage"):
			monster.take_damage(20, global_position)
			if camera:
				camera.apply_shake(5.0, 0.5)
			
			Engine.time_scale = 0.05
			await get_tree().create_timer(0.05, true, false, true).timeout
			Engine.time_scale = 1.0

# Fungsi ini dipanggil oleh Area2D DeadZone
func _on_dead_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("die"):
		body.die()
