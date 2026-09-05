Texture2DArray SourceTexture : register(t0);
Texture2DArray BloomTexture : register(t1);
Texture2DArray LightTexture : register(t2);
Texture2DArray AoTexture : register(t3);
SamplerState PointSampler : register(s0);

cbuffer PostProcessCB : register(b2)
{
    float2 InvTargetSize;
    float BloomStrength;
    float AoStrength;
    float LightStrength;
    float2 BlurDirection;
    float Padding;
};

struct PSInput
{
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR0;
    float Slice : TEXCOORD1;
};

float4 Emitter(PSInput input) : SV_TARGET
{
    float2 centered = input.TexCoord * 2.0 - 1.0;
    float falloff = saturate(1.0 - length(centered));
    falloff = falloff * falloff * (3.0 - 2.0 * falloff);
    return float4(input.Color.rgb * falloff * input.Color.a, falloff);
}

float4 Occluder(PSInput input) : SV_TARGET
{
    float2 centered = input.TexCoord * 2.0 - 1.0;
    float edge = saturate(1.0 - length(centered));
    return float4(edge.xxx * input.Color.a, edge);
}

float4 Blur(PSInput input) : SV_TARGET
{
    float2 stepUv = InvTargetSize * BlurDirection;
    float4 color = SourceTexture.Sample(PointSampler,
        float3(input.TexCoord, 0)) * 0.227027;
    color += SourceTexture.Sample(PointSampler,
        float3(input.TexCoord + stepUv * 1.384615, 0)) * 0.316216;
    color += SourceTexture.Sample(PointSampler,
        float3(input.TexCoord - stepUv * 1.384615, 0)) * 0.316216;
    color += SourceTexture.Sample(PointSampler,
        float3(input.TexCoord + stepUv * 3.230769, 0)) * 0.070270;
    color += SourceTexture.Sample(PointSampler,
        float3(input.TexCoord - stepUv * 3.230769, 0)) * 0.070270;
    return color;
}

float4 Composite(PSInput input) : SV_TARGET
{
    float3 uvw = float3(input.TexCoord, 0);
    float4 scene = SourceTexture.Sample(PointSampler, uvw);
    // Preserve relative energy from overlapping official emitters while
    // applying a soft knee. A hard saturate made dense city lights converge
    // to the same white/yellow patch.
    float3 bloomEnergy = max(BloomTexture.Sample(PointSampler, uvw).rgb, 0.0);
    float3 lightEnergy = max(LightTexture.Sample(PointSampler, uvw).rgb, 0.0);
    float3 bloom = bloomEnergy / (1.0 + bloomEnergy);
    float3 light = lightEnergy / (1.0 + lightEnergy);
    float ao = saturate(AoTexture.Sample(PointSampler, uvw).r);
    float sceneLuminance = dot(scene.rgb, float3(0.2126, 0.7152, 0.0722));
    float emitterLuminance = dot(light, float3(0.2126, 0.7152, 0.0722));

    // Light accumulation contains only certified OTB LightLevel/LightColor
    // emitters. AO contains only official structural flags from visible tiles.
    float3 lit = scene.rgb * (1.0 + light * LightStrength);

    // Bloom remains visible around isolated torches and magic effects, but
    // progressively limits itself in highlights and dense light clusters.
    float highlightProtection = 1.0 - smoothstep(0.62, 0.96, sceneLuminance);
    float denseLightProtection = 1.0 - smoothstep(0.45, 0.90, emitterLuminance);
    lit += bloom * BloomStrength * highlightProtection *
        lerp(0.45, 1.0, denseLightProtection);

    // Do not crush already-dark caves, nor dirty the centre of an emitter.
    float shadowProtection = lerp(0.45, 1.0,
        smoothstep(0.025, 0.30, sceneLuminance));
    float emitterProtection = 1.0 - emitterLuminance * 0.65;
    lit *= 1.0 - saturate(ao * AoStrength * shadowProtection * emitterProtection);

    // Shoulder only above 85% luminance: ordinary sprite colours are left
    // untouched while HDR peaks approach white smoothly instead of clipping.
    float3 shoulderInput = max(lit - 0.85, 0.0);
    float3 shoulder = 0.85 + 0.15 *
        (1.0 - exp(-shoulderInput / 0.15));
    lit = lerp(lit, shoulder, step(0.85, lit));
    return float4(saturate(lit), scene.a);
}
