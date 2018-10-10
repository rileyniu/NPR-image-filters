Shader "Custom/AgedEffect" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_PageTex("Page Texture", 2D) = "white" {}
		_NoiseTex("Noise Texture", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "white" {}
		_BumpAmt ("Distortion", Range(0,1)) = 0.5
		_EdgeColor("Dirt Color",Color) = (1,1,1,1)
		_EdgeRange("Dirt Range",Range(0,1)) = 0
		_DissolveFactor("DF", Range(0,0.5)) =  0.1
		_Power("Vignette Power", Range(0,1)) =  0.5
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Lambert addshadow

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _PageTex;
		sampler2D _BumpMap;
		sampler2D _NoiseTex;
		
		float _Power;
		fixed4 _Color;
		fixed4 _EdgeColor;
		float _EdgeRange;
		float _DissolveFactor;
		float _BumpAmt;

		struct Input {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;


		void surf (Input IN, inout SurfaceOutput o) {
			// Albedo comes from a texture tinted by color
			float3 normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
			normal.z /= _BumpAmt;
			o.Normal = normalize(normal);
		
			float2 dist = (IN.uv_MainTex - 0.5f) * 1.25f;
			dist.x = 1 - dot(dist, dist)  * _Power;

			fixed4 col = tex2D(_MainTex, IN.uv_MainTex) *_Color;

			fixed4 page = tex2D(_PageTex, IN.uv_MainTex);
			fixed3 noise = tex2D(_NoiseTex, IN.uv_MainTex)* dist.x;
			fixed DissolveFactor = _DissolveFactor ;
			col *= page;

			half dissolveClip = noise.g - _DissolveFactor;
			clip(dissolveClip);

			 float EdgeFactor = saturate((noise - DissolveFactor)/(_EdgeRange*DissolveFactor));
			 float4 BlendColor = col * _EdgeColor;
			 col = lerp(col, BlendColor, 1- EdgeFactor)* dist.x;
						
			o.Albedo = col.rgb;
			o.Alpha = col.a;
			//o.Albedo = fixed3(IN.uv_MainTex.x,0,0);
		}
		ENDCG
	}
	FallBack "Diffuse"
}
