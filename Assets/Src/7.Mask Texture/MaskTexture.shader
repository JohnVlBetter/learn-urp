Shader "LJ/MaskTexture"
{
    Properties
    {
        [MainTexture]_MainTex ("Main Texture", 2D) = "white"{}
        _BumpTex ("Bump Texture", 2D) = "bump"{}
        _BumpScale ("Bump Scale", Float) = 1.0
        _Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _SpecularMask ("Specular Mask", 2D) = "white" {}
		_SpecularScale ("Specular Scale", Float) = 1.0
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
            
            struct a2v{
                 float4 vertex:POSITION;
                 float3 normal:NORMAL;
                 float4 tangent:TANGENT;
                 float4 texcoord:TEXCOORD0;
            };
            
            struct v2f{
                 float4 position:SV_POSITION;
                 float4 uv:TEXCOORD0;
                 float3 lightDir: TEXCOORD1;
				 float3 viewDir : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_BumpTex);
            SAMPLER(sampler_BumpTex);
            TEXTURE2D(_SpecularMask);
            SAMPLER(sampler_SpecularMask);
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _SpecularMask_ST;
            float4 _BumpTex_ST;
            float _BumpScale;
            float _SpecularScale;
            float4 _Color;
			float4 _Specular;
			float _Gloss;
            CBUFFER_END
            
            v2f vert(a2v input){
                 v2f output;
                 VertexPositionInputs positionInputs = GetVertexPositionInputs(input.vertex.xyz);
                 output.position = positionInputs.positionCS;
                 output.uv.xy = TRANSFORM_TEX(input.texcoord, _MainTex);
                 output.uv.zw = TRANSFORM_TEX(input.texcoord, _BumpTex);

                 float3 worldNormal = TransformObjectToWorldNormal(input.normal);
                 float3 worldTangent = TransformObjectToWorld(input.tangent.xyz);
                 float3 worldBinormal = cross(normalize(worldNormal),normalize(worldTangent))*input.tangent.w;

                 float3x3 world2TangentMat = float3x3(worldTangent,worldBinormal,worldNormal);

                 output.lightDir = mul(world2TangentMat, _MainLightPosition.xyz);
                 output.viewDir = mul(world2TangentMat, GetWorldSpaceViewDir(input.vertex));

                 return output;
            }
            
            half4 frag(v2f input):SV_Target{
                 float3 tangentLightDir = normalize(input.lightDir);
				 float3 tangentViewDir = normalize(input.viewDir);

                 float4 packedNormal = SAMPLE_TEXTURE2D(_BumpTex, sampler_BumpTex, input.uv.zw);
                 float3 tangentNormal = UnpackNormal(packedNormal);

                 tangentNormal.xy *= _BumpScale;
				 tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                 half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv.xy).rgb * _Color.rgb;
				 
				 half3 ambient = unity_AmbientSky * albedo;
				 
				 half3 diffuse = _MainLightColor.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));
                 
				 half3 halfDir = normalize(tangentLightDir + tangentViewDir);

                 float specularMask = SAMPLE_TEXTURE2D(_SpecularMask, sampler_SpecularMask, input.uv.xy).r * _SpecularScale;
				 half3 specular = _MainLightColor.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss)*specularMask;
				 
				 return half4(ambient + diffuse + specular, 1.0);
            }
            
            ENDHLSL
        }
    }
}