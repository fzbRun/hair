Shader "Hair/villi"
{
    Properties
    {
        //_Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColorMap("Color Map", 2D) = "white"{}
        _ColorAttenuation("Color Attenuation", Range(0.0, 1.0)) = 1.0
        _Offset("Fur Offset", Range(0.0, 10.0)) = 1.0
        _NoiseMap("Noise Map", 2D) = "white"{}
        _FurShadowMap("Fur Shadow Map", 2D) = "white"{}
        _FurAOInstensity("Fur Shadow Instensity", Range(0.0, 1.0)) = 0.5
        _FurLength("Fur Length", Float) = 1.0
        [HideInInspector]_Step("Step", Float) = 0.0
        _Gravity("Fur Gravity", Range(0.0, 1.0)) = 1.0
        _Wind("Fur Wind", Color) = (1.0, 1.0, 1.0, 1.0)
        _WindStrength("Wind Strength", Range(0.0, 2.0)) = 1.0
        _WindSpeed("Fur Wind Speed", Range(0.0, 2.0)) = 1.0
        _FurDensity("Fur Density", Float) = 1.0
    }
    SubShader
    {

        HLSLINCLUDE

        #define INPUT_PROP(name) UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, name)

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

        //float _Offset;

        UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
            //UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
            UNITY_DEFINE_INSTANCED_PROP(float4, _ColorMap_ST)
            UNITY_DEFINE_INSTANCED_PROP(float4, _ColorMap_TexelSize)
            UNITY_DEFINE_INSTANCED_PROP(float, _ColorAttenuation)
            UNITY_DEFINE_INSTANCED_PROP(float, _Offset)
            UNITY_DEFINE_INSTANCED_PROP(float4, _NoiseMap_ST)
            UNITY_DEFINE_INSTANCED_PROP(float4, _FurShadowMap_ST)
            UNITY_DEFINE_INSTANCED_PROP(float, _FurAOInstensity)
            UNITY_DEFINE_INSTANCED_PROP(float, _FurLength)
            UNITY_DEFINE_INSTANCED_PROP(float, _Step)
            UNITY_DEFINE_INSTANCED_PROP(float, _Gravity)
            UNITY_DEFINE_INSTANCED_PROP(float4, _Wind)
            UNITY_DEFINE_INSTANCED_PROP(float, _WindStrength)
            UNITY_DEFINE_INSTANCED_PROP(float, _WindSpeed)
            UNITY_DEFINE_INSTANCED_PROP(float, _FurDensity)
        UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

        TEXTURE2D(_ColorMap);
        TEXTURE2D(_NoiseMap);
        TEXTURE2D(_FurShadowMap);
        SAMPLER(sampler_ColorMap);

        struct Attributes {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
            float2 texcoord : TEXCOORD;
            uint instanceID : SV_InstanceID;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct Varyings{
            float4 position : SV_POSITION;
            float3 worldPosition : VAR_POSITION;
            float3 normal : VAR_NORMAL;
            float4 tangent : VAR_TANGENT;
            float2 uv : VAR_UV;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };
        
        Varyings vert_base(Attributes i) {

            Varyings o;
            
            o.worldPosition = TransformObjectToWorld(i.vertex);
            o.position = TransformWorldToHClip(o.worldPosition);
            o.normal = TransformObjectToWorldNormal(i.normal);
            o.tangent = float4(TransformObjectToWorldDir(i.tangent.xyz), i.tangent.w);
            o.uv = i.texcoord;

            return o;

        }

        float4 frag_base(Varyings i) : SV_TARGET{

            Light light = GetMainLight();
            float3 lightColor = light.color;
            float3 objectColor = SAMPLE_TEXTURE2D(_ColorMap, sampler_ColorMap, i.uv);
            float3 L = normalize(light.direction);

            float3 N = normalize(i.normal);
            float3 T = normalize(i.tangent.xyz);
            float3 BT = normalize(cross(N, T)) * i.tangent.w;

            float3 V = normalize(GetCameraPositionWS() - i.worldPosition);
            float3 H = normalize(L + V);

            float3 ambient = 0.1f * objectColor;
            float3 diffuse = objectColor * saturate(0.5f + 0.5f * dot(N, L));
            float sinNH = dot(BT, H);
            float3 specular = pow(sqrt(1.0f - sinNH * sinNH), 64);

            float3 finalColor = (ambient + diffuse + specular) * lightColor;
            return float4(finalColor, 1.0f);

        }

        Varyings vert_fur(Attributes i){
        
            Varyings o;

            UNITY_SETUP_INSTANCE_ID(i);
            UNITY_TRANSFER_INSTANCE_ID(i, o);

            o.worldPosition = TransformObjectToWorld(i.vertex);
            o.normal = TransformObjectToWorldNormal(i.normal);
            o.tangent = float4(TransformObjectToWorldDir(i.tangent.xyz), i.tangent.w);

            float3 normal = normalize(o.normal);
            float k = pow(_Step, 3);
            //_Step = (i.instanceID + 1) * 0.05f;

            float sinG = dot(float3(0.0f, 1.0f, 0.0f), normal);
            float3 Gravity = mul(unity_ObjectToWorld, float4(0.0f, -INPUT_PROP(_Gravity) * 0.03f, 0.0f, 0.0f)) * sqrt(1.0f - sinG * sinG);

            float3 Wind = normalize(INPUT_PROP(_Wind).xyz * 2.0f - 1.0f);
            float3 tangent = normalize(Wind - normal * dot(normal, Wind));
            float3 MoveDir = 2 * normal - tangent;
            float3 wind = mul(unity_ObjectToWorld, abs(sin(INPUT_PROP(_WindSpeed) * _Time.y)) * MoveDir) * saturate(dot(normal, Wind)) * 0.01f * INPUT_PROP(_WindStrength);
            o.worldPosition += normal * _Step * INPUT_PROP(_FurLength) + (Gravity + wind) * k;

            o.position = TransformWorldToHClip(o.worldPosition);
            o.uv = i.texcoord;
            
            return o;

        }

        float4 frag_fur(Varyings i) : SV_TARGET{

            UNITY_SETUP_INSTANCE_ID(i);

            Light light = GetMainLight();
            float3 lightColor = light.color;

            float2 uv = i.uv;
            uv += _Step * INPUT_PROP(_ColorMap_TexelSize).xy * INPUT_PROP(_Offset);
            float3 noise = SAMPLE_TEXTURE2D(_NoiseMap, sampler_ColorMap, uv * INPUT_PROP(_NoiseMap_ST).xy).rgb;

            float3 objectColor = SAMPLE_TEXTURE2D(_ColorMap, sampler_ColorMap, uv * INPUT_PROP(_ColorMap_ST).xy);

            float3 L = normalize(light.direction);
            float3 N = normalize(i.normal);
            float3 T = normalize(i.tangent.xyz);
            float3 BT = normalize(cross(N, T)) * i.tangent.w;
            float3 V = normalize(GetCameraPositionWS() - i.worldPosition);
            float3 H = normalize(L + V);
            
            uv += noise.xy;
            float3 _FurAO = SAMPLE_TEXTURE2D(_FurShadowMap, sampler_ColorMap, i.uv * INPUT_PROP(_FurShadowMap_ST).xy).rgb;

            objectColor -= pow(1.0f - _Step, 3) * INPUT_PROP(_ColorAttenuation);
            float3 bright = dot(float3(0.299f, 0.587f, 0.114f), objectColor);
            objectColor -= bright * (1.0f - _Step);
            objectColor -= _FurAO * INPUT_PROP(_FurAOInstensity);

            float3 ambient = 0.1f * objectColor;
            float3 diffuse = saturate(0.5f + dot(N, L) * 0.5f) * objectColor;
            float sinNH = dot(BT, H);
            float3 specular = pow(sqrt(1.0f - sinNH * sinNH), 64) * 0.2f;
            float3 finalColor = (ambient + diffuse + specular) * lightColor;

            //(Noise * 2 - (FUR_OFFSET * FUR_OFFSET + (FUR_OFFSET * FurMask * 5)))* _tming;
            float alpha = noise.r + 0.4f - _Step;

            return float4(finalColor, alpha);

        }

        ENDHLSL

        Pass{

            Tags{
                "RenderPipeline" = "UniversalPipeline"
                "LightMode" = "UniversalForward"
                "Queue" = "Geometry"
                "RenderType" = "Opaque"
            }

           HLSLPROGRAM
                #pragma vertex vert_base;
                #pragma fragment frag_base;
           ENDHLSL

        }

        Pass{

            Blend SrcAlpha OneMinusSrcAlpha

            Tags{
                "RenderPipeline" = "UniversalPipeline"
                "LightMode" = "fur"
                "Queue" = "Geometry"
                "RenderType" = "Opaque"
            }

           HLSLPROGRAM
                #pragma vertex vert_fur;
                #pragma fragment frag_fur;
                #pragma multi_compile_instancing
                //#pragma instancing_options procedural:setup
           ENDHLSL

        }

    }
}
