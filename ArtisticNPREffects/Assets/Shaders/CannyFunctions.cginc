// Helper functions for Canny edge detection
// Code is based on a glsl implementation: https://github.com/DCtheTall/glsl-canny-edge-detection

// Sobel operator: Get the gradient vector of given pixel 
float2 sobelGradient(sampler2D tex, float2 uv, float2 size){
    
    float3 lum = float3(0.2125,0.7154,0.0721);

    // dot with luminance to obtain grey-scale intensity image
    float mc00 = dot(tex2D (tex, uv-fixed2(1,1)/size).rgb, lum);
    float mc10 = dot(tex2D (tex, uv-fixed2(0,1)/size).rgb, lum);
    float mc20 = dot(tex2D (tex, uv-fixed2(-1,1)/size).rgb, lum);
    float mc01 = dot(tex2D (tex, uv-fixed2(1,0)/size).rgb, lum);
    float mc11mc = dot(tex2D (tex, uv).rgb, lum);
    float mc21 = dot(tex2D (tex, uv-fixed2(-1,0)/size).rgb, lum);
    float mc02 = dot(tex2D (tex, uv-fixed2(1,-1)/size).rgb, lum);
    float mc12 = dot(tex2D (tex, uv-fixed2(0,-1)/size).rgb, lum);
    float mc22 = dot(tex2D (tex, uv-fixed2(-1,-1)/size).rgb, lum);
    // Operators on x and y direction
    float GX = -1 * mc00 + mc20 + -2 * mc01 + 2 * mc21 - mc02 + mc22;
    float GY = mc00 + 2 * mc10 + mc20 - mc02 - 2 * mc12 - mc22;
    return float2(GX,GY);
}



// Rotate a 2D vector an angle (in degrees)
float2 rotate2D(float2 v, float rad) {
  float s = sin(rad);
  float c = cos(rad);
  //return float2x2(c, s, -s, c) * v;
  return float2(c* v.x + s*v.y, -s *v.x +c *v.y);
}


// Round v to the nearest vector of 8 cardinal directions
float2 round2DVectorAngle(float2 v){
    float len = length(v);
    float2 n = normalize(v);
    float maximum = -1.;
    float bestAngle;
    for (int i = 0; i < 8; i++) {
        float theta = (float(i) * 2. * 3.1415) / 8.;
        float2 u = rotate2D(float2(1, 0), theta);
        float scalarProduct = dot(u, n);
        if (scalarProduct > maximum) {
        bestAngle = theta;
        maximum = scalarProduct;
        }
    }
    return len * rotate2D(float2(1, 0), bestAngle);
}

// Return the texture intensity gradient of an image where the angle of the direction is rounded to
// one of the 8 cardinal directions and gradients that are not local extrema are zeroed out
float2 nonMaxSuppression(sampler2D tex, float2 uv, float2 size){
    float2 gradient = sobelGradient(tex, uv, size);
    gradient = round2DVectorAngle(gradient);
    float2 gradientStep = normalize(gradient) /size;
    float gradientLength = length(gradient);
    float2 gradientPlusStep = sobelGradient(tex, uv + gradientStep, size);
  if (length(gradientPlusStep) > gradientLength) return float2(0, 0);
  float2 gradientMinusStep = sobelGradient(tex, uv - gradientStep, size);
  if (length(gradientMinusStep) > gradientLength) return float2(0, 0);
  return gradient;
}

/**
 * Apply a double threshold to each edge to classify each edge
 * as a weak edge or a strong edge
 */
float applyDoubleThreshold(
  float2 gradient,
  float weakThreshold,
  float strongThreshold
) {
  float gradientLength = length(gradient);
  if (gradientLength < weakThreshold) return 0.;
  if (gradientLength < strongThreshold) return .5;
  return 1.;
}


float applyHysteresis(
  sampler2D tex,
  float2 uv,
  float2 size,
  float weakThreshold,
  float strongThreshold
) {
  float dx = 1. /size.x;
  float dy = 1. /size.y;
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
      float2 ds = float2(
        -dx + (float(i) * dx),
        -dy + (float(j) * dy));
      float2 gradient = nonMaxSuppression(
        tex, clamp(uv + ds, float2(0, 0), float2(1, 1)), size);
      float edge = applyDoubleThreshold(gradient, weakThreshold, strongThreshold);
      if (edge == 1.) return 1.;
    }
  }
  return 0.;
}
