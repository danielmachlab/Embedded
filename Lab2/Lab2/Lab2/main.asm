; put code here to configure I/O lines
; connected to TPIC6C595 as output
...
; start main program
sbi DDRB, 1 ; set PORTB, 1 to output (srck)
sbi DDRB, 2 ; set PORTB, 2 to output (rck)
sbi DDRB, 0 ; set PORTB, 0 to output (ser_in)
cbi DDRB, 4 ; pet PINB, 4 to input
...
; display a digit
;ldi R16, 0b01100111 ; load pattern to display
;rcall five
;rcall display ; call display subroutine
;rcall pbtest
;rcall rotate ;goal: display all numbers starting at 0 going to 9
ldi R20, 1
ldi R28, 0
rcall four
rcall buttonlistener

;init:
	; show zero
	;rcall zero
	;rcall display
	;rcall delay
	; go to increment mode
	;rjmp incr

;incr:
;loop:
	; check input pin for push button active
	;	if it is pushed, branch to count
	;	else do nothing
	;
	; check value of reg from count
	;	if it is high --> reset
	;	if it is medium --> decr
	;	else inc R16, display

;decr:
;loop:
	; check if pin is active
	;	if it is pushed, branch to count
	;	else do nothing
	;
	; check value of reg from count
	;	if it is high --> reset
	;	if it is medium --> incr
	;	else dec R16, display


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
	cbi PORTB, 1 ; set srck low
	dec R17
	brne loop
	; put code here to generate RCK pulse
	sbi PORTB, 2 ; set rck high
	cbi PORTB, 2 ; set rck low
	; restore registers from stack
	pop R17
	out SREG, R17
	pop R17
	pop R16
	ret ;rjmp runcounter ; ret

count:
	ldi R28, 0x00 ; set count back to zero
count_loop:
	inc R28 ; increment register
	sbic PINB, 4 ; check if push button is still down
	rjmp runcounter ; if its not still pushed down, ret, else delay
	rcall delay_short ; delay for 100ms
	rjmp count_loop

buttonlistener:
	sbis PINB, 4
	rcall count
	rjmp buttonlistener

runcounter:
	;subi R28, 0x0A ; minus 1s
	cpi R28, 0x0A
	brsh zero
	cpi R28, 0x0A
	brlo nextnum
	;brne one ; t<1s

	;subi R28, 0x0A
	;brne one ; switch mode

	;subi R28, 0x0A
	;brne zero ; reset

	;rcall delay
	rjmp buttonlistener


lastnum:
	cpi R16, 0b00111111 ; zero
	breq nine

	cpi R16, 0b00000110
	breq zero

	cpi R16, 0b01011011
	breq one

	cpi R16, 0b01001111
	breq two
	
	cpi R16, 0b01100110
	breq three
	
	cpi R16, 0b01101101
	breq four
	
	cpi R16, 0b01111101
	breq five
	
	cpi R16, 0b00000111
	breq six
	
	cpi R16, 0b01111111
	breq seven
	
	cpi R16, 0b01100111
	breq eight




nextnum:
	cpi R16, 0b00111111 ; zero
	breq one

	cpi R16, 0b00000110
	breq two

	cpi R16, 0b01011011
	breq three

	cpi R16, 0b01001111
	breq four
	
	cpi R16, 0b01100110
	breq five
	
	cpi R16, 0b01101101
	breq six
	
	cpi R16, 0b01111101
	breq seven
	
	cpi R16, 0b00000111
	breq eight
	
	cpi R16, 0b01111111
	breq nine
	
	cpi R16, 0b01100111
	breq zero
	
	;rcall delay

zero:
	ldi R16, 0b00111111
	rcall display
	rjmp buttonlistener
	;rjmp display
	
one:
	ldi R16, 0b00000110
	rcall display
	rjmp buttonlistener
	;rjmp display
	
two:
	ldi R16, 0b01011011
	rcall display
	rjmp buttonlistener
	;rjmp display
	
three:
	ldi R16, 0b01001111
	rcall display
	rjmp buttonlistener
	;rjmp display
	
four:
	ldi R16, 0b01100110
	rcall display
	rjmp buttonlistener
	;rjmp display

nine: 
	ldi R16, 0b01100111
	rcall display
	rjmp buttonlistener
	;rjmp display
		
five:
	ldi R16, 0b01101101
	rcall display
	rjmp buttonlistener
	;rjmp display
	
six:
	ldi R16, 0b01111101
	rcall display
	rjmp buttonlistener
	;rjmp display
	
seven:
	ldi R16, 0b00000111
	rcall display
	rjmp buttonlistener
	;rjmp display

eight:
	ldi R16, 0b01111111
	rcall display
	rjmp buttonlistener
	;rjmp display




delay:
      ldi   r23, 4      ; r23 <-- Counter for outer loop
  d1: ldi   r24, 100    ; r24 <-- Counter for level 2 loop 
  d2: ldi   r25, 100    ; r25 <-- Counter for inner loop
  d3: dec   r25
      nop               ; no operation
      brne  d3 
      dec   r24
      brne  d2
      dec   r23
      brne  d1
      ret

delay_short:
      ldi   r23, 4 ;10     ; r23 <-- Counter for outer loop
  t1: ldi   r24, 203     ; r24 <-- Counter for level 2 loop 
  t2: ldi   r25, 246    ; r25 <-- Counter for inner loop
  t3: dec   r25
      nop               ; no operation 
      brne  t3 
      dec   r24
      brne  t2
      dec   r23
      brne  t1

	  ldi r26, 10 ;98
  t4: ldi r27, 20
  t5: dec r27
	  nop
	  brne t5
	  dec r26
	  brne t4
      ret

k1:rjmp one