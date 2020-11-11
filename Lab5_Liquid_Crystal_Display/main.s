;******************************************************************************************
; Author: Wesley Muehlhausen
; Project: Lab5
; Program: Liquid Crystal Display
; Date Created: October 14, 2020
;
; Description: this program will setup LCD and display a message on LCD
; Inputs: none
; Outputs: LCD
;******************************************************************************************
SYSCTL_RCGCGPIO_R       EQU   0x400FE608
SYSCTL_RCC_R            EQU   0x400FE060
GPIO_PORTA_DIR_R        EQU   0x40004400
GPIO_PORTA_DATA_R       EQU   0x400043FC
GPIO_PORTA_DEN_R        EQU   0x4000451C
GPIO_PORTC_DIR_R        EQU   0x40006400
GPIO_PORTC_DATA_R       EQU   0x400063FC
GPIO_PORTC_DEN_R        EQU   0x4000651C
GPIO_PORTE_DIR_R        EQU   0x40024400
GPIO_PORTE_DATA_R       EQU   0x400243FC
GPIO_PORTE_DEN_R        EQU   0x4002451C

	AREA	 MyData, DATA, READONLY

Msg_hd1 DCB    "Welcome to Lab 5", 0   ;prints these two messages
Msg_hd2 DCB    "Wesley Muehlhausen", 0
	
	AREA	 MyCode, CODE, READONLY, ALIGN=2
	EXPORT	__main

__main
	BL		Init_Clock		;initialize clocks
	BL		Init_Ports		;initialize ports
	BL		Init_LCD		;initialize LCD
	LDR		R0, =Msg_hd1	; R0 <- address of the message header 1
	BL		Display_Msg		;Display message 1
	MOV		R1, #0x42		; set the position
	BL		Set_Position	
	LDR		R0, =Msg_hd2	; R0 <- address of the message header 2
	BL		Display_Msg	;	;Display message 2
	
	
; Init_Ports - initializes ports A, C, and E for LCD display
Init_Ports
	
	;1. Write to SYSCTL_RCGCGPIO_R to activate the clocks for the three ports
	;PORT A
	; Initialize PORTs A,C and E. 
	; Activate the clocks for the three ports.
	LDR R1, =SYSCTL_RCGCGPIO_R
	LDR R0, [R1]
	ORR	R0, #0x15	;0x01 for A | 0x04 for C | 0x10 for E  0001  0100 00010101
	STR R0, [R1]
	NOP
	NOP ; allow time for clock to finish
		
	;2. Write to GPIO_PORTA_DIR_R, GPIO_PORTC_DIR_R, 
		;and GPIO_PORTE_DIR_R to set the direction of 
		;PA2-PA5, PC6, and PE0 as output pins
	; Set the directions of involved pins to output.
	; Pins PA2-PA5 are outputs
	; Pin PC6 is output
	; Pin PE0 is output
	LDR R1, =GPIO_PORTA_DIR_R ; 5) set direction register
	LDR R0, [R1]
	ORR R0,#0x3C ; PF0 and PF7-4 input, PF3-1 output      PA 2-5  00111100
	STR R0, [R1]
	LDR R1, =GPIO_PORTC_DIR_R ; 5) set direction register  PC 6 1000000
	LDR R0, [R1]
	ORR R0,#0x40 ; PF0 and PF7-4 input, PF3-1 output        
	STR R0, [R1]
	LDR R1, =GPIO_PORTE_DIR_R ; 5) set direction register
	LDR R0, [R1]
	ORR R0,#0x01 ; PF0 and PF7-4 input, PF3-1 output     PE 0   00000001
	STR R0, [R1]
	
;3. Write to GPIO_PORTA_DEN_R, GPIO_PORTC_DEN_R, and GPIO_PORTA_DEN_R
	;to set PA2-PA5, PC6, and PE0 signals to digital.
