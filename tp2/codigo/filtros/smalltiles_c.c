
#include "../tp2.h"

void smalltiles_c (unsigned char *src, unsigned char *dst, int cols, int filas, int src_row_size, int dst_row_size) {
	
	unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
	unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;
	
	int m_c = cols/2;  //mitad de columnas
	int m_f	= filas/2; //mitad de filas
	int f;
	int c;
	for (f = 0; f < filas/2; f++) {
		for (c = 0; c < cols/2; c++) {
			bgra_t *p_d_1 = (bgra_t*) &dst_matrix[f][c * 4];
			bgra_t *p_s = (bgra_t*) &src_matrix[2*f][c * 8];

			p_d_1->b = p_s->b;
			p_d_1->g = p_s->g;
			p_d_1->r = p_s->r;
			p_d_1->a = p_s->a;
			
			bgra_t *p_d_2 = (bgra_t*) &dst_matrix[f][(c+m_c)*4];
			p_d_2->b = p_s->b;
			p_d_2->g = p_s->g;
			p_d_2->r = p_s->r;
			p_d_2->a = p_s->a;
			
			bgra_t *p_d_3 = (bgra_t*) &dst_matrix[f + m_f][c * 4];
			p_d_3->b = p_s->b;
			p_d_3->g = p_s->g;
			p_d_3->r = p_s->r;
			p_d_3->a = p_s->a;
			
			bgra_t *p_d_4 = (bgra_t*) &dst_matrix[f + m_f][(c+m_c)*4];
			p_d_4->b = p_s->b;
			p_d_4->g = p_s->g;
			p_d_4->r = p_s->r;
			p_d_4->a = p_s->a;

		}
	}
	
	/*for (int f = 0; f < filas; f++) {
		for (int c = 0; c < cols; c++) {
			bgra_t *p_d = (bgra_t*) &dst_matrix[f][c * 4];
            bgra_t *p_s = (bgra_t*) &src_matrix[f][c * 4];

			p_d->b = p_s->b;
			p_d->g = p_s->g;
			p_d->r = p_s->r;
			p_d->a = p_s->a;

		}
	}*/
	
}
