// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TerrainTexture2DArray" {

	Properties {
		_MainTex ("Splat Map", 2D) = "white" {}
		_Textures("Textures", 2DArray) = ""{}
	}

	SubShader {

		Pass {
			CGPROGRAM

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram
			#pragma target 3.5

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;

			UNITY_DECLARE_TEX2DARRAY(_Textures);

			struct VertexData {
				float4 position : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct Interpolators {
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 uvSplat : TEXCOORD1;
			};

			Interpolators MyVertexProgram (VertexData v) {
				Interpolators i;
				i.position = UnityObjectToClipPos(v.position);
				i.uv = TRANSFORM_TEX(v.uv, _MainTex);
				i.uvSplat = v.uv;
				return i;
			}

			float4 MyFragmentProgram (Interpolators i) : SV_TARGET {
				float4 splat = tex2D(_MainTex, i.uvSplat);

				fixed4 tex1 = UNITY_SAMPLE_TEX2DARRAY(_Textures, float3(i.uvSplat, 0));				
				fixed4 tex2 = UNITY_SAMPLE_TEX2DARRAY(_Textures, float3(i.uvSplat, 1));
				fixed4 tex3 = UNITY_SAMPLE_TEX2DARRAY(_Textures, float3(i.uvSplat, 2));
				fixed4 tex4 = UNITY_SAMPLE_TEX2DARRAY(_Textures, float3(i.uvSplat, 3));

				return tex1 * splat.r + tex2 * splat.g + tex3 * splat.b + tex4 * splat.a;
			}

			ENDCG
		}
	}
}