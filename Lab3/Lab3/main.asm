;; Lab 3
;; Ted Paulsen, Daniel Machlab
;; Embedded Systems

; cbi is input sbi is output
cbi DDRB, 0 ; input - from A
cbi DDRB, 1 ; input - from B
sbi DDRB, 2 ; output - clockwise (A side) LED
sbi DDRB, 5 ; output - counterclockwise (B side) LED

; SETUP WORK 
.def curr = R16 ; R16 is the current rpg reading
.def prev = R15 ; R15 is the previous rpg reading 

; load both prev and curr with same initial readings
in curr, PINB ; load inputs into prev
andi curr, 0b00000011 ; mask out all signals but A & B
mov prev, curr ; copy contents of curr into prev
rcall delay ; delay a lil bit

; This is the infinite loop which reads new inputs
; and handles the changes
loop:
	; rcall delay
	rcall read_input

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





	; check if AB == 00
	cpi R17, 0b00000000 ; sets Z flag if R17 is 0
	breq stationary ; branch if Z flag set, else continue

	; check if AB == 01
	cpi R17, 0b00000001 ; sets Z flag if the result of the dec operation is 0
	breq clockwise ; branch if Z flag set, else continue

	; check if AB == 10
	cpi R17, 0b00000010 ; sets Z flag if the result of the dec operation is 0
	breq counterclockwise ; branch if Z flag set, else continue

	; check if AB == 11
	cpi R17, 0b00000011 ; sets Z flag if the result of the dec operation is 0
	breq stationary ; branch if Z flag set, else continue

	rjmp loop ; finally, continue the loop

; subroutine which transfers curr into prev
; and then loads new reading into curr
read_input:
	mov prev, curr ; copy current readings into prev
	in curr, PINB ; load new readings
	andi curr, 0b00000011 ; mask out only signals A & B
	ret

; subroutine to handle when the rpg is stationary
; currently it turns off both LEDs
stationary:
	cbi PORTB, 2 ; turn off LED A
	cbi PORTB, 5 ; turn off LED B
	rjmp loop

; subroutine to hande when rpg is turning clockwise
; currently it runs on the right LED
clockwise:
	cbi PORTB, 2 ; turn off LED A
	sbi PORTB, 5 ; turn on LED B
	rjmp loop

; subroutine to hande when rpg is turning counter-clockwise
; currently it runs on the left LED 
counterclockwise:
	sbi PORTB, 2 ; turn on LED A
	cbi PORTB, 5 ; turn off LED B
	rjmp loop

; a delay routine
delay:
	ldi r26, 255
t4: ldi r27, 255
t5: dec r27
	nop
	brne t5
	dec r26
	brne t4
	ret