shader_type canvas_item;

uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : hint_color = vec4(1.0, 0.0, 0.0, 1.0);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    vec3 final_color = mix(tex_color.rgb, flash_color.rgb, flash_intensity);
    float final_alpha = tex_color.a * (1.0 - flash_intensity) + flash_intensity;

    COLOR = vec4(final_color, final_alpha);
}
