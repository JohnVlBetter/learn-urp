Shader "LJ/AlphaTest"
{
    Properties
    {
        [MainTexture]_MainTex ("Main Texture", 2D) = "white"{}
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _Cutoff("Alpha Cutoff",float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout" "RenderPipeline" = "UniversalPipeline" }

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
                 float4 positionOS:POSITION;
                 float3 normalOS:NORMAL;
                 float4 texcoord:TEXCOORD0;
            };
            
            struct v2f{
                 float4 positionCS:SV_POSITION;
                 float2 uv:TEXCOORD0;
                 float3 positionWS: TEXCOORD1;
				 float3 normalWS : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _Color;
			float _Cutoff;
            CBUFFER_END
            
            v2f vert(a2v input){
                 v2f output;
                 VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
				 output.positionCS = positionInputs.positionCS;
                 
				 output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
                 
				 output.positionWS = positionInputs.positionWS;
                 
				 VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS.xyz);
				 output.normalWS = normalInputs.normalWS;

                 return output;
            }
            
            half4 frag(v2f input):SV_Target{
                 half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                 
				 float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS.xyz);
				 Light light = GetMainLight(shadowCoord);

				 float3 worldLightDir = normalize(light.direction);
                 float3 worldNormal = normalize(input.normalWS);

                 clip (texColor.a - _Cutoff);
                 
				 float3 albedo = texColor.rgb * _Color.rgb;
				
				 float3 ambient = unity_AmbientSky * albedo;
				 
				 float3 diffuse = _MainLightColor.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
				 
				 return float4(ambient + diffuse, 1.0);
            }
            
            ENDHLSL
        }
    }
}