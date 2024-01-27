Shader "Hidden/RayMarchingTwo"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}
		SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0

			#include "UnityCG.cginc"
			#include "Distancefunctions.cginc"

			sampler2D _MainTex;
			
			//Setup
			uniform sampler2D _CameraDepthTexture;
			uniform float4x4 _CamFrustum, _CamToWorld;
			uniform float _maxDistance;
			uniform float _MaxIterations;
			uniform float _Accuracy;

			//uniform float _maxDistance, _box1round, _boxSphereSmooth, _sphereIntersectSmooth;
			//uniform float4 _sphere1, _sphere2, _box1;
			//Mod interval
			uniform int _useModInterval;
			uniform float4 _modInterval;
			uniform int _modInfinite;

			//Light
			uniform int _useLight;
			uniform float3 _LightDir, _LightCol;
			uniform float _LightIntensity;
			uniform int _useAmbientOcclusion;
			
			//Color
			uniform fixed4 _mainColor;
			
			//Shadow
			uniform int _useShadow;
			uniform float2 _ShadowDistance;
			uniform float _ShadowIntensity;
			uniform float _ShadowPenumbra;
			
			//SDf
			uniform float4 _sphere;
			uniform float _sphereSmooth;
			uniform float _degreeRotate;
			
			uniform float4 _box1;



			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 ray: TEXCOORD1;
			};

			v2f vert(appdata v)
			{
				v2f o;
				half index = v.vertex.z;
				v.vertex.z = 0;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv.xy;

				o.ray = _CamFrustum[(int)index].xyz;
				o.ray /= abs(o.ray.z);
				o.ray = mul(_CamToWorld, o.ray);

				return o;
			}

			//float BoxSphere(float3 p) {
			//	float Sphere1 = sdSphere(p - _sphere1.xyz, _sphere1.w);
			//	float Box1 = sdRoundBox(p - _box1.xyz, _box1.www, _box1round);
			//	float combine1 = opSS(Sphere1, Box1, _boxSphereSmooth);
			//	float Sphere2 = sdSphere(p - _sphere2.xyz, _sphere2.w);
			//	float combine2 = opIS(Sphere2, combine1, _sphereIntersectSmooth);
			//	return combine2;
			//}

			


			float distanceField(float3 p) {
				//return mandelbulbSDF(p, 2 ,10);
				float result;
				float ground = sdPlane(p, float4(0, 1, 0, 0));
				if (_useModInterval) {
					if (_modInfinite) {
						float modX = pMod1(p.x, _modInterval.x);
						float modY = pMod1(p.y, _modInterval.y);
						float modZ = pMod1(p.z, _modInterval.z);
					}
					else {
						p = opRepLim(p, _modInterval.w, _modInterval.xyz);
					}
				}
				float sphere = sdSphere(p - _sphere.xyz, _sphere.w);
				float box1 = sdBox(p - _box1.xyz, _box1.w);
				result = opSS(sphere, box1, _sphereSmooth);
				//result = sdTorus(p - _sphere.xyz, float2(_sphere.w, 0.1));
				//result = sdBox(p - _box1.xyz, _box1.w);
				//float prism = sdHexPrism(p - _sphere.xyz, float2(1, _sphere.w));
				/* //Create 8 spheres, and place them in a circle
				for (int i = 1; i < 8; i++) {
					float sphereAdd = sdSphere(RotateY(p, _degreeRotate * i) - _sphere.xyz, _sphere.w);
					sphere = opUS(sphere, sphereAdd, _sphereSmooth);
				}*/
				//result = sdTorus(p, float2(1, 1));
				//result = opIS(prism,box1,_sphereSmooth);
				//float boxSphere1 = BoxSphere(p);
				//result = opU(ground, boxSphere1);
				return result; 
			}

			float3 getNormal(float3 p) {
				const float2 offset = float2(0.001, 0.0);
				float3 n = float3(
					distanceField(p + offset.xyy) - distanceField(p - offset.xyy),
					distanceField(p + offset.yxy) - distanceField(p - offset.yxy),
					distanceField(p + offset.yyx) - distanceField(p - offset.yyx));
				return normalize(n);
			}

			float hardShadow(float3 ro, float3 rd, float minT, float maxT) 
			{
				for (float t = minT; t < maxT;) {
					float h = distanceField(ro + rd * t);
					if (h < 0.001) {
						return 0.0;
					}
					t += h;
				}
				return 1.0;
			}


			float softShadow(float3 ro, float3 rd, float minT, float maxT, float k)
			{
				float result = 1.0;
				for (float t = minT; t < maxT;) {
					float h = distanceField(ro + rd * t);
					if (h < 0.001) {
						return 0.0;
					}
					result = min(result, k * h / t);
					t += h;
				}
				return result;
			}

			uniform float _AoStepsize, _AoIntensity;
			uniform int _AoIterations;

			float AmbientOcclusion(float3 p, float3 n) {

				float step = _AoStepsize;
				float ao = 0.0;
				float dist;
				for (int i = 1; i <= _AoIterations; i++) {
					dist = step * i;
					ao += max(0.0,(dist - distanceField(p + n * dist)) / dist);
				}
				return (1.0 - ao * _AoIntensity);
			}


			float3 Shading(float3 p, float3 n)
			{
				float3 result;
				//Diffuse Color
				float3 color = _mainColor.rgb;
				result = color;
				//Directional Light
				if (_useLight) {
					float3 light = (_LightCol * dot(-_LightDir, n) * 0.5 + 0.5) * _LightIntensity;
					result *= light;
				}
				//Shadows
				if (_useShadow) {
					float shadow = softShadow(p, -_LightDir, _ShadowDistance.x, _ShadowDistance.y, _ShadowPenumbra) * 0.5 + 0.5;
					shadow = max(0.0, pow(shadow, _ShadowIntensity));
					result *= shadow;
				}
				//Ambient occlusion
				if (_useAmbientOcclusion){
					float ao = AmbientOcclusion(p, n);
					result *= ao;
				}
				//result = color * light * shadow * ao;

				return result;

			}


			fixed4 raymarching(float3 ro, float3 rd, float depth)
			{
				fixed4 result = fixed4(1, 1, 1, 1);
				const int max_iteration = _MaxIterations;
				float t = 0;//Distance travelled along the ray direction

				for (int i = 0; i < max_iteration; i++) {
					if (t > _maxDistance || t >= depth) {
						//Enivornment
						result = fixed4(rd, 0);
						break;
					 }

					float3 p = ro + rd * t;
					//check for hit in distancefield
					float d = distanceField(p);
					if (d < _Accuracy) {//We have hit something
						//shading
						float3 n = getNormal(p);
						float3 s = Shading(p, n);
						result = fixed4(s,1);
						break;
					}
					t += d;
				}



				return result;
			}


			fixed4 frag(v2f i) : SV_Target
			{
				float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
				depth *= length(i.ray);
				fixed3 col = tex2D(_MainTex, i.uv);
				float3 rayDirection = normalize(i.ray.xyz);
				float3 rayOrigin = _WorldSpaceCameraPos;
				fixed4 result = raymarching(rayOrigin, rayDirection, depth);

				return fixed4(col * (1.0 - result.w) + result.xyz * result.w, 1.0);
			}
			ENDCG
		}
	}
}
