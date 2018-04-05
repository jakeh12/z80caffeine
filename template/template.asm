;-------------------------------------------------------------------------------
; DEFINITIONS
;-------------------------------------------------------------------------------

; stack
STACK_BOTTOM	equ 	$ffff ; grows downwards

; serial
SER_DATA		equ	$00 ; (read/write)
SER_FLAG		equ	$80	; (read-only)
SER_BIT_RXE		equ	0
SER_BIT_TXF		equ	1

; software buttons
FLAGS			equ $80
BTN0_BIT		equ $04
BTN1_BIT		equ $08

; display and buzzer
DISP_DATA		equ $80 ; (write-only)
BEEPER_BIT		equ $80

; ram
RAM_START	equ	$8000
MAIN_MAIN	equ	$0006
;-------------------------------------------------------------------------------


;===============================================================================
; PROGRAM
;===============================================================================

	org RAM_START
	
main:	
	call display_snake
	call beep
	jp MAIN_MAIN


;-------------------------------------------------------------------------------
; SUBROUTINE: DISPLAY_SNAKE
;-------------------------------------------------------------------------------
;  displays a "snake" running around the seven segment display
; 
;  inputs:
;    none
;
;  outputs:
;	 none
;	
;  modifies:
;    af
;-------------------------------------------------------------------------------
display_snake:
	ld a, 1
display_snake_loop:
	out DISP_DATA, a
	cp a, 64
	ret z
	call delay
	sla a
	jp display_snake_loop
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: DISPLAY_SNAKE
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; SUBROUTINE: BEEP
;-------------------------------------------------------------------------------
;  creates a short beep using the onboard beeper
; 
;  inputs:
;    none
;
;  outputs:
;	 none
;	
;  modifies:
;    af, bc, cd
;-------------------------------------------------------------------------------
beep:
	ld a, 0
	ld c, $ff
_beep_delay0:
	xor BEEPER_BIT
	out DISP_DATA, a
	ld d, $ff
_beep_delay1:
	dec d
	jp nz, _beep_delay1
	dec c
	jp nz, _beep_delay0
	ret
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: BEEP
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; SUBROUTINE: DELAY
;-------------------------------------------------------------------------------
; makes processor busy for about half a second
;
;  inputs:
;    none
;
;  outputs:
;    none
;
;  modifies:
;    c, de
;-------------------------------------------------------------------------------
delay:
	ld c, $02
_delay0:
	ld d, $ff
_delay1:
	ld e, $ff
_delay2:
	dec e
	jp nz, _delay2
	dec d
	jp nz, _delay1
	dec c
	jp nz, _delay0
	ret
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: DELAY
;-------------------------------------------------------------------------------


;===============================================================================
; PADDING
;===============================================================================

; pad file to eeprom size
	;ds	ROM_SIZE - $
;-------------------------------------------------------------------------------

