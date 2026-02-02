shader_type canvas_item;

uniform sampler2D noise_img : repeat_enable;
uniform float speed = 0.02; // Diperlambat sedikit agar lebih natural
uniform vec4 fog_color : source_color = vec4(1.0, 1.0, 1.0, 0.3);
uniform vec2 camera_offset; // Kita ambil dari posisi global kamera

void fragment() {
    // 1. Ambil UV dasar dari layar
    // 2. Tambahkan offset kamera dibagi skala tertentu (misal 500.0)
    // Angka 500.0 ini menentukan seberapa "jauh" kabutnya di latar belakang
    vec2 world_uv = SCREEN_UV + (camera_offset * 0.001); 
    
    // 3. Tambahkan gerakan konstan (angin)
    vec2 moving_uv = world_uv + vec2(TIME * speed, TIME * speed * 0.4);
    
    // 4. Ambil noise dan terapkan warna
    float noise = texture(noise_img, moving_uv).r;
    COLOR = vec4(fog_color.rgb, noise * fog_color.a);
}