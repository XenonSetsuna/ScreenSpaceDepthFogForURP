Shader "Post-process/DepthFog"
{
    Properties
    {
        _NoiseTexture ("", 2D) = "white" {}
        _NoiseOffset ("", float) = 0
        _Color ("", Color) = (1, 1, 1, 1)
        _Intensity ("", float) = 0.5
        _Height ("", float) = 10
        _Distance ("", float) = 0
        _Thickness ("", float) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }

        ZWrite Off
		ZTest Always
		Cull Off
        Blend SrcAlpha OneMinusSrcAlpha

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)

        CBUFFER_END

        ENDHLSL

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM

            // 设置关键字
            #pragma shader_feature _AdditionalLights

            // 接收阴影所需关键字
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            struct Attributes
            {
                half4 positionOS: POSITION;
                half2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                half4 positionCS: SV_POSITION;
                half2 uv : TEXCOORD0;
            };

            TEXTURE2D(_CameraDepthTexture);
            TEXTURE2D(_NoiseTexture);

            #define textureSampler1 SamplerState_Point_Repeat
            SAMPLER(textureSampler1);

            half _NoiseOffset;
            half4 _Color;
            half _Intensity;
            half _Height;
            half _Distance;
            half _Thickness;

            Varyings vert(Attributes v)
            {
                Varyings o;
                ZERO_INITIALIZE(Varyings, o);
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.uv;
                return o;
            }

            half4 SolvePositionWSFromDepth(half2 uv , half linerDepth)
			{
				half3 positionSS = half3(uv, linerDepth);
				half4 positionNDC = mul(unity_CameraInvProjection, half4(positionSS * 2.0 - 1.0 , 1.0));
				positionNDC = half4(positionNDC.xyz / positionNDC.w, 1.0);
				half4 positionWS = mul( unity_CameraToWorld, positionNDC * half4(1,1,-1,1));
				positionWS = half4(positionWS.xyz, 1.0);
				return positionWS;
			}

            half4 frag(Varyings i): SV_Target
            {
                Light mainLight = GetMainLight();

                half depthFromDepthTexture = SAMPLE_TEXTURE2D(_CameraDepthTexture, textureSampler1, i.uv).r;
                half linerDepth = Linear01Depth(depthFromDepthTexture, _ZBufferParams);
                linerDepth = saturate(linerDepth - _Distance) / (1 - _Distance);
                linerDepth = pow(linerDepth, 1 / _Thickness);
                clip(linerDepth - 0.001);
                half3 linerDepthPositionWS = SolvePositionWSFromDepth(i.uv, 1 - depthFromDepthTexture);
                
                int cameraIsInsideFog = saturate(ceil(_Height - _WorldSpaceCameraPos.y));
                int targetIsInsideFog = saturate(ceil(_Height -linerDepthPositionWS.y));

                //half noise1 = SAMPLE_TEXTURE2D(_NoiseTexture, textureSampler1, half2((linerDepthPositionWS.x + _NoiseOffset) * 0.015, linerDepthPositionWS.y * 0.03) * (0.5 + 0.5 * pow(1 - linerDepth, 0.05))).r;
                //half noise2 = SAMPLE_TEXTURE2D(_NoiseTexture, textureSampler1, half2((linerDepthPositionWS.z + _NoiseOffset) * 0.015, linerDepthPositionWS.y * 0.03) * (0.5 + 0.5 * pow(1 - linerDepth, 0.05))).r;
                //half noise3 = SAMPLE_TEXTURE2D(_NoiseTexture, textureSampler1, (linerDepthPositionWS.xz + half2(_NoiseOffset, _NoiseOffset)) * 0.01 * (0.5 + 0.5 * pow(1 - linerDepth, 0.05))).r;
                //half noise = 1 - linerDepth + linerDepth * pow(noise1, 0.25) * pow(noise2, 0.25) * pow(noise3, 0.25);
                //noise = 0.25 + 0.75 * noise;

                float inFogDepth = distance(_WorldSpaceCameraPos.xyz, linerDepthPositionWS.xyz) / distance(_WorldSpaceCameraPos.xyz, SolvePositionWSFromDepth(i.uv, 1)) * cameraIsInsideFog * targetIsInsideFog;//相机与目标点都在雾里面
                inFogDepth += distance(_WorldSpaceCameraPos.xyz, linerDepthPositionWS.xyz) * (_Height - linerDepthPositionWS.y) / (_WorldSpaceCameraPos.y - linerDepthPositionWS.y) / distance(_WorldSpaceCameraPos.xyz, SolvePositionWSFromDepth(i.uv, 1)) * (1 - cameraIsInsideFog) * targetIsInsideFog;//相机在雾外面，目标点在雾里面
                inFogDepth += distance(_WorldSpaceCameraPos.xyz, linerDepthPositionWS.xyz) * (_Height - _WorldSpaceCameraPos.y) / (linerDepthPositionWS.y - _WorldSpaceCameraPos.y) / distance(_WorldSpaceCameraPos.xyz, SolvePositionWSFromDepth(i.uv, 1)) * cameraIsInsideFog * (1 - targetIsInsideFog);//相机在雾里面，目标点在雾外面

                inFogDepth = pow(inFogDepth, 1 / _Thickness);

                half mainLightIntensity = (mainLight.color.r + mainLight.color.g + mainLight.color.b) / 3;
                half3 color = _Color.rgb * (mainLight.color.rgb * (1 - inFogDepth) + inFogDepth) * _Intensity;

                //return half4(linerDepth, linerDepth, linerDepth, 1);
                return half4(color, inFogDepth);
            }

            ENDHLSL

        }
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
