function transform:setX(x)
end


[[void Matrix4::setTransformation(float x, float y, float angle, float sx, float sy, float ox, float oy, float kx, float ky)
{
	memset(e, 0, sizeof(float)*16); // zero out matrix
	float c = cosf(angle), s = sinf(angle);
	// matrix multiplication carried out on paper:
	// |1     x| |c -s    | |sx       | | 1 ky    | |1     -ox|
	// |  1   y| |s  c    | |   sy    | |kx  1    | |  1   -oy|
	// |    1  | |     1  | |      1  | |      1  | |    1    |
	// |      1| |       1| |        1| |        1| |       1 |
	//   move      rotate      scale       skew       origin
	e[10] = e[15] = 1.0f;
	e[0]  = c * sx - ky * s * sy; // = a
	e[1]  = s * sx + ky * c * sy; // = b
	e[4]  = kx * c * sx - s * sy; // = c
	e[5]  = kx * s * sx + c * sy; // = d
	e[12] = x - ox * e[0] - oy * e[4];
	e[13] = y - ox * e[1] - oy * e[5];
}]]
