
#include "../tp2.h"

void reset_avrg (bgra16_t *avrg);
void sum_avrg (bgra16_t *avrg, bgra_t *p);
void calculate_avrg (bgra16_t *avrg, int ammt);
void copy_avrg (bgra16_t *avrg, bgra_t *p);

void pixelar_c (
	unsigned char *src, 
	unsigned char *dst, 
	int cols, 
	int filas, 
	int src_row_size, 
	int dst_row_size
) {
	unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
	unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;

	bgra16_t avrg;

	for (int f = 0; f < filas; f += 2) {
		for (int c = 0; c < cols; c += 2) {
			reset_avrg(&avrg);

			bgra_t *p_s;
			p_s = (bgra_t*) &src_matrix[f][c * 4];
			sum_avrg(&avrg, p_s);
			p_s = (bgra_t*) &src_matrix[f][(c+1) * 4];
			sum_avrg(&avrg, p_s);
			p_s = (bgra_t*) &src_matrix[f+1][c * 4];
			sum_avrg(&avrg, p_s);
			p_s = (bgra_t*) &src_matrix[f+1][(c+1) * 4];
			sum_avrg(&avrg, p_s);

			calculate_avrg(&avrg, 4);

			bgra_t *p_d;
			p_d = (bgra_t*) &dst_matrix[f][c * 4];
			copy_avrg(&avrg, p_d);
			p_d = (bgra_t*) &dst_matrix[f][(c+1) * 4];
			copy_avrg(&avrg, p_d);
			p_d = (bgra_t*) &dst_matrix[f+1][c * 4];
			copy_avrg(&avrg, p_d);
			p_d = (bgra_t*) &dst_matrix[f+1][(c+1) * 4];
			copy_avrg(&avrg, p_d);
		}
	}
}

void reset_avrg (bgra16_t *avrg) {
	avrg->b = 0;
	avrg->g = 0;
	avrg->r = 0;
	avrg->a = 0;
}

void sum_avrg (bgra16_t *avrg, bgra_t *p) {
	avrg->b += p->b;
	avrg->g += p->g;
	avrg->r += p->r;
	avrg->a += p->a;
}

void calculate_avrg (bgra16_t *avrg, int ammt) {
	avrg->b = avrg->b / ammt;
	avrg->g = avrg->g / ammt;
	avrg->r = avrg->r / ammt;
	avrg->a = avrg->a / ammt;
}

void copy_avrg (bgra16_t *avrg, bgra_t *p) {
	p->b = avrg->b;
	p->g = avrg->g;
	p->r = avrg->r;
	p->a = avrg->a;
}