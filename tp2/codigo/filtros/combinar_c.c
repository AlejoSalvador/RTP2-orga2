
#include "../tp2.h"

float clamp(float pixel)
{
	float res = pixel < 0.0 ? 0.0 : pixel;
	return res > 255.0 ? 255 : res;
}

void invertir_img(int filas, int cols, int src_row_size, int dst_row_size, unsigned char (*src)[dst_row_size], unsigned char (*dst)[dst_row_size] ) {

	bgra_t *p_s, *p_d;
	for (int f = 0; f < filas; ++f) {
		for (int c = 0; c < cols; ++c) {
			p_s = (bgra_t*) &src[f][c * 4];
			p_d = (bgra_t*) &dst[f][(cols - c - 1) * 4];
			*p_d = *p_s;
		}
	}
}

void process_pixel(bgra_t *p_s, bgra_t *p_d, float ratio);

void combinar_c (
	unsigned char *src, 
	unsigned char *dst, 
	int cols, 
	int filas, 
	int src_row_size,
	int dst_row_size,
	float alpha
) {
	unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
	unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;

	invertir_img(filas, cols, src_row_size, dst_row_size, src_matrix, dst_matrix);

	float ratio = alpha / 255.0;

	bgra_t *p_s, *p_d;
	for (int f = 0; f < filas; ++f) {
		for (int c = 0; c < cols; ++c) {
			p_s = (bgra_t*) &src_matrix[f][c * 4];
			p_d = (bgra_t*) &dst_matrix[f][c * 4];
			process_pixel(p_s, p_d, ratio);
		}
	}
}

void process_pixel(bgra_t *p_s, bgra_t *p_d, float ratio) {
	p_d->b = ((p_s->b - p_d->b) * ratio) + p_d->b;
	p_d->g = ((p_s->g - p_d->g) * ratio) + p_d->g;
	p_d->r = ((p_s->r - p_d->r) * ratio) + p_d->r;
}