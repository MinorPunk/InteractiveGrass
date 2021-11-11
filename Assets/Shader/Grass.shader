Shader "Unlit/Grass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _VelocityMap ("VelocityMap", 2D) = "black" {}
        _WindSpeed ("WindSpeed", float) = 1
        _NoiseScale ("NoiseScale",float) = 1
        _RTPixelSize ("RTPixelSize",float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent"  "Queue" = "Transparent"}
        Cull off
        Zwrite off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //#pragma multi_compile_instancing
            // make fog work
            //#pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                //UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _VelocityMap;
            float4 _MainTex_ST;
            float _NoiseScale;
            float _WindSpeed;
            float _RTPixelSize;

            float4 wglnoise_mod289(float4 x)
            {
                return x - floor(x / 289) * 289;
            }


            float2 wglnoise_mod289(float2 x)
            {
                return x - floor(x / 289) * 289;
            }

            float4 wglnoise_permute(float4 x)
            {
                return wglnoise_mod289((x * 34 + 1) * x);
            }

            float2 wglnoise_fade(float2 t)
            {
                return t * t * t * (t * (t * 6 - 15) + 10);
            }

            float ClassicNoise_impl(float2 pi0, float2 pf0, float2 pi1, float2 pf1)
            {
                pi0 = wglnoise_mod289(pi0); // To avoid truncation effects in permutation
                pi1 = wglnoise_mod289(pi1);

                float4 ix = float2(pi0.x, pi1.x).xyxy;
                float4 iy = float2(pi0.y, pi1.y).xxyy;
                float4 fx = float2(pf0.x, pf1.x).xyxy;
                float4 fy = float2(pf0.y, pf1.y).xxyy;

                float4 i = wglnoise_permute(wglnoise_permute(ix) + iy);

                float4 phi = i / 41 * 3.14159265359 * 2;
                float2 g00 = float2(cos(phi.x), sin(phi.x));
                float2 g10 = float2(cos(phi.y), sin(phi.y));
                float2 g01 = float2(cos(phi.z), sin(phi.z));
                float2 g11 = float2(cos(phi.w), sin(phi.w));

                float n00 = dot(g00, float2(fx.x, fy.x));
                float n10 = dot(g10, float2(fx.y, fy.y));
                float n01 = dot(g01, float2(fx.z, fy.z));
                float n11 = dot(g11, float2(fx.w, fy.w));

                float2 fade_xy = wglnoise_fade(pf0);
                float2 n_x = lerp(float2(n00, n01), float2(n10, n11), fade_xy.x);
                float n_xy = lerp(n_x.x, n_x.y, fade_xy.y);
                return 1.44 * n_xy;
            }

            // Classic Perlin noise
            float ClassicNoise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                return ClassicNoise_impl(i, f, i + 1, f - 1);
            }

            v2f vert (appdata v)
            {
                v2f o;
                //取VelocityMap值
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                worldPos.y = worldPos.z;
                float2 velocity = tex2Dlod(_VelocityMap, worldPos * _RTPixelSize);
                //remap
                //velocity.x = velocity.x * 2 - 1;
                //velocity.y = velocity.y * 2 - 1;
                float2 noisePos = float2(v.vertex.x + _Time.y *_WindSpeed, v.vertex.z + _Time.y*_WindSpeed) * _NoiseScale;
                float noise = ClassicNoise(noisePos);
                float xOffset = v.vertex.y * noise + v.vertex.y * velocity.x;
                float zOffset = v.vertex.y * velocity.y;
                float4 newVertex = v.vertex;
                newVertex.x += xOffset;
                newVertex.z += zOffset;
                o.vertex = UnityObjectToClipPos(newVertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
