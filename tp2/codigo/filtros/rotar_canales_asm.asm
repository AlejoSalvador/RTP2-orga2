section .data
DEFAULT REL

section .text
mascara:	db 1,2,0,3,5,6,4,7,9,10,8,11,13,14,12,15

global rotar_asm

;void rotar asm(unsigned char *src,	RDI
;		 unsigned char *dst	RSI
;		 int cols			RDX
;		 int filas			RCX
;		 int src row size	R8
;		 int dst row size)	R9

rotar_asm:
movsxd rdx, edx
movsxd rax, ecx
movsxd r8, r8d
movsxd r9, r9d

movdqu xmm1, [mascara]		; en xmm1 la mascara para 4 pixeles
mov r10, rdi
mov r11, rsi

	   ;en rdi tengo el puntero a la fuente
	   ;en rsi tengo el puntero a destino
	   ;en rdx tengo la altura
	   ;en rcx tengo el ancho
	   ;en r8 tengo el ancho de fuente
	   ;en r9 tengo el ancho de destino

	   ;idea: levantar tres veces, rotar segun segun sea necesario, cerear los valores que no necesito y hacer un or entre los 3
	

	  ;mov rax, 4
	  ;mul rdx
	  ;mov rdx, rax

		

cicloFilas:	  
  	 cmp rax, 0		;comparo el alto con 0 a ver si termine de procesar todas las filas	
	   je finRotar
	   mov rdi, r10
	   mov rsi, r11
	   mov rcx, rdx
	   shr rcx, 2		;proceso de a 4 pixeles

		cicloColumnas:

			   movdqu xmm0, [rdi]	;xmm0= |a15|....|a0|	;uso xmm0 para rojo
			   pshufb xmm0,xmm1
			   movdqu [rsi], xmm0		;muevo a memoria	

			   add rdi, 16
			   add rsi, 16			
			   loop	cicloColumnas

		;sino es multiplo de 4 ntonces me faltan procesar 3, 2 o 1 pixel
			mov rcx, rax
			shr rcx, 2
			shl rcx, 2
			sub rcx, rax		;esta resta puede ser: 0, -1, -2 o -3
			cmp rcx, 0
			je .no_faltan
			cmp rcx, -1
			je .faltan_1
			cmp rcx, -2
			je .faltan_2
			;si no salta entonces faltaba 3 pixeles:
			
			movdqu xmm0, [rdi]	;xmm0= |a15|....|a0|	;uso xmm0 para rojo
			pshufb xmm0,xmm1
			movq [rsi], xmm0		;muevo a memoria 2 pixeles
			add rsi, 8
			psrldq xmm0, 8
			movd [rsi], xmm0
			jmp .no_faltan
			
			.faltan_1:
			movd xmm0, [rdi]	;xmm0= |a15|....|a0|	;uso xmm0 para rojo
			pshufb xmm0,xmm1
			movd [rsi], xmm0		;muevo 1 pixel memoria	
			jmp .no_faltan
			
			.faltan_2:
			movq xmm0, [rdi]	;xmm0= |a15|....|a0|	;uso xmm0 para rojo
			pshufb xmm0,xmm1
			movq [rsi], xmm0		;muevo a memoria
			jmp .no_faltan	
			

	.no_faltan:

	   add r10, r8			;a rdi le sumo el ancho para apuntar a la proxima fila
	   add r11, r9
	   dec rax			;decremento el contador de filas
	   jmp cicloFilas

finRotar:

		
	ret
