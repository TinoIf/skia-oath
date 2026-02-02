extends Node2D

# --- SAKLAR UTAMA ---
@export var can_crumble : bool = true # Centang ini jika ingin platform hancur
@export var respawn_delay : float = 2.0

@onready var anim_body = $AnimatableBody2D
@onready var collision = $AnimatableBody2D/CollisionShape2D
@onready var sprite = $AnimatableBody2D/Sprite2D
@onready var anim_player = $AnimatableBody2D/AnimationPlayer
@onready var timer = $AnimatableBody2D/Timer

var is_crumbling : bool = false

func _ready():
	# Baik hancur maupun permanen, keduanya harus bergerak di awal
	if anim_player.has_animation("move_loop"):
		anim_player.play("move_loop")
	
	timer.one_shot = true
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)

func _on_area_2d_body_entered(body: Node2D) -> void:
	# LOGIKA SAKLAR: Jika can_crumble mati (false), jangan lakukan apa-apa
	if not can_crumble:
		return
		
	# Jika can_crumble aktif, baru jalankan logika hancur
	if body.is_in_group("player") and not is_crumbling:
		is_crumbling = true
		start_crumble_sequence()

func start_crumble_sequence():
	if anim_player.has_animation("shake"):
		anim_player.play("shake")
	
	timer.start(0.4)
	print("Platform bergetar...")

func _on_timer_timeout():
	anim_player.play("break")
	collision.set_deferred("disabled", true)
	
	await get_tree().create_timer(respawn_delay).timeout
	respawn_platform()

func respawn_platform():
	is_crumbling = false
	
	# Kembalikan kondisi fisik dan visual
	collision.set_deferred("disabled", false)
	sprite.visible = true
	sprite.modulate.a = 1.0
	
	# Jalankan kembali animasi gerakan bolak-balik
	if anim_player.has_animation("move_loop"):
		anim_player.play("move_loop")
	else:
		anim_player.play("RESET")
		
	print("Platform muncul kembali dan mulai bergerak")
