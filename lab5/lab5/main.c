//************************************************************************/
/* UART functions written by A. Kruger 2010                             */
//1. get library, start wait, send 0x58 (slave address), write 0x00 or 0x01, write voltage value to display(0-255), stop
/************************************************************************/

#define F_CPU 8000000L
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include <util/delay.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "i2cmaster.h"

// Baud rate. The usart_int routine
#define BAUD_RATE 9600

// Variables and #define for the RX ring buffer.
#define RX_BUFFER_SIZE 64
unsigned char rx_buffer[RX_BUFFER_SIZE];
volatile unsigned char rx_buffer_head;
volatile unsigned char rx_buffer_tail;

// Function prototypes
void print_adc();
float * getMultipleADC(int n, int dt);
void setADC(int c, int v);

// More function prototypes
void get_adc(float *v);
int adc_read();

void newLine();

// UART function prototypes.
unsigned char uart_buffer_empty(void);
void usart_prints(const char *ptr);
void usart_printf(const char *ptr);
void usart_init(void);
void usart_putc(const char c);
void adc_init(void);
unsigned char usart_getc(void);

// sample strings in SRAM and Flash, used for examples.
const char sdata[40] = "Hello World!\n\r";          // String in SRAM
const char fdata[] PROGMEM = "My name is Ted\n";  // String in Flash

const char v_str_1[] = "ADC Voltage = ";
char v_str_val[5];
const char v_str_2[] = "V\n\r";
float v_float;

int main(void) {

	sei();

	usart_init();
	adc_init();

	const char welcome[] = "Hi welcome to chili's\n\r---------------------\n\r";
	usart_prints(welcome);

	// listen for user input
	while (1) {
		char c = usart_getc();

		if (c == 'G') {
			usart_putc(c);
			newLine();
			print_adc();

		} else if (c == 'M') {
			// Get parameters and echo them back
			usart_putc(c);

			char comma = usart_getc(); // ignore comma input
			usart_putc(comma);

			char n0 = usart_getc();
			usart_putc(n0);
			char n1 = usart_getc();
			usart_putc(n1);

			comma = usart_getc(); // ignore comma input
			usart_putc(comma);
			char dt0 = usart_getc();
			usart_putc(dt0);
			char dt1 = usart_getc();
			usart_putc(dt1);

			newLine();

			char n_str[3];
			n_str[0] = n0;
			n_str[1] = n1;
			n_str[2] = '\0';

			char dt_str[3];
			dt_str[0] = dt0;
			dt_str[1] = dt1;
			dt_str[2] = '\0';

			int n = atoi(n_str);
			int dt = atoi(dt_str);

			for (int i = 0; i < n; i++) {
				print_adc();
				
				// delay as long as it's not the last one
				if (i+1 != n) {
					_delay_ms(dt * 1000);
				}
			}

			// todo: do something with v

		} else if (c == 'S') {
			char response[] = "you typed S\n\r";
			usart_prints(response);
			int channel = 0; // todo: read these values instead of hard coding
			int voltage = 200;
			setADC(channel, voltage);
		}

		newLine();

	}

}

void newLine() {
	char nl[] = "\n\r";
	usart_prints(nl);
}

// get a single voltage measurement from ADC
// return: the current ADC voltage
void print_adc() {
	get_adc(&v_float);
	dtostrf(v_float, 2, 2, v_str_val);
	
	usart_prints(v_str_1);
	usart_prints(v_str_val);
	usart_prints(v_str_2);
}

// get multiple measurements from ADC
// n: number of measurements (2 <= n <= 20)
// dt: time between measurements (1 <= dt <= 60 seconds)
// return: pointer to the first element in an array of voltage readings
float * getMultipleADC(int n, int dt) {
	// allocate space for an array of n floats
	float *arr = malloc(sizeof(float) * n);

	// todo

	return arr;
}

