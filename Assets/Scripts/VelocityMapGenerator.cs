using System.Collections.Generic;
using UnityEngine;
using System;
using System.Runtime.InteropServices;

public class VelocityMapGenerator : MonoBehaviour
{
    [Serializable]
    private struct Creature
    {
        public Vector3 Pos;
        public float Radius;
    }

    private static class Kernels
    {
        public const int CSMain = 0;
    }

    [SerializeField] private ComputeShader _Shader;
    [SerializeField] private List<Creature> _CreatureSources;
    [SerializeField] private List<Transform> _DebugPlayer;
    [SerializeField] private float _DissipateSpeed;
    [SerializeField] private float _RTPixelSize;
    [SerializeField] private float _InteractPower;
    [SerializeField] private int _RTResolution;
    [SerializeField] private UnityEngine.Material _DebugMaterial;
    [SerializeField] private List<UnityEngine.Material> AssignToMaterials;
    private ComputeBuffer _CreatureSourcesBuffer;
    [HideInInspector] public RenderTexture VelocityTexture;

    private int _ThreadCount;

    private void Awake()
    {
        _ThreadCount = (_RTResolution + 7) / 8;
        VelocityTexture = new RenderTexture(_RTResolution, _RTResolution, 0, RenderTextureFormat.ARGBFloat);
        VelocityTexture.enableRandomWrite = true;
        VelocityTexture.Create();
    }

    private void Start()
    {
        _Shader.SetFloat("DissipateSpeed", _DissipateSpeed);
        _Shader.SetFloat("RTPixelSize", _RTPixelSize);
        _Shader.SetFloat("InteractPower", _InteractPower);

        _CreatureSourcesBuffer = new ComputeBuffer(1, Marshal.SizeOf(typeof(Creature)));
        _Shader.SetBuffer(Kernels.CSMain, "CreatureSources", _CreatureSourcesBuffer);

        _DebugMaterial.mainTexture = VelocityTexture;

        for (int i = 0; i < AssignToMaterials.Count; i++)
        {
            AssignToMaterials[i].SetTexture("VelocityTexture", VelocityTexture);
        }
    }

    private void Update()
    {
        _CreatureSources.Clear();
        for (int i = 0; i < _DebugPlayer.Count; i++)
        {
            _CreatureSources.Add(new Creature()
            {
                Pos = _DebugPlayer[i].transform.position,
                Radius = 0.5f
            });
        }

        _Shader.SetFloat("DissipateSpeed", _DissipateSpeed);
        _Shader.SetFloat("RTPixelSize", _RTPixelSize);
        _Shader.SetFloat("InteractPower", _InteractPower);

        _CreatureSourcesBuffer.SetData(_CreatureSources);
        /*
        _Shader.SetTexture(Kernels.Dissipate, "VelocityTexture", VelocityTexture);
        _Shader.Dispatch(Kernels.Dissipate, _ThreadCount, _ThreadCount, 1);
        */

        _Shader.SetTexture(Kernels.CSMain, "VelocityTexture", VelocityTexture);
        _Shader.SetTexture(Kernels.CSMain, "VelocityTextureSwap", VelocityTexture);
        _Shader.Dispatch(Kernels.CSMain, _ThreadCount, _ThreadCount, 1);
    }

    private void OnDisable()
    {
        _CreatureSourcesBuffer.Release();
        _CreatureSourcesBuffer.Dispose();
    }
}
