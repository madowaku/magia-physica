shader_type spatial;
render_mode unshaded, cull_back;

uniform vec4 base_color : source_color = vec4(0.25, 0.62, 0.95, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.08, 0.12, 0.32, 1.0);
uniform vec4 ink_color : source_color = vec4(0.04, 0.06, 0.16, 1.0);
uniform int style_mode : hint_range(0, 2) = 1;
uniform float bands : hint_range(2.0, 8.0) = 3.0;
uniform float pixel_steps : hint_range(8.0, 128.0) = 32.0;
uniform float outline_threshold : hint_range(0.0, 1.0) = 0.23;
uniform float outline_strength : hint_range(0.0, 1.0) = 0.75;

void fragment() {
    vec3 n = normalize(NORMAL);
    vec3 light_dir = normalize(vec3(0.5, 0.8, 0.65));
    float brightness = clamp(dot(n, light_dir) * 0.5 + 0.5, 0.0, 1.0);
    if (style_mode == 0) {
        ALBEDO = base_color.rgb * (0.35 + 0.65 * brightness);
    } else {
        float steps = max(2.0, bands);
        float light_level = floor(brightness * steps) / max(1.0, steps - 1.0);
        light_level = clamp(light_level, 0.0, 1.0);
        if (style_mode == 2) {
            light_level = floor(light_level * 3.0) / 3.0;
            // Color quantization; for true pixel-sized silhouettes use a low-resolution viewport.
            light_level = floor(light_level * pixel_steps) / max(pixel_steps, 1.0);
        }
        vec3 colored = mix(shadow_color.rgb, base_color.rgb, light_level);
        float facing = abs(dot(n, normalize(VIEW)));
        float edge = 1.0 - smoothstep(outline_threshold, outline_threshold + 0.12, facing);
        ALBEDO = mix(colored, ink_color.rgb, edge * outline_strength);
    }
    ALPHA = base_color.a;
}
