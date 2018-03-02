;; Lab 3
;; Ted Paulsen, Daniel Machlab
;; Embedded Systems

; cbi is input sbi is output
cbi DDRB, 0 ; input - from A
cbi DDRB, 1 ; input - from B
sbi DDRB, 2 ; output - clockwise (A side) LED

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
ldi count_temp, 5
ldi count_rpg, 240

rcall timer_config


; load both prev and curr with same initial readings
in curr, PINB ; load inputs into prev
andi curr, 0b00000011 ; mask out all signals but A & B
mov prev, curr ; copy contents of curr into prev
rcall delay ; delay a lil bit

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
	subi count_rpg, 5
	rjmp rpg_listener

; subroutine to hande when rpg is turning counter-clockwise 
counterclockwise:
	ldi count_temp, 5
	cpi count_rpg, 255
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
	ldi R30, 0x02
	out 0x33, R30
	ret

delay_30_percent:
	; Stop timer
	in tmp1, TCCR0B		; Save configuration
	ldi tmp2, 0x00		; Stop timer 0
	out TCCR0B, tmp2	;

	; Clear timer overflow flag
	in tmp2, TIFR		; tmp <-- TIFR 
	sbr tmp2, 1<<TOV0	; clear TOV0, write logic 1
	out TIFR, tmp2		; write config back to TIFR

	; Set initial counter offset and start
	out TCNT0, count_30    ; load counter
	out TCCR0B, tmp1    ; restart timer

wait_30:
	in tmp2, TIFR		; tmp <-- TIFR 
	sbrs tmp2, TOV0		; check overflow flag
	rjmp wait_30
	ret

delay_rpg_p1:
	; Stop timer
	in tmp1, TCCR0B		; Save configuration
	ldi tmp2, 0x00		; Stop timer 0
	out TCCR0B, tmp2	;

	; Clear timer overflow flag
	in tmp2, TIFR		; tmp <-- TIFR 
	sbr tmp2, 1<<TOV0	; clear TOV0, write logic 1
	out TIFR, tmp2		; write config back to TIFR

	; Set initial counter offset and start
	out TCNT0, count_rpg    ; load counter
	out TCCR0B, tmp1    ; restart timer

wait_p1:
	in tmp2, TIFR		; tmp <-- TIFR 
	sbrs tmp2, TOV0		; check overflow flag
	rjmp wait_p1
	ret


delay_rpg_p2:
	; Stop timer
	in tmp1, TCCR0B		; Save configuration
	ldi tmp2, 0x00		; Stop timer 0
	out TCCR0B, tmp2	;

	; Clear timer overflow flag
	in tmp2, TIFR		; tmp <-- TIFR 
	sbr tmp2, 1<<TOV0	; clear TOV0, write logic 1
	out TIFR, tmp2		; write config back to TIFR

	; Set initial counter offset and start 
	mov count_temp, count_rpg
	ldi count_rpg_2, 255
	subi count_temp, 130
	sub count_rpg_2, count_temp
	out TCNT0, count_rpg_2    ; load counter
	out TCCR0B, tmp1    ; restart timer

wait_p2:
	in tmp2, TIFR		; tmp <-- TIFR 
	sbrs tmp2, TOV0		; check overflow flag
	rjmp wait_p2
	ret
; we need to put a routine here to do that cross xor thing
; that he talked about in class. it vaguely talks about it in 
; the slides where it mentions the gray code for turning.
; basically we need to do this:
;    p1  p0
;      \/
;      /\
;     /  \
;    c1  c0   (XOR)
;   ---------------
;    t1  t0
;
; where p0, p1 represent the 0 and 1 bit of prev and 
; c0, c1 represent the 0 and 1 bit of curr and
; t0, t1 are the 0 and 1 bit of the destination register (R17)
;
; if (t1, t0) == (0, 1) ==> clockwise rotation
; if (t1, t0) == (1, 0) ==> counter-clockwise rotation
; if (t1, t0) == (0, 0) OR (1, 1) ==> stationary