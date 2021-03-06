﻿Shader "LowpolyPBR"
{
	//surfaceColor = emissive + ambient + diffuse + specular
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Color", Color) = (1, 1, 1, 1)
		_EmissiveTex ("Emissive Map", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "white" {}
		_BumpScale ("Normal Scale", float) = 1
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Shininess ("Shininess", float) = 1

		_RimColor ("RimColor", Color) = (1, 1, 1, 1)
		_RimPower ("RimPower", float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
		    Tags { "LightMode"="ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			#pragma multi_compile __ MatrixTangentSpace
			//emissive + ambient + diffuse + specular
			#pragma multi_compile __ ENABLE_EMISSIVE ENABLE_AMBIENT ENABLE_DIFFUSE ENABLE_SPECULAR
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 color : Color;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				#if MatrixTangentSpace
					float4 TtoW0:TEXCOORD2;
					float4 TtoW1:TEXCOORD3;
					float4 TtoW2:TEXCOORD4;
				#else
					float3 normal : NORMAL;
					float4 tangent : TANGENT;
					float3 worldPos : TEXCOORD2;
				#endif

				float4 color : Color;
			};

			float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) {
				return cross(normal, tangent.xyz) * (binormalSign * unity_WorldTransformParams.w);
			}

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float4 _Color;

			sampler2D _EmissiveTex;
			float4 _EmissiveTex_ST;

			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;

			float4 _Specular;
			float _Shininess;

			fixed4 _RimColor;
			float _RimPower;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw = v.uv.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				fixed3 normal = UnityObjectToWorldNormal(v.normal);	
				fixed3 worldPos = mul(unity_ObjectToWorld, v.vertex);

				#if MatrixTangentSpace
					fixed3 tangent = UnityObjectToWorldDir(v.tangent.xyz);
					float3 binormal = CreateBinormal(normal, tangent, v.tangent.w);
					o.TtoW0 = float4(tangent.x, binormal.x, normal.x, worldPos.x);
					o.TtoW1 = float4(tangent.y, binormal.y, normal.y, worldPos.y);
					o.TtoW2 = float4(tangent.z, binormal.z, normal.z, worldPos.z);
				#else
					o.normal = normal;
					float4 tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
					o.tangent = tangent;		
					o.worldPos = worldPos;
				#endif
				
				o.color = v.color;

				UNITY_TRANSFER_FOG(o, o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{				
				float3 tangentSpaceNormal = UnpackNormal(tex2D(_BumpMap, i.uv.zw));//UnpackScaleNormal 
				tangentSpaceNormal.xy *= _BumpScale;
				tangentSpaceNormal.z = sqrt(1.0 - saturate(dot(tangentSpaceNormal.xy, tangentSpaceNormal.xy)));
				#if MatrixTangentSpace
					fixed3 normal = normalize(half3(dot(i.TtoW0.xyz, tangentSpaceNormal), dot(i.TtoW1.xyz, tangentSpaceNormal), dot(i.TtoW2.xyz, tangentSpaceNormal)));
					fixed3 worldPos = fixed3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				#else
					float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
					fixed3 normal = normalize(tangentSpaceNormal.x * i.tangent + tangentSpaceNormal.y * binormal + tangentSpaceNormal.z * i.normal);
					fixed3 worldPos = i.worldPos;
				#endif

				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				float3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float3 halfDir = normalize(lightDir + viewDir); 

				// sample the texture
				fixed4 albedo = tex2D(_MainTex, i.uv.xy);
				albedo = lerp(albedo, _Color * albedo, i.color.a);
				//emissive = Ke
				//fixed3 emissive = tex2D(_EmissiveTex, i.uv);
				half rim = 1.0 - saturate(dot (normalize(viewDir), normal));
				fixed3 emissive = _RimColor.rgb * pow (rim, _RimPower);
				//ambient = Ka x globalAmbient
				fixed3 ambient = albedo.xyz * UNITY_LIGHTMODEL_AMBIENT.xyz;
				//diffuse = Kd x lightColor x max(N · L, 0)
				fixed3 diffuse = albedo.xyz * _LightColor0.rgb * max(0, dot(normal, lightDir));
				//specular = Ks x lightColor x facing x (max(N · H, 0)) shininess
				fixed3 specular = _Specular * _LightColor0.rgb * pow(max(dot(normal, halfDir), 0), _Shininess * 128) * albedo.a;
				//fixed3 specular = halfDir * 0.5 + 0.5;
				// apply fog
	

				#if ENABLE_EMISSIVE
					return fixed4(emissive, 1.0); 
				#elif ENABLE_AMBIENT
					return fixed4(ambient, 1.0);
				#elif ENABLE_DIFFUSE
					return fixed4(diffuse, 1.0);
				#elif ENABLE_SPECULAR
					return fixed4(specular, 1.0);
				#endif

				fixed4 color = fixed4(emissive + ambient + diffuse + specular, 1.0)
				UNITY_APPLY_FOG(i.fogCoord, color);
				return color;
			}
			ENDCG
		}
	}
}
