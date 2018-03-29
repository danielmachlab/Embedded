;;
;; Lab 4
;; Ted Paulsen, Daniel Machlab
;;
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
cbi DDRD, 2 ; input from onboard pushbutton


;; DATA LINES TO LCD
sbi DDRC, 3 ; output PC3 - D7
sbi DDRC, 2 ; output PC2 - D6
sbi DDRC, 1 ; output PC1 - D5
sbi DDRC, 0 ; output PC0 - D4

;; RPG readings
.def curr = R20 ; R20 is the current rpg reading
.def prev = R21 ; R21 is the previous rpg reading

;; LCD data
.def write = R16
.def duty_cycle = R23
.def mode = R29 ; 0x00 is mode a, 0x01 is mode b

ldi mode, 0x00
;; free registers: R24, R25, R26, R28, R29


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PUBLIC STATIC VOID MAIN 

cbi PORTB, 5 ; set to command mode
rcall lcd_init
sbi PORTB, 5 ; set to data mode

rjmp skip

msg1: .DB "DC = ", 0x00
msg2: .DB "Mode A: ", 0x00, 0x00
msg3: .DB "Mode B: ", 0x00, 0x00

skip:



;rcall display_static
;rcall write_letter
rcall display_modeA

rcall timer_config

ldi duty_cycle, 100
out OCR0B, duty_cycle
rjmp rpg_listener

;; END MAIN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; load both prev and curr with same initial readings
in curr, PINB ; load inputs into prev
andi curr, 0b00000011 ; mask out all signals but A & B
mov prev, curr ; copy contents of curr into prev
rcall delay_100ms ; delay a lil bit

; create static strings in memory
;msg1: .db "DC = ", 0x00 ;;mem reserved with .db must be an even number of bytes. If odd, padded with extra byte by assembler. 
;msg2: .db "% =", 0x00

write_letter:
	rcall delay_100ms
	; set to data mode
	sbi PORTB, 5
	; write upper nibble
	ldi write, 0b00000100
	out PORTC, write

	rcall lcd_strobe
	rcall delay_100ms

	; write lower nibble
	ldi write, 0b00000001
	out PORTC, write
	rcall lcd_strobe
	rcall delay_100ms
	ret

display_modeA:
	ldi r30, LOW(2*msg1)
	ldi r31, HIGH(2*msg1)
	rcall display_static

	cbi PORTB, 5 ; set to command mode
	rcall delay_200us 
	ldi R26, 0b1100
	out PORTC, R26 
	rcall lcd_strobe
	rcall delay_200us
	ldi R26, 0b0000
	out PORTC, R26 
	rcall lcd_strobe
	sbi PORTB, 5 ; set to data mode

	ldi r30, LOW(2*msg2)
	ldi r31, HIGH(2*msg2)
	rcall display_static
	rjmp rpg_listener

display_modeB:
	ldi r30, LOW(2*msg1)
	ldi r31, HIGH(2*msg1)
	rcall display_static

	cbi PORTB, 5 ; set to command mode
	rcall delay_200us 
	ldi R26, 0b1100
	out PORTC, R26 
	rcall lcd_strobe
	rcall delay_200us
	ldi R26, 0b0000
	out PORTC, R26 
	rcall lcd_strobe
	sbi PORTB, 5 ; set to data mode

	ldi r30, LOW(2*msg3)
	ldi r31, HIGH(2*msg3)
	rcall display_static
	rjmp rpg_listener
	

display_static:
	lpm r0,Z+ ; r0 <-- first byte
	tst r0 ; Reached end of message ?
	breq done_static ; Yes => quit
	swap r0 ; Upper nibble in place
	out PORTC,r0 ; Send upper nibble out
	rcall lcd_strobe ; Latch nibble
	//rcall delay_200us
	swap r0 ; Lower nibble in place
	out PORTC,r0 ; Send lower nibble out
	rcall lcd_strobe ; Latch nibble
	//rcall delay_200us
	rjmp display_static
  done_static:
	ret

display_dynamic:
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

	rjmp display_dynamic
  done_dynamic:
	ret

