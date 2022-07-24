Shader "LJ/TextureMapping"
{
    Properties
    {
        [MainTexture]_MainTex ("Main Texture", 2D) = "white"{}
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
                 float4 texcoord:TEXCOORD0;
            };
            
            struct v2f{
                 float4 position:SV_POSITION;
                 float3 normal:TEXCOORD0;
                 float2 uv:TEXCOORD1;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END
            
            v2f vert(a2v input){
                 v2f output;
                 VertexPositionInputs positionInputs = GetVertexPositionInputs(input.vertex.xyz);
                 output.position = positionInputs.positionCS;
                 output.normal = input.normal;
                 output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
                 return output;
            }
            
            half4 frag(v2f input):SV_Target{
                 float3 n = normalize(TransformObjectToWorldNormal(input.normal));
                 half3 l = normalize(_MainLightPosition.xyz);
                 half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
            
                 half half_lambert_ndotl = saturate(dot(n,l)*0.5+0.5);
                 half lambert_ndotl = saturate(dot(n,l));
            
                 half4 dif = _MainLightColor * albedo * half_lambert_ndotl;

                 half4 ambient = albedo * unity_AmbientSky;
            
                 return ambient + dif;
            }
            
            ENDHLSL
        }
    }
}