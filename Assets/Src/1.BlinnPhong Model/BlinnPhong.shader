Shader "LJ/BlinnPhong"
{
    Properties
    {
        _MainColor ("Main Color", Color) = (1,1,1,1)
        _SpecularColor ("Spec Color", Color) = (1,1,1,1)
        _Shininess ("Shininess", float) = 256
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
           #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

           struct Attributes{
                float4 vertex:POSITION;
                half3 normal:NORMAL;
           };

           struct v2f{
                float4 position:SV_POSITION;
                float3 normal:TEXCOORD0;
                float4 vertex:TEXCOORD1;
           };

           CBUFFER_START(UnityPerMaterial)
           half4 _MainColor;
           half4 _SpecularColor;
           float _Shininess;
           CBUFFER_END

           v2f vert(Attributes input){
                v2f output;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.vertex.xyz);
                output.position = positionInputs.positionCS;
                output.normal = input.normal;
                output.vertex = input.vertex;
                return output;
           }

           half4 frag(v2f input):SV_Target{
                float3 n = normalize(TransformObjectToWorldNormal(input.normal));
                half3 l = normalize(_MainLightPosition.xyz);
                half3 v = normalize(GetWorldSpaceViewDir(input.vertex.xyz));

                //DIFFUSE
                half ndotl = saturate(dot(n,l));
                half4 dif = _MainLightColor * _MainColor * ndotl;

                //SPECULAR
                half3 h = normalize(l + v);
                half4 ndoth = saturate(dot(n,h));
                half4 spec = _MainLightColor * _SpecularColor * pow(ndoth,_Shininess);

                return unity_AmbientSky + dif + spec;
           }

           ENDHLSL
        }
    }
}