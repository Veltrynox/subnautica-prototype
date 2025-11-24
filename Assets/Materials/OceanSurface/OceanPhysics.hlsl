#ifndef OCEAN_PHYSICS_INCLUDED
#define OCEAN_PHYSICS_INCLUDED

// Depends on OCEAN_GLOBALS_INCLUDED

WaveResult GetSingleWave(float3 p, float time, float a, float wavelength, float2 direction, float speed)
{
    float2 d = normalize(direction);
    if (wavelength < 0.001) wavelength = 1.0;

    float k = 2 * PI / wavelength;
    float c = sqrt(9.8 / k) * speed;
    float f = k * (dot(d, p.xz) - c * time);
    
    float s = sin(f);
    float cn = cos(f);

    float3 deltaPos = float3(d.x * (a * cn), a * s, d.y * (a * cn));

    float wa = k * a;
    float3 tangent = float3(1 - d.x * d.x * (wa * s), d.x * (wa * cn), -d.x * d.y * (wa * s));
    float3 binormal = float3(-d.x * d.y * (wa * s), d.y * (wa * cn), 1 - d.y * d.y * (wa * s));

    WaveResult result;
    result.positionOffset = deltaPos;
    result.normal = normalize(cross(binormal, tangent));
    return result;
}

WaveResult GetWave(float3 p, float time)
{
    float3 finalPos = p;
    float3 summedNormals = float3(0, 0, 0);
    int count = clamp(_WaveCount, 0, 8);

    [unroll]
    for (int i = 0; i < count; ++i)
    {
        WaveResult w = GetSingleWave(p, time, _WaveData[i].x, _WaveData[i].y, _WaveDirections[i].xy, _WaveData[i].z);
        finalPos += w.positionOffset;
        summedNormals += w.normal;
    }
    
    WaveResult result;
    result.positionOffset = finalPos;
    if (length(summedNormals) < 0.001) summedNormals = float3(0,1,0);
    result.normal = normalize(summedNormals);
    return result;
}
#endif