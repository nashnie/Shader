using System.Collections;  
using System.Collections.Generic;  
using UnityEngine;  
using UnityEngine.Rendering;  

public class RenderAfterPostEffect : MonoBehaviour  
{  
	private CommandBuffer commandBuffer = null;  
	private Renderer targetRenderer = null;  

	public Material replaceMaterial = null;  

	void OnEnable()  
	{  
		targetRenderer = this.GetComponentInChildren<Renderer>();  
		if (targetRenderer)  
		{  
			commandBuffer = new CommandBuffer();  
			commandBuffer.DrawRenderer(targetRenderer, replaceMaterial); 
			Camera.main.AddCommandBuffer(CameraEvent.AfterImageEffects, commandBuffer);  
			targetRenderer.enabled = false;  
		}  
	}  

	void OnDisable()  
	{  
		if (targetRenderer)  
		{  
			Camera.main.RemoveCommandBuffer(CameraEvent.AfterImageEffects, commandBuffer);  
			commandBuffer.Clear();  
			targetRenderer.enabled = true;  
		}  
	}  
}  