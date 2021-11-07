;
; File:     main_rgb.asm
; Target:   PIC12F508
; Author:   dan1138
; Date:     2021-NOV-06
; Compiler: MPASMWIN(v5.22) absolute mode
; IDE:      none
;
; Description:
;
;   Example project for the PIC12F508 controller using the MPASMWIN(v5.22) from the command line.
;
;
;
;
;
;   Cycle through all 8 combinations of an RGB LED connected 
;   to GP0,GP1,GP2 when the switch connected to GP3 is pressed.
; 
;                        PIC12F508
;               +-----------:_:-----------+
;        5v0 -> : 1 VDD             VSS 8 : <- GND
;            <> : 2 GP5         PGD/GP0 7 : <> LED_RED/PGD
;            <> : 3 GP4         PGC/GP1 6 : <> LED_GREEN/PGC
;     VPP/SW -> : 4 GP3/MCLR        GP2 5 : <> LED_BLUE
;               +-------------------------+
;                          DIP-8
;
    list        p=12F508
    list        c=132,n=0
    list        r=dec
;
; Include target specific definitions for special function registers
;
#include "p12f508.inc"
;
; Set the configuration word
;
 __CONFIG _OSC_IntRC & _WDT_OFF & _CP_OFF & _MCLRE_OFF
;
;
;
;
; Declare RAM for application
;
  CBLOCK 0x07
    TMR0_Sample      :1
    LED_Drive        :1
    SW_DebounceCount :1
    SW_StateFlags    :1
  ENDC

#define SW_BIT    GPIO,GP3
#define SW_Sample SW_StateFlags,0
#define SW_Last   SW_StateFlags,1
#define SW_Stable SW_StateFlags,2
#define SW_State  SW_StateFlags,3
#define SW_DEBOUNCE_TICKS (20)


#define LEDs_Off (b'111')

#define TMR0_1MS_BIT (b'10000000')
;
; Power on reset
;
    org 0x0000

Start:
    movwf   OSCCAL          ; Set factory default for internal oscillator
    goto    main
;
; The PIC12F508 can only call functions that start 
; within the first 256 instruction words.
; 
; This specific implementation does not call any functions
; so there is nothing here.
;
main:
    movlw   b'11010100'     ; Select TIMER0 clock source as FOSC/4, prescale TMR0 at 1:32
    option
;
; Wait for about one second before making PGC/PGD outputs.
; This will give the In-Circuit-Serial-Programmer a chance
; to connect to the PIC12F508
;
    clrf    TMR0_Sample
    clrf    TMR0
POR_Wait:
    btfss   TMR0,7
    goto    POR_Wait
    bcf     TMR0,7
    decfsz  TMR0_Sample,F
    goto    POR_Wait

    movlw   b'11010010'     ; Select TIMER0 clock source as FOSC/4, prescale TMR0 at 1:8
    option
    movlw   b'11111000'     ; GP2,GP1,GP0 as output
    tris    GPIO
;
; Initialize application states
;
    clrf    TMR0
    clrf    TMR0_Sample
    clrf    SW_StateFlags
    movlw   SW_DEBOUNCE_TICKS
    movwf   SW_DebounceCount
    movlw   LEDs_Off
    movwf   LED_Drive
    movwf   GPIO
;
; State machine to debounce switch and change LEDs
;
AppLoop:
    movf    TMR0,W          ; Get TIMER0 count state
    xorwf   TMR0_Sample,W   ; Compare it to the last Tick sample
    andlw   TMR0_1MS_BIT    ; TIMER0 bit that changes every 1.024 milliseconds
    btfsc   STATUS,Z        ; skip when it is one millisecond tick time
    goto    AppLoop
Tick_One_ms:
    xorwf   TMR0_Sample,F   ; Remember state of 1.024ms bit
    bcf     SW_Sample       ; Assume switch is not pressed
    btfss   SW_BIT          ; Skip if switch released
    bsf     SW_Sample       ; Switch is pressed
    clrw    
    btfsc   SW_Sample       ; Skip if sample switch state released
    iorlw   1   
    btfsc   SW_Last         ; Skip if last sample switch state is released
    xorlw   1   
    btfsc   STATUS,Z        ; Skip if current sample different from last
    goto    DebounceCount
;
; Update the last sample
    bcf     SW_Last
    btfsc   SW_Sample
    bsf     SW_Last
;
; Restart debounce count
    movlw   SW_DEBOUNCE_TICKS
    movwf   SW_DebounceCount
    goto    AppLoop

DebounceCount:
    movf    SW_DebounceCount,F  ; Set zero flag if debounce count is zero
    btfss   STATUS,Z            ; Skip if debounce count at zero
    decfsz  SW_DebounceCount,F  ; Skip when debounce count changes from one to zero
    goto    AppLoop
;
; Update the stable state
    bcf     SW_Stable
    btfsc   SW_Sample
    bsf     SW_Stable
;
; Check to see if the last state is different from the new state
    clrw
    btfsc   SW_Stable
    iorlw   1
    btfsc   SW_State
    xorlw   1
    btfsc   STATUS,Z        ; Skip if last state different from current stable state
    goto    AppLoop
;
; Update the last state
    bcf     SW_State
    btfsc   SW_Stable
    bsf     SW_State
;
; Change what LEDs are on and off
    btfss   SW_State        ; Skip if switch changed to pressed
    goto    AppLoop
;
; Do the actual work of changing the output bits
    movlw   -1
    addwf   LED_Drive,F     ; Increment pattern
    btfss   LED_Drive,0
    bcf     GPIO,GP0        ; turn on  RED   LED
    btfsc   LED_Drive,0
    bsf     GPIO,GP0        ; turn off RED   LED
    btfss   LED_Drive,1
    bcf     GPIO,GP1        ; turn on  GREEN LED
    btfsc   LED_Drive,1
    bsf     GPIO,GP1        ; turn off GREEN LED
    btfss   LED_Drive,2
    bcf     GPIO,GP2        ; turn on  BLUE  LED
    btfsc   LED_Drive,2
    bsf     GPIO,GP2        ; turn off BLUE  LED
    goto    AppLoop

;
; The PIC12F508 reset vector is the highest 
; instruction word in the code space.
;
; This is used to load the WREG with the factory 
; oscillator calibration value then  the program 
; counter rollover to zero to start the code.
;
; This example code places a GOTO instruction here.
;
; WARNING:  Programming a real part with this code
;           will erase the oscillator calibration value
;           set when the part was manufactured.
;
    org     0x1FF

ResetVector:
#ifdef USING_SIMULATOR
    goto    Start
#endif
    end