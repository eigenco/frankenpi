	cpu	8086

;;;; INITIALIZE FIRST MEMORY SEGMENT ;;;;

	xor	ax, ax
	xor	di, di
	mov	es, di
	mov	cx, 65535
	rep	stosw

;;;; FILL INTERRUPT VECTOR TABLE ;;;;

	xor	di, di
	mov	es, di
	mov	cx, 0xff
fill:
	mov	ax, 0x03fe
	stosw
	mov	ax, 0xffc0
	stosw
	loop	fill

;;;; INITIALIZE INTERRUPTS ;;;;

	mov	al, 0x36
	out	0x43, al
	xor	al, al
	out	0x40, al
	out	0x40, al
	out     0x41, al
	out     0x41, al

	xor	si, si
	mov	ds, si
	mov	word [0x08*4], INT08 ; TIMER HANDLER
	mov     word [0x09*4], INT09 ; KEYBOARD HANDLER
	mov	word [0x12*4], INT12 ; MEMORY SERVICE
	mov	word [0x16*4], INT16 ; KEYBOARD SERVICE
	mov	word [0x1a*4], INT1A ; TIME SERVICE

;;;; INITIALIZE BIOS DATA AREA ;;;;

	mov	si, 0x40
	mov	ds, si
	mov	word [0x1a], 0x1e
	mov	word [0x1c], 0x1e

;	mov	sp, 0x30
;	mov	ss, sp
;	mov	sp, 0xfe

;;;; INITIALIZE VGA & XT-CF ;;;;

	call	0xc000:3
	call	0xce00:3

;;;; BOOT FROM THE XT-CF ;;;;

	xor	di, di
	xor	si, si
	mov	es, di
	mov	ds, si

	int	0x19

INT08:
	push	ds
	push	ax
	mov	ax, 0x40
	mov	ds, ax
	clc
	adc	word [0x6c], 1
	adc	word [0x6e], 0
	int	0x1c
	mov	al, 0x20
	out	0x20, al
	pop	ax
	pop	ds
	iret

INT09:
	push	ax
	push	bx
	push	es
	push	di
	push	ds
	in      al, 0x60
	mov	di, 0x40
	mov	es, di
	mov	di, [es:0x1c]

	cmp	al, 0x1d                   ; <CTRL> down
	jne	INT09_not_1D
	or	[es:0x17], byte 00000100b
	jmp	INT09_nobuff
INT09_not_1D:

	cmp	al, 0x9d                   ; <CTRL> up
	jne	INT09_not_9D
	and	[es:0x17], byte 11111011b
	jmp	INT09_nobuff
INT09_not_9D:

        cmp     al, 0x38                   ; <ALT> down
        jne     INT09_not_38
        or      [es:0x17], byte 00001000b
        jmp     INT09_nobuff
INT09_not_38:

        cmp     al, 0xB8                   ; <ALT> up
        jne     INT09_not_B8
        and     [es:0x17], byte 11110111b
        jmp     INT09_nobuff
INT09_not_B8:

	cmp	al, 0x2a                   ; <LSHIFT> down
	jne	INT09_not_2A
	or	[es:0x17], byte 00000010b
	jmp	INT09_nobuff
INT09_not_2A:

	cmp	al, 0xaa                   ; <LSHIFT> up
	jne	INT09_not_AA
	and	[es:0x17], byte 11111101b
	jmp	INT09_nobuff
INT09_not_AA:

	cmp	al, 0x7f
	ja	INT09_nobuff
	mov	bx, cs
	mov	ds, bx
	mov	ah, al
	mov	bx, ASCII
	xlatb
	mov	bl, [es:0x17]
	test	bl, 3
	jz	INT09_not_SHIFT
	mov	al, ah
	mov	bx, SHIFTED
	xlatb
INT09_not_SHIFT:

	mov	bl, [es:0x17]
	test	bl, 4
	jz	INT09_not_CTRL
	sub	al, 0x60
INT09_not_CTRL:
        mov     bl, [es:0x17]
        test    bl, 8
        jz      INT09_not_ALT
        xor     al, al
INT09_not_ALT:
	mov	word [es:di], ax
	add	di, 2
	cmp	di, 0x3e
	jb	INT09_not_yet_buffer_roll
	sub	di, 32
INT09_not_yet_buffer_roll:
	mov	[es:0x1c], di

INT09_nobuff:
	pop	ds
	pop	di
	pop	es
	pop	bx
	pop	ax
	iret
