using UnityEngine;

/// <summary>
/// This script is responsible for managing and passing wave data to an ocean shader.
/// </summary>
[ExecuteAlways]
public class OceanWaveData : MonoBehaviour
{
    public Material oceanMaterial;
    [Range(1, 8)]
    public int waveCount = 4;

    // Wave data
    public float[] waveAmplitudes = new float[8];
    public float[] waveLengths = new float[8];
    public float[] waveSpeeds = new float[8];
    public Vector4[] waveDirections = new Vector4[8];

    // Internal arrays to send to shader
    private Vector4[] _packedWaveData = new Vector4[8];
    private Vector4[] _packedDirections = new Vector4[8];


    void OnValidate()
    {
        // Resize arrays if they are wrong length to prevent index errors
        if (waveAmplitudes.Length != 8) System.Array.Resize(ref waveAmplitudes, 8);
        if (waveLengths.Length != 8) System.Array.Resize(ref waveLengths, 8);
        if (waveSpeeds.Length != 8) System.Array.Resize(ref waveSpeeds, 8);
        if (waveDirections.Length != 8) System.Array.Resize(ref waveDirections, 8);
    }

    void Update()
    {
        if (oceanMaterial == null) return;

        // Reset packed data
        for (int i = 0; i < 8; i++)
        {
            _packedWaveData[i] = new Vector4(
                waveAmplitudes[i],
                waveLengths[i],
                waveSpeeds[i],
                0
            );

            // Ensure direction is safe (avoid 0,0,0)
            Vector4 dir = waveDirections[i];
            if (dir.sqrMagnitude < 0.001f) dir = new Vector4(1, 0, 0, 0);
            _packedDirections[i] = dir;
        }

        oceanMaterial.SetInt("_WaveCount", waveCount);
        oceanMaterial.SetVectorArray("_WaveData", _packedWaveData);
        oceanMaterial.SetVectorArray("_WaveDirections", _packedDirections);
    }
}