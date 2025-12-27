precision highp float;
uniform sampler2D uTextureSampler;
varying vec2 vTextureCoord;

// Color correction matrix for USB camera YUV to RGB conversion
// This corrects the color space issues in USB camera output
void main()
{
    vec4 color = texture2D(uTextureSampler, vTextureCoord);

    // Apply color correction for USB camera YUV issues
    // Adjust saturation and color balance
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 adjusted = mix(vec3(gray), color.rgb, 1.1); // Slight saturation boost

    // Gamma correction to fix brightness/color temperature
    adjusted = pow(adjusted, vec3(1.0/2.2));

    gl_FragColor = vec4(adjusted, color.a);
}
