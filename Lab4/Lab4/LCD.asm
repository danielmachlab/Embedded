;;
;; Lab 4
;; Ted Paulsen, Daniel Machlab
;;
;.include "m88padef.inc"
.cseg

;msg1: .DB "DC = ", 0x00
;.dw 0

; cbi is input sbi is output
; read from rpg
cbi DDRB, 0 ; input - from A
cbi DDRB, 1 ; input - from B
sbi DDRB, 2 ; output - clockwise (A side) LED

; output E & RS
sbi DDRB, 3 ; output - enable line
sbi DDRB, 5 ; output to RS line of lcd

; lcd data lines
sbi DDRC, 3 ; output PC3 - D7
sbi DDRC, 2 ; output PC2 - D6
sbi DDRC, 1 ; output PC1 - D5
sbi DDRC, 0 ; output PC0 - D4

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
ldi count_temp, 1
ldi count_rpg, 180

rcall lcd_init


;ldi r30, LOW(2*msg1)
;ldi r31, HIGH(2*msg1)

;rcall displayCString

rcall write_letter_A_to_lcd

endloop: rjmp endloop

write_letter_A_to_lcd:
	rcall delay_100ms
	; set to data mode
	sbi PORTB, 5
	; write upper nibble
	ldi R26, 0x03
	out PORTC, R26
	rcall lcd_strobe

	rcall delay_100ms

	; write lower nibble
	ldi R26, 0x03
	out PORTC, R26
	rcall lcd_strobe

	rcall delay_100ms
	ret
		
	
displayCString:
	sbi PORTB, 5
	lpm r0,Z+ ; r0 <-- first byte
	tst r0 ; Reached end of message ?
	breq done ; Yes => quit
	swap r0 ; Upper nibble in place
	out PORTC,r0 ; Send upper nibble out
	rcall lcd_strobe ; Latch nibble
	//rcall delay_200us
	swap r0 ; Lower nibble in place
	out PORTC,r0 ; Send lower nibble out
	rcall lcd_strobe ; Latch nibble
	//rcall delay_200us
	rjmp displayCstring
done:
	ret


//LCD INITILZSLD
lcd_init:
	rcall delay_100ms ; line 1 -- 100 ms
	rcall lcd_init_3 ; line 2 -- (0x03)

	rcall delay_5ms ; line 3 -- 5 ms
	rcall lcd_init_3 ; line 4 -- (0x03)

	rcall delay_200us ; line 5	
	rcall lcd_init_3 ; line 6 -- (0x03)

	rcall delay_200us ; line 7 	 
	rcall lcd_init_2 ; line 8 -- (0x02)

	rcall delay_5ms ; line 9
	rcall lcd_init_2 ; line 10a -- upper nibble (0x28)

	rcall delay_200us
	rcall lcd_init_8; line 10 b -- lower nibble (0x28)

	;rcall delay_200us
	;rcall lcd_init_0 ; line 11 a -- upper nibble (0x08)

	;rcall delay_200us
	;rcall lcd_init_8 ; line 11b -- lower nibble (0x08)

	rcall delay_200us
	rcall lcd_init_0 ; line 12a -- upper nibble (0x01)

	rcall delay_200us
	rcall lcd_init_1 ; line 12b -- lower nibble (0x01)

	rcall delay_5ms
	rcall lcd_init_0 ; line 14a -- upper nibble (0x0C)

	rcall delay_200us
	rcall lcd_init_C ; line 14b -- upper nibble (0x0C)

	rcall delay_5ms 
	rcall lcd_init_0 ; line 13a -- upper nibble (0x06)

	rcall delay_200us
	rcall lcd_init_6 ; line 13b -- upper nibble (0x06)

	



	

	ret

lcd_init_0:
	ldi R26, 0x00
	cbi PORTB, 5
	out PORTC, R26 ; line 11a -- write 08 hex (upper nibble then lower nibble)
	rcall lcd_strobe

lcd_init_1:
	ldi R26, 0x01
	cbi PORTB, 5
	out PORTC, R26 ; line 11a -- write 08 hex (upper nibble then lower nibble)
	rcall lcd_strobe

lcd_init_2:
	ldi R26, 0x02
	cbi PORTB, 5 ; set RS low
	out PORTC, R26 ;line 8 -- write 0x02 with RS=0 (set to 4-bit mode)
	rcall lcd_strobe
	ret

lcd_init_3:
	ldi R26, 0x03
	cbi PORTB, 5 
	out PORTC, R26 ; line 2 -- write 0x03 with RS=0 (set to 8-bit mode)
	rcall lcd_strobe
	ret

lcd_init_6:
	ldi R26, 0x06
	cbi PORTB, 5
	out PORTC, R26 ; line 11a -- write 08 hex (upper nibble then lower nibble)
	rcall lcd_strobe
	
lcd_init_8:
	ldi R26, 0x08
	cbi PORTB, 5
	out PORTC, R26; line 10b -- lower nibble
	rcall lcd_strobe
	ret

lcd_init_C:
	ldi R26, 0x0C
	cbi PORTB, 5
	out PORTC, R26 ; line 11a -- write 08 hex (upper nibble then lower nibble)
	rcall lcd_strobe

delay_100ms:
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

delay_100us:
		ldi  r18, 3
		ldi  r19, 9
	L4: dec  r19
		brne L4
		dec  r18
		brne L4
		ret

lcd_strobe:
	cbi PORTB, 3 ; drive E low
	rcall delay_200us ; delay
	sbi PORTB, 3 ; drive E hight 
	rcall delay_200us
	cbi PORTB, 3 ; drive E low
	ret