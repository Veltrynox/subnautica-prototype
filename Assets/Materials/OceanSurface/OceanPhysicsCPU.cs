using UnityEngine;

public static class OceanPhysicsCPU
{
    public struct WaveParam
    {
        public float amplitude;
        public float wavelength;
        public float speed;
        public Vector2 direction;
    }

    public static Vector3 GetWaveHeight(Vector3 position, float time, WaveParam[] waves)
    {
        Vector3 finalPos = position;

        foreach (var w in waves)
        {
            finalPos += GetSingleWave(position, time, w);
        }

        return finalPos;
    }

    private static Vector3 GetSingleWave(Vector3 p, float time, WaveParam w)
    {
        Vector2 d = w.direction.normalized;
        float wavelength = w.wavelength < 0.001f ? 1.0f : w.wavelength;

        float k = 2 * Mathf.PI / wavelength;
        float c = Mathf.Sqrt(9.8f / k) * w.speed;
        float f = k * (Vector2.Dot(d, new Vector2(p.x, p.z)) - c * time);

        float s = Mathf.Sin(f);
        float cn = Mathf.Cos(f);

        // Calculate offsets (Gerstner Wave)
        float wa = k * w.amplitude;

        // This matches your HLSL: float3 deltaPos = float3(d.x * (a * cn), a * s, d.y * (a * cn));
        return new Vector3(
            d.x * (w.amplitude * cn),
            w.amplitude * s,
            d.y * (w.amplitude * cn)
        );
    }
}