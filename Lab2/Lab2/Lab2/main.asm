; put code here to configure I/O lines
; connected to TPIC6C595 as output
...
; start main program
sbi DDRB, 1 ; set PORTB, 1 to output (srck)
sbi DDRB, 2 ; set PORTB, 2 to output (rck)
sbi DDRB, 0 ; set PORTB, 0 to input (ser_in)
...
; display a digit
ldi R16, 0b00111111 ; load pattern to display
rcall display ; call display subroutine

display:
	; backup used registers on stack
	push R16
	push R17
	in R17, SREG
	push R17
	ldi R17, 8 ; loop --> test all 8 bits
loop:
	rol R16 ; rotate left trough Carry
	BRCS set_ser_in_1 ; branch if Carry set
	; put code here to set SER_IN to 0
	cbi PORTB, 0 ; maybe
	rjmp end
set_ser_in_1:
	; put code here to set SER_IN to 1
	sbi PORTB, 0 ; maybe
end:
	; put code here to generate SRCK pulse
	sbi PORTB, 1 ; set srck high
	nop
	nop
	cbi PORTB, 1 ; set srck low

	nop
	nop
	dec R17
	brne loop
	; put code here to generate RCK pulse
	sbi PORTB, 2 ; set rck low
	nop
	nop
	cbi PORTB, 2


	; restore registers from stack
	pop R17
	out SREG, R17
	pop R17
	pop R16
	ret