#ifndef M_INCLUDED
#define M_INCLUDED

//计算M项，高斯函数
float getM(float roughness, float Theta) {
	return exp(-0.5f * Theta * Theta / (roughness * roughness)) / (2.50663f * roughness);
}

//第一贝塞尔修正函数
float bessi0(float x)
{
	float ax, ans;
	float y;

	if ((ax = abs(x)) < 3.75) {
		y = x / 3.75, y = y * y;
		ans = 1.0 + y * (3.5156229 + y * (3.0899424 + y * (1.2067492
			+ y * (0.2659732 + y * (0.360768e-1 + y * 0.45813e-2)))));
	}
	else {
		y = 3.75 / ax;
		ans = (exp(ax) / sqrt(ax)) * (0.39894228 + y * (0.1328592e-1
			+ y * (0.225319e-2 + y * (-0.157565e-2 + y * (0.916281e-2
				+ y * (-0.2057706e-1 + y * (0.2635537e-1 + y * (-0.1647633e-1
					+ y * 0.392377e-2))))))));
	}
	return ans;
}

float getWetaM(float roughness, float ThetaLi, float ThetaLr) {
	
	float v = roughness * roughness;
	float I0 = bessi0(cos(ThetaLi) * cos(ThetaLr) / v);
	return (1.0f / (v * exp(2.0f / v)) * exp((1.0f - sin(ThetaLi) * sin(ThetaLr) / v))) * I0;

}

#endif