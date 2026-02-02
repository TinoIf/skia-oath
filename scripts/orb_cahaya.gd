extends Area2D

@onready var take_orb = $AudioStreamPlayer2D

func _ready():
	# Animasi melayang sedikit menggunakan Tween
	var tween = create_tween().set_loops()
	tween.tween_property(self, "position:y", position.y - 10, 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", position.y, 1.0).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# 1. Hentikan deteksi tabrakan agar tidak terpicu dua kali
		$CollisionShape2D.set_deferred("disabled", true)
		# 2. Sembunyikan sprite/visual orb
		visible = false
		
		# 3. Jalankan logika data
		GameManager.add_orb()
		
		# 4. Putar suara dan TUNGGU hingga selesai
		take_orb.play()
		await take_orb.finished
		
		# 5. Baru hapus node dari memori
		queue_free()
