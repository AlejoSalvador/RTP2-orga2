section .data
DEFAULT REL

section .data
const_unos db 	0xff,0xff,0xff,0xff,	0xff,0xff,0xff,0xff,	0xff,0xff,0xff,0xff,	0xff,0xff,0xff,0xff ;
filtro1 db 		0xff,0xff,0xff,0xff,	0x00,0x00,0x00,0x00,	0x00,0x00,0x00,0x00,	0x00,0x00,0x00,0x00
cfloat: dd 1.0
cfloatn: dd -1.0
; void colorizar_asm (
; 	unsigned char *src,
; 	unsigned char *dst,
; 	int cols,
; 	int filas,
; 	int src_row_size,
; 	int dst_row_size,
;   float alpha
; );

; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = cols
; 	rcx = filas
; 	r8 = src_row_size
; 	r9 = dst_row_size
;   xmm0 = alpha


global colorizar_asm


section .text

colorizar_asm:
push rbp
mov rbp, rsp
push r12
push r13
push r14
push rbx

movsxd rax, edx		;rax: w
;movdqu xmm12, xmm0
sub rcx, 2
sub rax, 2

;inc rsi				;dejo los bordes en negro
mov r10, rdi
mov r11, rsi

pxor xmm11, xmm1
pxor xmm12, xmm12
movdqu xmm8, [const_unos]	;xmm6 = ||
movdqu xmm9, [filtro1]
movdqu xmm11, [cfloat]
movdqu xmm12, [cfloatn]		
pxor xmm7, xmm7 

