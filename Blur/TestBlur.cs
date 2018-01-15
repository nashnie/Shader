using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestBlur : MonoBehaviour 
{
	private Blur blur;

	void Start () 
	{
		blur = gameObject.AddComponent<Blur> ();
	}


	void OnRenderImage(RenderTexture source, RenderTexture destination)  
	{  
		blur.BlurImage (source, destination);
	}  
}
