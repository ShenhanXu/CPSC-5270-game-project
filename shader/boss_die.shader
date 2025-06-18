shader_type canvas_item;

uniform float death_progress : hint_range(0.0, 1.0) = 0.0;
uniform float explosion_intensity : hint_range(0.0, 5.0) = 3.0;
uniform vec4 explosion_color : hint_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform float dissolve_size : hint_range(0.0, 0.5) = 0.1;
uniform float flash_speed : hint_range(0.0, 20.0) = 10.0;


float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 噪声纹理
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // 从中心向外的爆炸效果
    vec2 center = vec2(0.5, 0.5);
    float dist_from_center = distance(UV, center);
    
    // 创建爆炸噪声
    float explosion_noise = noise(UV * 8.0 + TIME * 2.0);
    explosion_noise = smoothstep(0.3, 0.7, explosion_noise);
    
    // 溶解效果 - 基于噪声和距离
    float dissolve_threshold = death_progress * 1.5 - 0.5;
    float dissolve_noise = noise(UV * 12.0);
    float dissolve_mask = step(dissolve_threshold, dissolve_noise + dist_from_center * 0.5);
    
    // 爆炸边缘发光
    float glow_edge = death_progress * 1.2;
    float glow_mask = 1.0 - smoothstep(glow_edge - dissolve_size, glow_edge, dist_from_center);
    glow_mask *= smoothstep(glow_edge + dissolve_size, glow_edge, dist_from_center);
    
    // 闪烁效果
    float flash = sin(TIME * flash_speed) * 0.5 + 0.5;
    flash *= death_progress * explosion_intensity;
    
    // 最终颜色计算
    vec3 final_color = tex_color.rgb;
    
    // 添加爆炸颜色
    final_color = mix(final_color, explosion_color.rgb, glow_mask * explosion_intensity * 0.5);
    
    // 添加闪烁
    final_color += explosion_color.rgb * flash * explosion_noise * 0.3;
    
    // 最终透明度
    float final_alpha = tex_color.a * dissolve_mask;
    
    COLOR = vec4(final_color, final_alpha);
}