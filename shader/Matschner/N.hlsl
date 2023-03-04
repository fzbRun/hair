#ifndef N_INCLUDED
#define N_INCLUDED

float3 fresnelSchlick(float cosTheta)
{
    float F0 = 0.0465f;
    return F0 + (1.0 - F0) * pow(1.0 - saturate(cosTheta), 5.0);
}

float3 getAtt(float cosTheta, float phi, float3 color, float eccentricity) {

    float RefractionParameter = 1.55f;
    RefractionParameter = 1.19f / cosTheta + 0.36f * cosTheta;
    float a = rcp(RefractionParameter);

    //偏心率近似(感觉我这个例子完全没影响）
    /*
    float RefractionParameter1 = 2.0f * (RefractionParameter - 1.0f) * pow(eccentricity, 2) - RefractionParameter + 2.0f;
    float RefractionParameter2 = 2.0f * (RefractionParameter - 1.0f) * pow(eccentricity, -2) - RefractionParameter + 2.0f;
    RefractionParameter = 0.5f * ((RefractionParameter1 + RefractionParameter2) + cos(2.0f * phi) * (RefractionParameter1 + RefractionParameter2));
    */

    float htt = cos(phi * 0.5f) * (1.0f + a * (0.6f - 0.8f * cos(phi)));
    float projectionCosTheta = cosTheta * sqrt(saturate(1.0f - htt * htt));

    float Ftt = pow(1.0f - fresnelSchlick(projectionCosTheta), 2);
    
    float power = sqrt(1.0f - htt * htt * a * a) / (2.0f * cosTheta);
    float3 Ttt = pow(color, power);

    return Ftt * Ttt;

}

//UE4近似
float3 getAtrt(float cosTheta, float3 color) {

    float Ftrt = fresnelSchlick(cosTheta * 0.5f);   //0.5f = sqrt(1.0f - 3/4); 3/4 = pow(sqrt(3)/2, 2)
    Ftrt = pow(1.0f - Ftrt, 2) * Ftrt;

    float power = 0.8f / cosTheta;
    float3 Ttrt = pow(color, power);

    return Ftrt * Ttrt;

}

float getDtt(float cosPhi) {
    float power = -3.65f * cosPhi - 3.98f;
    return exp(power);
}

float getDtrt(float cosPhi) {
    float power = 17.0f * cosPhi - 16.78f;
    return exp(power);
}

float3 getNr(float phi) {
    return 0.25f * cos(phi * 0.5f);
}

float3 getNtt(float cosTheta, float phi, float3 color, float eccentricity) {
    return 0.5f * getAtt(cosTheta, phi, color, eccentricity) * getDtt(cos(phi));
}

float3 getNtrt(float cosTheta, float phi, float3 color) {

    return 0.5f * getAtrt(cosTheta, color) * getDtrt(cos(phi));
}

#endif