cbuffer ViewportCB : register(b0)
{
    float2 ViewportSize;
    float2 Padding;
};

struct VSInput
{
    float2 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR0;
    float Slice : TEXCOORD1;
};

struct VSOutput
{
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR0;
    float Slice : TEXCOORD1;
};

VSOutput main(VSInput input)
{
    VSOutput output;
    float2 clip = input.Position / ViewportSize * 2.0;
    clip.x -= 1.0;
    clip.y = 1.0 - clip.y;
    output.Position = float4(clip, 0.0, 1.0);
    output.TexCoord = input.TexCoord;
    output.Color = input.Color;
    output.Slice = input.Slice;
    return output;
}
