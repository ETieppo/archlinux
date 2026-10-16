#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float threshold;
    vec2 texel;
    vec4 c0;
    vec4 c1;
    vec4 c2;
    vec4 c3;
    vec4 deep;
    float exposure;
};
layout(binding = 1) uniform sampler2D source;

float rand(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

float strip(vec2 p, vec2 c, vec2 size, float soft) {
    vec2 q = abs(p - c) - size;
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
    return 1.0 - smoothstep(0.0, soft, d);
}

void main() {
    vec2 uv = qt_TexCoord0;
    float f = texture(source, uv).a;
    vec4 sm = textureLod(source, uv, 1.0);
    float fa = max(sm.a, 1e-4);
    float hot = clamp(sm.r / fa, 0.0, 1.0);
    float key = clamp(sm.g / fa * 3.0, 0.0, 1.0);

    float w = fwidth(f) * 0.9 + 0.0015;
    float body = smoothstep(threshold - w, threshold + w, f);

    vec2 e = texel * 1.5;
    vec2 grad = vec2(
        textureLod(source, uv + vec2(e.x, 0.0), 0.5).a - textureLod(source, uv - vec2(e.x, 0.0), 0.5).a,
        textureLod(source, uv + vec2(0.0, e.y), 0.5).a - textureLod(source, uv - vec2(0.0, e.y), 0.5).a);
    vec2 out2 = length(grad) > 1e-6 ? -normalize(grad) : vec2(0.0);

    float s = clamp((f - threshold) / (0.95 - threshold), 0.0, 1.0);
    float h = sqrt(1.0 - (1.0 - s) * (1.0 - s));
    vec3 n = normalize(vec3(out2 * sqrt(max(1.0 - h * h, 0.0)), h + 1e-4));

    vec3 L = normalize(vec3(-0.5, -0.75, 0.6));
    vec3 R = reflect(vec3(0.0, 0.0, -1.0), n);
    float ndl = max(dot(n, L), 0.0);
    float fres = pow(1.0 - n.z, 2.6);

    vec3 neonA = c0.rgb * exposure;
    vec3 neonB = c1.rgb * exposure;
    vec3 rimTint = mix(neonA, neonB, 0.5 + 0.5 * cos(6.2831 * (key * 0.5 + uv.x * 0.35 + time * 0.02)));

    vec3 col = deep.rgb * (0.55 + 0.45 * ndl);
    col += mix(c2.rgb, c3.rgb, uv.x) * exposure * 0.06 * smoothstep(0.2, 1.0, -R.y);

    col += neonA * strip(R.xy, vec2(-0.48, -0.5), vec2(0.26, 0.05), 0.16) * 0.9;
    col += neonB * strip(R.xy, vec2(0.52, 0.42), vec2(0.24, 0.045), 0.16) * 0.75;
    col += rimTint * fres * 0.6;
    col += neonA * hot * fres * 0.9;

    col += vec3(1.0) * strip(R.xy, vec2(-0.4, -0.55), vec2(0.08, 0.02), 0.06) * 0.35;
    col += vec3(1.0) * pow(max(dot(R, L), 0.0), 260.0) * 1.1;
    col *= mix(1.0, 0.35, smoothstep(0.9, 1.0, uv.y));

    vec4 b1 = textureLod(source, uv, 3.5);
    vec4 b2 = textureLod(source, uv, 5.0);
    vec4 b3 = textureLod(source, uv, 6.5);
    float glow = b1.a * 0.05 + b2.a * 0.06 + b3.a * 0.08;
    float glowHot = b1.r * 0.3 + b2.r * 0.25 + b3.r * 0.2;
    vec3 glowTint = mix(neonB, neonA, clamp(glowHot * 3.0, 0.0, 1.0));

    float sh = textureLod(source, uv - vec2(0.0, texel.y * 26.0), 4.5).a;
    float shA = smoothstep(0.05, 0.6, sh) * 0.55;

    vec4 outc = vec4(0.0, 0.0, 0.0, shA);
    float gA = clamp(glow + glowHot, 0.0, 1.0);
    outc.rgb += glowTint * gA;
    outc.a += gA * 0.3 * (1.0 - outc.a);
    outc = vec4(col * body, body) + outc * (1.0 - body);

    outc.rgb += (rand(uv * 1731.0 + fract(time)) - 0.5) / 255.0;
    fragColor = clamp(outc, 0.0, 1.0) * qt_Opacity;
}
