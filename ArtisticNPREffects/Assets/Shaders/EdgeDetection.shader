// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/EdgeDetection" {
	Properties {
		_MainTex ("MainTex", 2D) = "white" {}
		_Color ("color", Color) = (1, 1, 1, 1)
		_SizeX("ResolutionX", range(1,2048)) = 256
		_SizeY("ResolutionY", range(1,2048)) = 256
		_PageTex ("Page Texture", 2D) = "whtie" {}
		_Threshold1("Threshold1", Range(0, 5)) = 0.5
		_Threshold2("Threshold2", Range(0, 5)) = 0.5
		
	}
	SubShader {
		
		
		pass{
		
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"
		#include "CannyFunctions.cginc"
 
		float _SizeX;
		float _SizeY;
		fixed4 _Color;
		float _Threshold1;
		float _Threshold2;
		sampler2D _MainTex;
		sampler2D _PageTex;
		float4 _PageTex_ST;
		float4 _MainTex_ST;

		struct v2f {
			float4 pos:SV_POSITION;
			float2 uv_MainTex:TEXCOORD0;
			
		};
 
		v2f vert (appdata_full v) {
			v2f o;
			o.pos=UnityObjectToClipPos(v.vertex);
			o.uv_MainTex = TRANSFORM_TEX(v.texcoord,_MainTex);
			return o;
		}
		
		float4 frag(v2f i):COLOR
		{
			// Edge detection with sobel filter only
			// Simple. Detects edges and their orientation/ Inaccurate and sensitive to nosie 
			float2 sobel = sobelGradient(_MainTex, i.uv_MainTex, float2(_SizeX, _SizeY));
			float final = 1-abs(length(sobel));
			

			// Edge detection with Canny's algorithm, Gaussian filter is not included

			// Smoothing effect to remove noise. Good localization and response. Enhances signal to
			// noise ratio. Immune to noisy environment. / Extremely costly

			// Line thining, suppress non-maximum pixels to zero
			float2 gradient = nonMaxSuppression(_MainTex, i.uv_MainTex, float2(_SizeX, _SizeY));
			// Double threshhold
			float edge = applyDoubleThreshold(gradient, _Threshold1, _Threshold2);
			// Strong & weak pixel tests
			 if (edge == .5) {
				edge = applyHysteresis(
				_MainTex, i.uv_MainTex, float2(_SizeX, _SizeY),  _Threshold1, _Threshold2);
			}
			//float final = 1- abs(edge);

			float4 pageCol = tex2D(_PageTex, i.uv_MainTex) * _Color;
			return lerp(final, final * pageCol, 0.9);
		}
		ENDCG
		}//
 
	} 
}
