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
        _Threshold1("Feather Effect", Range(0, 1)) = 0.5
        _Intensity("Sketch Effect", Range(0, 1)) = 0.5
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
            float4 _Color;
            float _Threshold1;
            float _Intensity;
            
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

            float3 boxBlur(float2 uv){
                fixed3 color = fixed3(0,0,0);
                fixed3 grayFactor = fixed3(.299, .587, .114);
                float2 size = float2(_TextureSizeX, _TextureSizeY);
                color += 1- dot((tex2D(_MainTex, uv+float2(-1, -1)/size)).rgb, grayFactor);
                color += 1- dot((tex2D(_MainTex, uv+float2(0, -1)/size)).rgb, grayFactor);
                color += 1- dot((tex2D(_MainTex, uv+float2(1, -1)/size)).rgb, grayFactor);
                color += 1- dot((tex2D(_MainTex, uv+float2(-1, 0)/size)).rgb, grayFactor);
                color += 1- dot((tex2D(_MainTex, uv)).rgb, grayFactor);
                color += 1- dot((tex2D(_MainTex, uv+float2(1, 0)/size)).rgb, grayFactor);
                color += 1- dot((tex2D(_MainTex, uv+float2(-1, 1)/size)).rgb, grayFactor);
                color += 1- dot((tex2D(_MainTex, uv+float2(0, 1)/size)).rgb, grayFactor);
                color += 1- dot((tex2D(_MainTex, uv+float2(1, 1)/size)).rgb, grayFactor);
                
                return 0.8*color/9.0;
            }

            fixed4 frag (v2f IN) : COLOR
            {

               	float4 renderTex = tex2D(_MainTex, IN.uv);
                float4 noiseTex = tex2D(_NoiseTex, IN.uv);
		        fixed3 grayFactor = fixed3(.299, .587, .114);
                float grayValue = dot(renderTex.rgb, grayFactor); 
                float invGray = 1 - grayValue;
                float3 final_color= boxBlur(IN.uv);
                // float f =  min(grayValue + grayValue * final_color.r/(1.0-final_color.r) , 1);
                // float f = min(final_color, invGray);
                float f = min ( grayValue * (1 / (1-final_color)) , 1.0 );
		        return float4(f, f, f,1) * noiseTex;
            }
            ENDCG
        }
    }

    
}
