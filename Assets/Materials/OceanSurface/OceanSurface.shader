Shader "Custom/OceanShader"
{
    Properties
    {
        [Header(Material)]
        _BaseColor("Base Color", Color) = (0.2,0.5,0.8,1)
        _Metallic("Metallic", Range(0,1)) = 0.0
        _Smoothness("Smoothness", Range(0,1)) = 0.9
        
        [Header(Transparency)]
        _Alpha("Water Opacity", Range(0, 1)) = 0.7
        _RefractionStrength("Refraction Strength", Range(0, 0.2)) = 0.05

        [Header(Underwater Lighting)]
        _SSSColor("Subsurface Color", Color) = (0.1, 0.4, 0.4, 1)
        _SSSStrength("Translucency Strength", Range(0, 10)) = 1.0
        _SSSPower("Sun Spot Focus", Range(1, 100)) = 40.0
        _SSSDistortion("Wave Lens Distortion", Range(0.1, 2.0)) = 0.5

        [Header(Fog)]
        _FogColor("Fog Color", Color) = (0.2, 0.2, 0.2, 1)
        _FogDensity("Fog Density", Range(0, 1)) = 0.03

        [Header(Tessellation)]
        _Tess("Tessellation Factor", Range(1, 64)) = 16
        _MinDist("Min Distance", Float) = 10.0
        _MaxDist("Max Distance", Float) = 50.0

        [Header(Wave Count)]
        [IntRange] _WaveCount ("Number of Waves", Range(1, 8)) = 4

        [Enum(None, 0, Normal World, 1, Linear Depth, 2, Fog Mask, 3, Refraction Only, 4, Fresnel, 5)] 
        _DebugMode("Debug View", Float) = 0
    }

    SubShader
    {
        // Change Queue to Transparent
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline" = "UniversalPipeline" }
        LOD 300

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }
            
            // Transparency blending states
            ZWrite On
            Blend SrcAlpha OneMinusSrcAlpha Cull Off

            HLSLPROGRAM
            #pragma target 5.0
            
            #pragma vertex vert
            #pragma hull hull
            #pragma domain domain
            #pragma fragment frag
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            
            #include "OceanLogic.hlsl"
            
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}