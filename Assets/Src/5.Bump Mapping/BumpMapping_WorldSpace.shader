Shader "LJ/BumpMapping(world space)(an error now,fix later)"
{
    Properties
    {
        [MainTexture]_MainTex ("Main Texture", 2D) = "white"{}
        _BumpTex ("Bump Texture", 2D) = "bump"{}
        _BumpScale ("Bump Scale", Float) = 1.0
        _Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
            #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct a2v{
                 float4 vertex:POSITION;
                 float3 normal:NORMAL;
                 float4 tangent:TANGENT;
                 float4 texcoord:TEXCOORD0;
            };
            
            struct v2f{
                 float4 position:SV_POSITION;
                 float4 uv:TEXCOORD0;
                 float4 TtoW0 : TEXCOORD1;  
				 float4 TtoW1 : TEXCOORD2;  
				 float4 TtoW2 : TEXCOORD3; 
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_BumpTex);
            SAMPLER(sampler_BumpTex);
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _BumpTex_ST;
            float _BumpScale;
            float4 _Color;
			float4 _Specular;
			float _Gloss;
            CBUFFER_END
            
            v2f vert(a2v input){
                 v2f output;
                 output.position = TransformObjectToHClip(input.vertex.xyz);
                 output.uv.xy = TRANSFORM_TEX(input.texcoord, _MainTex);
                 output.uv.zw = TRANSFORM_TEX(input.texcoord, _BumpTex);

                 VertexPositionInputs positionInputs = GetVertexPositionInputs(input.vertex.xyz);
                 float3 worldPos = positionInputs.positionCS;
                 float3 worldNormal = TransformObjectToWorldNormal(input.normal);
                 float3 worldTangent = TransformObjectToWorld(input.tangent.xyz);
                 float3 worldBinormal = cross(normalize(worldNormal),normalize(worldTangent))*input.tangent.w;

                 output.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				 output.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				 output.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                 return output;
            }
            
            half4 frag(v2f input):SV_Target{
                 float3 worldPos = float3(input.TtoW0.w, input.TtoW1.w, input.TtoW2.w);

				 float3 lightDir = normalize( _MainLightPosition.xyz);
				 float3 viewDir = normalize(GetWorldSpaceViewDir(worldPos));

                 float4 packedNormal = SAMPLE_TEXTURE2D(_BumpTex, sampler_BumpTex, input.uv.zw);
                 float3 tangentNormal = UnpackNormal(packedNormal);

                 tangentNormal.xy *= _BumpScale;
				 tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                 tangentNormal = normalize(half3(dot(input.TtoW0.xyz, tangentNormal),
                    dot(input.TtoW1.xyz, tangentNormal), dot(input.TtoW2.xyz, tangentNormal)));

                 half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv.xy).rgb * _Color.rgb;
				 
				 half3 ambient = unity_AmbientSky * albedo;
				 
				 half3 diffuse = _MainLightColor.rgb * albedo * max(0, dot(tangentNormal, lightDir));
                 
				 half3 halfDir = normalize(lightDir + viewDir);
				 half3 specular = _MainLightColor.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);
				 
				 return half4(ambient + diffuse + specular, 1.0);
            }
            
            ENDHLSL
        }
    }
}