; ****
; main
; ****

; "Hello world"
; with input handling and library function implementations

; Suntax:	NASM 2.15
; CPU:		80386+
; OS:		32-bit compatible with System V ABI
; Entrypoint:	_start

; ** Label prefixes:
;   
;   prefix	description
;   ______________________________
;
;   c_		constant
;   v_		mutable
;   INT_	interrupt
;   SYS_	syscall value
;   _		private symbol
;

; ** Comment syntax:
;
;   string	description
;   ______________________________
;
;   **		section header
;   **********	separator
;   x*		pointer to x
;   x->y	put x into y
;   |		related to common instruction
;   ** def:	function description
;   ** in:	function inputs
;   ** out:	function outputs
;

	BITS 32
	GLOBAL _start

; ********** ;

	; ** Preprocessor **
	
	; Interrupts
	%define	INT_SYS	    0x80    ; syscall

	; _ax values for syscall
	%define	SYS_EXIT    0x01    ; exit
	%define	SYS_READ    0x03    ; read
	%define	SYS_WRITE   0x04    ; write

	; Unicode values
	%define ENDL	    0x0A
	
	; File descriptors
	%define STDIN	    0x00
	%define STDOUT	    0x01

	; Library functions
	%undef	vexit
	%undef	vsyscall
	%undef	puts
	%undef	read
	%undef	strlen
	%undef	strcpy
	%undef	strcat
	
	; Application functions
	%undef	prompt
	%undef	fmtmsg

SECTION .rodata

	; ** Constants **
	
c_prompt:	db  "Enter your username:", ENDL, \
		    ">"			    , 0

c_msg0:		db  ENDL, \
		    "Hello"		    , 0

c_msg_sep:	db  ", "		    , 0

c_msg1:		db  "!", ENDL		    , 0

c_msg_end:	db  ENDL, \
		    "Kind regards,", ENDL, \
		    "A group of many x86 instructions.", ENDL \
					    , 0

; ********** ;

SECTION .data

	; ** Mutables **

; ********** ;

SECTION .bss

	; ** Uninitialized **

	v_in	db 128 dup(?)	; input buffer
	v_out	db 128 dup(?)	; output buffer

; ********** ;

SECTION .text

	; ** Library functions **

;	** def:	    exit if negative error code in eax
;	** in:	    eax: syscall error code
vexit:
	not	eax		; unsign error code
	inc	eax		;

	push	eax		; error* ->stack top

	mov	eax, SYS_EXIT	; select exit
	pop	ebx		; | stack top	->error*

	int	INT_SYS		; ** syscall

;	** def:	    make syscall, check error
vsyscall:
	int	INT_SYS		; ** syscall

	cmp	eax, 0		;
	jl	vexit		; exit if negative

	ret

;	** def:	    get length of null-terminated string
;	** in:	    eax: string*
;	** out:	    ecx: length
strlen:
	push	ebx		; save ebx

	mov	ebx, eax	; copy string*
	xor	ecx, ecx	; reset counter

 _strlen_next:			; ** loop

	cmp	[ebx], byte 0	; if null byte
	je	_strlen_end	;   exit loop

	inc	ecx		; count byte
	inc	ebx		; count addr

	jmp	_strlen_next	; ** next

 _strlen_end:
	pop	ebx		; restore ebx

	ret

;	** def:	    copy null-terminated string from source to destination address
;	** in:	    esi: source*
;		    edi: destination*
;	** out:	    ecx: length copied
strcpy:
	push	esi		; save source address
	push	edi		; save destination address

 _strcpy_next:			; ** loop

	cmp	[esi], byte 0	; if null byte
	je	_strcpy_end	;   exit loop
	
	cld			; clear direction flag
	movsb			; copy byte, inc si and di

	jmp	_strcpy_next	; ** next

 _strcpy_end:
	mov	[edi], byte 0	; copy null byte
	
	pop	edi		; restore source start
	pop	ecx		; restore destination start

	sub	esi, ecx	; length = last byte - start
	xchg	ecx, esi	; copy to return register
	
	ret

;	** def:	    concatenate two strings into a buffer
;	** in:	    eax:	string*
;		    ebx:	string*
;	** out:	    edx:	buffer*
strcat:
	mov	edx, v_out	; return buffer* ->edx

	mov	edi, edx	; destination start
	mov	esi, eax	; source 1
	call	strcpy		; ** call

	add	edi, ecx	; count buffer
	mov	esi, ebx	; source 2
	call	strcpy		; ** call

	ret

;	** def:	    print to stdout
;	** in:	    eax: string*
puts:
				; (string* eax)
	call	strlen		; ** call

	push	ecx		; length    ->stack base
	push	eax		; string*   ->stack top

	mov	eax, SYS_WRITE	; select write
	mov	ebx, STDOUT 	; | file descriptor
	pop	ecx		; |	stack top   ->string*
	pop	edx		; |	stack base  ->length

	call	vsyscall    	; ** syscall

	ret

;	** def:	    read from stdin
;	** out:	    edx: string*
read:
	mov	ecx, v_in	; set buffer start

 _read_next:			; ** loop

	mov	eax, SYS_READ	; select read
	mov	ebx, STDIN	; | file descriptor
				; | (buffer*)
	mov	edx, 1		; | single byte

	call	vsyscall	; ** syscall
	
	cmp	[ecx], byte ENDL; if newline-
	jz	_read_end	;   or null at ecx, then exit
	
	inc	ecx		; count addr

	jmp	_read_next	; ** next

 _read_end:
	mov	[ecx], byte 0	; always null terminate
	mov	edx, v_in	; buffer* ->edx

	ret

; ********** ;

	; ** Application functions **

;	** def:	    display prompt and read from stdin
;	** out:	    edx: string*
prompt:
    	mov	eax, c_prompt
	call	puts		; ** print
	call	read		; ** input

	ret

;	** def:	    format a welcome message from user input
;	** in:	    edx: string*
;	** out:	    edx: string*
fmtmsg:
	cmp	[edx], byte 0
	jne	_fmtmsg_addsep	; add separator if input

	jmp	_fmtmsg_start
	
 _fmtmsg_addsep:

	mov	eax, c_msg_sep	; save original input
	mov	ebx, edx	; set separator
	call	strcat		; ** call   ->buffer
    	
				; copy to v_in to prevent overflow in v_out
	mov	esi, edx	; source buffer
	mov	edi, v_in	; destination buffer
	call	strcpy		; ** call

	mov	edx, edi	; buffer    ->input register

	jmp	_fmtmsg_start
 
 _fmtmsg_start:

 	mov	eax, c_msg0	; string 1
	mov	ebx, edx	; input
	call	strcat		; ** call   ->buffer
	
	push	edx		; save buffer start

	jmp	_fmtmsg_end

 _fmtmsg_end:
	
	mov	eax, edx	; buffer
	mov	ebx, c_msg1	; string 2
	call	strcat		; ** call   ->buffer

	mov	eax, edx	; buffer
	mov	ebx, c_msg_end	; string 3
	call	strcat		; ** call   ->buffer

	pop	edx		; restore buffer start
	
	ret

; ********** ;

	; ** Entrypoint **

_start:
	call	prompt		; input	    ->edx
	call	fmtmsg		; message   ->edx

	mov	eax, edx	; set message
	call	puts		; ** call

	jmp	_end
_end:
	mov	eax, SYS_EXIT	; select exit
	mov	ebx, 0		; | exit code	

	int	INT_SYS		; ** syscall

; ********** ;
