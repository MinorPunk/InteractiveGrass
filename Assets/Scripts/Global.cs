using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Global : MonoBehaviour
{
    [SerializeField] private VelocityMapGenerator _VelocityMapGenerator;
    [SerializeField] private Material _GrassMaterial;

    private void Start()
    {
        _GrassMaterial.SetTexture("_VelocityMap", _VelocityMapGenerator.VelocityTexture);
    }
}