ciclo_filas:
	cmp rcx, 0
	je fin
	mov rdi, r10
	mov rsi, r11
	mov rdx, rax
	add rsi, r9
	add rsi, 4
	;sar rcx, 2			;proceso de a 4 pixeles
		; si se considera la siguiente matriz:
		;		| pixel1 | pixel2 | pixel3 |
		;		| pixel4 | pixel5 | pixel6 |
		;		| pixel7 | pixel8 | pixel9 |
	ciclo_columnas:		;proceso de a 9 pixeles para obtener 1 en la imagen destino
		; xmm0, xmm1 y xmm2 van a guardar las tres filas de la matriz que contienen los pixeles
		movdqu xmm1, [rdi]		;xmm1 = | ---- | pixel3 | pixel2 | pixel1 |
		movdqu xmm2, [rdi+r8]	;xmm2 = | ---- | pixel6 | pixel5 | pixel4 |
		movdqu xmm3, [rdi+r8*2]	;xmm3 = | ---- | pixel9 | pixel8 | pixel7 |
					
		movdqu xmm4, xmm1		;xmm4 = | --- | a3,r3,g3,b3 | a2,r2,g2,b2 | a1,r1,g1,b1 | 
		punpcklbw xmm4, xmm7	;xmm4 = |0a2|0r2|0g2|0b2|0a1|0r1|0g1|0b1|
		pslldq xmm1, 4			;	
		psrldq xmm1, 12			;xmm1 = | 0000 | 0000 | 0000 | a3,r3,g3,b3 |
		punpcklbw xmm1, xmm7	;xmm1 = |00|00|00|00|0a3|0r3|0g3|0b3|
		movdqu xmm5, xmm4
		pcmpgtw xmm5, xmm1		; xmm5 = el resultado de la comparacion
		pand xmm4, xmm5
		pxor xmm5, xmm8			;invierto los bits del resultado
		pand xmm1, xmm5			;el resultado de ls componentes mayores entre pixeles 1,2 y 3
		por	xmm1, xmm4			; xmm1 = |0a|0r|0g|0b|0a|0r|0g|0b|
		
		movdqu xmm6, xmm2		;guardo la segunda fila
		
		movdqu xmm4, xmm2		;xmm4 = | --- | a6,r6,g6,b6 | a5,r5,g5,b5 | a4,r4,g4,b4 | 
		punpcklbw xmm4, xmm7	;xmm4 = |0a5|0r5|0g5|0b5|0a4|0r4|0g4|0b4|
		pslldq xmm2, 4			;	
		psrldq xmm2, 12			;xmm2 = | 0000 | 0000 | 0000 | a6,r6,g6,b6 |
		punpcklbw xmm2, xmm7	;xmm2 = |00|00|00|00|0a6|0r6|0g6|0b6|
		movdqu xmm5, xmm4
		pcmpgtw xmm5, xmm2		; xmm5 = el resultado de la comparacion
		pand xmm4, xmm5
		pxor xmm5, xmm8			;invierto los bits del resultado
		pand xmm2, xmm5			;el resultado de los componentes mayores entre pixeles 4,5 y 6
		por	xmm2, xmm4			;xmm2 = |0a|0r|0g|0b|0a|0r|0g|0b|
		
		movdqu xmm5, xmm1
		pcmpgtw xmm5, xmm2		; xmm5 = el resultado de la comparacion
		pand xmm1, xmm5
		pxor xmm5, xmm8			;invierto los bits del resultado
		pand xmm2, xmm5			;el resultado de los componentes mayores entre pixeles 1,2,3,4,5 y 6
		por xmm1, xmm2			; xmm1 = |0a|0r|0g|0b|0a|0r|0g|0b|
								
		movdqu xmm4, xmm3		;xmm4 = | --- | a6,r6,g6,b6 | a5,r5,g5,b5 | a4,r4,g4,b4 | 
		punpcklbw xmm4, xmm7	;xmm4 = |0a8|0r8|0g8|0b8|0a7|0r7|0g7|0b7|
		pslldq xmm3, 4			;	
		psrldq xmm3, 12			;xmm3 = | 0000 | 0000 | 0000 | a6,r6,g6,b6 |
		punpcklbw xmm3, xmm7	;xmm3 = |00|00|00|00|0a6|0r6|0g6|0b6|
		movdqu xmm5, xmm4
		pcmpgtw xmm5, xmm3		; xmm5 = el resultado de la comparacion
		pand xmm4, xmm5
		pxor xmm5, xmm8			;invierto los bits del resultado
		pand xmm3, xmm5			;el resultado de los componentes mayores entre pixeles 7,8 y 9
		por xmm3, xmm4			;xmm3 = |0a|0r|0g|0b|0a|0r|0g|0b|
		
		movdqu xmm5, xmm1
		pcmpgtw xmm5, xmm3		; xmm5 = el resultado de la comparacion
		pand xmm1, xmm5
		pxor xmm5, xmm8			;invierto los bits del resultado
		pand xmm3, xmm5			;el resultado de los componentes mayores entre pixeles 1,2,3,4,5,6,7,8 y 9
		por xmm1, xmm3			; xmm1 = |0a|0r|0g|0b|0a|0r|0g|0b|
		
		movdqu xmm2, xmm1		;
		punpcklwd xmm1, xmm7	;xmm1 = |000a|000r|000g|000b|
		
		punpckhwd xmm2, xmm7	;xmm2 = |000a|000r|000g|000b|
		movdqu xmm5, xmm1
		pcmpgtw xmm5, xmm2		; xmm5 = el resultado de la comparacion
		pand xmm1, xmm5
		pxor xmm5, xmm8			;invierto los bits del resultado
		pand xmm2, xmm5			;el resultado de los componentes mayores entre pixeles 1,2,3,4,5,6,7,8 y 9 esta en xmm1
		por xmm1, xmm2			; xmm1 = |max_a|max_r|max_g|max_b|						
		
		movdqu xmm2, xmm1		;
		movdqu xmm3, xmm1
		pand xmm1, xmm9			;xmm1 = |0000|0000|0000|maxb|
		psrldq xmm2, 4		
		pand xmm2, xmm9			;xmm2 = |0000|0000|0000|maxg|
		psrldq xmm3, 8
		pand xmm3, xmm9			;xmm3 = |0000|0000|0000|maxr|
		; aplico las funciones fi con cada componente
		movq r12, xmm1		;r12 = el maximo b
		movq r13, xmm2		;r13 = el maximo g
		movq r14, xmm3		;r14 = el maximo r
		movdqu xmm1, xmm0
		call fi_b
		movdqu xmm2, xmm0 
		call fi_g
		movdqu xmm3, xmm0
		call fi_r
		;obtengo el pixel_5 
		
		pslldq xmm6, 8
		psrldq xmm6, 12			;xmm6 = |0000|0000|0000|pixel_5| 
		punpcklbw xmm6, xmm7 	;xmm6 = |0000|0000|0a0r|0g0b|
		punpcklwd xmm6, xmm7 	;xmm6 = |000a|000r|000g|000b|
		
		movdqu xmm4, xmm6		; 		
		movdqu xmm5, xmm6
		pand xmm4, xmm9			; xmm2 = |0000|0000|0000|000b|
		psrldq xmm5, 4
		pand xmm5, xmm9		; xmm5 = |0000|0000|0000|000g|
		psrldq xmm6, 8
		pand xmm6, xmm9		; xmm6 = |0000|0000|0000|000r|
		cvtdq2ps xmm4, xmm4 	; xmm2 = | float(pixel_5_b) |
		cvtdq2ps xmm5, xmm5 	; xmm5 = | float(pixel_5_g) |
		cvtdq2ps xmm6, xmm6 	; xmm6 = | float(pixel_5_r) |
		;resumiendo xmm1=fi_b,  xmm2=fi_g,  xmm3=fi_r
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		mulps xmm1, xmm4		;xmm1 = fi_b* pixel_5_b
		mulps xmm2, xmm5		;xmm2 = fi_g* pixel_5_g
		mulps xmm3, xmm6		;xmm3 = fi_r* pixel_5_r
		cvtps2dq xmm1, xmm1 	; xmm1 = | b |
		cvtps2dq xmm2, xmm2 	; xmm2 = | g |
		cvtps2dq xmm3, xmm3 	; xmm3 = | r |
		pslldq xmm1, 12
		psrldq xmm1, 12
		pslldq xmm2, 12
		psrldq xmm2, 8
		pslldq xmm3, 12
		pslldq xmm3, 4
		por xmm1, xmm2
		por xmm1, xmm3		;xmm1 = |0000|000r|000g|000b
		
		packusdw xmm1, xmm7 	; xmm1 = |0000| 0000| 000r| 0g0b |
		packuswb xmm1, xmm7		; xmm1 = |0000|0000|0000|0rgb|
		movq rbx, xmm1
		mov [rsi], ebx
		
		add rdi, 4
		add rsi, 4
		dec rdx
		cmp rdx, 0
		jne ciclo_columnas
		
		
	
	.seguir:
	dec rcx
	lea r10, [r10+r8]
	lea r11, [r11+r9]
	jmp ciclo_filas
	
	fin:
	pop rbx
	pop r14
	pop r13
	pop r12
	pop rbp
	ret


fi_b:
	cmp r14, r12
	jge .no_3
	cmp r13, r12
	jge .no_3
	addps xmm1, xmm11
	jmp .fin_b
	.no_3:
	mulps xmm1, xmm12
	addps xmm1, xmm11 
	.fin_b:
	ret
	

fi_r:
	cmp r14, r13
	jl .no
	cmp r14, r12
	jl .no
	addps xmm3, xmm11
	jmp .fin_r
	.no:
	mulps xmm3, xmm12
	addps xmm3, xmm11
	.fin_r:
	ret
	
fi_g:
	cmp r14, r13
	jge .no_2
	cmp r13, r12
	jl .no_2
	addps xmm2, xmm11
	jmp .fin_g
	.no_2:
	mulps xmm2, xmm12
	addps xmm2, xmm11 
	.fin_g:
	ret