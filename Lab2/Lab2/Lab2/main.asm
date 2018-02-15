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
ldi R22, 0x00
ldi R20, 0b00000000 ;start in countup mode
ldi R28, 0
rcall zero
rcall buttonlistener

display:
	mov R22, R16 ; backup R16
	or R16, R20 ; or R30 with R16
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
	mov R16, R22 ; reset R16 from backup
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
	cpi R28, 0x14 ;if button is held longer than 2 seconds
	brsh reset

	cpi R28, 0x0A ;if button is held longer than 1 second but less than 2 seconds
	brsh switchcount

	cpi R28, 0x0A ;if button is held less than 1 second
	brlo nextnum
		
	rjmp buttonlistener

reset:
	ldi R20, 0b00000000
	rjmp zero

nextnum:
	cpi R20, 0x00 ;0x00 represents countup mode
	breq countup 
	cpi R20, 0b10000000 ;0b10000000 represents countdown mode
	breq countdown

switchcount:
	cpi R20, 0x00
	breq countdown ;if in countup mode, change to countdown mode
	cpi R20, 0b10000000
	breq countup ; if in countdown mode, change to countup mode

countdown:
	ldi r20, 0b10000000 ; set mode to countdown
	
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


countup:
	ldi R20, 0x00 ;set mode to countup

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