// set DAC output voltage
// c: DAC channel number (0 or 1)
// v: output voltage (int between 0 and 255)
void setADC(int c, int v) {
	i2c_start_wait(0x58+I2C_WRITE); //slave address
	char response[] = "debug statement\n\r";
	usart_prints(response);
	i2c_write(c); //select DAC channel
	i2c_write(v); //write voltage value to display
	i2c_stop(); //stop

	
}

void adc_init() {
	// AREF = AVcc
	ADMUX = (1<<REFS0);
	
	// ADC Enable and prescaler of 128
	// 16000000/128 = 125000
	ADCSRA = (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0);
}


void get_adc(float *v) {
	int temp = adc_read();
	*v = (float)(temp*5.0)/1023.0;
	//*v = (temp*5)/1023;
}

int adc_read() {
	// select the corresponding channel 0~7
	// ANDing with ’7? will always keep the value
	// of ‘ch’ between 0 and 7
	//ch &= 0b00000111;  // AND operation with 7
	ADMUX = (ADMUX & 0xF8); // clears the bottom 3 bits before ORing
	
	// start single convertion
	// write ’1? to ADSC
	ADCSRA |= (1<<ADSC);
	
	// wait for conversion to complete
	// ADSC becomes ’0? again
	// till then, run loop continuously
	while(ADCSRA & (1<<ADSC));
	
	return (ADC);
}


/************************************************************************/
/* USART Library                                                        */
/************************************************************************/

// UART receive interrupt handler.
// To do: check and warn if buffer overflows.
ISR(USART_RX_vect) {
	char c = UDR0;
	rx_buffer[rx_buffer_head] = c;

	if (rx_buffer_head == RX_BUFFER_SIZE - 1) {
		rx_buffer_head = 0;
	} else {
		rx_buffer_head++;
	}
}

// Configures the USART for serial 8N1 with
// the Baud rate controlled by a #define.
void usart_init(void) {
	unsigned short s;

	// Set Baud rate, controlled with #define above.

	s = (double)F_CPU / (BAUD_RATE*16.0) - 1.0;
	UBRR0H = (s & 0xFF00);
	UBRR0L = (s & 0x00FF);

	// Receive complete interrupt enable: RXCIE0
	// Receiver & Transmitter enable: RXEN0,TXEN0

	UCSR0B = (1<<RXCIE0)|(1<<RXEN0)|(1<<TXEN0);

	// Along with UCSZ02 bit in UCSR0B, set 8 bits

	UCSR0C = (1<<UCSZ01)|(1<<UCSZ00);

	DDRD |= (1<< 1);         // PD0 is output (TX)
	DDRD &= ~(1<< 0);        // PD1 is input (Rx)

	// Empty buffers

	rx_buffer_head = 0;
	rx_buffer_tail = 0;
}

// Send NULL-terminated data from FLASH.
// Uses polling (and it blocks).
void usart_printf(const char *ptr) {
	char c;
	while(pgm_read_byte_near(ptr)) {
		c = pgm_read_byte_near(ptr++);
		usart_putc(c);
	}
}

// Send "c" via the USART.  Uses poling
// (and it blocks). Wait for UDRE0 to become
// set (=1), which indicates the UDR0 is empty
// and can accept the next character.
void usart_putc(const char c){
	while (!(UCSR0A & (1<<UDRE0)))
		;

	UDR0 = c;
}


// Send NULL-terminated data from SRAM.
// Uses polling (and it blocks).
void usart_prints(const char *ptr) {
	while(*ptr) {
		while (!( UCSR0A & (1<<UDRE0)))
			;

		UDR0 = *(ptr++);
	}
}

// Get char from the receiver buffer.  This
// function blocks until a character arrives.
unsigned char usart_getc(void) {
	unsigned char c;

	// Wait for a character in the buffer.
	while (rx_buffer_tail == rx_buffer_head)
		;

	c = rx_buffer[rx_buffer_tail];

	if (rx_buffer_tail == RX_BUFFER_SIZE-1)
		rx_buffer_tail = 0;
	else
		rx_buffer_tail++;

	return c;
}

// Returns TRUE if receive buffer is empty.
unsigned char uart_buffer_empty(void) {
	return (rx_buffer_tail == rx_buffer_head);
}
