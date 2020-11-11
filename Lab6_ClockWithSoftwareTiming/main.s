;******************************************************************************************
; Author: Wesley Muehlhausen
; Project: Lab6
; Program: Clock with Software Timing
; Date Created: October 21, 2020
; 
;
; Description: this program will implement a digital clock that displays
;		the time in the military format.
; Inputs: none
; Outputs: LCD display and LEDs
;******************************************************************************************
SYSCTL_RCGCGPIO_R       EQU   0x400FE608
SYSCTL_RCC_R            EQU   0x400FE060
GPIO_PORTA_DIR_R        EQU   0x40004400
GPIO_PORTA_DATA_R       EQU   0x400043FC
GPIO_PORTA_DEN_R        EQU   0x4000451C
GPIO_PORTB_DATA_R       EQU   0x400053FC
GPIO_PORTB_DIR_R        EQU   0x40005400
GPIO_PORTB_DEN_R        EQU   0x4000551C
GPIO_PORTC_DIR_R        EQU   0x40006400
GPIO_PORTC_DATA_R       EQU   0x400063FC
GPIO_PORTC_DEN_R        EQU   0x4000651C
GPIO_PORTE_DIR_R        EQU   0x40024400
GPIO_PORTE_DATA_R       EQU   0x400243FC
GPIO_PORTE_DEN_R        EQU   0x4002451C
; Display position for Hour, Minute, and Second on LCD
;******************************************************************************************
POS_HOUR	EQU	0x44			; display position for Hour
POS_MINUTE	EQU	(POS_HOUR+3)	; display position for Minute
POS_SECOND	EQU	(POS_MINUTE+3)	; display position for Second

;******************************************************************************************
; Special characters and their positions on LCD
;******************************************************************************************
COLON		EQU	0x3A			; ASCII value for ":"
COL_POS1	EQU	(POS_HOUR+2)	;
COL_POS2	EQU	(POS_MINUTE+2)	;
;******************************************************************************************

	THUMB
	AREA 	MyData, DATA, READONLY, ALIGN=2
Msg_hd	DCB		"Pacific time", 0 ; message header
	
	
	;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	; To Do: Define Hour, Minute, and Second as RAM variables, 
	; 1-byte each.
	AREA 	MyData2, DATA, READWRITE, ALIGN=2
Hour 		DCB		0
Minute		DCB		0
Second		DCB		0
	;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	AREA	MyCode, CODE, READONLY, ALIGN=2
	EXPORT	__main

__main
	
	BL		Init_Hardware_Lab6 ; This subroutine initializes the hardware needed for Lab6.
								; You should write it below.
	
	LDR		R0, =Hour	;;init Hour to 0x23
	LDRB	R1, [R0]
	MOV		R1, #0x23
	STR		R1, [R0]
	
	LDR		R0, =Minute ;;init Minute to 0x59
	LDRB	R1, [R0]
	MOV		R1, #0x59
	STR		R1, [R0]
	
	LDR		R0, =Second ;;init Second to 0x55
	LDRB	R1, [R0]
	MOV		R1, #0x55
	STR		R1, [R0]
	
	
	MOV		R1, #0x02
	BL		Set_Position
	LDR		R0, =Msg_hd
	BL		Display_Msg
	LDR		R1,	=COL_POS1
	BL		Set_Position;
	LDR		R1,	=COLON		;
	BL		Display_Char	; display the colon
	LDR		R1,	=COL_POS2
	BL		Set_Position	;
	LDR		R1,	=COLON		;
	BL		Display_Char	; display the colon
again
	BL		Display			; This subroutine displays the current time. Write it below.
	BL		Timer			; This subroutine tracks the time in steps of 250 ms and 
							; adjusts the LED shifts accordingly. Write it below.
	BL		Update			; After a whole second has passed, this subroutine updates
							; the new time value. Write it below.	
	B		again

Display	
	PUSH	{R0-R1, LR}
