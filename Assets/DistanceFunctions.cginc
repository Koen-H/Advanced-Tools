//For signedDistance functions, I used this as my source:
// https://iquilezles.org/articles/distfunctions/


// Sphere
// s: radius
float sdSphere(float3 p, float s)
{
	return length(p) - s;
}
// (Infinite) Plane
// n.xyz: normal of the plane (normalized).
// n.w: offset
float sdPlane(float3 p, float4 n) 
{
	//n must be normalized
	return dot(p, n.xyz) + n.w;
}

float sdTorus(float3 p, float2 t)
{
	float2 q = float2(length(p.xz) - t.x, p.y);
	return length(q) - t.y;
}

// Box
// b: size of box in x/y/z
float sdBox(float3 p, float3 b)
{
	float3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) +
		length(max(d, 0.0));
}

// Rounded Box
float sdRoundBox(float3 p, float3 b, float r) {
	float3 q = abs(p) - b;
	return min(max(q.x, max(q.y, q.z)), 0.0) + length(max(q, 0.0)) - r;
}

// Hexagonal Prism - exact
float sdHexPrism(float3 p, float2 h)
{
	const float3 k = float3(-0.8660254, 0.5, 0.57735);
	p = abs(p);
	p.xy -= 2.0 * min(dot(k.xy, p.xy), 0.0) * k.xy;
	float2 d = float2(
		length(p.xy - float2(clamp(p.x, -k.z * h.x, k.z * h.x), h.x)) * sign(p.y - h.x),
		p.z - h.y);
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}



// BOOLEAN OPERATORS //

// Union
float opU(float d1, float d2)
{
	return min(d1, d2);
}

// Subtraction
float opS(float d1, float d2)
{
	return max(-d1, d2);
}

// Intersection
float opI(float d1, float d2)
{
	return max(d1, d2);
}

// SMOOTH BOOLEAN OPERATORS

float opUS(float d1, float d2, float k) {
	float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
	return lerp(d2, d1, h) - k * h * (1.0 - h);
}

float opSS(float d1, float d2, float k) {
	float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
	return lerp(d2, -d1, h) + k * h * (1.0 - h);
}

float opIS(float d1, float d2, float k) {
	float h = clamp(0.5 - 0.5 * (d2 - d1) / k, 0.0, 1.0);
	return lerp(d2, d1, h) + k * h * (1.0 - h);
}




// Mod Position Axis
float pMod1 (inout float p, float size)
{
	float halfsize = size * 0.5;
	float c = floor((p+halfsize)/size);
	p = fmod(p+halfsize,size)-halfsize;
	p = fmod(-p+halfsize,size)-halfsize;
	return c;
}


//Mandelbulb RUN WITHOUT SHADING
float mandelbulbSDF(float3 p, float power, int iterations)
{
	float3 z = p;
	float dr = 1.0;
	float r = 0.0;
	for (int i = 0; i < iterations; i++) {
		r = length(z);
		if (r > 2.0) break;
		float theta = acos(z.z / r);
		float phi = atan2(z.y, z.x);
		dr = pow(r, power - 1.0) * power * dr + 1.0;
		float zr = pow(r, power);
		theta = theta * power;
		phi = phi * power;
		z = zr * float3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
		z += p;
	}
	return 0.5 * log(r) * r / dr;
}


float displacement(float3 p) {
	float disp = sin(20.0 * p.x) * sin(20.0 * p.y) * sin(20.0 * p.z);
	return disp;
}

float opTwist(in float3 p)
{
	const float k = 9; // or some other amount
	float c = cos(k * p.y);
	float s = sin(k * p.y);
	float2x2 m = float2x2(c, -s, s, c);
	float3 q = float3(mul(m, float2(p.xz)), p.y);
	return sdBox(p, 1);;//Change the sdf
}