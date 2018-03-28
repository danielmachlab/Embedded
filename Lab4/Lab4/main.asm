;;
;; Lab 4
;; Ted Paulsen, Daniel Machlab
;;

; cbi is input sbi is output
cbi DDRB, 0 ; input - from A
cbi DDRB, 1 ; input - from B
sbi DDRB, 2 ; output - clockwise (A side) LED
sbi DDRB, 3
sbi DDRB, 5 ; output to RS line of lcd
sbi DDRC, 3 ; output PC3 - D7
sbi DDRC, 2 ; output PC2 - D6
sbi DDRC, 1 ; output PC1 - D5
sbi DDRC, 0 ; output PC0 - D4

; SETUP WORK 
.def curr = R20 ; R20 is the current rpg reading
.def prev = R21 ; R21 is the previous rpg reading
.def count_temp = R19

.def tmp1 = R23
.def tmp2 = R24
.def count_30 = R25
.def count_rpg = R22
.def count_rpg_2 = R16
//.def temp_var = R29

ldi count_30, 0xA3	; preload count_30 to 160
ldi count_rpg, 140	; preload count_rpg to 140
ldi count_temp, 1
ldi count_rpg, 180

rcall lcd_init

rcall write_letter_A_to_lcd
;rcall pt

;il: rjmp il

rcall timer_config

; load both prev and curr with same initial readings
in curr, PINB ; load inputs into prev
andi curr, 0b00000011 ; mask out all signals but A & B
mov prev, curr ; copy contents of curr into prev
rcall delay ; delay a lil bit

; create static strings in memory
;msg1: .db "DC = ", 0x00 ;;mem reserved with .db must be an even number of bytes. If odd, padded with extra byte by assembler. 
;msg2: .db "% =", 0x00

rjmp rpg_listener ; listen for rpg changes infinitely

; this is my most recent attempt at initializing the lcd
; it follows LINE FOR LINE from slide number 44 (not page number) of the LCD lecture slides
; ASCII code for 'A' is 41 hex
; upper nibble is 0x04, lower nibble is 0x01

write_letter_A_to_lcd:
	; set to data mode
	sbi PORTB, 5
	; write upper nibble
	ldi R26, 0101
	out PORTC, R26
	rcall lcd_strobe

	rcall delay_100us

	; write lower nibble
	ldi R26, 0011
	out PORTC, R26
	rcall lcd_strobe

	rcall delay_100ms
	ret


pt:
	sf25: .DB "R "
	ldi r24, 2
	ldi r30, LOW(2*sf25)
	ldi r31, HIGH(2*sf25)

displayCString:
	sbi PORTB, 5
L20:
	lpm
	swap r0
	out PORTC, r0
	rcall lcd_strobe
	rcall delay_100us
	swap r0
	out PORTC, r0
	rcall lcd_strobe
	rcall delay_100us
	adiw zh:zl,1
	dec r24
	brne L20
	ret

	

rpg_listener:
	;rcall lightoff
	in prev, PINB
	andi prev, 0b00000011

	rcall lighton
	rcall delay_30_percent	; delay for 77 us
	rcall delay_rpg_p1 //108us		; delay for 103 us
	rcall lightoff
	rcall delay_rpg_p2 //3 us
	rcall delay_30_percent

	;rcall delay
	in curr, PINB
	andi curr, 0b00000011
	cp prev, curr
	brne rpg_handler
	rjmp rpg_listener 

; This is the infinite loop which reads new inputs
; and handles the changes
rpg_handler:
	;rcall lighton
	
	;rcall read_input
	;rcall delay
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

lighton:
	sbi PORTB, 2
	ret

lightoff:
	cbi PORTB, 2
	ret

; subroutine which transfers curr into prev
; and then loads new reading into curr
;read_input:
;	mov prev, curr ; copy current readings into prev
;	in curr, PINB ; load new readings
;	andi curr, 0b00000011 ; mask out only signals A & B
;	ret

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
	

; subroutine to handle when the rpg is stationary
; currently it turns off both LEDs
stationary:
	rjmp rpg_listener

; subroutine to hande when rpg is turning clockwise
clockwise:
	cpi count_rpg, 130
	breq rpg_listener
	subi count_rpg, 1
	rjmp rpg_listener

; subroutine to hande when rpg is turning counter-clockwise 
counterclockwise:
	ldi count_temp, 1
	cpi count_rpg, 200
	breq rpg_listener
	add count_rpg, count_temp
	rjmp rpg_listener

; a delay routine
delay:
	ldi r26, 2
t4: ldi r27, 25
t5:	ldi r28, 50
t6:	dec r28
	nop
	brne t6
    dec r27
	nop
	brne t5
	dec R26
	brne t4
	ret

timer_config:
	ldi R30, 0x23 ; WGM01, WGM00 <= 1, 1
	out TCCR0A, R30
	ldi R30, 0b00001010 ; WGM02 <= 1
	out TCCR0B, R30
	ldi R30, 0xC8 ; OCR0A <= 200
	out OCR0A, R30
	ret

delay_30_percent:
	; Stop timer
	in tmp1, TCCR0B		; Save configuration
	ldi tmp2, 0x00		; Stop timer 0
	out TCCR0B, tmp2	;

	; Clear timer overflow flag
	in tmp2, TIFR0		; tmp <-- TIFR0 
	sbr tmp2, 1<<TOV0	; clear TOV0, write logic 1
	out TIFR0, tmp2		; write config back to TIFR0

	; Set initial counter offset and start
	out TCNT0, count_30    ; load counter
	out TCCR0B, tmp1    ; restart timer
