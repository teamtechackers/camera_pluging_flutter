#extension GL_OES_EGL_image_external : require
precision mediump float;
uniform samplerExternalOES uTextureSampler;
varying vec2 vTextureCoord;

// Natural color correction for USB camera - minimal adjustments
void main()
{
    vec4 color = texture2D(uTextureSampler, vTextureCoord);

    // Keep colors natural - avoid over-correction that causes shininess
    vec3 corrected = color.rgb;

    // Minimal color balance adjustments for skin tones
    corrected.r *= 1.02;  // Very slight red boost for natural skin
    corrected.g *= 1.00;  // Keep green natural
    corrected.b *= 0.98;  // Slight blue reduction

    // Minimal saturation - avoid making skin look shiny
    float gray = dot(corrected, vec3(0.299, 0.587, 0.114));
    corrected = mix(vec3(gray), corrected, 1.03); // Very slight saturation

    gl_FragColor = vec4(corrected, color.a);
}
