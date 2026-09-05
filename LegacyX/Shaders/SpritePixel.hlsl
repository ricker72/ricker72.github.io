Texture2DArray SpriteTexture : register(t0);
SamplerState SpriteSampler : register(s0);

cbuffer VividCB : register(b1)
{
    float VividEnabled;
    float Saturation;
    float Contrast;
    float ReliefStrength;
};

struct PSInput
{
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR0;
    float Slice : TEXCOORD1;
};

float4 main(PSInput input) : SV_TARGET
{
    float3 uvw = float3(input.TexCoord, input.Slice);
    float4 sampleColor = SpriteTexture.Sample(SpriteSampler, uvw);
    if (VividEnabled < 0.5 || sampleColor.a <= 0.001)
        return sampleColor * input.Color;

    uint width;
    uint height;
    uint elements;
    uint levels;
    SpriteTexture.GetDimensions(0, width, height, elements, levels);
    float2 texel = 1.0 / max(float2(width, height), 1.0);
    float l = dot(SpriteTexture.Sample(SpriteSampler,
        float3(input.TexCoord - float2(texel.x, 0), input.Slice)).rgb,
        float3(0.2126, 0.7152, 0.0722));
    float r = dot(SpriteTexture.Sample(SpriteSampler,
        float3(input.TexCoord + float2(texel.x, 0), input.Slice)).rgb,
        float3(0.2126, 0.7152, 0.0722));
    float u = dot(SpriteTexture.Sample(SpriteSampler,
        float3(input.TexCoord - float2(0, texel.y), input.Slice)).rgb,
        float3(0.2126, 0.7152, 0.0722));
    float d = dot(SpriteTexture.Sample(SpriteSampler,
        float3(input.TexCoord + float2(0, texel.y), input.Slice)).rgb,
        float3(0.2126, 0.7152, 0.0722));

    // Ephemeral normal derived from the certified diffuse sprite. No client
    // asset or OTBM data is modified.
    float3 normal = normalize(float3((l - r) * ReliefStrength,
        (u - d) * ReliefStrength, 1.0));
    float3 lightDirection = normalize(float3(-0.35, -0.45, 0.82));
    float diffuse = saturate(dot(normal, lightDirection));
    float edge = saturate((abs(l - r) + abs(u - d)) * 1.25);

    float3 rgb = sampleColor.rgb * (0.90 + diffuse * 0.14);
    float luminance = dot(rgb, float3(0.2126, 0.7152, 0.0722));

    // Keep water gradients, cave blacks and already-bright city materials
    // inside their original gamut. Vivid strength reaches its requested
    // value in the mid-tones and fades towards both luminance extremes.
    float midToneWeight = smoothstep(0.025, 0.18, luminance) *
        (1.0 - smoothstep(0.72, 0.98, luminance));
    float adaptiveSaturation = lerp(1.0, Saturation, midToneWeight);
    rgb = lerp(luminance.xxx, rgb, adaptiveSaturation);

    // Luminance-centred contrast avoids independent RGB channel clipping.
    float contrastedLuminance = (luminance - 0.5) * Contrast + 0.5;
    float luminanceScale = contrastedLuminance / max(luminance, 0.001);
    rgb *= lerp(1.0, luminanceScale, midToneWeight);
    rgb *= 1.0 - edge * 0.10;
    return float4(saturate(rgb), sampleColor.a) * input.Color;
}