wait_30:
	in tmp2, TIFR0		; tmp <-- TIFR0 
	sbrs tmp2, TOV0		; check overflow flag
	rjmp wait_30
	ret

delay_rpg_p1:
	; Stop timer
	in tmp1, TCCR0B		; Save configuration
	ldi tmp2, 0x00		; Stop timer 0
	out TCCR0B, tmp2	;

	; Clear timer overflow flag
	in tmp2, TIFR0		; tmp <-- TIFR0 
	sbr tmp2, 1<<TOV0	; clear TOV0, write logic 1
	out TIFR0, tmp2		; write config back to TIFR0

	; Set initial counter offset and start
	out TCNT0, count_rpg    ; load counter
	out TCCR0B, tmp1    ; restart timer
wait_p1:
	in tmp2, TIFR0		; tmp <-- TIFR0 
	sbrs tmp2, TOV0		; check overflow flag
	rjmp wait_p1
	ret

delay_rpg_p2:
	; Stop timer
	in tmp1, TCCR0B		; Save configuration
	ldi tmp2, 0x00		; Stop timer 0
	out TCCR0B, tmp2	;

	; Clear timer overflow flag
	in tmp2, TIFR0		; tmp <-- TIFR0 
	sbr tmp2, 1<<TOV0	; clear TOV0, write logic 1
	out TIFR0, tmp2		; write config back to TIFR0

	; Set initial counter offset and start 
	mov count_temp, count_rpg
	ldi count_rpg_2, 255
	subi count_temp, 130
	sub count_rpg_2, count_temp
	out TCNT0, count_rpg_2    ; load counter
	out TCCR0B, tmp1    ; restart timer
wait_p2:
	in tmp2, TIFR0		; tmp <-- TIFR0 
	sbrs tmp2, TOV0		; check overflow flag
	rjmp wait_p2
	ret





//LCD INITILZSLD
lcd_init:
	rcall delay_100ms ; line 1 -- 100 ms
	rcall lcd_init_3 ; line 2 -- (0x03)

	rcall delay_5ms ; line 3 -- 5 ms
	rcall lcd_init_3 ; line 4 -- (0x03)

	rcall delay_200us ; line 5	
	rcall lcd_init_3 ; line 6 -- (0x03)

	rcall delay_200us ; line 7 	 
	rcall lcd_init_2 ; line 8 -- (0x02)

	rcall delay_5ms ; line 9
	rcall lcd_init_2 ; line 10a -- upper nibble (0x28)

	rcall delay_200us
	rcall lcd_init_8; line 10 b -- lower nibble (0x28)

	rcall delay_200us
	rcall lcd_init_0 ; line 11 a -- upper nibble (0x08)

	rcall delay_200us
	rcall lcd_init_8 ; line 11b -- lower nibble (0x08)

	rcall delay_200us
	rcall lcd_init_0 ; line 12a -- upper nibble (0x01)

	rcall delay_200us
	rcall lcd_init_1 ; line 12b -- lower nibble (0x01)

	rcall delay_5ms 
	rcall lcd_init_0 ; line 13a -- upper nibble (0x06)

	rcall delay_200us
	rcall lcd_init_6 ; line 13b -- upper nibble (0x06)

	rcall delay_5ms
	rcall lcd_init_0 ; line 14a -- upper nibble (0x0C)

	rcall delay_200us
	rcall lcd_init_C ; line 14b -- upper nibble (0x0C)

	ret

lcd_init_0:
	ldi R26, 0x00
	cbi PORTB, 5
	out PORTC, R26 ; line 11a -- write 08 hex (upper nibble then lower nibble)
	rcall lcd_strobe

lcd_init_1:
	ldi R26, 0x01
	cbi PORTB, 5
	out PORTC, R26 ; line 11a -- write 08 hex (upper nibble then lower nibble)
	rcall lcd_strobe

lcd_init_2:
	ldi R26, 0x02
	cbi PORTB, 5 ; set RS low
	out PORTC, R26 ;line 8 -- write 0x02 with RS=0 (set to 4-bit mode)
	rcall lcd_strobe
	ret

lcd_init_3:
	ldi R26, 0x03
	cbi PORTB, 5 
	out PORTC, R26 ; line 2 -- write 0x03 with RS=0 (set to 8-bit mode)
	rcall lcd_strobe
	ret

lcd_init_6:
	ldi R26, 0x06
	cbi PORTB, 5
	out PORTC, R26 ; line 11a -- write 08 hex (upper nibble then lower nibble)
	rcall lcd_strobe
	
lcd_init_8:
	ldi R26, 0x08
	cbi PORTB, 5
	out PORTC, R26; line 10b -- lower nibble
	rcall lcd_strobe
	ret

lcd_init_C:
	ldi R26, 0x0C
	cbi PORTB, 5
	out PORTC, R26 ; line 11a -- write 08 hex (upper nibble then lower nibble)
	rcall lcd_strobe

delay_100ms:
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

delay_100us:
		ldi  r18, 3
		ldi  r19, 9
	L4: dec  r19
		brne L4
		dec  r18
		brne L4
		ret

lcd_strobe:
	cbi PORTB, 3 ; drive E low
	rcall delay_200us ; delay
	sbi PORTB, 3 ; drive E hight 
	rcall delay_200us
	;cbi PORTB, 3 ; drive E low
	ret