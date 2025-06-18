
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float glow_strength : hint_range(0.0, 5.0) = 3.0;
uniform vec4 glow_color : hint_color = vec4(1.0, 1.0, 0.0, 1.0);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    

    vec2 center = vec2(0.5, 0.5);
    float dist_from_center = distance(UV, center);
    

    float dissolve_radius = progress * 0.8;
    float dissolve_mask = smoothstep(dissolve_radius - 0.1, dissolve_radius, dist_from_center);
    

    float glow = sin(TIME * 8.0) * 0.5 + 0.5;
    glow *= (1.0 - progress) * glow_strength;

    vec3 final_color = tex_color.rgb + glow_color.rgb * glow * 0.5;
    float final_alpha = tex_color.a * (1.0 - dissolve_mask);
    
    COLOR = vec4(final_color, final_alpha);
}