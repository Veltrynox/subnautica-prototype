#ifndef OCEAN_TESS_INCLUDED
#define OCEAN_TESS_INCLUDED

// Depends on OCEAN_GLOBALS and OCEAN_PHYSICS

float CalcDistanceTessFactor(float4 p0, float4 p1, float minDist, float maxDist, float tess)
{
    float3 wPos0 = TransformObjectToWorld(p0.xyz);
    float3 wPos1 = TransformObjectToWorld(p1.xyz);
    float3 edgeCenter = (wPos0 + wPos1) * 0.5;
    float dist = distance(edgeCenter, _WorldSpaceCameraPos);
    float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0);
    return f * tess;
}

ControlPoint vert(Attributes IN)
{
    ControlPoint OUT;
    OUT.positionOS = IN.positionOS;
    OUT.normalOS = IN.normalOS;
    OUT.uv = IN.uv;
    return OUT;
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
    float3 posOS = patch[0].positionOS.xyz * bary.x + patch[1].positionOS.xyz * bary.y + patch[2].positionOS.xyz * bary.z;
    float2 uv = patch[0].uv * bary.x + patch[1].uv * bary.y + patch[2].uv * bary.z;

    float3 worldPos = TransformObjectToWorld(posOS);
    WaveResult wave = GetWave(worldPos, _Time.y); // Calls OceanPhysics
    
    OUT.positionWS = wave.positionOffset;
    OUT.positionCS = TransformWorldToHClip(OUT.positionWS);
    OUT.normalWS = wave.normal;
    OUT.uv = uv;
    OUT.viewDirWS = GetWorldSpaceViewDir(OUT.positionWS);
    OUT.screenPos = ComputeScreenPos(OUT.positionCS);
    return OUT;
}
#endif