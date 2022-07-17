; we have about 660 bytes to spare in the VGABIOS
;
; FPGA/RP mass storage interface for BIOS int 13h in VGABIOS

incbin "tvexp.bin", 0, 0x7d68

	xor     ax, ax
	mov     es, ax
	mov     word [es:0x13*4], INT13
	mov     word [es:0x13*4+2], 0xc000
	jmp     0x4f                             ; return to VGABIOS

INT13:
	cmp     ah, 2
	je      INT13_read
	cmp     ah, 3
	je      INT13_write
	cmp     ah, 8
	je      INT13_type
	iret

INT13_read:
	push    ax
	push	bx
	push	cx
	push	dx
	push    di
	mov     di, bx       ; target given as ES:BX, stosb takes ES:DI
	mov     bh, dh       ; head: DH -> BH
	mov     bl, al       ; number of sectors to read -> BL

	mov     al, 0        ; reset interface
	mov     dx, 0x170
	out     dx, al

	inc     dx

	mov     al, ch       ; cylinder
	out     dx, al
	
	mov     al, bh       ; head
	out     dx, al
	
	mov     al, cl       ; sector
	out     dx, al
read_next:
	dec     dx
	mov     al, 1        ; read next
	out     dx, al
wait_read:
	in      al, dx
	cmp     al, 255
	jne     wait_read
	mov     cx, 512	
	inc     dx
read:
	in      al, dx
	stosb
	loop    read	
	dec     bl
	jnz     read_next
	pop     di
	pop	dx
	pop	cx
	pop	bx
	pop     ax           ; return in al: number of sectors read
	xor     ah, ah       ; return in ah: no error
	iret

INT13_write:
	iret

INT13_type:
	mov     cx, 0xff3f
	mov     dx, 0x0f01
	iret

times 32767-($-$$) db 0
;	db	0
	db	-70