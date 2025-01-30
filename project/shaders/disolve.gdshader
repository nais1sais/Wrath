shader_type spatial;

//credit DisplacedFikaDev

uniform sampler2D base_texture : source_color;
uniform sampler2D emission_texture : source_color;
uniform float emission_texture_intensity : hint_range(0.0, 50.0) = 1.0;
uniform vec3 inside_color: source_color;
uniform float dissolve_amount: hint_range(0.0, 1.0) = 0.0;
uniform sampler2D noise_texture;

uniform vec3 glow_color: source_color = vec3(0.533, 0.533, 0.533);
uniform float glow_intensitiy = 1.77;
uniform float glow_border_width: hint_range(0.0, 0.25) = 0.018;
uniform float glow_border_smoothness: hint_range(0.0, 0.1) = 0.003;

uniform sampler2D normal_texture;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;


void fragment() {
	float dissolve_noise = texture(noise_texture, UV).r;

	float border_mask = 0.0;
	if (dissolve_amount > 0.0) {
		float border_size = dissolve_amount + glow_border_width;
		border_mask = 1.0 - smoothstep(
			border_size - glow_border_smoothness,
			border_size + glow_border_smoothness,
			dissolve_noise
		);
	}

	vec3 surface_emisson = mix(vec3(0.0), glow_color, border_mask);
	surface_emisson += texture(emission_texture, UV).rgb * emission_texture_intensity;

	vec3 surface_color = texture(base_texture, UV).rgb;
	ALBEDO = surface_color;
	//ALBEDO = vec3(border_mask);
	EMISSION = surface_emisson * glow_intensitiy;
	ALPHA = dissolve_noise;
	ALPHA_SCISSOR_THRESHOLD = dissolve_amount;

	NORMAL_MAP = texture(normal_texture, UV).xyz;

}
