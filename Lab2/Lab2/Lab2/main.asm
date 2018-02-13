; put code here to configure I/O lines
; connected to TPIC6C595 as output
...
; start main program
sbi DDRB, 1 ; set PORTB, 1 to output (srck)
sbi DDRB, 2 ; set PORTB, 2 to output (rck)
sbi DDRB, 0 ; set PORTB, 0 to input (ser_in)
...
; display a digit
;ldi R16, 0b01100111 ; load pattern to display
;rcall five
;rcall display ; call display subroutine
rcall rotate ;goal: display all numbers starting at 0 going to 9

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
	nop			 ; wait
	cbi PORTB, 1 ; set srck low
	nop
	dec R17
	brne loop
	; put code here to generate RCK pulse
	sbi PORTB, 2 ; set rck high
	nop			 ; wait
	cbi PORTB, 2 ; set rck low

	; restore registers from stack
	pop R17
	out SREG, R17
	pop R17
	pop R16
	ret

rotate: ;doesn't work as planned :/
	rcall zero
	rcall display
	rcall delay

	rcall one
	rcall display
	rcall delay

	rcall two
	rcall display
	rcall delay

	rcall three
	rcall display
	rcall delay

	ret
	;etc downto 9
	

zero:
	ldi R16, 0b00111111
	ret
	;rjmp display
	
one:
	ldi R16, 0b00000110
	ret
	;rjmp display
	
two:
	ldi R16, 0b01011011
	ret
	;rjmp display
	
three:
	ldi R16, 0b01001111
	ret
	;rjmp display
	
four:
	ldi R16, 0b01100110
	ret
	;rjmp display
	
five:
	ldi R16, 0b01101101
	ret
	;rjmp display
	
six:
	ldi R16, 0b01111101
	ret
	;rjmp display
	
seven:
	ldi R16, 0b00000111
	ret
	;rjmp display

eight:
	ldi R16, 0b01111111
	ret
	;rjmp display

nine: 
	ldi R16, 0b01100111
	ret
	;rjmp display


delay:
      ldi   r23, 4      ; r23 <-- Counter for outer loop
  d1: ldi   r24, 255    ; r24 <-- Counter for level 2 loop 
  d2: ldi   r25, 246    ; r25 <-- Counter for inner loop
  d3: dec   r25
      nop               ; no operation
      brne  d3 
      dec   r24
      brne  d2
      dec   r23
      brne  d1
      ret