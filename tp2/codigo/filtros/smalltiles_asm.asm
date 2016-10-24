section .data
DEFAULT REL

section .text
global smalltiles_asm
smalltiles_asm:
;void smalltiles_c (unsigned char *src, unsigned char *dst, int cols, int filas, int src_row_size, int dst_row_size)
;rdi:src | rsi:dst | edx:cols | ecx:filas | r8d:src_row_size | r9d:dst_row_size

push rbp
mov rbp, rsp
push rbx
push r12
push r13
	
movsxd r11, ecx
shr r11, 1		
movsxd r13, edx
shr r13, 1		
movsxd r8, r8d	
movsxd r9, r9d	

mov rax, r9
mov	rdx, r11
mul edx			
mov r12d, edx
shl r12, 32
mov r12d, eax

mov rdx, r11
mov r10, rdi
mov r11, rsi
lea r12, [r12+rsi]

.ciclo_columna:
		cmp rdx, 0
		je .fin
		mov rdi, r10
		mov rsi, r11
		mov rbx, r12
		mov rcx, r13
		sar rcx, 1		; proceso dos pixels por vez
		.ciclo_fila:
			movdqu xmm0, [rdi]
			pshufd xmm1, xmm0, 0x08
			movq [rsi], xmm1
			movq [rsi+r13*4], xmm1
			movq [rbx], xmm1
			movq [rbx+r13*4], xmm1
			add rdi, 16
			add rsi, 8
			add rbx, 8
			
			loop .ciclo_fila
			
		mov rcx, r13
		shr rcx, 1
		shl rcx, 1
		sub rcx, r13
		cmp rcx, 0
		je .salir_c_fila
		mov eax, [rdi]
		mov [rsi], eax
		mov [rsi+r13*4], eax
		mov [rbx], eax
		mov [rbx+r13*4], eax
				
		.salir_c_fila:
				lea r10, [r10+r8*2]
				lea r11, [r11+r9]
				lea r12, [r12+r9]
				dec rdx
				jmp .ciclo_columna
				
.fin:
	pop r13
	pop r12
	pop rbx
	pop rbp

	ret