; Define the signals on involved pins as digital
	; PA2-PA5 signals are digital
	; PC6 signal is digital
	; PE0 signal is digital
	LDR R1, =GPIO_PORTA_DEN_R ; 5) set direction register
	LDR R0, [R1]
	ORR R0,#0x3C ; PF0 and PF7-4 input, PF3-1 output        PA 2-5  00111100
	STR R0, [R1]
	LDR R1, =GPIO_PORTC_DEN_R ; 5) set direction register  1000000
	LDR R0, [R1]
	ORR R0,#0x40 ; PF0 and PF7-4 input, PF3-1 output        PC 6 1000000
	STR R0, [R1]
	LDR R1, =GPIO_PORTE_DEN_R ; 5) set direction register
	LDR R0, [R1]
	ORR R0,#0x01 ; PF0 and PF7-4 input, PF3-1 output        PE 0   00000001
	STR R0, [R1]
	
	BX LR
	

; Display_Msg - displays the message
Display_Msg  ;//////////////ToDo
	PUSH	{LR, R0, R1}
loop2
	LDRB	R1, [R0]  ;Get Array[i] (Array[R4]) and put into R1
	CMP		R1, #0x00		;compare value with NULL 
	BEQ		loopInBounds	;if loop is over 
	BL		Display_Char
	ADD 	R0, #1			;incriment
	B		loop2
loopInBounds ;skip here
	POP		{LR, R0, R1}
	BX		LR
		
; Display_Char - writes an ASCII value in R1 to LCD
Display_Char
	PUSH	{LR, R0, R1}
	BL		SplitNum	;
	BL		WriteData	; write upper 4 bits of ASCII byte
	MOV		R1, R0
	BL		WriteData	; write lower 4 bits of ASCII byte
	MOV		R0, #0x01	
	BL		Delay1ms	; wait for 1ms
	POP		{LR, R0, R1}
	BX		LR

; Set_Position - sets the position in R1 for displaying data in LCD
Set_Position
	PUSH	{LR, R1, R0}
	ORR		R1,	#0x80	; set b7 of R1
	BL		SplitNum	
	BL		WriteCMD	; write upper 4 bits of the command
	MOV		R1,	R0
	BL		WriteCMD	; write lower 4 bits of the command
	MOV		R0, #0x01		
	BL		Delay1ms	; wait for 1ms
	POP		{LR, R1, R0}
	BX		LR

; WriteData - sends a data (lower 4 bits) in R1 to LCD
WriteData
	PUSH	{LR, R1, R0}
	LSL		R1, R1, #2		; data from bits 2 - 5
	LDR		R0, =GPIO_PORTA_DATA_R
	STRB	R1, [R0]
	LDR		R0, =GPIO_PORTE_DATA_R
	MOV		R1, #0x01	; Sending data
	STRB	R1, [R0]
	MOV		R1, #0x00	; Enabling the LCD (falling edge)
	LDR		R0,	=GPIO_PORTC_DATA_R
	STRB	R1, [R0]
	NOP
	NOP
	MOV		R1, #0x40	; Raising the edge in preparation for the next write 
	STRB	R1, [R0]
	POP		{LR, R1, R0}
	BX		LR			

; WriteCMD - sends a command (lower 4 bits) in R1 to LCD
WriteCMD 
	PUSH	{LR, R1, R0}
	LSL		R1, R1, #2		; data from bits 2 - 5
	LDR		R0, =GPIO_PORTA_DATA_R
	STRB	R1, [R0]
	MOV		R1, #0x00;		; RS=0 for sending a command
	LDR		R0, =GPIO_PORTE_DATA_R
	STRB	R1, [R0]
	MOV		R1, #0x00	; Enabling the LCD
	LDR		R0, =GPIO_PORTC_DATA_R
	STRB	R1, [R0]
	NOP
	NOP
	MOV		R1, #0x40	; Raising PC6
	STRB	R1, [R0]
	POP		{LR, R1, R0}
	BX		LR

; SlipNum - separates hex numbers in R1
;	  R1 <- MS digit
;	  R0 <- LS digit
SplitNum
	PUSH	{LR}
	MOV		R0, R1
	AND		R0, #0x0F		; mask the upper 4 bits
	LSR		R1,	R1, #4 
	POP		{LR}
	BX		LR

