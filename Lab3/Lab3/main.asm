;; Lab 3
;; Ted Paulsen, Daniel Machlab
;; Embedded Systems

cbi DDRB, 0
cbi DDRB, 1
sbi DDRB, 2

loop:
	inc R16
	dec R16
	rjmp loop
