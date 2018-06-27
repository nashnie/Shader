Shader "LowpolyPBR"
{
	//surfaceColor = emissive + ambient + diffuse + specular
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_EmissiveTex ("Emissive Map", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "white" {}
		_BumpScale("Normal Scale", float) = 1
		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Shininess("Shininess", float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			#pragma multi_compile __ MatrixTangentSpace
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float4 tangent : TEXCOORD2;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				#if MatrixTangentSpace
					float4 TtoW0:TEXCOORD1;
					float4 TtoW1:TEXCOORD2;
					float4 TtoW2:TEXCOORD3;
				#else
					float3 normal : NORMAL;
					float4 tangent : TANGENT;
					float3 worldPos : TEXCOORD1;
				#endif
			};

			float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) {
				return cross(normal, tangent.xyz) * (binormalSign * unity_WorldTransformParams.w);
			}

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _EmissiveTex;
			float4 _EmissiveTex_ST;

			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;

			float4 _Specular;
			float _Shininess;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw = o.uv.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				fixed3 normal = UnityObjectToWorldNormal(v.normal);	
				fixed3 worldPos = mul(unity_ObjectToWorld, v.vertex);

				#if MatrixTangentSpace
					fixed3 tangent = UnityObjectToWorldDir(v.tangent.xyz);
					float3 binormal = CreateBinormal(normal, v.tangent.xyz, v.tangent.w);
					o.TtoW0 = float4(tangent.x, binormal.x, normal.x, worldPos.x);
					o.TtoW1 = float4(tangent.y, binormal.y, normal.y, worldPos.y);
					o.TtoW2 = float4(tangent.z, binormal.z, normal.z, worldPos.z);
				#else
					o.normal = normal;
					float4 tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
					o.tangent = tangent;		
				#endif
				o.worldPos = worldPos;
				UNITY_TRANSFER_FOG(o, o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

				float3 tangentSpaceNormal = UnpackNormal(tex2D(_BumpMap, i.uv.zw));//UnpackScaleNormal 
				tangentSpaceNormal.xy *= _BumpScale;
				tangentSpaceNormal.z = sqrt(1.0 - saturate(dot(tangentSpaceNormal.xy, tangentSpaceNormal.xy)));
				#if MatrixTangentSpace
					i.normal = normalize(half3(dot(i.TtoW0.xyz, normal), dot(i.TtoW1.xyz, normal), dot(i.TtoW2.xyz, normal)));
				#else
					float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
					i.normal = normalize(tangentSpaceNormal.x * i.tangent + tangentSpaceNormal.y * binormal + tangentSpaceNormal.z * i.normal);
				#endif

				float3 halfDir = normalize(lightDir + viewDir); 

				// sample the texture
				fixed4 albedo = tex2D(_MainTex, i.uv.xy);
				//emissive = Ke
				//fixed3 emissive = tex2D(_EmissiveTex, i.uv);
				fixed3 emissive = (0, 0, 0, 0);
				//ambient = Ka x globalAmbient
				fixed3 ambient = albedo.xyz * UNITY_LIGHTMODEL_AMBIENT.xyz;
				//diffuse = Kd x lightColor x max(N · L, 0)
				fixed3 diffuse = albedo.xyz * _LightColor0.rgb * max(0, dot(i.normal, lightDir));
				//specular = Ks x lightColor x facing x (max(N · H, 0)) shininess
				fixed3 specular = _Specular * _LightColor0.rgb * pow(max(dot(i.normal, halfDir), 0), _Shininess * 128) * albedo.a;
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, albedo);
				return fixed4(emissive + ambient + diffuse + specular, 1.0);
			}
			ENDCG
		}
	}
}
