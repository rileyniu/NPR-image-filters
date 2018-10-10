
Shader "Custom/Gaussian"
{
Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		  _TextureSize ("_TextureSize",Float) = 256
        _BlurRadius ("_BlurRadius",Range(1,15) ) = 5

	}
	SubShader
	{

		Pass
		{
			CGPROGRAM


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
	 	int _BlurRadius;
        float _TextureSize;
			float GetGaussianDistribution( float x, float y, float rho ) {
				float g = 1.0f / sqrt( 2.0f * 3.141592654f * rho * rho );
				return g * exp( -(x * x + y * y) / (2 * rho * rho) );
			}

			float4 GetGaussBlurColor( float2 uv)
			{
				//算出一个像素的空间
				float space = 1.0/_TextureSize; 
				//参考正态分布曲线图，可以知道 3σ 距离以外的点，权重已经微不足道了。
				//反推即可知道当模糊半径为r时，取σ为 r/3 是一个比较合适的取值。
				float rho = (float)_BlurRadius * space / 3.0;

				//---权重总和
				float weightTotal = 0;
				for( int x = -_BlurRadius ; x <= _BlurRadius ; x++ )
				{
					for( int y = -_BlurRadius ; y <= _BlurRadius ; y++ )
					{
						weightTotal += GetGaussianDistribution(x * space, y * space, rho );
					}
				}


				float4 colorTmp = float4(0,0,0,0);
				for( int x = -_BlurRadius ; x <= _BlurRadius ; x++ )
				{
					for( int y = -_BlurRadius ; y <= _BlurRadius ; y++ )
					{
						float weight = GetGaussianDistribution( x * space, y * space, rho )/weightTotal;

						float4 color = tex2D(_MainTex,uv + float2(x * space,y * space));
						color = color * weight;
						colorTmp += color;
					}
				}
				return  colorTmp;
			}


			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				float4 grayscale = dot(col.rgb, float3(0.299,0.587,0.114));
				float4 invert = fixed4(1, 1, 1, 1) - grayscale;
				float4 blur = GetGaussBlurColor(i.uv);
				//blur = fixed4(1, 1, 1, 1) -dot(blur.rgb, float3(0.299,0.587,0.114))
				//blur = min ( grayscale * (1 / (1-blur)) , 1.0 );

				return blur;
			}
			ENDCG
		}
	}
}