ASCII:
	db       0  ; 00
	db      27  ; 01 <ESC>
	db      '1' ; 02
	db      '2' ; 03
	db      '3' ; 04
	db      '4' ; 05
	db      '5' ; 06
	db      '6' ; 07
	db      '7' ; 08
	db      '8' ; 09
	db      '9' ; 0A
	db      '0' ; 0B
	db      '-' ; 0C
	db      '=' ; 0D
	db       8  ; 0E <BACKSPACE>
	db       9  ; 0F <TAB>
	db      'q' ; 10
	db      'w' ; 11
	db      'e' ; 12
	db      'r' ; 13
	db      't' ; 14
	db      'y' ; 15
	db      'u' ; 16
	db      'i' ; 17
	db      'o' ; 18
	db      'p' ; 19
	db      '[' ; 1A
	db      ']' ; 1B
	db      13  ; 1C <ENTER>
	db       0  ; 1D
	db      'a' ; 1E
	db      's' ; 1F
	db      'd' ; 20
	db      'f' ; 21
	db      'g' ; 22
	db      'h' ; 23
	db      'j' ; 24
	db      'k' ; 25
	db      'l' ; 26
	db      ';' ; 27
	db      39  ; 28
	db       0  ; 29
	db       0  ; 2A
	db      '\' ; 2B
	db      'z' ; 2C
	db      'x' ; 2D
	db      'c' ; 2E
	db      'v' ; 2F
	db      'b' ; 30
	db      'n' ; 31
	db      'm' ; 32
	db      ',' ; 33
	db      '.' ; 34
	db      '/' ; 35
	db       0  ; 36 <SHIFT>
	db       0  ; 37
	db       0  ; 38
	db      ' ' ; 39 <SPACE>
	db	 0  ; 3a
	db	 0  ; 3b
	db	 0  ; 3c
	db	 0  ; 3d
	db	 0  ; 3e
	db	 0  ; 3f
	db	 0  ; 40
	db	 0  ; 41
	db	 0  ; 42
	db	 0  ; 43
	db	 0  ; 44
	db	 0  ; 45
	db	 0  ; 46
	db	 0  ; 47
	db	 0  ; 48
	db	 0  ; 49
	db	 0  ; 4a
	db	 0  ; 4b
	db	 0  ; 4c
	db	 0  ; 4d
	db	 0  ; 4e
	db	 0  ; 4f
	db	 0  ; 50
	db	 0  ; 51
	db	 0  ; 52
	db	 0  ; 53
	db	 0  ; 54
	db	 0  ; 55
	db	 0  ; 56
	db	 0  ; 57
	db	 0  ; 58
	db	 0  ; 59
	db	 0  ; 5a
	db	 0  ; 5b
	db	 0  ; 5c
	db	 0  ; 5d
	db	 0  ; 5e
	db	 0  ; 5f
SHIFTED:
	db       0   ; 00
	db       0   ; 01 <ESC>
	db      0x21 ; 02
	db      0x40 ; 03
	db      0x23 ; 04
	db      0x24 ; 05
	db      0x25 ; 06
	db      0x5e ; 07
	db      0x26 ; 08
	db      0x2a ; 09
	db      0x28 ; 0A
	db      0x29 ; 0B
	db      0x5f ; 0C
	db      0x2b ; 0D
	db       0   ; 0E <BACKSPACE>
	db       0   ; 0F <TAB>
	db      'Q'  ; 10
	db      'W'  ; 11
	db      'E'  ; 12
	db      'R'  ; 13
	db      'T'  ; 14
	db      'Y'  ; 15
	db      'U'  ; 16
	db      'I'  ; 17
	db      'O'  ; 18
	db      'P'  ; 19
	db      0x7b ; 1A
	db      0x7d ; 1B
	db       0   ; 1C <ENTER>
	db       0   ; 1D
	db      'A'  ; 1E
	db      'S'  ; 1F
	db      'D'  ; 20
	db      'F'  ; 21
	db      'G'  ; 22
	db      'H'  ; 23
	db      'J'  ; 24
	db      'K'  ; 25
	db      'L'  ; 26
	db      0x3a ; 27
	db      0x22 ; 28
	db      0x7e ; 29
	db       0   ; 2A
	db      0x7c ; 2B
	db      'Z'  ; 2C
	db      'X'  ; 2D
	db      'C'  ; 2E
	db      'V'  ; 2F
	db      'B'  ; 30
	db      'N'  ; 31
	db      'M'  ; 32
	db      0x3c ; 33
	db      0x3e ; 34
	db      0x3f ; 35
	db	 0   ; 36
	db	 0   ; 37
	db	 0   ; 38
	db	 0   ; 39
	db	 0   ; 3a
	db	 0   ; 3b
	db	 0   ; 3c
	db	 0   ; 3d
	db	 0   ; 3e
	db	 0   ; 3f
	db	 0   ; 40
	db	 0   ; 41
	db	 0   ; 42
	db	 0   ; 43
	db	 0   ; 44
	db	 0   ; 45
	db	 0   ; 46
	db	 0   ; 47
	db	 0   ; 48
	db	 0   ; 49
	db	 0   ; 4a
	db	 0   ; 4b
	db	 0   ; 4c
	db	 0   ; 4d
	db	 0   ; 4e
	db	 0   ; 4f
	db	 0   ; 50
	db	 0   ; 51
	db	 0   ; 52
	db	 0   ; 53
	db	 0   ; 54
	db	 0   ; 55
	db	 0   ; 56
	db	 0   ; 57
	db	 0   ; 58
	db	 0   ; 59
	db	 0   ; 5a
	db	 0   ; 5b
	db	 0   ; 5c
	db	 0   ; 5d
	db	 0   ; 5e
	db	 0   ; 5f

INT12:
	mov	ax, 640
	iret

INT16:
	push	ds
	push	bx
	mov	bx, 0x40
	mov	ds, bx
	or	ah, ah
	jz	INT16_read
	dec	ah
	jz	INT16_wait
	xor	ax, ax
INT16_exit:
	pop	bx
	pop	ds
	iret
INT16_read:
	cli
	mov	bx, [ds:0x1a]
	cmp	bx, [ds:0x1c]
	sti
	jz	INT16_read
	mov	ax, [ds:bx]
	add	bx, 2
	cmp	bx, 0x3e
	jb	INT16_got_key
	sub	bx, 32
INT16_got_key:
	mov	[ds:0x1a], bx
	jmp	INT16_exit
INT16_wait:
	cli
	mov	bx, [ds:0x1a]
	cmp	bx, [ds:0x1c]
	mov	ax, [ds:bx]
	sti
	pop	bx
	pop	ds
	retf	2

INT1A:
	push	ax
	push	ds
	mov	ax, 0x40
	mov	ds, ax
	mov	cx, [ds:0x6e]
	mov	dx, [ds:0x6c]
	pop	ds
	pop	ax
	iret

	times	1024-16-($-$$) nop
	cli
	jmp     0xffc0:0
	times   1024-2-($-$$) nop
	iret
	iret
