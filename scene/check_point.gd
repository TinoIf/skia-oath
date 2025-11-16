extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
var is_activated = false

func _ready():
	# (Opsional) Set animasi awal
	anim.play("Idle")

# Ini adalah fungsi yang terhubung dari sinyal body_entered
func _on_body_entered(body):
	# 1. Cek jika itu Player DAN checkpoint ini belum diaktifkan
	if body.is_in_group("player") and not is_activated:
		
		# 2. Tandai sudah aktif
		is_activated = true
		
		# 3. Mainkan animasi (opsional)
		anim.play("Activated")
		
		# 4. INI BAGIAN PENTING:
		# Simpan posisi checkpoint ini ke "buku catatan" global
		GlobalState.last_checkpoint_position = self.global_position
		
		print("Checkpoint diaktifkan di: ", self.global_position)
