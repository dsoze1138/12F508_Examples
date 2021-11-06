/*
 * file: main.c
 * target: PIC12F508
 * IDE: MPLABX v5.50
 * compiler: XC8 v2.32 (free mode)
 *
 * Description:
 * 
 *  Toggle GP2 output.
 *
 *
 *                       PIC12F508
 *              +-----------:_:-----------+
 *       5v0 -> : 1 VDD             VSS 8 : <- GND
 *           <> : 2 GP5         PGD/GP0 7 : <> ICD_PGD
 *           <> : 3 GP4         PGC/GP1 6 : <> ICD_PGC
 *  ICD_MCLR -> : 4 GP3/MCLR        GP2 5 : <> TOGGLE
 *              +-------------------------+
 *                         DIP-8
 *
 */

/*
 * PIC12F508 specific configuration words
 */
#pragma config OSC = IntRC      /* Oscillator Selection bits (internal RC oscillator) */
#pragma config WDT = OFF        /* Watchdog Timer Enable bit (WDT disabled) */
#pragma config CP = OFF         /* Code Protection bit (Code protection off) */
#pragma config MCLRE = ON       /* GP3/MCLR Pin Function Select bit (GP3/MCLR pin function is MCLR) */
/*
 * Include PIC12F508 specific symbols
 */
#include <xc.h>
/*
 * Application specific constants
 */
#define FSYS (4000000ul)                    /* syetem oscillator frequency in Hz */
#define FCYC (FSYS/4ul)                     /* number of inctruction clocks in one second */

/*
 * Global data
 */
unsigned short Counter;

/*
 * Application
 */
void Delay(void)
{
    do { } while(++Counter);
}

void main(void) 
{
/*
 * Initialize PIC hardware for this application
 */
    OPTION = 0b11010111; /*  Select TIMER0 clock source as FOSC/4 */
    /*
     * PIC12F508 specific initialization
     */
    GPIO      = 0;
    TRISGPIO  = 0b11111011; /* GP2 as output */
    /*
     * Process loop
     */
    for(;;)
    {
        GPIObits.GP2 = 1;
        Delay();
        GPIObits.GP2 = 0;
        Delay();
    }
}
