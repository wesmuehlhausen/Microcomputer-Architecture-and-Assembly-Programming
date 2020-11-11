SYSCTL_RCGCGPIO_R       EQU 	0x400FE608
SYSCTL_RCC_R            EQU 	0x400FE060
GPIO_PORTA_DIR_R        EQU  	0x40004400
GPIO_PORTA_DATA_R       EQU  	0x400043FC
GPIO_PORTA_DEN_R        EQU  	0x4000451C
GPIO_PORTC_DIR_R        EQU  	0x40006400
GPIO_PORTC_DATA_R       EQU  	0x400063FC
GPIO_PORTC_DEN_R        EQU  	0x4000651C
GPIO_PORTD_DATA_R       EQU 	0x400073FC
GPIO_PORTD_DIR_R        EQU 	0x40007400
GPIO_PORTD_DEN_R        EQU		0x4000751C
GPIO_PORTE_DIR_R        EQU 	0x40024400
GPIO_PORTE_DATA_R       EQU 	0x400243FC
GPIO_PORTE_DEN_R        EQU		0x4002451C

; Lab constants
;*****************************************************************************************
;MSG_POS					EQU		0x00

; RAM variables
;******************************************************************************************
	AREA	RAMData, DATA,	ALIGN=2


; ROM data (Prompt message)
;******************************************************************************************
	AREA	ROMData, DATA, READONLY, ALIGN=2
;Msg_prompt	DCB	"Key Entered: ", 0	;

; Lab6 Code
;******************************************************************************************
	THUMB
	AREA	MyCode, CODE, READONLY, ALIGN=2
	
	EXPORT	Init_Clock
	EXPORT	Init_LCD_Ports
	EXPORT	Init_LCD
	EXPORT	Display_Msg	
	EXPORT  Display_Char
	
	IMPORT  SplitNum
	IMPORT  WriteCMD
	IMPORT  Delay1ms
	
	IMPORT  Key_ASCII
	IMPORT  RFlag
	IMPORT  Xunit
	IMPORT  Xten
	IMPORT  NUM_POS1
	IMPORT  NUM_POS2
	IMPORT  Key
		
	
; SetPrompt subroutine

; Subroutine Scan_Col_0 - scans column 0
;******************************************************************************************

;*****************************************************************************************
;*****************************************************************************************

Init_Clock;;;;;;;;;;;;;;;;;;;;;;;;;;;;;000000
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
	
Init_LCD_Ports;;;;;;;;;;;;;;;;;;;;;;;;;;;;;000000
	; Initialize PORTs A, C and E. Note: this initialization uses an UNFRIENDLY code
	PUSH	{LR}
	MOV		R3, #0x15; Activating the clocks for the three ports.
	LDR		R2,=SYSCTL_RCGCGPIO_R
	STR		R3, [R2]
	NOP
	NOP
	MOV		R3, #0x3C; Pins PTA2-PTA5 are outputs
	LDR		R2, =GPIO_PORTA_DIR_R
	STR		R3, [R2]
	MOV		R3, #0x40; Pin PC6 is output
	LDR		R2, =GPIO_PORTC_DIR_R
	STR		R3, [R2]
	MOV		R3, #0x01; Pin PE0 is output
	LDR		R2,	=GPIO_PORTE_DIR_R
	STR		R3, [R2]
	
	MOV		R3, #0xFF; PORTA's signals are digital
	LDR		R2, =GPIO_PORTA_DEN_R
	STR		R3, [R2]
	LDR		R2, =GPIO_PORTC_DEN_R; PORTC's signals are digital
	STR		R3, [R2]
	LDR		R2, =GPIO_PORTE_DEN_R; PORTC's signals are digital
	STR		R3, [R2]
	POP		{LR}
 	BX		LR	

Display_Msg;;;;;;;;;;;;;;;;;;;;;;;;;;;;;000000
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

Display_Char;;;;;;;;;;;;;;;;;;;;;;;;;;;;;000000
	PUSH	{LR, R1, R0}
	BL		SplitNum	;
	BL		WriteData	; write upper 4 bits of ASCII byte
	MOV		R1, R0
	BL		WriteData	; write lower 4 bits of ASCII byte
	MOV		R0, #0x01	
	BL		Delay1ms	; wait for 1ms
	POP		{LR, R1, R0}
	BX		LR


; WriteData - sends a data (lower 4 bits) in ACCA to LCD

WriteData;;;;;;;;;;;;;;;;;;;;;;;;;;;;;000000
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


; Init_LCD - initializes LCD according to the initializing sequence indicated
;	  by the manufacturer

Init_LCD;;;;;;;;;;;;;;;;;;;;;;;;;;;;;000000
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

	

	
	END



		