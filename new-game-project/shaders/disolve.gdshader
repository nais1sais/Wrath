shader_type spatial;

//credit DisplacedFikaDev

uniform vec3 base_color: source_color;
uniform vec3 inside_color: source_color;
uniform float dissolve_amount: hint_range(0.0, 1.0) = 0.0;
uniform sampler2D noise_texture;

uniform vec3 glow_color: source_color = vec3(1.0, 1.0, 1.0);
uniform float glow_intensitiy = 5.0;
uniform float glow_border_width: hint_range(0.0, 0.25) = 0.05;
uniform float glow_border_smoothness: hint_range(0.0, 0.1) = 0.04;

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
	
	vec3 surface_color = base_color;
	ALBEDO = surface_color;
	//ALBEDO = vec3(border_mask);
	EMISSION = surface_emisson * glow_intensitiy;
	ALPHA = dissolve_noise;
	ALPHA_SCISSOR_THRESHOLD = dissolve_amount;
	
}

