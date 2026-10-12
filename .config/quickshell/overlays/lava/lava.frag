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
// field: a = density, r/a = selected, g/a = hue key
layout(binding = 1) uniform sampler2D source;

vec3 palette(float k) {
    k = clamp(k, 0.0, 1.0) * 3.0;
    if (k < 1.0) return mix(c0.rgb, c1.rgb, k);
    if (k < 2.0) return mix(c1.rgb, c2.rgb, k - 1.0);
    return mix(c2.rgb, c3.rgb, k - 2.0);
}

float rand(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

float rbox(vec2 p, vec2 c, vec2 size, float soft) {
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
    float key = sm.g / fa;
    vec3 tint = palette(key) * exposure;

    // ---- liquid body --------------------------------------------------
    float w = fwidth(f) * 0.9 + 0.0015;
    float body = smoothstep(threshold - w, threshold + w, f);

    vec2 e = texel * 2.0;
    vec2 grad = vec2(
        textureLod(source, uv + vec2(e.x, 0.0), 1.0).a - textureLod(source, uv - vec2(e.x, 0.0), 1.0).a,
        textureLod(source, uv + vec2(0.0, e.y), 1.0).a - textureLod(source, uv - vec2(0.0, e.y), 1.0).a);
    vec2 out2 = length(grad) > 1e-6 ? -normalize(grad) : vec2(0.0);

    // dome profile: steep at the rim, flat on top
    float s = clamp((f - threshold) / (0.93 - threshold), 0.0, 1.0);
    float h = sqrt(1.0 - (1.0 - s) * (1.0 - s));
    vec3 n = normalize(vec3(out2 * sqrt(max(1.0 - h * h, 0.0)), h + 1e-4));

    vec3 L = normalize(vec3(-0.5, -0.75, 0.6));
    float ndl = max(dot(n, L), 0.0);
    float fres = pow(1.0 - n.z, 3.0);
    vec3 R = reflect(vec3(0.0, 0.0, -1.0), n);

    // coloured liquid body: saturated rim, deeper (still tinted) core
    vec3 core = tint * 0.5 + deep.rgb * 0.15;
    vec3 col = mix(tint * 1.05, core, smoothstep(0.0, 0.85, h));
    col *= 0.72 + 0.28 * ndl;
    // liquid settles in the lower half: lit fill under the core
    col += tint * 0.45 * smoothstep(-0.1, 0.9, n.y) * (1.0 - 0.35 * h);

    // light passing through and leaving on the far side
    float caus = pow(clamp(dot(out2, normalize(-L.xy)), 0.0, 1.0), 1.6)
               * pow(1.0 - h, 1.3) * smoothstep(0.0, 0.12, s);
    col += mix(tint, vec3(1.0), 0.15) * caus * 1.2;

    // selected bubble glows from inside
    col += tint * hot * (0.12 + 0.45 * (1.0 - h) * (1.0 - h));

    // iridescent fresnel rim
    vec3 irid = 0.5 + 0.5 * cos(6.2831 * (fres * 0.8 + key * 0.6 + time * 0.015 + vec3(0.0, 0.33, 0.67)));
    col += mix(tint, irid * exposure, 0.5) * fres * 0.75;

    // studio reflections: key softbox top-left, faint coloured fill bottom-right
    float key1 = rbox(R.xy, vec2(-0.42, -0.52), vec2(0.2, 0.085), 0.11);
    float fill = rbox(R.xy, vec2(0.5, 0.55), vec2(0.22, 0.05), 0.12);
    col += vec3(1.0) * key1 * 0.5;
    col += tint * fill * 0.3;
    col += vec3(1.0) * pow(max(dot(R, L), 0.0), 220.0) * 1.2;
    // the pool gets deeper and darker towards the screen edge
    col *= mix(1.0, 0.35, smoothstep(0.9, 1.0, uv.y));

    // ---- light the liquid throws on its surroundings ---------------------
    vec4 b1 = textureLod(source, uv, 3.5);
    vec4 b2 = textureLod(source, uv, 5.0);
    vec4 b3 = textureLod(source, uv, 6.5);
    vec4 bs = b1 + b2 + b3;
    vec3 glowTint = palette(bs.g / max(bs.a, 1e-4)) * exposure;
    float glow = b1.a * 0.12 + b2.a * 0.12 + b3.a * 0.14;
    float glowHot = b1.r * 0.25 + b2.r * 0.25 + b3.r * 0.2;

    float sh = textureLod(source, uv - vec2(0.0, texel.y * 26.0), 4.5).a;
    float shA = smoothstep(0.05, 0.6, sh) * 0.5;

    vec4 outc = vec4(0.0, 0.0, 0.0, shA);
    float gA = clamp(glow + glowHot, 0.0, 1.0);
    outc.rgb += glowTint * gA;
    outc.a += gA * 0.35 * (1.0 - outc.a);
    outc = vec4(col * body, body) + outc * (1.0 - body);

    outc.rgb += (rand(uv * 1731.0 + fract(time)) - 0.5) / 255.0;
    fragColor = clamp(outc, 0.0, 1.0) * qt_Opacity;
}
