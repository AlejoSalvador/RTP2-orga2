; void combinar_asm (
; 	unsigned char *src,
; 	unsigned char *dst,
; 	int cols,
; 	int filas,
; 	int src_row_size,
; 	int dst_row_size,
; 	float alpha
; );

; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = cols
; 	rcx = filas
; 	r8 = dst_row_size
; 	r9 = dst_row_size
; 	xmm0 = alpha

global combinar_asm

extern combinar_c

section .data:
  mask:
    db 0x0C,0x0D,0x0E,0x0F, ; px4
    db 0x08,0x09,0x0A,0x0B, ; px3
    db 0x04,0x05,0x06,0x07, ; px2
    db 0x00,0x01,0x02,0x03  ; px1
  c255: dd 255.0

section .text

combinar_asm:

	call invertir_img

  call combinar

	ret

invertir_img:
  push r12
  push rcx
  push rdi
  push rsi

  mov r15, rdx
  shl r15, 2 ; cols * 4
  ; r15 = cantidad de bytes en fila
  sub r15, 16

  .ciclo_filas:
    mov r12, r15

    .ciclo_col:
      movdqu xmm1, [rdi]  ; |px1|px2|px3|px4|
      movdqu xmm7, [mask] ; |      mask     |
      pshufb xmm1, xmm7   ; |px4|px3|px2|px1|

      movdqu [rsi + r12], xmm1

      add rdi, 16
      sub r12, 16
      cmp r12, 0
      jge .ciclo_col

    lea rsi, [rsi + rdx * 4]
    loop .ciclo_filas

  pop rsi
  pop rdi
  pop rcx
  pop r12

  ret

combinar:

  movd xmm1, [c255]
  divss xmm0, xmm1 ; xmm0 = |x|x|x|d| ; d = alpha/255.0
  movdqu xmm1, xmm0 ; xmm1 = xmm0
  shufps xmm0, xmm1, 0000o ; xmm0 = |d|d|d|d|

  mov rax, rcx
  mul rdx
  mov rcx, rax
  shr rcx, 2
  .ciclo:
    call procesar
    add rdi, 16
    add rsi, 16
    loop .ciclo

  ret

procesar:
  ; Traigo 4 pixeles de cada img
  movdqu xmm1, [rdi] ; xmm1 = |px1s|px2s|px3s|px4s|
  movdqu xmm2, [rsi] ; xmm2 = |px1d|px2d|px3d|px4d|
  movdqu xmm5, xmm2  ; Lo guardo para utilizar luego.

  pxor xmm7, xmm7

  movdqu xmm8, xmm1
  punpcklbw xmm8, xmm7  ; xmm8  = | px1s | px2s |
  movdqu xmm9, xmm1
  punpckhbw xmm9, xmm7  ; xmm9  = | px3s | px4s |

  movdqu xmm12, xmm2
  punpcklbw xmm12, xmm7 ; xmm12 = | px1d | px2d |
  movdqu xmm13, xmm2
  punpckhbw xmm13, xmm7 ; xmm13 = | px3d | px4d |

  psubw xmm8, xmm12     ; xmm8  = | px1s - px1d | px2s - px2d |
  psubw xmm9, xmm13     ; xmm9  = | px3s - px3d | px4s - px4d |

  movdqu xmm1, xmm8
  movdqu xmm2, xmm8
  pxor xmm7, xmm7
  pcmpgtw xmm7, xmm1
  punpcklwd xmm1, xmm7  ; xmm1 = | px1s - px1d |
  punpckhwd xmm2, xmm7  ; xmm2 = | px2s - px2d |

  movdqu xmm3, xmm9
  movdqu xmm4, xmm9
  pxor xmm7, xmm7
  pcmpgtw xmm7, xmm3
  punpcklwd xmm3, xmm7  ; xmm3 = | px3s - px3d |
  punpckhwd xmm4, xmm7  ; xmm4 = | px4s - px4d |

  cvtdq2ps xmm1, xmm1  ; xmm1 = | f(px1s - px1d) |
  cvtdq2ps xmm2, xmm2  ; xmm2 = | f(px2s - px2d) |
  cvtdq2ps xmm3, xmm3  ; xmm3 = | f(px3s - px3d) |
  cvtdq2ps xmm4, xmm4  ; xmm4 = | f(px4s - px4d) |

  mulps xmm1, xmm0  ; xmm1 = | f(px1s - px1d) * d |
  mulps xmm2, xmm0  ; xmm2 = | f(px2s - px2d) * d |
  mulps xmm3, xmm0  ; xmm3 = | f(px3s - px3d) * d |
  mulps xmm4, xmm0  ; xmm4 = | f(px4s - px4d) * d |

  ; p() = procesado = ((pxXs - pxXd) / d)
  cvtps2dq xmm1, xmm1  ; xmm1 = | p(px1) |
  cvtps2dq xmm2, xmm2  ; xmm2 = | p(px2) |
  cvtps2dq xmm3, xmm3  ; xmm3 = | p(px3) |
  cvtps2dq xmm4, xmm4  ; xmm4 = | p(px4) |

  packssdw xmm1, xmm2  ; xmm1 = | p(px1) | p(px2) |
  packssdw xmm3, xmm4  ; xmm3 = | p(px3) | p(px4) |

  packsswb xmm1, xmm3  ; xmm1 = | p(px1) | p(px2) | p(px3) | p(px4) |

  paddb xmm1, xmm5 ; xmm1 = | p(px1) + px1d | p(px2) + px2d | p(px3) + px3d | p(px4) + px4d |

  movdqu [rsi], xmm1 ; Guardo el resultado final en memoria

  ret
