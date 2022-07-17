Shader "LJ/BlinnPhong"
{
    Properties
    {
        _MainColor ("Main Color", Color) = (0.8,0.8,0.8,1)
        _SpecularColor ("Spec Color", Color) = (1,1,1,1)
        _WarmColor ("Warm Color", Color) = (1,0.8,0.2,1)
        _CoolColor ("Cool Color", Color) = (0.2,0.2,1,1)
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
                float4 vertex:TEXCOORD1;
           };

           CBUFFER_START(UnityPerMaterial)
           half4 _MainColor;
           half4 _SpecularColor;
           half4 _WarmColor;
           half4 _CoolColor;
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

                half4 c_cool = _CoolColor + 0.25 * _MainColor;
                half4 c_warm = _WarmColor+ 0.25 * _MainColor;

                half t = dot(n,l) * 0.5 + 0.5;
                half3 r = 2 * dot(n,l) * n - l;
                half s = saturate(100 * dot(r,v)-97);

                half4 c_result = s * _SpecularColor +(1-s)*(t*c_warm+(1-t)*c_cool);

                return c_result;
           }

           ENDHLSL
        }
    }
}