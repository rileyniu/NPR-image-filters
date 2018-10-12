Shader "Custom/Pencil"
{
	
    Properties
    {
        _MainTex ("Base (RGB), Alpha (A)", 2D) = "black" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _TextureSizeX ("_TextureSizex",Float) = 256
        _TextureSizeY ("_TextureSizey",Float) = 256
        _NoiseTex ("Noise Texture", 2D) = "black" {}
        _PaperTex ("Paper Texture", 2D) = "black" {}
    }
    
    SubShader
    {

        Pass
        {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag            
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _NoiseTex;
            sampler2D _PaperTex;
            float _TextureSizeX;
            float _TextureSizeY;

            struct appdata_t
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                fixed4 color : COLOR;
            };
            
            struct v2f
            {
                float4 vertex : SV_POSITION;
                half2 uv : TEXCOORD0;
                fixed4 color : COLOR;
            };
            
            v2f vert (appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.color = v.color;
                return o;
            }

            float3 GaussianBlur(float2 uv){
                fixed3 color = fixed3(0,0,0);
                fixed3 grayFactor = fixed3(.299, .587, .114);
                float2 size = float2(_TextureSizeX, _TextureSizeY);
                color +=1*( 1- dot((tex2D(_MainTex, uv+float2(-1, -1)/size)).rgb, grayFactor));
                color +=2*( 1- dot((tex2D(_MainTex, uv+float2(0, -1)/size)).rgb, grayFactor));
                color +=1*( 1- dot((tex2D(_MainTex, uv+float2(1, -1)/size)).rgb, grayFactor));
                color +=2*( 1- dot((tex2D(_MainTex, uv+float2(-1, 0)/size)).rgb, grayFactor));
                color +=4*( 1- dot((tex2D(_MainTex, uv)).rgb, grayFactor));
                color +=2*( 1- dot((tex2D(_MainTex, uv+float2(1, 0)/size)).rgb, grayFactor));
                color +=1*( 1- dot((tex2D(_MainTex, uv+float2(-1, 1)/size)).rgb, grayFactor));
                color +=2*( 1- dot((tex2D(_MainTex, uv+float2(0, 1)/size)).rgb, grayFactor));
                color +=1*( 1- dot((tex2D(_MainTex, uv+float2(1, 1)/size)).rgb, grayFactor));
                
                return color/16.5;
            }

            // This is simple pencil sketch effect is based on most popular algorithm implemented in Matlab or C++
            fixed4 frag (v2f IN) : COLOR
            {

               	float4 renderTex = tex2D(_MainTex, IN.uv);
                float4 paper = tex2D(_PaperTex, IN.uv);
                float4 noiseTex = tex2D(_NoiseTex, IN.uv);
                // Obtain grayscale pixel
		        fixed3 grayFactor = fixed3(.299, .587, .114);
                float grayValue = dot(renderTex.rgb, grayFactor); 
                // Invert grayscale 
                float invGray = 1 - grayValue;
                // Perform Gaussian blur
                float3 final_color= GaussianBlur(IN.uv)*.95;

                // blend color
                float f =  min(grayValue + grayValue * final_color.r/(1.0-final_color.r) , 1);
                f = float4(f, f, f,1);
                f = lerp(f, grayValue, .1);

                // add sketch noise
                if (f<.9){
                    f = lerp(f, noiseTex, 0.2); 
                }
                
		        return f;
            }
            ENDCG
        }
    }

    
}
