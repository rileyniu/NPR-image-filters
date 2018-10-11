Shader "Custom/ColorSketch"
{
	
    Properties
    {
        _MainTex ("Base (RGB), Alpha (A)", 2D) = "black" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _SketchTex ("Sketch Texture", 2D) = "black" {}
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
            sampler2D _SketchTex;
            sampler2D _PaperTex;
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

            fixed4 feather(float2 uv, float thresh, float4 originCol){

                float dx = uv.x - .5;
                float dy = uv.y - .5;
                float distanceSq = dx * dx + dy * dy;
                float v = distanceSq / thresh;
                float r = clamp(originCol.r + v, 0, 1);
                float g = clamp(originCol.g + v, 0, 1);
                float b = clamp(originCol.b + v, 0, 1);
                return fixed4(r, g, b, 1);
            }
            
            fixed4 frag (v2f IN) : COLOR
            {
                float4 paper = tex2D(_PaperTex, IN.uv);
                
                float4 col = tex2D(_MainTex, IN.uv)* _Color;
                col = feather(IN.uv, _Threshold1 * .7, col);
                float4 mask = tex2D(_SketchTex, IN.uv);
                mask = feather(IN.uv,_Threshold1 *1.1, mask);
                float4 final = col;
                // Mix the sketch texture and original image
                final = lerp(col,.8*(mask +col),_Intensity);
                // Add paper texture
                return lerp(final, saturate(final)*paper, .8);
            }
            ENDCG
        }
    }

    
}
