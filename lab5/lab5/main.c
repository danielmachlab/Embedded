/*
 * lab5.c
 *
 * Created: 4/7/2018 2:23:34 PM
 * Author : ted
 */ 

#ifndef F_CPU
#define F_CPU 8000000UL		// 8 MHz clock speed 
#endif

#define BAUDRATE 19200
#define UBRRVAL ((F_CPU/(BAUDRATE*16UL))-1)


#include <avr/io.h>			// includes #defines for PORTC etc.
#include <util/delay.h>		// includes some pre-made delay routines

void sei() {
	
}

void usart_init() {
	UBRRL = UBRRVAL;
	UBRRH = (UBRRVAL>>8);
	
	UCSRC = (1<<URSEL)|(0<<UMSEL)|(0<<UPM1)|(0<<UPM0)|(0<<USBS)|(0<<UCSZ2)|(1<<UCSZ1)|(1<<UCSZ0);
	UCSRB = (1<<RXEN)|(1<<TXEN)
}

void usart_prints(sdata) {
	
}

void usart_printf(fdata) {
	
}

int main(void) {
	
	unsigned char c;
	char str[25];
	int adH, adL, dac;
	int i;
	
	sei();
	
	usart_init();
	usart_prints();
	usart_printf();
	
}

