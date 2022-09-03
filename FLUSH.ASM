; tasm flush
; tlink /t flush

.model tiny
.code
        org     100h
start:
        mov     al, 2
        mov     dx, 170h
        out     dx, al
        
        xor     ax, ax
        int     16h

        mov     di, 40h
        mov     es, di
        mov     di, 72h
        mov     es:[di], 01234h
        db      0eah
        dw      0, 0ffffh
end start
