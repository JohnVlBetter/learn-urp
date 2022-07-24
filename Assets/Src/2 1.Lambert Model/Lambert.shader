Shader "LJ/Lambert"
{
    Properties
    {
        _MainColor ("Main Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
           HLSLPROGRAM
           #pragma vertex vert
           #pragma fragment frag

           #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
           #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

           struct Attributes{
                float4 vertex:POSITION;
                half3 normal:NORMAL;
           };

           struct v2f{
                float4 position:SV_POSITION;
                float3 normal:TEXCOORD0;
           };

           CBUFFER_START(UnityPerMaterial)
           half4 _MainColor;
           CBUFFER_END

           v2f vert(Attributes input){
                v2f output;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.vertex.xyz);
                output.position = positionInputs.positionCS;
                output.normal = input.normal;
                return output;
           }

           half4 frag(v2f input):SV_Target{
                float3 n = normalize(TransformObjectToWorldNormal(input.normal));
                half3 l = normalize(_MainLightPosition.xyz);

                //half-lambert
                half half_lambert_ndotl = saturate(dot(n,l)*0.5+0.5);
                //lambert
                half lambert_ndotl = saturate(dot(n,l));

                half4 dif = _MainLightColor * _MainColor * half_lambert_ndotl;

                return unity_AmbientSky + dif;
           }

           ENDHLSL
        }
    }
}