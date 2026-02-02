extends ColorRect

func _process(_delta):
	# Ambil kamera yang sedang aktif di levelmu
	var camera = get_viewport().get_camera_2d()
	if camera:
		# Kirim posisi kamera ke shader
		material.set_shader_parameter("camera_offset", camera.global_position)
