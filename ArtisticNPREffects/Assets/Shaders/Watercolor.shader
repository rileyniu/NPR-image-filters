
Shader "Custom/Watercolor"
{
Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_TextureSize ("_TextureSize",Float) = 256
		_PaperTexture("_Paper Texture", 2D) = "white" {}
		// Edge wobbling noise textures, using low-frequency fractal Perlin noise
		_NoiseTex1("Edge Wobbling NoiseTex", 2D) = "white" {}
		_NoiseTex2("Edge Wobbling NoiseTex", 2D) = "white" {}
		_TurbulentFlowMap("Turbulent Flow Map", 2D) = "white" {}
		_Distortion("Distortion", Range(0,0.1)) = 0.005
		_PigmentDensity("Pigment Density", Range(0, 5)) = 1
		_WaterEffect("WaterEffect", Range(0, 5)) = 0.5
         _Granulation ("Granulation",Range(0,5) ) = 1
	}

	SubShader
	{
		Pass
		{
			CGPROGRAM
			#define SIGMA 30.0
			#define BSIGMA 0.2 //reduce contrast
			#define MSIZE 30
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

		 sampler2D _MainTex;
		 sampler2D _PaperTexture;
		 sampler2D _NoiseTex1;
		 sampler2D _NoiseTex2;
		 sampler2D _TurbulentFlowMap;
		 float _TextureSize;
		 float _Distortion;
		 float _WaterEffect;
		 float _PigmentDensity;
		 float _Granulation;


		// Image abstraction with bilateral filter
		float normpdf(float x, float sigma){
			return 0.39894 * exp(-.5 * x * x/(sigma * sigma))/sigma; 
		}

		float normpdf3(float3 x, float sigma){
			return 0.39894 * exp(-.5 * dot(x, x)/(sigma * sigma))/sigma;
		}
		
		float3 bilateralFilter(float3 c, float2 uv){

			float3 col = c;
			half kSize = (MSIZE - 1)/2;
			float kernel[MSIZE];
			float3 finalCol = 0;

			float space = 1.0/_TextureSize; 

			// Compute the kernel
			float Z = 0;
			for (int j = 0; j<=kSize; j++){
				kernel[kSize+j] = kernel[kSize -j] = normpdf(j, SIGMA);
			}

			float3 tempColor;
			float factor;
			float bZ = 1.0/normpdf(0.0, BSIGMA);
			//read out the texels
			for (int i=-kSize; i <= kSize; ++i)
			{
				for (int j=-kSize; j <= kSize; ++j)
				{	
					tempColor = tex2D(_MainTex, (uv +float2(i * space, j* space))).rgb;
					factor = normpdf3(tempColor-col, BSIGMA)*bZ*kernel[kSize+j]*kernel[kSize+i];
					Z += factor;
					finalCol += factor*tempColor;

				}
			}
			return finalCol/Z;
		}


		// Edge detection based on Sobel operator, returns the intensity value
		float edgeDetection(float2 uv){

			float3 lum = float3(0.2125,0.7154,0.0721);
			float mc00 = dot(tex2D (_MainTex,uv-fixed2(1,1)/_TextureSize).rgb, lum);
			float mc10 = dot(tex2D (_MainTex,uv-fixed2(0,1)/_TextureSize).rgb, lum);
			float mc20 = dot(tex2D (_MainTex,uv-fixed2(-1,1)/_TextureSize).rgb, lum);
			float mc01 = dot(tex2D (_MainTex,uv-fixed2(1,0)/_TextureSize).rgb, lum);
			float mc11mc = dot(tex2D (_MainTex,uv).rgb, lum);
			float mc21 = dot(tex2D (_MainTex,uv-fixed2(-1,0)/_TextureSize).rgb, lum);
			float mc02 = dot(tex2D (_MainTex,uv-fixed2(1,-1)/_TextureSize).rgb, lum);
			float mc12 = dot(tex2D (_MainTex,uv-fixed2(0,-1)/_TextureSize).rgb, lum);
			float mc22 = dot(tex2D (_MainTex,uv-fixed2(-1,-1)/_TextureSize).rgb, lum);
			
			// intensity on x and y direction
			float GX = -1 * mc00 + mc20 + -2 * mc01 + 2 * mc21 - mc02 + mc22;
			float GY = mc00 + 2 * mc10 + mc20 - mc02 - 2 * mc12 - mc22;
			float result = length(float2(GX,GY));//length的内部算法就是灰度公式的算法，欧几里得长度
			return result;
		}
	


		fixed4 frag (v2f IN) : SV_Target
		{
			float3 finalCol;
			
			// Edge wobbling: High-frequency boundary distortion due to rough paper surface;
			float2 noise1 = tex2D(_NoiseTex1, IN.uv)* _Distortion;
			float2 noise2 = tex2D(_NoiseTex2, IN.uv)* _Distortion;
			float2 newUV = 	IN.uv+noise1-noise2;

			// Edge detection
			float intensity = edgeDetection(newUV);
			float3 color = tex2D(_MainTex, newUV);

			// Image abstraction
			finalCol = bilateralFilter(color, newUV);

			// Turbulence flow: Low-frequency pigment separation due to uneven water density.
			float turbFlowNoise = tex2D(_TurbulentFlowMap, IN.uv);
			float density = 1 + _WaterEffect * (turbFlowNoise - 0.1);
			finalCol = finalCol - (finalCol - finalCol *finalCol) * (density - 1.5);

			// Edge darkening 
			float d = 1 + _PigmentDensity *(intensity - 0.5);
			finalCol = finalCol - (finalCol - finalCol *finalCol) * (d - .5);
			
			// Paper granulation texture
			float paperTex = tex2D(_PaperTexture, IN.uv);
			float d2 = 1 + _Granulation *(paperTex - 0.5);
			finalCol = finalCol - (finalCol - finalCol *finalCol) * (d2 - 2);
			
			 return float4(finalCol,1);

		}
		ENDCG
		}
	}
}
