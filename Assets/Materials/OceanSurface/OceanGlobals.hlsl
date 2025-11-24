#ifndef OCEAN_GLOBALS_INCLUDED
#define OCEAN_GLOBALS_INCLUDED

// --- STRUCTS ---
struct Attributes {
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 uv : TEXCOORD0;
};

struct ControlPoint {
    float4 positionOS : INTERNALTESSPOS;
    float3 normalOS : NORMAL;
    float2 uv : TEXCOORD0;
};

struct TessellationFactors {
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

struct Varyings {
    float4 positionCS : SV_POSITION;
    float3 positionWS : TEXCOORD3;
    float3 normalWS : NORMAL;
    float2 uv : TEXCOORD0;
    float3 viewDirWS : TEXCOORD1;
    float4 screenPos : TEXCOORD4;
};

struct WaveResult {
    float3 positionOffset;
    float3 normal;
};

// --- VARIABLES ---
CBUFFER_START(UnityPerMaterial)
    float4 _BaseColor;
    float _Metallic;
    float _Smoothness;
    float _Alpha; 
    float _RefractionStrength;

    float4 _SSSColor;
    float _SSSStrength;
    float _SSSPower;
    float _SSSDistortion;

    float4 _FogColor;
    float _FogDensity;

    float _Tess;
    float _MinDist;
    float _MaxDist;
    
    int _WaveCount;
    float4 _WaveData[8]; 
    float4 _WaveDirections[8];

    float _DebugMode;
CBUFFER_END

#endif