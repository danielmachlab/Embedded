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
rcall zero
rcall pbtest

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

;count:
	;ldi R20, 0x00 ; set count back to zero
;loop:
	;inc R20 ; increment register
	;sbis PINB, 4 ; check if push button is still down
	;ret ; if its not still pushed down, ret, else delay
	;rcall delay_short ; delay for 100ms

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
	ret

rotate:
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


pbtest:
	;in r19, PINB
	ldi   r21, 255
	;sbic PINB, 4 ;skip next instruction if input is cleared or something. works with input direct to 5v bus.
	;rcall zero
	
	sbis PINB, 4
	rcall nextnum

	rcall delay
	dec r21
	brne pbtest

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
	ret
	;rjmp display
	
one:
	ldi R16, 0b00000110
	rcall display
	ret
	;rjmp display
	
two:
	ldi R16, 0b01011011
	rcall display
	ret
	;rjmp display
	
three:
	ldi R16, 0b01001111
	rcall display
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
	  ldi   r23, 4      ; r23 <-- Counter for outer loop
  e1: ldi   r24, 255    ; r24 <-- Counter for level 2 loop 
  e2: ldi   r25, 246    ; r25 <-- Counter for inner loop
  e3: dec   r25
      nop               ; no operation
      brne  e3 
      dec   r24
      brne  e2
      dec   r23
      brne  e1
      ret

k1:rjmp one