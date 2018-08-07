using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TerrainTexture2DArray : MonoBehaviour {

    public Texture2D[] textures;
    public Material terrainMaterial;
    private int textureWidth = 512;
    private int textureHeight = 512;

	// Use this for initialization
	void Start () {
        Texture2DArray textureArray = new Texture2DArray(textureWidth, textureHeight, textures.Length, TextureFormat.RGBA32, false);
        for (int i = 0; i < textures.Length; i++)
        {
            //Graphics.CopyTexture(textures[i], 0, 0, textureArray, i, 0);
            textureArray.SetPixels(textures[i].GetPixels(0), i, 0);
        }
        //terrainMaterial.SetTexture("_Textures", textureArray);

        Terrain terrain = gameObject.GetComponent<Terrain>();
        terrain.materialTemplate.SetTexture("_Textures", textureArray);
    }
}
