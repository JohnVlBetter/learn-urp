Shader "LJ/RampTexture"
{
    Properties
    {
        _RampTex ("Ramp Texture", 2D) = "white"{}
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
                 float4 texcoord:TEXCOORD0;
            };
            
            struct v2f{
                 float4 position:SV_POSITION;
                 float2 uv:TEXCOORD0;
                 float3 normal:TEXCOORD1;
                 float3 worldPos:TEXCOORD2;
                 float4 vertex:TEXCOORD3;
            };

            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);
            
            CBUFFER_START(UnityPerMaterial)
            float4 _RampTex_ST;
            float4 _Color;
			float4 _Specular;
			float _Gloss;
            CBUFFER_END
            
            v2f vert(a2v input){
                 v2f output;
                 VertexPositionInputs positionInputs = GetVertexPositionInputs(input.vertex.xyz);
                 output.position = positionInputs.positionCS;
                 output.uv = TRANSFORM_TEX(input.texcoord, _RampTex);

                 output.normal = TransformObjectToWorldNormal(input.normal);
                 output.worldPos = TransformObjectToWorld(input.vertex.xyz);
                 output.vertex = input.vertex;

                 return output;
            }
            
            half4 frag(v2f input):SV_Target{
                 float3 worldNormal = normalize(input.normal);
				 half3 lightDir = normalize(_MainLightPosition.xyz/* - TransformObjectToWorld(input.vertex)*/);

                 float halfLambert = dot(worldNormal,lightDir)*0.5+0.5;
                 half3 diffuseColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(halfLambert,halfLambert)).rgb 
                    * _Color.rgb * _MainLightColor.rgb;
                 float3 viewDir = normalize(GetWorldSpaceViewDir(input.worldPos));
                 float3 halfDir = normalize(lightDir+viewDir);
                 half4 spec = _MainLightColor * _Specular * pow(saturate(dot(worldNormal,halfDir)),_Gloss);

                 return float4(unity_AmbientSky + diffuseColor + spec,1.0);
            }
            
            ENDHLSL
        }
    }
}