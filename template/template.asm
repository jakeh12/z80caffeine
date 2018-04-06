;===============================================================================
; TEMPLATE FOR Z80 CAFFEINE RAM FLASH
;-------------------------------------------------------------------------------
; description goes here
;===============================================================================

;-------------------------------------------------------------------------------
; DEFINITIONS
;-------------------------------------------------------------------------------

; stack
STACK_BOTTOM		equ 	$ffff ; grows downwards

; serial
SER_DATA_IO_ADDR	equ	$00		; (rw) serial data buffer io address
SER_FLAG_IO_ADDR	equ	$80		; (r) serial flags buffer io address
SER_FLAG_RXE_BIT	equ	0		; receive buffer empty flag (0 = empty, 1 = full)
SER_FLAG_TXF_BIT	equ	1		; transmit buffer full (0 = transmitting, 
								; 1 = empty/ready)

; software buttons
BTN_IO_ADDR			equ $80		; button state buffer io address
BTN_0_BIT			equ 2		; button 0 bit (0 = pressed, 1 = nothing)
BTN_1_BIT			equ 3		; button 1 bit (0 = pressed, 1 = nothing)

; display and beeper
DISP_IO_ADDR		equ $80		; (w) display and buzzer output latch address
DISP_BEEPER_BIT		equ 7		; beeper bit

; ram
RAM_START_ADDR		equ	$8000	; first byte of RAM ($8000-$FFFF)

; jump table
BOOT_MAIN_ADDR		equ	$0006	; main of the bootloader (should not be needed)
;-------------------------------------------------------------------------------

;===============================================================================
; PROGRAM
;===============================================================================

	org RAM_START_ADDR
	
main:
	ld hl, hello_world_string
	call send_string
	call display_snake
	call beep
	jp main


;===============================================================================
; SUBROUTINES
;===============================================================================


;-------------------------------------------------------------------------------
; SUBROUTINE: READ_BUTTONS_BLOCK
;-------------------------------------------------------------------------------
;  waits until a button is pressed
; 
;  inputs:
;    none
;
;  outputs:
;	 a - button pressed (0 = both, 1 = BTN1 , 2 = BTN0, 3 = none)
;
;  modifies:
;    af, bc
;-------------------------------------------------------------------------------
read_buttons_block:
	in a, (BTN_IO_ADDR)
	srl a
	srl a
	and $03
	cp $03
	jp z, read_buttons_block
	ld b, a
_read_buttons_block_pushed
	in a, (BTN_IO_ADDR)
	srl a
	srl a
	and $03
	cp $03
	ld a, b
	ret z
	jp _read_buttons_block_pushed
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: READ_BUTTONS_BLOCK
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; SUBROUTINE: DISPLAY_DIGIT
;-------------------------------------------------------------------------------
;  displays a hexadecimal digit on the seven segment display
; 
;  inputs:
;    hl	- 4-bit digit to be printed on the hex display
;
;  outputs:
;	none
;	
;  modifies:
;    af, bc, hl
;-------------------------------------------------------------------------------
display_digit:
	ld bc, segment_digits
	add hl, bc
	ld a, (hl)
	out DISP_IO_ADDR, a
	ret
segment_digits:
	db $3f, $06, $5b, $4f, $66, $6d, $7d, $07, $7f, $6f, $77, $7c, $39, $5e, $79, $71
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: DISPLAY_DIGIT
;-------------------------------------------------------------------------------


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
	out DISP_IO_ADDR, a
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
	xor 1 << DISP_BEEPER_BIT 
	out DISP_IO_ADDR, a
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
; makes processor busy for about 0.25 seconds
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


;-------------------------------------------------------------------------------
; SUBROUTINE: RECEIVE_DATA
;-------------------------------------------------------------------------------
;  wait for two bytes which define the length of the byte stream to be received
;  and stores the received bytes in the memory
; 
;  inputs:
;    hl	- pointer to the beginning of the location where to store the data
;
;  outputs:
;    bc - the lenght of the data stored at location hl
;
;  modifies:
;    af, bc, de, hl
;-------------------------------------------------------------------------------
receive_data:
	call receive_byte
	ld c, a
	call receive_byte
	ld b, a
	ld de, bc
