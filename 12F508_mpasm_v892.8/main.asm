;
; File:     main.S
; Target:   PIC12F508
; Author:   dan1138
; Date:     2021-01-25
; Compiler: MPASMWIN(v5.51)
; IDE:      MPLAB v8.92
;
; Description:
;
;   Example project for the PIC12F508 controller using the MPASMWIN(v5.84) tool chain.
;
;
;
;
;
;   Toggle GP2 output.
; 
; 
;                        PIC12F508
;               +-----------:_:-----------+
;        5v0 -> : 1 VDD             VSS 8 : <- GND
;            <> : 2 GP5         PGD/GP0 7 : <> ICD_PGD
;            <> : 3 GP4         PGC/GP1 6 : <> ICD_PGC
;   ICD_MCLR -> : 4 GP3/MCLR        GP2 5 : <> TOGGLE
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
 __CONFIG _OSC_IntRC & _WDT_OFF & _CP_OFF & _MCLRE_ON
;
;
;
;
; Declare one byte in RAM
;
MainData    UDATA
    global  Counter
Counter:    RES      2
;
; Simple test application that implements a
; delay function then sets GPIO bit GB2 high
; calls the delay function, then sets GPIO 
; bit GB2 low, calls the delay function then loops.
;
StartCode   CODE    0x0000
    global  Start, Delay, main, Loop
Start:
    clrf    Counter
    clrf    Counter+1
    goto    main
;
Delay:
    incfsz  Counter,F                   ; Increment Counter value low 8-bits
    goto    Delay
    incfsz  Counter+1,F                 ; Increment Counter value high 8-bits
    goto    Delay
    retlw   0
;
main:
    movlw   b'11011111' ; Select TIMER0 clock source as FOSC/4
    option
    movlw   b'11111011' ; GP2 as output
    tris    GPIO
;
; Toggle GPIO bit 2
;
Loop:
    bsf     GPIO,GP2    ; set port bit high
    call    Delay
    bcf     GPIO,GP2    ; set port bit low
    call    Delay
    goto    Loop
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
ResetVec    CODE    0x1FF
    global  ResetVector
ResetVector:
#ifdef USING_SIMULATOR
    goto    Start
#endif
    end