extern float time;
extern float curvature;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords) {
    vec2 centered = (uv - 0.5) * 2.0;
    
    float r2 = dot(centered, centered);
    vec2 distorted = centered * (1.0 + curvature * r2);
    distorted = distorted / 2.0 + 0.5;
    
    distorted = clamp(distorted, 0.0, 1.0);
    
    vec4 pixel = Texel(tex, distorted);
    
    float flicker = 0.999 + 0.001 * sin(time * 6.0);
    pixel.rgb *= flicker;
    
    pixel.rgb += (fract(sin(dot(distorted + time * 0.0001, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 0.005;
    
    return pixel * color;
}
