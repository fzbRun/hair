Shader "Hair/Marschner"
{
    Properties
    {
        _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Cuticle_ladder("Curicle Ladder", Range(-10.0, -5.0)) = -5.0 //角质层鳞片偏移度
        _Absorption("Absorption", Range(0.2, 1.0)) = 0.2	//单位长度吸收系数
        _Eccentricity("Eccentricity", Range(0.85, 1.0)) = 0.85  //偏心率
        _Lobe("Lobe", Range(5.0, 10.0)) = 5.0   //天顶角方向的粗糙度lobe
    }
    SubShader
    {

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
        #include "M.hlsl"
        #include "N.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _Color;
            float _Cuticle_ladder;
            float _Absorption;
            float _Eccentricity;
            float _Lobe;
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

        float4 frag(Varyings i) : SV_TARGET{

            Light light = GetMainLight();
            float3 color = light.color;

            float3 lightDir = normalize(light.direction);
            float3 viewDir = normalize(GetCameraPositionWS() - i.worldPos);
            float3 normal = normalize(i.normal);
            float3 tangent = normalize(i.tangent.xyz);

            //虽然不知道切线的方向是不是随头发的方向，如果不是，那么就是bitangent是随头发方向的,试一下
            //试完证明就是bitangent是头发方向
            float3 bitangent = normalize(cross(normal, tangent) * i.tangent.w * unity_WorldTransformParams.w);
            tangent = -normalize(cross(normal, bitangent));

            /*
            float cosPhiLi = dot(lightDir, bitangent);    //与垂截面的法线的cos就是与垂截面的sin
            float cosThetaLi = sqrt(1.0f - cosPhiLi * cosPhiLi);
            //这里的出射方向应该就是视野方向，因为如果视野方向不满足在圆锥形的反射波瓣中，应该会被高斯函数吃掉
            float cosPhiLr = dot(viewDir, bitangent);
            float cosThetaLr = sqrt(1.0f - cosPhiLr * cosPhiLr);

            float ThetaLi = acos(cosThetaLi);
            float ThetaLr = acos(cosThetaLr);

            float Theta_h = 0.5f * (ThetaLi + ThetaLr);
            float Theta = ThetaLi + ThetaLr;
            float Phi = acos(cosPhiLi) + acos(cosPhiLr);
            */

            //其实不需要管切线朝向哪里，只需要知道入射和出射的正负关系就行
            float sinThetaLi = dot(bitangent, lightDir);    //与bitangent的cos值
            float ThetaLi = asin(sinThetaLi);
            
            float sinThetaLr = dot(bitangent, viewDir);
            float ThetaLr = asin(sinThetaLr);

            float Theta = ThetaLr - ThetaLi;
            float Theta_h = (ThetaLr + ThetaLi) * 0.5f;
            float sinTheta_h = sin(Theta_h);
            float Theta_d = (ThetaLr - ThetaLi) * 0.5f;
            float cosTheta_d = cos(Theta_d);

            float3 phiDirLi = normalize(lightDir - bitangent * sinThetaLi);
            float cosPhiLi = dot(tangent, phiDirLi);
            float phiLi = acos(cosPhiLi);

            float3 phiDirLr = normalize(viewDir - bitangent * sinThetaLr);
            float cosPhiLr = dot(tangent, phiDirLr);
            float phiLr = acos(cosPhiLr);

            float Phi = phiLr - phiLi;

            _Cuticle_ladder = radians(_Cuticle_ladder);
            _Lobe = radians(_Lobe);

            float3 Nr = getNr(Phi);
            float3 Mr = getM(_Lobe, sinTheta_h - _Cuticle_ladder);
            //Mr = getWetaM(_Lobe, ThetaLi, ThetaLr);   //Meta模型，更加精准，但是更费,但我这个好像错了
            float3 Ntt = getNtt(cosTheta_d, Phi, _Color, _Eccentricity);
            float3 Mtt = getM(_Lobe * 0.5f, sinTheta_h + _Cuticle_ladder * 0.5f);
            float3 Ntrt = getNtrt(cosTheta_d, Phi, _Color);
            float3 Mtrt = getM(2.0f * _Lobe, sinTheta_h + 1.5f * _Cuticle_ladder);

            float3 hairColor = Nr * Mr + (Ntt * Mtt + Ntrt * Mtrt) * (1.0f - _Absorption);
            //hairColor = Ntt * Mtt + Ntrt * Mtrt;
            hairColor /= cosTheta_d * cosTheta_d;
            hairColor *= saturate(dot(normal, lightDir));
            hairColor *= color;

            /*
            float3 ambient = _Color * color * 0.1f;
            float3 diffuse = _Color * color * saturate(dot(normal, lightDir));
            hairColor += diffuse + ambient;
            */

            return float4(hairColor, 1.0f);
            //return Phi;

        }

        ENDHLSL

        Pass{

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
