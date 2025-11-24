#ifndef OCEAN_LOGIC_INCLUDED
#define OCEAN_LOGIC_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

// --- INCLUDES ---
#include "OceanGlobals.hlsl"
#include "OceanPhysics.hlsl"
#include "OceanTessellation.hlsl"

// --- HELPERS ---

float3 ReconstructWorldPosition(float2 screenUV, float depth)
{
    #if UNITY_REVERSED_Z
        real rawDepth = depth;
    #else
        real rawDepth = lerp(UNITY_NEAR_CLIP_VALUE, 1, depth);
    #endif
    float4 ndc = float4(screenUV * 2.0 - 1.0, rawDepth, 1.0);
    float4 worldPos = mul(unity_MatrixInvVP, ndc);
    return worldPos.xyz / worldPos.w;
}

// --- FRAGMENT SHADER ---

half4 frag(Varyings IN, bool isFrontFace : SV_IsFrontFace) : SV_Target
{
    float faceSign = isFrontFace ? 1.0 : -1.0;

    InputData inputData = (InputData)0;
    inputData.positionWS = IN.positionWS;
    inputData.normalWS = normalize(IN.normalWS) * faceSign;
    inputData.viewDirectionWS = normalize(IN.viewDirWS);
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);

    SurfaceData surfaceData = (SurfaceData)0;
    surfaceData.albedo = _BaseColor.rgb;
    surfaceData.metallic = _Metallic;
    surfaceData.smoothness = _Smoothness;
    surfaceData.alpha = 1.0;

    half4 lightingColor = UniversalFragmentPBR(inputData, surfaceData);

    // --- REFRACTION & FOG LOGIC ---
    float2 screenUV = IN.screenPos.xy / IN.screenPos.w;
    float iorRatio = isFrontFace ? 1.0 : 1.33; 
    float2 distortion = inputData.normalWS.xz * _RefractionStrength * faceSign * iorRatio;
    half3 refractionColor = SampleSceneColor(screenUV + distortion);

    float debugFresnel = 0;
    float debugFogFactor = 0;
    float debugTravelDist = 0;

    if (isFrontFace) 
    {
        float rawDepth = SampleSceneDepth(screenUV + distortion);
        float3 backgroundPos = ReconstructWorldPosition(screenUV + distortion, rawDepth);
        float travelDist = distance(inputData.positionWS, backgroundPos);
        float fogFactor = 1.0 - exp(-travelDist * _FogDensity);
        float verticalDepth = max(0, inputData.positionWS.y - backgroundPos.y);
        half3 depthFogColor = _FogColor.rgb * exp(-verticalDepth * _FogDensity * 0.5);
        refractionColor = lerp(refractionColor, depthFogColor, fogFactor);
        
        debugFogFactor = fogFactor;
        debugTravelDist = travelDist;
    }

    // --- SSS LOGIC ---
    Light mainLight = GetMainLight(inputData.shadowCoord);
    float3 distortedLightDir = normalize(mainLight.direction + (inputData.normalWS * _SSSDistortion));
    float transDot = saturate(dot(inputData.viewDirectionWS, -distortedLightDir));
    float sunSpot = pow(transDot, _SSSPower) * _SSSStrength;
    float waveHeightMask = saturate((inputData.positionWS.y + 1.0) * 0.5); 
    half3 translucency = mainLight.color * _SSSColor.rgb * (sunSpot * (0.5 + 0.5 * waveHeightMask)) * mainLight.shadowAttenuation;

    // --- COMPOSITE ---
    half3 finalColor = refractionColor;

    if (isFrontFace)
    {
        finalColor = lerp(refractionColor, lightingColor.rgb, _Alpha);
    }
    else
    {
        float NdotV = dot(inputData.normalWS, inputData.viewDirectionWS);
        float fresnel = pow(1.0 - saturate(NdotV), 4.0);
        debugFresnel = fresnel;
        finalColor = lerp(refractionColor, lightingColor.rgb, fresnel * 0.5) + translucency;
    }

    // --- DEBUG ---
    if (_DebugMode == 1) return half4(inputData.normalWS * 0.5 + 0.5, 1.0);
    if (_DebugMode == 2) {
        float depthVis = (!isFrontFace) ? debugTravelDist / 20.0 : IN.positionCS.w / 20.0;
        return half4(depthVis, depthVis, depthVis, 1.0);
    }
    if (_DebugMode == 3) return half4(debugFogFactor, debugFogFactor, debugFogFactor, 1.0);
    if (_DebugMode == 4) return half4(refractionColor, 1.0);
    if (_DebugMode == 5) return half4(debugFresnel, debugFresnel, debugFresnel, 1.0);

    return half4(finalColor, 1.0);
}

#endif