set_mode:
	ldi R26, 0x01
	eor mode, R26 ; 0x00 eor 0x01 = 0x01, 0x01 eor 0x01 = 0x00	
	
	cpi mode, 0x00
	brne display_modeA
	rjmp display_modeB

	ret

rpg_listener:
	;; button listener
	sbis PIND, 2
	rcall set_mode
	;rcall lightoff
	in prev, PINB
	andi prev, 0b00000011
	rcall lighton
	rcall lightoff
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

;; subroutine to hande when rpg is turning clockwise
;; if [OCR0B] == TOP -> do nothing
;; else increment
clockwise:
	in R26, OCR0B ; current duty cycle
	in R27, OCR0A ; 200
	cp R26, R27
	brne incr
	rjmp rpg_listener
  incr:
	inc R26
	out OCR0B, R26
	rjmp rpg_listener

;; subroutine to hande when rpg is turning counter-clockwise
;; if [OCR0B] == 0 -> decrement
;; else keep at zero
counterclockwise:
	in R26, OCR0B ; load value from OCROA
	tst R26
	brne decr
	rjmp rpg_listener
  decr:
	dec R26
	out OCR0B, R26
	rjmp rpg_listener

timer_config:
	ldi R30, 0b00100011 ; WGM01, WGM00 <= 1, 1
	out TCCR0A, R30
	ldi R30, 0b00001001 ; No prescale
	out TCCR0B, R30
	ldi R30, 0xC8 ; OCRA <= 200 (set TOP to 200)
	out OCR0A, R30
	ret

lcd_init:
	rcall delay_100ms ; line 1 -- 100 ms
	
	ldi R26, 0x03
	out PORTC, R26 ; line 2 -- write 0x03 with RS=0 (set to 8-bit mode)
	rcall lcd_strobe

	rcall delay_5ms ; line 3 -- 5 ms
	
	ldi R26, 0x03
	out PORTC, R26 ; line 4 -- write 0x03 with RS=0 (set to 8-bit mode)
	rcall lcd_strobe

	rcall delay_200us ; line 5	
	 
	ldi R26, 0x03
	out PORTC, R26 ;line 6 -- write 0x03 with RS=0 (set to 8-bit mode)
	rcall lcd_strobe

	rcall delay_200us ; line 7 	 

	ldi R26, 0x02
	out PORTC, R26 ;line 8 -- write 0x02 with RS=0 (set to 4-bit mode)
	rcall lcd_strobe

	rcall delay_5ms ; line 9
		
	ldi R26, 0x02
	out PORTC, R26 ; line 10a -- write 28 hex (upper nibble then lower nibble) 
	rcall lcd_strobe

	rcall delay_200us

	ldi R26, 0x08
	out PORTC, R26; line 10b -- lower nibble
	rcall lcd_strobe

	rcall delay_200us

	ldi R26, 0x00
	out PORTC, R26 ; line 11a -- write 08 hex (upper nibble then lower nibble)
	rcall lcd_strobe

	rcall delay_200us
	
	ldi R26, 0x08
	out PORTC, R26 ; line 11b -- lower nibble
	rcall lcd_strobe

	rcall delay_200us

	ldi R26, 0x00
	out PORTC, R26 ; line 11a -- write 08 hex (upper nibble then lower nibble)
	rcall lcd_strobe

	rcall delay_200us
	
	ldi R26, 0x01
	out PORTC, R26 ; line 11b -- lower nibble
	rcall lcd_strobe

	rcall delay_5ms 

	ldi R26, 0x00
	out PORTC, R26 ; line 12a -- write 01 hex (upper nibble then lower nibble)
	rcall lcd_strobe

	rcall delay_200us

	ldi R26, 0x06
	out PORTC, R26 ; line 12b -- lower nibble
	rcall lcd_strobe

	rcall delay_5ms

	ldi R26, 0x00
	out PORTC, R26; line 13a -- write 06 hex (upper nibble then lower nibble)
	rcall lcd_strobe

	rcall delay_200us

	ldi R26, 0x0C
	out PORTC, R26 ; line 13b -- lower nibble
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