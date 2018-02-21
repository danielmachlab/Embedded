;; Lab 3
;; Ted Paulsen, Daniel Machlab
;; Embedded Systems

;cbi is input sbi is output
cbi DDRB, 0 ; input - from A
cbi DDRB, 1 ; input - from B
sbi DDRB, 2 ; output - turn left(A side) LED
sbi DDRB, 5 ; output - turn right(B side) LED



loop:
	inc R16
	dec R16
	rjmp loop

infiniteloopcheckingforturnofRPG:
	in R16, PINB
	
;	andi rpg, 	


	rjmp infiniteloopcheckingforturnofRPG