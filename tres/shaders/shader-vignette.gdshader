shader_type canvas_item;

void fragment() {
      vec2 uv = UV;
      vec2 center = vec2(0.5, 0.5);
      float dist = distance(uv, center);
      float vignette = smoothstep(0.8, 0.3, dist);
      COLOR.rgb *= vignette;
}

