;; Lab 4
;; Ted Paulsen, Daniel Machlab - iD

.include "m88padef.inc"

.org 0x000 rjmp RESET
.org 0x002 rjmp set_modeAB ;change modes
.org 0x01A
RESET:


;EIMSK
ldi R22, 0b00000010
out EIMSK, R22
;EICRA
ldi R22, 0b00000101
sts EICRA, R22
;EIFR
;ldi R22, 0x02
;sts 


;; LINES TO RPG
cbi DDRB, 0 ; input - from A
cbi DDRB, 1 ; input - from B
sbi DDRB, 2 ; output - clockwise (A side) LED
sbi DDRD, 5 ; set pwm pin as output

;; E & RS LINES TO LCD
sbi DDRB, 3 ; output to E
sbi DDRB, 5 ; output to RS line of lcd

;; DATA LINE TO PUSHBUTTON
;cbi DDRB, 2 ; input from pushbutton
cbi DDRD, 3 ; input from onboard pushbutton

;; DATA LINES TO LCD
sbi DDRC, 3 ; output PC3 - D7
sbi DDRC, 2 ; output PC2 - D6
sbi DDRC, 1 ; output PC1 - D5
sbi DDRC, 0 ; output PC0 - D4

;; RPG READINGS
.def curr = R20 ; R20 is the current rpg reading
.def prev = R21 ; R21 is the previous rpg reading

;; LCD DATA
.def duty_cycle = R23
.def mode = R29 ; 0x00 is mode a, 0x01 is mode b

;; DIVIDE REGISTERS
.def drem16uL = r14
.def drem16uH = r15
.def dres16uL = r16
.def dres16uH = r17
.def dd16uL	= r16
.def dd16uH	= r17
.def dv16uL	= r18
.def dv16uH	= r19
.def dcnt16u = r20

;; free registers: R24, R25, R26, R28
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PUBLIC STATIC VOID MAIN 
ldi mode, 0x00
cbi PORTB, 5 ; set to command mode
rcall lcd_init
sbi PORTB, 5 ; set to data mode

rjmp skip
	msg1: .DB "DC = ", 0x00
	msg2: .DB "Mode A: ", 0x00, 0x00
	msg3: .DB "Mode B: ", 0x00, 0x00
skip:

;rcall display_modeA

rcall timer_config
ldi duty_cycle, 153
out OCR0B, duty_cycle
sei
rjmp system_listener

;; END MAIN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

system_listener:
	;; button listener
	;sbis PIND, 2
	;rcall set_modeAB

	;rcall lightoff
	in prev, PINB
	andi prev, 0b00000011

	rcall delay_200us

	in curr, PINB
	andi curr, 0b00000011
	cp prev, curr
	brne to_rpg_handler
	rjmp system_listener



set_modeAB:
	ldi R26, 0x01
	eor mode, R26 ; 0x00 eor 0x01 = 0x01, 0x01 eor 0x01 = 0x00	
	cbi PORTB, 5 ; set to command mode
	;rcall lcd_clear
	;rcall cursor_home
	sbi PORTB, 5
	cpi mode, 0x00
	brne display_modeA
	rjmp display_modeB

display_modeA:
	rcall bottom_line_mode
	ldi r30, LOW(2*msg2)
	ldi r31, HIGH(2*msg2)
	rcall display_static
	reti

display_modeB:
	rcall bottom_line_mode
	ldi r30, LOW(2*msg3)
	ldi r31, HIGH(2*msg3)
	rcall display_static
	reti

display_static:
	lpm r0,Z+ ; r0 <-- first byte
	tst r0 ; Reached end of message ?
	breq done_static ; Yes => quit
	swap r0 ; Upper nibble in place
	out PORTC,r0 ; Send upper nibble out
	rcall lcd_strobe ; Latch nibble
	swap r0 ; Lower nibble in place
	out PORTC,r0 ; Send lower nibble out
	rcall lcd_strobe ; Latch nibble
	rjmp display_static
  done_static:
	ret

display_dutycycle:
	rcall cursor_home

	ldi r30, LOW(2*msg1)
	ldi r31, HIGH(2*msg1)
	rcall display_static

	;; DISPLAY DC VALUE
	rcall computeDC

	ldi R30, low(dtxt)
	ldi R31, high(dtxt)
	rcall displayDC

	ret

