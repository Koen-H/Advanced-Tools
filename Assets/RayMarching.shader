Shader "Unlit/RayMarching"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

#define MAX_STEPS 1000
#define MAX_DIST 100
#define SURF_DIST 1e-3

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ro: TEXCOORD1;
                float3 hitPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos,1));
                o.ro = _WorldSpaceCameraPos;
                o.hitPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float smoothMax(float a, float b, float k) {
                return log(exp(k * a) + exp(k * b)) / k;
            }

            float smoothMin(float a, float b, float k) {
                return -smoothMax(-a, -b, k);
            }

            //float GetDist(float3 p) {
            //    float d = length(p)-.5; //sphere
            //    d = length(float2(length(p.xz) - .1, p.y)) -.1  ;//Donut
            //    //d = max(max(-p.x, -p.z), 0.5 * p.y + 0.5) -.1;//Pyramid
            //    return d;
            //}


            /*Sphere
            float GetDist(float3 p) {
                float d = length(p) - 0.5; // Sphere
                d = length(float2(length(p.xz) - 0.1, p.y)) - 0.1; // Torus
                return d;
            }*/

            /*Capsule*/
            float sdCapsule(float3 p, float3 a, float3 b, float r) {
                float3 ab = b - a;
                float3 ap = p - a;

                float t = dot(ab, ap / dot(ab, ab));
                t = clamp(t, 0, 1);
                float3 c = a + t * ab;
                float val = length(p - c) - r;
                return val;
            }


            float GetDist(float3 p) {
                float d1 = sdCapsule(p, float3(0, 0, 0), float3(0, 1, 0), 0.2);  // upper capsule
                float d2 = sdCapsule(p, float3(0, 0, 0), float3(1, 0, 0), 0.2);  // lower capsule
                float d3 = sdCapsule(p, float3(0, 0, 0), float3(0, 1, 0), 0.2);
                //float d = min(d1, d2);
                float d = smoothMin(d1, d3, 0.01);
                //float dUpperLower = smoothMax(d1, d2, 0.1);
                //float dAll = smoothMax(dUpperLower, d3, 0.1);
                //return dAll;
                //float capsulesX = 5;
                //float capsulesY = 20;
                //for (int i = 0; i < capsulesX; i++) {
                //    for (int y = 0; y < capsulesY; y++) {
                //        d3 = sdCapsule(p, float3(i, y, 0), float3(i, 1, 0), 0.2);
                //        d = min(d, d3);
                //    }
                //    //d3 = sdCapsule(p, float3(i, 0, 0), float3(i, 1, 0), 0.2);
                //}
                return d;
            }
            /**/

            /*Cone
            float GetDist(float3 p) {
                float r1 = 0.5; // radius of the base of the cone
                float r2 = 0.9; // radius of the top of the cone (0.0 for a pointed cone)
                float h = 1.0; // height of the cone

                float3 q = float3(length(p.xz), p.y, 0);
                float2 k1 = float2(r1, h);
                float2 k2 = float2(r2, 0);

                float d1 = length(q - k2.xy) - k2.x;
                float d2 = max(dot(q, normalize(k1)), q.y);
                float d3 = length(float2(d1, d2));
                float d4 = min(max(q.y, -h - q.y), length(p - float3(0, -h, 0)));

                return d3 +d4; // add a small padding to the surface to avoid self-shadowing artifacts
            }*/





            float Raymarch(float3 ro, float3 rd) {
                float dO = 0;
                float dS;
                for (int i = 0; i < MAX_STEPS; i++) {
                    float3 p = ro + dO * rd;
                    dS = GetDist(p);
                    dO += dS;
                    // If hit surface
                    if (dS<SURF_DIST || dO>MAX_DIST)break;
                }
                return dO;
            }

            float3 GetNormal(float3 p) {
                float2 e = float2(1e-2, 0);
                float3 n = GetDist(p) - float3(
                    GetDist(p-e.xyy),
                    GetDist(p-e.yxy),
                    GetDist(p-e.yyx)
                    );
                return normalize(n);
            }

            /*old
            fixed4 frag(v2f i) : SV_Target
            {

                float2 uv = i.uv-.5;
                float3 ro = i.ro;// float3(0, 0, -3);
                float3 rd = normalize(i.hitPos-ro); //normalize(float3(uv.x,uv.y,1));

                float d = Raymarch(ro, rd);
                fixed4 col = 0;
                if (d < MAX_DIST) {
                    float3 p = ro + rd * d;
                    float3 n = GetNormal(p);
                    col.rgb = n;
                }
                else discard;
                //col.rgb = rd;
                return col;
            }*/

            //new
            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv - 0.5;
                float3 ro = i.ro;//ray origin
                float3 rd = normalize(i.hitPos - ro);//ray direction

                float d = Raymarch(ro, rd);
                fixed4 col = 0;
                if (d < MAX_DIST)
                {
                    float3 p = ro + rd * d;
                    float3 n = GetNormal(p);
                    float diffuse = max(0.0, dot(n, -rd));

                    // Apply Lambertian diffuse reflection
                    col = tex2D(_MainTex, i.uv);
                    col.rgb *= diffuse;
                }

                return col;
            }
            ENDCG
        }
    }
}