Disp_Hour ; This code segment displays the current value of Hour. Make sure you understand it. 
; NOTE: the values of Hour, Minute, and Second are stored in the BCD format. We add the 0x30 
; to convert them to ASCII before display!


	LDR		R1,	=POS_HOUR	; set the display position for Hour
	BL		Set_Position	;
	LDR		R0,	=Hour
	LDRB	R1, [R0]
	BL		SplitNum       ; R1 <- MS, R0 <- LS
	ADD		R1, R1,	#0x30	; convert to ASCII
	BL		Display_Char	; display the tenth digit of Hour
	MOV		R1,R0
	ADD		R1,	R1,	#0x30		; convert to ASCII
	BL		Display_Char	; display the unit digit of Hour
				
Disp_Minute
	; Write a code segment to display the current value of Minute.
	LDR		R1,	=POS_MINUTE	; set the display position for Hour
	BL		Set_Position	;
	LDR		R0,	=Minute
	LDRB	R1, [R0]
	BL		SplitNum       ; R1 <- MS, R0 <- LS
	ADD		R1, R1,	#0x30	; convert to ASCII
	BL		Display_Char	; display the tenth digit of Hour
	MOV		R1,R0
	ADD		R1,	R1,	#0x30		; convert to ASCII
	BL		Display_Char	; display the unit digit of Hour
		
Disp_Second
	;Write a code segment to display the current value of Second.
	LDR		R1,	=POS_SECOND	; set the display position for Hour
	BL		Set_Position	;
	LDR		R0,	=Second
	LDRB	R1, [R0]
	BL		SplitNum       ; R1 <- MS, R0 <- LS
	ADD		R1, R1,	#0x30	; convert to ASCII
	BL		Display_Char	; display the tenth digit of Hour
	MOV		R1,R0
	ADD		R1,	R1,	#0x30		; convert to ASCII
	BL		Display_Char	; display the unit digit of Hour
	
	
	POP		{R0-R1, LR}		
	BX		LR





; Timer Block
Timer
; This subroutine keeps track of time in steps of 250 ms and 
; updates the LED shifts accordingly. After 4 cycles of 250 ms LED shifts, 
; we know that a whole second has passed. It is time to leave this subroutine
; and increment the time by one second through the Update subroutine below.
; To write the Timer subroutine, follow the flowchart provided in the lab guide.
	PUSH	{LR, R0-R4}
							;1)
	MOV		R1, #4			;R1 is COUNT set to 4
	MOV		R3, #0x01		;Start at light PB0
nextLight					;2)
	LDR R0, =GPIO_PORTB_DATA_R
	STRB R3, [R0]			;turn on light at R3
							;3)
	MOV R0, #250 			;250ms delay
	BL Delay1ms
							;4)
	LSL		R3, #1			;switch to next light
	SUB		R1, #1			; decrement COUNT
	CMP		R1, #0			;if R1 COUNT is equal to zero, end
	BNE		nextLight
	
	POP		{LR, R0-R4}
	BX		LR
	
	
; Update Block
Update
	PUSH	{LR, R0-R4}
	
	;SECONDS
	LDR		R0,	=Second 	;point to Second and then load value into R1
	LDRB	R1, [R0]
	BL		Inc_with_Adjustment	 	 	;seconds = seconds + 1
	STRB	R1, [R0]
	CMP		R1, #0x60		 	;compare seconds with 59
	BNE		UpdateTime	;if not, go back to incrimenting
	MOV		R1, #0x00		 	;set seconds to zero
	STRB	R1, [R0]
	;MINUTES
	LDR		R0,	=Minute 	;point to Minute and then load value into R1
	LDRB	R1, [R0]
	BL		Inc_with_Adjustment	 	;Minutes = Minutes + 1
	STRB	R1, [R0]
	CMP		R1, #0x60		 	;compare Minutes with 59
	BNE		UpdateTime	;if not, go back to incrimenting
	MOV		R1, #0x00		 	;set Minutes to zero
	STRB	R1, [R0]
	;HOURS
	LDR		R0,	=Hour 	;point to Hour and then load value into R1
	LDRB	R1, [R0]
	BL		Inc_with_Adjustment	  	;Hours = Hours + 1
	STRB	R1, [R0]
	CMP		R1, 0x24		 	;compare Hours with 23
	BNE		UpdateTime	;if not, go back to incrimenting
	MOV		R1, #0x00		 	;set hours to zero
	STRB	R1, [R0]
UpdateTime
	
	
    POP		{LR, R0-R4}
	BX		LR



	
