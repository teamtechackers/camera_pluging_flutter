#extension GL_OES_EGL_image_external : require
precision mediump float;
uniform samplerExternalOES uTextureSampler;
varying vec2 vTextureCoord;

// Color correction for USB camera YUV input
void main()
{
    vec4 color = texture2D(uTextureSampler, vTextureCoord);

    // USB cameras often have YUV color space issues
    // Apply correction to improve color accuracy
    vec3 corrected = color.rgb;

    // Adjust color balance - USB cameras may have incorrect color temperature
    // Boost red slightly, reduce blue/green if needed
    corrected.r *= 1.05;  // Slight red boost
    corrected.g *= 0.98;  // Slight green reduction
    corrected.b *= 0.97;  // Slight blue reduction

    // Apply saturation adjustment
    float gray = dot(corrected, vec3(0.299, 0.587, 0.114));
    corrected = mix(vec3(gray), corrected, 1.08); // Slight saturation increase

    gl_FragColor = vec4(corrected, color.a);
}