to_rpg_handler:
	rjmp rpg_handler

computeDC:
  .dseg
	dtxt: .BYTE 5 ; allocate mem

  .cseg
	in R22, OCR0B
	lsr R22

	brcs save_5_to_decimal
	rjmp save_0_to_decimal

  save_5_to_decimal:
	ldi R26, 0x35
	sts dtxt+3, R26
	rjmp continue

  save_0_to_decimal:
	ldi R26, 0x30
	sts dtxt+3, R26
	rjmp continue

  continue:
	;; set numerator
	mov dd16uL, R22
	;andi dd16uL, 0b00001111
	ldi dd16uH, 0x00
	;mov dd16uH, R22
	;andi dd16uH, 0b11110000
	;swap dd16uH

	;; set denomonator
	ldi dv16uL, low(10)
	ldi dv16uH, high(10)

	; divide by 10 and store ones place
	rcall div16u
	ldi R20, 0x30
	add R14, R20
	sts dtxt+1, R14

	; divide 10 and store tens place
	rcall div16u
	ldi R20, 0x30
	add R14, R20
	sts dtxt, R14

	; store terminating char for string
	ldi R20, 0x00
	sts dtxt+4, R20

	; generate decimal point
	ldi R20, 0x2e
	sts dtxt+2, R20
	
	ret

displayDC:
	ld R0, Z+
	tst R0
	breq done_dynamic

	;; write upper nibble
	swap R0
	out PORTC, R0
	rcall lcd_strobe

	;; write lower nibble
	swap R0
	out PORTC, R0
	rcall lcd_strobe

	rjmp displayDC
  done_dynamic:
	ret

rpg_handler:
	rcall test_rpg
	; check if AB == 00
	cpi R17, 0b00000000 ; sets Z flag if R17 is 0
	breq stationary ; branch if Z flag set, else continue
	; check if AB == 01
	cpi R17, 0b00000001 ; sets Z flag if the result of the dec operation is 0
	breq counterclockwise; originally clockwise ; branch if Z flag set, else continue
	; check if AB == 10
	cpi R17, 0b00000010 ; sets Z flag if the result of the dec operation is 0
	breq clockwise; originally counterclockwise ; branch if Z flag set, else continue
	; check if AB == 11
	cpi R17, 0b00000011 ; sets Z flag if the result of the dec operation is 0
	breq stationary ; branch if Z flag set, else continue
	rjmp rpg_handler ; finally, continue the loop

test_rpg:
	cpi curr, 0b00000000 ; if curr is 00, immediately xor with prev
	breq exor_prev
	cpi curr, 0b00000011 ; if curr is 11, immediately xor with prev
	breq exor_prev
	mov R17, curr 
	ldi R18, 0b00000011 
	eor R17, R18 ; if curr had 10, R17 will be loaded with 01 
exor_prev: 
	eor R17, prev
	ret
	
stationary:
	rjmp system_listener

clockwise:
	in R26, OCR0B ; current duty cycle
	in R27, OCR0A ; 200
	cp R26, R27
	brne incr
	rjmp system_listener
  incr:
	inc R26
	out OCR0B, R26
	rcall display_dutycycle
	rjmp system_listener

counterclockwise:
	in R26, OCR0B ; load value from OCROA
	tst R26
	brne decr
	rjmp system_listener
  decr:
	dec R26
	out OCR0B, R26
	rcall display_dutycycle
	rjmp system_listener

timer_config:
	ldi R30, 0b00100011 ; WGM01, WGM00 <= 1, 1
	out TCCR0A, R30
	ldi R30, 0b00001001 ; No prescale
	out TCCR0B, R30
	ldi R30, 0xC8 ; OCRA <= 200 (set TOP to 200)
	out OCR0A, R30
	ret

