using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestLowpoly : MonoBehaviour {

    public bool isEndableMatrixTangentSpace = false;

    //ENABLE_EMISSIVE ENABLE_AMBIENT ENABLE_DIFFUSE ENABLE_SPECULAR
    public bool isEndableEmissive = false;
    public bool isEndableAmbient = false;
    public bool isEndableDiffuse = false;
    public bool isEndableSpecular = false;

    private MeshRenderer meshRender;
	// Use this for initialization
	void Start () {
        meshRender = gameObject.GetComponentInChildren<MeshRenderer>();
    }
	
	// Update is called once per frame
	void Update () {
		if (isEndableMatrixTangentSpace)
        {
            meshRender.material.EnableKeyword("MatrixTangentSpace");
        }
        else
        {
            meshRender.material.DisableKeyword("MatrixTangentSpace");
        }

        if (isEndableEmissive)
        {
            meshRender.material.EnableKeyword("ENABLE_EMISSIVE");
            meshRender.material.DisableKeyword("ENABLE_AMBIENT");
            meshRender.material.DisableKeyword("ENABLE_DIFFUSE");
            meshRender.material.DisableKeyword("ENABLE_SPECULAR");
        }
        else if (isEndableAmbient)
        {
            meshRender.material.DisableKeyword("ENABLE_EMISSIVE");
            meshRender.material.EnableKeyword("ENABLE_AMBIENT");
            meshRender.material.DisableKeyword("ENABLE_DIFFUSE");
            meshRender.material.DisableKeyword("ENABLE_SPECULAR");
        }
        else if (isEndableDiffuse)
        {
            meshRender.material.DisableKeyword("ENABLE_EMISSIVE");
            meshRender.material.DisableKeyword("ENABLE_AMBIENT");
            meshRender.material.EnableKeyword("ENABLE_DIFFUSE");
            meshRender.material.DisableKeyword("ENABLE_SPECULAR");
        }
        else if (isEndableSpecular)
        {
            meshRender.material.DisableKeyword("ENABLE_EMISSIVE");
            meshRender.material.DisableKeyword("ENABLE_AMBIENT");
            meshRender.material.DisableKeyword("ENABLE_DIFFUSE");
            meshRender.material.EnableKeyword("ENABLE_SPECULAR");
        }
        else
        {
            meshRender.material.DisableKeyword("ENABLE_EMISSIVE");
            meshRender.material.DisableKeyword("ENABLE_AMBIENT");
            meshRender.material.DisableKeyword("ENABLE_DIFFUSE");
            meshRender.material.DisableKeyword("ENABLE_SPECULAR");
        }
	}
}