; Init_LCD - initializes LCD according to the initializing sequence indicated
;	  by the manufacturer
Init_LCD
	PUSH	{LR, R0, R1}
	
	; WAIT 30 SECONDS TO POWER UP
	MOV		R0,	#30		;
	BL		Delay1ms	; wait for 30 ms

	;BYTE 1:	SEND TO LCD
	; send byte 1 of code to LCD
	MOV		R1,	#0x30	; R1 <- byte #1 of code: $30
	BL		SplitNum	;
	BL		WriteCMD	; write byte #1
	MOV		R0,	#5		;
	BL		Delay1ms	; wait for 5 ms
	
	;BYTE 2:	SEND TO LCD
	MOV		R1,	#0x30	; R1 <- byte #1 of code: $30
	BL		SplitNum	;
	BL		WriteCMD	; write byte #1
	MOV		R0,	#1		;
	BL		Delay1ms	; wait for 1 ms
	; wait
	
	;BYTE 3:	SEND TO LCD
	MOV		R1,	#0x30	; R1 <- byte #1 of code: $30
	BL		SplitNum	;
	BL		WriteCMD	; write byte #1
	MOV		R0,	#1		;
	BL		Delay1ms	; wait for 1 ms
	; wait
	
	;BYTE 4:	SEND TO LCD
	MOV		R1,	#0x20	; R1 <- byte #1 of code: $20
	BL		SplitNum	;
	BL		WriteCMD	; write byte #1
	MOV		R0,	#1		;
	BL		Delay1ms	; wait for 1 ms
	; wait
	
	;BYTE 5:	SEND TO LCD
	MOV		R1,	#0x28		; R1 <- byte #5 of code: $28
				;  db5 = 1, db4 = 0 (DL = 0 - 4 bits), 
				;  db3 = 1 (N = 1 - 2 lines),
				;  db2 = 0 (F = 0 - 5x7 dots).
	BL		SplitNum	;
	BL		WriteCMD	; write upper 4 bits of byte #5
	MOV		R1,R0
	BL		WriteCMD	; write lower 4 bits of byte #5
	MOV		R0,	#1	;
	BL		Delay1ms	; wait for 1ms
	
	;BYTE 6:	SEND TO LCD
	MOV		R1,	#0x0C	; R1 <- byte #1 of code
	BL		SplitNum	;
	BL		WriteCMD
	MOV		R1,R0
	BL		WriteCMD	; write byte #1
	MOV		R0,	#1		;
	BL		Delay1ms	; wait for 1 ms
	; wait
	
	;BYTE 7:	SEND TO LCD
	MOV		R1,	#0x01	; R1 <- byte #1 of code
	BL		SplitNum	
	BL		WriteCMD
	MOV		R1,R0
	BL		WriteCMD	; write byte #1
	MOV		R0,	#5		;
	BL		Delay1ms	; wait for 5 ms
	; wait
	
	;BYTE 8:	SEND TO LCD
	MOV		R1,	#0x06	; R1 <- byte #1 of code
	BL		SplitNum	;
	BL		WriteCMD
	MOV		R1,R0
	BL		WriteCMD	; write byte #1
	MOV		R0,	#1	;
	BL		Delay1ms	; wait for 5 ms
	; wait
	
	POP		{LR, R0, R1}
	BX		LR


Init_Clock
	; Bypass the PLL to operate at main 16MHz Osc.
	PUSH	{LR}
	LDR		R0, =SYSCTL_RCC_R
	LDR		R1, [R0]
	BIC		R1, #0x00400000 ; Clearing bit 22 (USESYSDIV)
	BIC		R1, #0x00000030	; Clearing bits 4 and 5 (OSCSRC) use main OSC
	ORR		R1, #0x00000800 ; Bypassing PLL
	
	STR		R1, [R0]
	POP		{LR}
	BX		LR

;Delay milliseconds
Delay1ms
	PUSH	{LR, R0, R3, R4} 
	MOVS	R3, R0
	BNE		L1; if n=0, return
	BX		LR; return

L1	LDR		R4, =5336
			; do inner loop 5336 times (16 MHz CPU clock)
L2	SUBS	R4, R4,#1
	BNE		L2
	SUBS	R3, R3, #1
	BNE		L1
	POP		{LR, R0, R3, R4}
	BX		LR
	
	END