; Increment with Adjustment -- Note: this subroutine adjusts the units digit only since tens adigits
;									are taken care of by the reset procedure above
Inc_with_Adjustment
	MOV		R3, R1
	AND		R3, R3, #0x0F
	CMP		R3, #0x09
	BNE		No_Adjustment
	ADD		R1, R1, #0x06
No_Adjustment	
	ADD		R1, R1, #0x01
	BX		LR
	
; Initializing PORTB and Subroutines from Lab5:
;*******************************************
;*******************************************
Init_Hardware_Lab6
	PUSH	{LR}
	BL		Init_Clock
	BL		Init_Ports
	BL		Init_LCD
	POP		{LR}
	BX		LR

Init_Clock
	; Bypass the PLL to operate at main 16MHz Osc.
	PUSH	{LR}
	LDR		R0, =SYSCTL_RCC_R
	LDR		R1, [R0]
	BIC		R1, #0x00400000 ; Clearing bit 22 (USESYSDIV)
	BIC		R1, #0x00000030	; Clearing bits 4 and 5 (OSCSRC) use main OSC
;	ORR		R1, #0x00000010	; Using internal 16 MHz internal OSC
	ORR		R1, #0x00000800 ; Bypassing PLL
	
	STR		R1, [R0]
	POP		{LR}
	BX		LR
	
Init_Ports
	; Initialize PORTs A, B, C and E. 
	PUSH	{R2, R3, LR}
	; To Do: Activate the clocks for the four ports.
	LDR R2, =SYSCTL_RCGCGPIO_R
    LDR R3, [R2]
    ORR R3, #0x17 ;--FE.DCBA
    STR R3, [R2]  ;0001.0111
	NOP			;0x  1    7
	NOP
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Set the direction of PB3-PB0 (The LED pins) as output.
	LDR		R2, =GPIO_PORTA_DIR_R
	LDR		R3, [R2]
	ORR		R3, #0x3C
	STR		R3, [R2]
	
	LDR		R2, =GPIO_PORTB_DIR_R
	LDR		R3, [R2]
	ORR		R3, #0x0F ;0, 1, 2, 3 output
	STR		R3, [R2]
	
	LDR		R2, =GPIO_PORTC_DIR_R
	LDR		R3, [R2]
	ORR		R3, #0x40
	STR		R3, [R2]
	
	LDR		R2,	=GPIO_PORTE_DIR_R
	LDR		R3, [R2]
	ORR		R3, #0x01
	STR		R3, [R2]
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Set PB3-PB0 signals as digital.
	LDR		R2, =GPIO_PORTA_DEN_R
	LDR		R3, [R2]
	ORR		R3, #0x3C
	STR		R3, [R2]
	
	LDR		R2, =GPIO_PORTB_DEN_R; PORTB's signals are digital
	LDR		R3, [R2]
	ORR		R3, #0x0F ;0, 1, 2, 3 output
	STR		R3, [R2]
	
	LDR		R2, =GPIO_PORTC_DEN_R; PORTC's signals are digital
	LDR		R3, [R2]
	ORR		R3, #0x40
	STR		R3, [R2]
	
	LDR		R2, =GPIO_PORTE_DEN_R; PORTC's signals are digital
	LDR		R3, [R2]
	ORR		R3, #0x01
	STR		R3, [R2]
	POP		{R2, R3, LR}
 	BX		LR	

Display_Msg
	PUSH	{LR, R0, R1}
disp_again
	LDRB	R1, [R0] 		; R1 <- ASCII data
	CMP		R1,	#0x00		; check for the end of the string
	BEQ		disp_end			  
	BL		Display_Char
	ADD		R0, R0, #1		; increment R0
	B		disp_again	
disp_end
	POP		{LR, R0, R1}
	BX		LR
		
; Display_Char - writes an ASCII value in ACCA to LCD

Display_Char
	PUSH	{LR, R1, R0}
	BL		SplitNum	;
	BL		WriteData	; write upper 4 bits of ASCII byte
	MOV		R1, R0
	BL		WriteData	; write lower 4 bits of ASCII byte
	MOV		R0, #0x01	
	BL		Delay1ms	; wait for 1ms
	POP	{LR, R1, R0}
	BX		LR