_receive_data_loop:
	call receive_byte
	ld (hl), a
	inc hl
	dec bc
	ld a, b
	cp 0
	jr nz, _receive_data_loop
	ld a, c
	cp 0
	jr nz, _receive_data_loop
	ld bc, de
	ret
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: RECEIVE DATA
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; SUBROUTINE: TO_HEX
;-------------------------------------------------------------------------------
;  converts a number into hex ascii string
; 
;  inputs:
;    a	- value to be converted to hex
;    hl	- pointer to the beginning of the string to be saved
;
;  outputs:
;    none
;
;  modifies:
;    af, bc, hl
;-------------------------------------------------------------------------------
to_hex:
	ld b, a
	ld c, 2
	srl a			; extract the upper 4 bits
	srl a
	srl a
	srl a
_to_hex_offset:
        cp 10
        jp m, _to_hex_offset_0_9
        add 'a'-10		; number is in range a-f
        jr _to_hex_offset_done
_to_hex_offset_0_9:
        add '0'			; number is in range 0-9
_to_hex_offset_done:
	ld (hl), a
	inc hl
	dec c
	jr z, _to_hex_done
	ld a, b
	and %00001111		; extract the lower 4 bits
	jr _to_hex_offset
_to_hex_done:
	ld (hl), $00		; add terminating NULL
	ret
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: TO_HEX
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; SUBROUTINE: RECEIVE_STRING
;-------------------------------------------------------------------------------
;  keeps reading string in byte-by-byte until a CR byte is received
; 
;  inputs:
;    hl - pointer to the beginning of the string to be saved
;
;  outputs:
;    none
;
;  modifies:
;    af, hl
;-------------------------------------------------------------------------------
receive_string:
	call receive_byte
	cp $0d
	jp nz, _receive_string_continue
	ld (hl), 0
	ret
_receive_string_continue:
	ld (hl), a
	inc hl
	call send_byte
	jp receive_string
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: RECEIVE_STRING
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; SUBROUTINE: SEND_STRING
;-------------------------------------------------------------------------------
;  keeps sending a string byte-by-byte until a NULL character is detected
; 
;  inputs:
;    hl - pointer to the beginning of the string
;
;  outputs:
;    none
;
;  modifies:
;    af, hl, b
;-------------------------------------------------------------------------------
send_string:
	ld a, (hl)
	cp 0
	jp nz, _send_string_send_byte
	ret
_send_string_send_byte:
	call send_byte
	inc hl
	jp send_string
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: SEND_STRING
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; SUBROUTINE: RECEIVE_BYTE
;-------------------------------------------------------------------------------
;  waits until receive buffer full flag goes low (data is present)
;  and returns the data
;
;  inputs:
;    none
;
;  outputs:
;    a - byte received
;
;  modifies:
;    af
;-------------------------------------------------------------------------------
receive_byte:
	in a, (SER_FLAG_IO_ADDR)
        bit SER_FLAG_RXE_BIT, a
        jp nz, receive_byte
	in a, (SER_FLAG_IO_ADDR)
	ret
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: RECEIVE_BYTE
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; SUBROUTINE: SEND_BYTE
;-------------------------------------------------------------------------------
;  waits until the transmit buffer empty flag goes high (in case
;  there is a pending transmission) and then writes the 
;  byte into the transmit buffer
;
;  inputs:
;    a - byte to be transmitted
;
;  outputs:
;    none
;
;  modifies:
;    af, b
;-------------------------------------------------------------------------------
send_byte:
	ld b, a
_send_byte_wait:
	in a, (SER_FLAG_IO_ADDR)
	bit SER_FLAG_TXF_BIT, a
	jp nz, _send_byte_wait
	ld a, b
	out (SER_DATA_IO_ADDR), a
	ret
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: SEND_BYTE
;-------------------------------------------------------------------------------


;===============================================================================
; DATA
;===============================================================================

hello_world_string:
	db "Hello world!", $0a, $0d, $00

