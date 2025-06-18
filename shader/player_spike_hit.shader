shader_type canvas_item;

uniform float hit_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.03;
uniform vec4 hit_color : hint_color = vec4(0.8, 0.2, 0.2, 1.0);
uniform float flash_speed : hint_range(0.0, 20.0) = 15.0;
uniform float edge_glow : hint_range(0.0, 0.5) = 0.1;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 distorted_uv = UV;
    if (hit_intensity > 0.0) {
        vec2 center = vec2(0.5, 0.5);
        float dist_from_center = distance(UV, center);
        float wave = sin(dist_from_center * 20.0 - TIME * 10.0) * hit_intensity;
        vec2 wave_offset = normalize(UV - center) * wave * distortion_strength;
        distorted_uv += wave_offset;
    }

    vec4 tex_color = texture(TEXTURE, distorted_uv);

    // 添加透明像素丢弃，防止边框发光
    if (tex_color.a < 0.1) {
        discard;
    }

    float flash = sin(TIME * flash_speed) * 0.5 + 0.5;
    flash *= hit_intensity;

    vec2 edge_dist = min(UV, 1.0 - UV);
    float edge_factor = smoothstep(0.0, edge_glow, min(edge_dist.x, edge_dist.y));
    edge_factor = 1.0 - edge_factor;
    edge_factor *= hit_intensity;

    vec3 final_color = tex_color.rgb;
    final_color = mix(final_color, hit_color.rgb, hit_intensity * 0.6);
    final_color += hit_color.rgb * flash * 0.3;
    final_color += hit_color.rgb * edge_factor * 0.4;
    final_color = clamp(final_color, 0.0, 1.0);

    COLOR = vec4(final_color, tex_color.a);
}

