shader_type canvas_item;
uniform sampler2D noise_img : repeat_enable;
uniform float speed = 0.05;
uniform vec4 fog_color : source_color = vec4(1.0, 1.0, 1.0, 0.3);

void fragment() {
    // SCREEN_UV membuat kabut menempel di layar
    // Kita tambahkan OFFSET berdasarkan posisi kamera (FRAGCOORD)
    vec2 world_uv = SCREEN_UV + (FRAGCOORD.xy * 0.00001); 
    
    // Tambahkan variabel waktu untuk scrolling
    vec2 moving_uv = world_uv + vec2(TIME * speed, TIME * speed * 0.1);
    
    float noise = texture(noise_img, moving_uv).r;
    COLOR = vec4(fog_color.rgb, noise * fog_color.a);
}
