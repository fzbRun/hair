Shader "Hair/kajiya"
{
    Properties
    {
        _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Shift("Shift", Range(-10, -5)) = -5.0
        _ScatterColor("Scatter Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _WarpNDL("Warp NDL", Range(0.0, 1.0)) = 0.5
    }
    SubShader
    {
         HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _Color;
            float _Shift;
            float4 _ScatterColor;
            float _WarpNDL;
        CBUFFER_END;

        CBUFFER_START(UnityPerDraw)

        CBUFFER_END

        struct Attributes {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
        };

        struct Varyings {
            float4 position : SV_POSITION;
            float3 normal : VAR_NORMAL;
            float4 tangent : VAR_TANGENT;
            float3 worldPos : VAR_WORLDPOSITION;
        };

        Varyings vert(Attributes i) {

            Varyings o;

            o.worldPos = TransformObjectToWorld(i.vertex.xyz);
            o.position = TransformWorldToHClip(o.worldPos);
            o.normal = TransformObjectToWorldNormal(i.normal);
            o.tangent = float4(TransformObjectToWorldDir(i.tangent.xyz), i.tangent.w);

            return o;

        }

        float3 fresnelSchlick(float cosTheta)
        {
            float F0 = 0.0465f;
            return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
        }

        float4 frag(Varyings i) : SV_TARGET{

            Light light = GetMainLight();
            float3 color = light.color;

            float3 lightDir = normalize(light.direction);
            float3 viewDir = normalize(GetCameraPositionWS() - i.worldPos);
            float3 normal = normalize(i.normal);
            float3 tangent = normalize(i.tangent.xyz);
            float3 bitangent = cross(normal, tangent) * i.tangent.w;
            tangent = normalize(cross(normal, bitangent));

            _Shift = radians(_Shift);
            float3 normal_Primary = normalize(sin(_Shift) * bitangent + normal);
            float3 bitangent_Primary = normalize(cross(normal_Primary, tangent));

            float3 normal_Secondary = normalize(sin(-1.5f * _Shift) * bitangent + normal);
            float3 bitangent_Secondary = normalize(cross(normal_Secondary, tangent));

            float3 ambient = 0.1f * _Color;
            float3 diffuse = saturate(dot(normal, lightDir) + _WarpNDL) / (1.0f + _WarpNDL);
            diffuse = _ScatterColor * saturate(dot(normal, lightDir)) * diffuse * _Color;


            float3 h = normalize(lightDir + viewDir);
            float cosHB = dot(h, bitangent_Primary);
            float cosNH = sqrt(1.0f - cosHB * cosHB);
            float dirAtten = smoothstep(-1, 0, cosHB);
            float3 specular_P = pow(cosNH, 64) * dirAtten;

            cosHB = dot(h, bitangent_Secondary);
            cosNH = sqrt(1.0f - cosHB * cosHB);
            dirAtten = smoothstep(-1, 0, cosHB);
            float3 specular_S = pow(cosNH, 64) * dirAtten;

            float3 specular = specular_P + specular_S * _Color;

            /*
            float cosVB = dot(viewDir, bitangent);
            float cosVN = sqrt(1.0f - cosVB * cosVB);
            float FS = fresnelSchlick(saturate(cosVN));
            float FD = 1.0f - FS;
            */

            float3 hairColor = ambient + diffuse + specular;
            hairColor *= color;

            return float4(hairColor, 1.0);

        }

        ENDHLSL

        Pass {

            Tags {
                "RenderPipeline" = "UniversalPipeline"
                "LightMode" = "UniversalForward"
                "Queue" = "Geometry"
                "RenderType" = "Opaque"
            }

            HLSLPROGRAM
                #pragma vertex vert;
                #pragma fragment frag;
            ENDHLSL

        }
    }
}
