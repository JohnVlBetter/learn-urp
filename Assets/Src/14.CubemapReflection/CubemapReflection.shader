Shader "LJ/CubemapReflection"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _Cubemap ("Reflection Cubemap", Cube) = "_Skybox"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        HLSLINCLUDE
        #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
        float4 _BaseColor;
        CBUFFER_END

        TEXTURECUBE(_Cubemap);
        SAMPLER(sampler_Cubemap);

        ENDHLSL

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM

            #pragma shader_feature _AdditionalLights

            #pragma vertex vert
            #pragma fragment frag
            
            #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct a2v{
                 float4 positionOS:POSITION;
                 float3 normalOS:NORMAL;
            };
            
            struct v2f{
                 float4 positionCS:SV_POSITION;
                 float3 positionWS: TEXCOORD1;
				 float3 normalWS : TEXCOORD2;
            };
            
            v2f vert(a2v input){
                 v2f output;
                 VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
				 output.positionCS = positionInputs.positionCS;
				 output.positionWS = positionInputs.positionWS;
                 
				 VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);
				 output.normalWS = normalInputs.normalWS;

                 return output;
            }

            half4 frag(v2f input):SV_Target{
                half3 normalWS = NormalizeNormalPerPixel(input.normalWS);
                half3 viewDirWS = SafeNormalize(_WorldSpaceCameraPos.xyz - input.positionWS);

                Light mainLight = GetMainLight();
                half3 color = _BaseColor * mainLight.color * max(0, dot(mainLight.direction, normalWS)); 
                
                float3 reflectWS = reflect(-viewDirWS, normalWS);
                color += SAMPLE_TEXTURECUBE(_Cubemap,sampler_Cubemap,reflectWS);

                return half4(color , 1.0);

            }
            
            ENDHLSL
        }
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}