lcd_init:
	rcall delay_100ms 
	ldi R26, 0x03 ; 0x03 	
	rcall lcd_strobe
	rcall delay_5ms 
	ldi R26, 0x03 ; 0x03
	out PORTC, R26 
	rcall lcd_strobe
	rcall delay_200us 
	ldi R26, 0x03 ; 0x03
	out PORTC, R26 
	rcall lcd_strobe
	rcall delay_200us 	 
	ldi R26, 0x02 ; 0x02
	out PORTC, R26 
	rcall lcd_strobe
	rcall delay_5ms 
	ldi R26, 0x02 ; 0x28 upper nibble
	out PORTC, R26 
	rcall lcd_strobe
	rcall delay_200us
	ldi R26, 0x08 ; 0x28 lower nibble
	out PORTC, R26
	rcall lcd_strobe
	rcall delay_200us
	ldi R26, 0x00 ; 0x08 upper nibble
	out PORTC, R26 
	rcall lcd_strobe
	rcall delay_200us
	ldi R26, 0x08 ; 0x08 lower nibble
	out PORTC, R26 
	rcall lcd_strobe
	rcall delay_200us
	rcall lcd_clear
	ldi R26, 0x00 ; 0x06 upper nibble
	out PORTC, R26 
	rcall lcd_strobe
	rcall delay_200us
	ldi R26, 0x06 ; 0x06 lower nibble
	out PORTC, R26 
	rcall lcd_strobe
	rcall delay_5ms
	ldi R26, 0x00 ; 0x0C upper nibble
	out PORTC, R26
	rcall lcd_strobe
	rcall delay_200us
	ldi R26, 0x0C ; 0x0C lower nibble
	out PORTC, R26 
	rcall lcd_strobe
	rcall delay_5ms
	ret

bottom_line_mode:
	cbi PORTB, 5 ; set to command mode
	rcall delay_200us 
	ldi R26, 0b1100 ; 1100 0000 upper nibble
	out PORTC, R26 
	rcall lcd_strobe
	rcall delay_200us
	ldi R26, 0b0000 ; 1100 0000 lower nibble
	out PORTC, R26 
	rcall lcd_strobe
	sbi PORTB, 5 ; set to data mode
	ret

cursor_home:
	cbi PORTB, 5 ; set to command mode
	rcall delay_200us
	ldi R26, 0b1000 ;1000 0000 upper nibble
	out PORTC, R26 
	rcall lcd_strobe
	rcall delay_200us
	ldi R26, 0x00 ; 1000 0000 lower nibble
	out PORTC, R26 
	rcall lcd_strobe
	rcall delay_5ms 
	sbi PORTB, 5 ; set to data mode
	ret

lcd_clear:
	rcall delay_200us
	ldi R26, 0x00 ;0x01 upper nibble
	out PORTC, R26 
	rcall lcd_strobe
	rcall delay_200us
	ldi R26, 0x01
	out PORTC, R26 ; 0x01 upper nibble
	rcall lcd_strobe
	rcall delay_5ms 
	ret

lcd_strobe:
	cbi PORTB, 3 ; drive E low
	rcall delay_200us ; delay
	sbi PORTB, 3 ; drive E hight 
	rcall delay_200us
	cbi PORTB, 3 ; drive E low
	ret

delay_100ms:
    ; 100ms at 8 MHz
		ldi  r18, 6
		ldi  r19, 15
		ldi  r20, 242
	L1: dec  r20
		brne L1
		dec  r19
		brne L1
		dec  r18
		brne L1
		ret

delay_5ms:
		ldi  r18, 53
		ldi  r19, 242
	L2: dec  r19
		brne L2
		dec  r18
		brne L2
		nop
		ret

delay_200us:
		ldi  r18, 4
		ldi  r19, 19
	L3: dec  r19
		brne L3
		dec  r18
		brne L3
		ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Divide 16 bit number routine from Atmel ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
div16u:	clr	drem16uL	;clear remainder Low byte
	sub	drem16uH,drem16uH;clear remainder High byte and carry
	ldi	dcnt16u,17	;init loop counter
d16u_1:	rol	dd16uL		;shift left dividend
	rol	dd16uH
	dec	dcnt16u		;decrement counter
	brne	d16u_2		;if done
	ret			;    return
d16u_2:	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_3		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_1		;else
d16u_3:	sec			;    set carry to be shifted into result
	rjmp	d16u_1