extends Node2D

@onready var anim_player = %SpikeAnimation
var is_active : bool = false

func _ready():
	%CollisionDamageArea.set_deferred("disabled", true)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_active:
		trigger_trap()

func trigger_trap():
	is_active = true	
	anim_player.play("spike_anim")
	
	# Tunggu sampai animasi selesai baru bisa dipicu lagi
	await anim_player.animation_finished
	is_active = false

func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(20)
		anim_player.play("reset_spike")
