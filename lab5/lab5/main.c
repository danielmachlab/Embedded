//************************************************************************/
/* UART functions written by A. Kruger 2010                             */
/************************************************************************/

#define F_CPU 8000000L
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include <util/delay.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

// Baud rate. The usart_int routine
#define BAUD_RATE 9600

// Variables and #define for the RX ring buffer.
#define RX_BUFFER_SIZE 64
unsigned char rx_buffer[RX_BUFFER_SIZE];
volatile unsigned char rx_buffer_head;
volatile unsigned char rx_buffer_tail;

// Function prototypes
float getSingleADC();
float * getMultipleADC(int n, int dt);
void setADC(int c, float v);

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

int main(void) {
	unsigned char c;
	char str[25];
	char msgs[50];
	int v;
	sei();

	usart_init();
	adc_init();
	const char msg[] = "I now hev an iphone\n\r";
	usart_prints(msg);

	// listen for user input
	while (1) {
		c = usart_getc();

		if (c == 'G') {
			get_adc(&v);
			sprintf(&msgs, "v = %.3f V\n\r", v);
			char response[] = "you typed G\n\r";
			usart_prints(msgs);
			usart_prints(response);
			
			
			//float v = getSingleADC();
			// todo: do something with this v

		} else if (c == 'M') {
			char response[] = "you typed M\n\r";
			usart_prints(response);

			int n = 5; // todo: read these values instead of hard coding
			int dt = 10;
			float *v = getMultipleADC(n, dt); // v is a pointer to the first element in a float array
			// todo: do something with v

		} else if (c == 'S') {
			char response[] = "you typed S\n\r";
			usart_prints(response);

			int channel = 0; // todo: read these values instead of hard coding
			int voltage = 3;
			setADC(channel, voltage);
		}

	}

}

// get a single voltage measurement from ADC
// return: the current ADC voltage
float getSingleADC() {
	float a = 0.0;

	// todo

	return a;
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
// v: output voltage
void setADC(int c, float v) {
	// todo
}

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



void adc_init()
{
	// AREF = AVcc
	ADMUX = (1<<REFS0);
	
	// ADC Enable and prescaler of 128
	// 16000000/128 = 125000
	ADCSRA = (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0);
}

int adc_read()//0-1023, convert to float
{
	// select the corresponding channel 0~7
	// ANDing with ’7′ will always keep the value
	// of ‘ch’ between 0 and 7
	//ch &= 0b00000111;  // AND operation with 7
	ADMUX = (ADMUX & 0xF8); // clears the bottom 3 bits before ORing
	
	// start single convertion
	// write ’1′ to ADSC
	ADCSRA |= (1<<ADSC);
	
	// wait for conversion to complete
	// ADSC becomes ’0′ again
	// till then, run loop continuously
	while(ADCSRA & (1<<ADSC));
	
	return (ADC);
}

void get_adc(float *v)
{
	int temp = adc_read();   
	*v = (float)(temp*5.0)/1023.0;
	//*v = (temp*5)/1023;
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
