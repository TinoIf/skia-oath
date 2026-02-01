shader_type canvas_item;

// Parameter ini bisa diakses lewat GDScript
uniform bool active = false;

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	// Jika active = true, ubah warnanya jadi putih solid (rgb 1,1,1), pertahankan transparansinya (a)
	vec4 white_color = vec4(1.0, 1.0, 1.0, original_color.a);
	// Pilih warna berdasarkan status 'active'
	COLOR = active ? white_color : original_color;
}