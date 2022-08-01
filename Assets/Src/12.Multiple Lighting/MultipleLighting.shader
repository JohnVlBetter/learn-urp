Shader "LJ/MultipleLighting"
{
    Properties
    {
        [Toggle(_AdditionalLights)] _AddLights ("AddLights", Float) = 1
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 64
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        HLSLINCLUDE
        #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
        float4 _Diffuse;
        float4 _Specular;
		float _Gloss;
        CBUFFER_END

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
                 float4 tangentOS:TANGENT;
            };
            
            struct v2f{
                 float4 positionCS:SV_POSITION;
                 float3 viewDirWS:TEXCOORD0;
                 float3 positionWS: TEXCOORD1;
				 float3 normalWS : TEXCOORD2;
            };
            
            v2f vert(a2v input){
                 v2f output;
                 VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
				 output.positionCS = positionInputs.positionCS;
				 output.positionWS = positionInputs.positionWS;
                 
				 VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS,input.tangentOS);
				 output.normalWS = normalInputs.normalWS;
                 output.viewDirWS = GetCameraPositionWS() - output.positionWS;

                 return output;
            }

            half3 LightingBased(half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS)
            {
                half NdotL = saturate(dot(normalWS, lightDirectionWS));
                half3 radiance = lightColor * lightAttenuation * NdotL * _Diffuse.rgb;

                half3 halfDir = normalize(lightDirectionWS + viewDirectionWS);
                half3 specular = lightColor * pow(saturate(dot(normalWS, halfDir)), _Gloss) * _Specular.rgb;
                
                return radiance + specular;
            }

            half3 LightingBased(Light light, half3 normalWS, half3 viewDirectionWS)
            {
                return LightingBased(light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS);
            }
            
            half4 frag(v2f input):SV_Target{
                 half3 normalWS = NormalizeNormalPerPixel(input.normalWS);
                 half3 viewDirWS = SafeNormalize(input.viewDirWS);

                 Light mainLight = GetMainLight();
                 half3 color = LightingBased(mainLight,normalWS,viewDirWS);

                 #ifdef _AdditionalLights

                    uint pixelLightCount = GetAdditionalLightsCount();
                    for(uint i = 0;i<pixelLightCount;++i){
                        Light tmpL = GetAdditionalLight(i, input.positionWS);
                        color += LightingBased(tmpL,normalWS,viewDirWS);
                    }

                 #endif

                 half3 ambient = SampleSH(normalWS);
                 return half4(ambient + color , 1.0);

            }
            
            ENDHLSL
        }
    }

    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}