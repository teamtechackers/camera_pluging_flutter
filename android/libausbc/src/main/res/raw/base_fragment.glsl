precision highp float;
uniform sampler2D uTextureSampler;
varying vec2 vTextureCoord;

// Color correction matrix for USB camera YUV to RGB conversion
// This corrects the color space issues in USB camera output
void main()
{
    vec4 color = texture2D(uTextureSampler, vTextureCoord);

    // Natural color correction - avoid over-saturation and brightness
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 adjusted = mix(vec3(gray), color.rgb, 1.02); // Minimal saturation boost

    // Mild gamma correction for natural skin tones
    adjusted = pow(adjusted, vec3(1.0/1.8));

    gl_FragColor = vec4(adjusted, color.a);
}
