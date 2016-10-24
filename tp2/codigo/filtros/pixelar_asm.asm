; void pixelar_asm (
; 	unsigned char *src,
; 	unsigned char *dst,
; 	int cols,
; 	int filas,
; 	int src_row_size,
; 	int dst_row_size
; );

; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = cols
; 	rcx = filas
; 	r8 = src_row_size
; 	r9 = dst_row_size

extern pixelar_c

global pixelar_asm

section .text

pixelar_asm:

  pxor xmm6, xmm6 ; seteo en 0, ya que lo utilizo para extender los pixeles

  ; iteraciones por columna
  mov r12, rdx
  shr r12, 2 ; cantidad de columnas / 4

  ; iteraciones por filas
  mov r13, rcx
  shr rcx, 1 ; cantidad de filas / 2

  .ciclo_fila:
    mov r13, rcx

    call procesar_fila

    lea rdi, [rdi + rdx * 4]
    lea rsi, [rsi + rdx * 4]

    mov rcx, r13

    loop .ciclo_fila

	ret

procesar_fila:
  mov rcx, r12

  .ciclo_col:
    movdqu xmm7, [rdi] ; |px11|px12|px21|px22|

    movdqu xmm1, xmm7
    punpcklbw xmm1, xmm6 ; |px11|px12|
    movdqu xmm2, xmm7
    punpckhbw xmm2, xmm6 ; |px21|px22|

    movdqu xmm7, [rdi + rdx * 4] ; |px13|px14|px23|px24|

    movdqu xmm3, xmm7
    punpcklbw xmm3, xmm6 ; |px13|px14|
    movdqu xmm4 , xmm7
    punpckhbw xmm4, xmm6 ; |px23|px24|

    paddw xmm1, xmm3 ; |px11 + px13|px12 + px14|
    paddw xmm2, xmm4 ; |px21 + px23|px22 + px24|

    movdqu xmm3, xmm1
    shufpd xmm3, xmm1, 00000001b ; |px12 + px14|px11 + px13|

    movdqu xmm4, xmm2
    shufpd xmm4, xmm2, 00000001b ; |px22 + px24|px21 + px23|

    paddd xmm1, xmm3 ; |px11 + px12 + px13 + px14|px11 + px12 + px13 + px14|
    paddd xmm2, xmm4 ; |px21 + px22 + px23 + px24|px21 + px22 + px23 + px24|

    psrlw xmm1, 2 ; |avrg(px1)|avrg(px1)|
    psrlw xmm2, 2 ; |avrg(px2)|avrg(px2)|

    packuswb xmm1, xmm2 ; |avrg(px1)|avrg(px1)|avrg(px2)|avrg(px2)|

    movdqu [rsi], xmm1
    movdqu [rsi + rdx * 4], xmm1

    add rdi, 16
    add rsi, 16

    loop .ciclo_col

  ret