; Set_Position - sets the position for displaying data in LCD

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

; WriteData - sends a data (lower 4 bits) in ACCA to LCD

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

; WriteCMD - sends a command (lower 4 bits) in ACCA to LCD

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
	PUSH	{LR}
	MOV		R0, #30		;
	BL		Delay1ms		; wait 30ms for LCD to power up
	
	; send byte 1 of code to LCD
	MOV		R1,	#0x30		; R1 <- byte #1 of code: $30
	BL		SplitNum	;
	BL		WriteCMD	; write byte #1
	MOV		R0,	#5		;
	BL		Delay1ms	; wait for 5 ms
	
	; send byte 2 of code to LCD
	MOV		R1,	#0x30		; R1 <- byte #2 of code: $30
	BL		SplitNum	;
	BL		WriteCMD	; write byte #2
	MOV		R0, #1		;
	BL		Delay1ms	; wait for 1ms
	
	; send byte 3 of code to LCD
	MOV		R1,	#0x30		; R1 <- byte #3 of code: $30
	BL		SplitNum	;
	BL		WriteCMD	; write byte #3
	MOV		R0,	#1		;
	BL		Delay1ms	; wait for 1ms
	
	; send byte 4 of code to LCD
	MOV		R1,	#0x20		; R1 <- byte #4 of code: $20
	BL		SplitNum	;
	BL		WriteCMD	; write byte #4
	MOV		R0,	#1		;
	BL		Delay1ms	; wait for 1ms
	
	; send byte 5 of code to LCD
	MOV		R1,	#0x28		; R1 <- byte #5 of code: $28
				;  db5 = 1, db4 = 0 (DL = 0 - 4 bits), 
				;  db3 = 1 (N = 1 - 2 lines),
				;  db2 = 0 (F = 0 - 5x7 dots).
	BL		SplitNum	;
	BL		WriteCMD	; write upper 4 bits of byte #5
	MOV		R1,R0
	BL		WriteCMD	; write lower 4 bits of byte #5
	MOV		R0,	#1		;
	BL		Delay1ms	; wait for 1ms
	
	; send byte 6 of code to LCD
	MOV		R1,	#0x0C		; R1 <- byte #6 of code: $0C
				;  db3 = 1, db2 = 1 (D = 1 - display ON)
				;  db1 = 0 (C = 0 - cursor OFF)
				;  db0 = 0 (B = 0 - blink OFF)
	BL		SplitNum	;
	BL		WriteCMD	; write upper 4 bits of byte #6
	MOV		R1,R0
	BL		WriteCMD	; write lower 4 bits of byte #6
	MOV		R0,	#1		;
	BL		Delay1ms	; wait for 1ms
	
	; send byte 7 of code to LCD
	MOV		R1,	#0x01		; R1 <- byte #7 of code: $01
				;  db0 = 1 (clears display and returns
				;	the cursor home).		 
	BL		SplitNum	;
	BL		WriteCMD	; write upper 4 bits of byte #8
	MOV		R1,R0
	BL		WriteCMD	; write lower 4 bits of byte #8
	MOV		R0,	#3		;
	BL		Delay1ms	; wait for 3ms
	
	; send byte 8 of code to LCD
	MOV		R1,	#0x06		; R1 <- byte #8 of code: $06
				;  db2 = 1,
				;  db1 = 1 (I/D = 1 - increment cursor)
				;  db0 = 0 (S = 0 - no display shift)
	BL		SplitNum	;
	BL		WriteCMD	; write upper 4 bits of byte #7
	MOV		R1,R0
	BL		WriteCMD	; write lower 4 bits of byte #7
	MOV		R0,	#1		;
	BL		Delay1ms	; wait for 1ms
	POP		{LR}
	BX		LR

	
;Delay milliseconds
Delay1ms
	PUSH	{LR, R0, R3}
	MOVS	R3, R0
	BNE		L1; if n=0, return
	BX		LR; return

L1	LDR		R4, =5334
			; do inner loop 5336 times (16 MHz CPU clock)
L2	SUBS	R4, R4,#1
	BNE		L2
	SUBS	R3, R3, #1
	BNE		L1
	POP		{LR, R0, R3}
	BX		LR
	
	END