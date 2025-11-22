Shader "Custom/OceanShader"
{
    Properties
    {
        [Header(Material)]
        _BaseColor("Base Color", Color) = (0.2,0.5,0.8,1)
        _Metallic("Metallic", Range(0,1)) = 0.0
        _Smoothness("Smoothness", Range(0,1)) = 0.5

        [Header(Waves)]
        _WaveAmplitude("Amplitude", float) = 0.5
        _WaveLength("Wavelength", float) = 5.0
        _WaveSpeed("Speed", float) = 1.0
        _WaveDirection("Direction", Vector) = (1,0,0,0)

        [Header(Tessellation)]
        _Tess("Tessellation Factor", Range(1, 64)) = 16
        _MinDist("Min Distance", Float) = 10.0
        _MaxDist("Max Distance", Float) = 50.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 300

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma hull hull
            #pragma domain domain
            #pragma fragment frag
            
            #pragma target 5.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct ControlPoint
            {
                float4 positionOS : INTERNALTESSPOS;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct TessellationFactors
            {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS : NORMAL;
                float2 uv : TEXCOORD0;
                float3 viewDirWS : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float _Metallic;
                float _Smoothness;

                float _WaveAmplitude;
                float _WaveLength;
                float _WaveSpeed;
                float4 _WaveDirection;
                
                float _Tess;
                float _MinDist;
                float _MaxDist;
            CBUFFER_END

            // ---------------------------------------------------------
            // WAVE LOGIC
            // ---------------------------------------------------------
            
            struct WaveResult {
                float3 position;
                float3 normal;
            };

            WaveResult GetWave(float3 p, float time)
            {
                float2 d = normalize(_WaveDirection.xy);
                
                // Wave settings
                float k = 2 * PI / _WaveLength;
                float c = sqrt(9.8 / k) * _WaveSpeed; 
                float f = k * (dot(d, p.xz) - c * time);
                float a = _WaveAmplitude;
                
                float s = sin(f);
                float cn = cos(f);

                // Calculate Position
                float3 pos = p;
                pos.x += d.x * (a * cn);
                pos.z += d.y * (a * cn);
                pos.y += a * s;

                // Calculate Normals
                float wa = k * a;
                
                float3 tangent = float3(1, 0, 0);
                float3 binormal = float3(0, 0, 1);

                tangent.x -= d.x * d.x * (wa * s);
                tangent.y += d.x * (wa * cn);
                tangent.z -= d.x * d.y * (wa * s);

                binormal.x -= d.x * d.y * (wa * s);
                binormal.y += d.y * (wa * cn);
                binormal.z -= d.y * d.y * (wa * s);

                float3 n = normalize(cross(binormal, tangent));

                WaveResult result;
                result.position = pos;
                result.normal = n;
                return result;
            }

            // ---------------------------------------------------------
            // STAGES
            // ---------------------------------------------------------

            ControlPoint vert(Attributes IN)
            {
                ControlPoint OUT;
                OUT.positionOS = IN.positionOS;
                OUT.normalOS = IN.normalOS;
                OUT.uv = IN.uv;
                return OUT;
            }

            float CalcDistanceTessFactor(float4 p0, float4 p1, float minDist, float maxDist, float tess)
            {
                float3 wPos0 = TransformObjectToWorld(p0.xyz);
                float3 wPos1 = TransformObjectToWorld(p1.xyz);
                float3 edgeCenter = (wPos0 + wPos1) * 0.5;
                float dist = distance(edgeCenter, _WorldSpaceCameraPos);
                float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0);
                return f * tess;
            }

            TessellationFactors PatchConstantFunction(InputPatch<ControlPoint, 3> patch)
            {
                TessellationFactors f;
                f.edge[0] = CalcDistanceTessFactor(patch[1].positionOS, patch[2].positionOS, _MinDist, _MaxDist, _Tess);
                f.edge[1] = CalcDistanceTessFactor(patch[2].positionOS, patch[0].positionOS, _MinDist, _MaxDist, _Tess);
                f.edge[2] = CalcDistanceTessFactor(patch[0].positionOS, patch[1].positionOS, _MinDist, _MaxDist, _Tess);
                f.inside = (f.edge[0] + f.edge[1] + f.edge[2]) / 3.0;
                return f;
            }

            [domain("tri")]
            [outputcontrolpoints(3)]
            [outputtopology("triangle_cw")]
            [partitioning("fractional_odd")]
            [patchconstantfunc("PatchConstantFunction")]
            ControlPoint hull(InputPatch<ControlPoint, 3> patch, uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }

            [domain("tri")]
            Varyings domain(TessellationFactors factors, OutputPatch<ControlPoint, 3> patch, float3 bary : SV_DomainLocation)
            {
                Varyings OUT;
                
                // Interpolate initial position
                float3 posOS = patch[0].positionOS.xyz * bary.x + patch[1].positionOS.xyz * bary.y + patch[2].positionOS.xyz * bary.z;
                float2 uv = patch[0].uv * bary.x + patch[1].uv * bary.y + patch[2].uv * bary.z;

                // To World
                float3 worldPos = TransformObjectToWorld(posOS);

                // APPLY WAVE & RECALC NORMAL
                WaveResult wave = GetWave(worldPos, _Time.y);
                worldPos = wave.position;
                
                // Output
                OUT.positionCS = TransformWorldToHClip(worldPos);
                OUT.normalWS = wave.normal;
                OUT.uv = uv;
                OUT.viewDirWS = GetWorldSpaceViewDir(worldPos);

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Standard URP Lighting Setup
                InputData inputData = (InputData)0;
                inputData.positionWS = IN.positionCS.xyz;
                
                inputData.normalWS = normalize(IN.normalWS);
                inputData.viewDirectionWS = normalize(IN.viewDirWS);
                
                // Surface Data
                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = _BaseColor.rgb;
                surfaceData.metallic = _Metallic;
                surfaceData.smoothness = _Smoothness;
                surfaceData.alpha = 1.0;

                // Calculate Lighting
                half4 color = UniversalFragmentPBR(inputData, surfaceData);
                return color;
            }

            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}