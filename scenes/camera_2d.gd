extends Camera2D

var shake_intensity : float = 0.0

func _process(_delta):
	# Jika intensity lebih dari 0, goyang offset kamera secara acak
	if shake_intensity > 0:
		offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	else:
		offset = Vector2.ZERO

# Fungsi utama yang akan dipanggil saat memukul musuh
func apply_shake(intensity: float, duration: float):
	shake_intensity = intensity
	
	# Gunakan Tween untuk menurunkan intensitas getaran perlahan ke nol
	var tween = create_tween()
	tween.tween_property(self, "shake_intensity", 0.0, duration)
