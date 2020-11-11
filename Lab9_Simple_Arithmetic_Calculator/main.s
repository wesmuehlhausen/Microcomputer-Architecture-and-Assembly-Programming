;*************************************************************************************************
; Author: Wesley Muehlhausen
; Project: Lab9
; Program: 16-bit Caculator
; Date Created: November 8, 2020
;
; Description: this program will implement a calculator. 
; Inputs: the keypad
; Outputs: LCD
;*************************************************************************************************



; TO DO: Read carefully all the definitions below and make sure you understand them
; you will need these definitions throughout the project

; Special characters and their positions on LCD for calculator
;*************************************************************************************************
BLANK		EQU	0x20	; ASCII value for " "
POUND_SIGN	EQU	0x23	; ASCII value for "#"
ASTERISK	EQU	0x2A	; ASCII value for "*"
NULL		EQU	0x00	; ASCII value for NULL
LetterA		EQU	0x41	; ASCII value for A
LetterB		EQU	0x42	; ASCII value for B
LetterC		EQU	0x43	; ASCII value for C
LetterD		EQU	0x44	; ASCII value for D

; Positions for the number and the result on LCD (calculator)
;*************************************************************************************************
Size_Cal				EQU	5		; size for result buffer
POS_Ready_Cal			EQU	0x00	; display position for message prompt
POS_Operand1_Cal		EQU	0x03	; display position for the number
POS_Operand_msg_Cal		EQU	0x40	; display position for the operand prompt message
POS_Operation_msg_Cal	EQU	0x40	; display position for the operation message
POS_Error_msg_Cal		EQU	0x40	; display position for the error message
POS_Result_msg_Cal		EQU	0x40	; display position for the result message
POS_Result_Cal			EQU	0x4B	; display position for the result value

; Constant Strings - ROM
;**************************************************************************************************
	AREA Strings, DATA, READONLY, ALIGN=2
Ready_Cal				DCB		"<<            >>", 0;	
Add_msg_Cal				DCB		"+", 0	;
Sub_msg_Cal				DCB		"-", 0	;
Mult_msg_Cal			DCB		"*", 0	;
Div_msg_Cal				DCB		"/", 0	;
Error_msg_Cal			DCB		"Error! Re-enter ", 0	;
Result_msg_Cal			DCB		"Result:         ", 0	;
Blank_line_Cal			DCB		"                ", 0;
Error_blank_Cal			DCB		"       ",0;
Operand1_msg_Cal		DCB		"Input Oprnd1..  ", 0;
Operand2_msg_Cal		DCB		"Input Oprnd2..  ",0;
Operation_msg_Cal		DCB		"Input Oprtn..   ", 0;
; Flags and Variables
;*************************************************************************************************
	AREA 	MyData, DATA, READWRITE, ALIGN=2
Key_ASCII			DCD		0		; ASCII value of the pressed key
Operand1_Cal		DCD		0		; first operand entered from the keypad
Operand2_Cal		DCD		0		; second operand entered from the keypad
Result_Cal			DCD		0		; result of arithmetic operation
ErFlag_Cal			DCD		0		; error flag
Mode_Cal			DCD		0		; operation flag
Buffer_Number		SPACE	Size_Cal+1	; String of BCD digit from the keypad
POS_Operation_Cal	DCD		0		; last display position on line 1
POS_Operand2_Cal	DCD		0	; display position for the second operand
ClearFlag_Cal		DCD		0

; CODE
;**************************************************************************************************
	AREA	MyCode, CODE, READONLY, ALIGN=2
	EXPORT	__main
	EXPORT	Key_ASCII
	EXPORT  Delay1ms		

	IMPORT	Init_LCD_Ports
	IMPORT	Init_LCD
	IMPORT	Init_Keypad
	IMPORT	Set_Position
	IMPORT	Display_Msg
	IMPORT	Display_Char 
	IMPORT 	SYSCTL_RCC_R
	IMPORT	Scan_Keypad
	;IMPORT  Key

__main
	BL		Init_Clock
	BL		Init_LCD_Ports
	BL		Init_LCD
	BL		Init_Keypad
	BL		Init_Vars_Cal			; initializing variables and flags
	LDR		R1, =POS_Ready_Cal		; set the message prompt
	BL		Set_Position	; 
	LDR		R0,	=Ready_Cal	; display the message prompt
	BL		Display_Msg	;
	
Start
	BL  	Clear
	
	BL  	Get_Operand1_Cal
	LDR 	R0, =ClearFlag_Cal
	LDR	R1, [R0]
	CMP 	R1, #1
	BEQ	Start
Re_enter
	BL	Get_Operation_Cal		; get and display the operation 
	LDR 	R0, =ClearFlag_Cal
	LDR	R1, [R0]
	CMP 	R1, #1
	BEQ	Start
	
	BL	Get_Operand2_Cal		; 
	LDR 	R0, =ClearFlag_Cal
	LDR	R1, [R0]
	CMP 	R1, #1
	BEQ	Start
	
	BL	Operation_Cal			; perform arithmetic operation
	BL	Display_Result_Cal		; display the result
	LDR 	R0, =ClearFlag_Cal
	LDR	R1, [R0]
	CMP 	R1, #1
	BEQ	Re_enter
	
;	BL	Wait_for_Clear

Waiting_For_C
	BL		Scan_Keypad
	LDR		R0, =Key_ASCII
	LDRB		R1, [R0]
	CMP		R1, #LetterC
	BNE		Waiting_For_C
	B		Start		
	LTORG
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; **********Subroutine Get_Operand1_Cal- gets the first BCD number as operand and stores its hex equivalent in Operand1_Cal
Get_Operand1_Cal
	PUSH	{R0, R1, R2, R5}
	;1	PROMPT FOR OPERAND ENTRY
	LDR		R1, =POS_Operand_msg_Cal	
	BL		Set_Position	; 
	LDR		R0,	=Operand1_msg_Cal	
	BL		Display_Msg	;
	;2  SET POSITION TO DISPLAY INPUT OPERAND
	LDR		R1, =POS_Operand1_Cal
	BL		Set_Position	
	;3  INITIALIZE A COUNTER FOR THE SIZE OF TJE OPERAND, I = 0;
back1	
	MOV		R5, #0
	;4	READ KEY FROM KEYPAD
	LDR		R0, =Key_ASCII
	LDR		R1, [R0]
	CMP		R1, POUND_SIGN
	;KEY = #?
	BNE		next1;if key != '#', then continue, otherwise compare i and 0
	;;KEY is equal to #
	CMP		R5, #0
	BEQ		back1;if i = 0, read key again
	;ELSE, (i > 0) jump to end condition
	B		end1
	
next1;KEY is NOT equal to #
	;KEY = C?
	CMP		R1, LetterC
	BNE		next2;if key != 'C', then continue, otherwise compare ClearFlag and 1
	;if KEY is equal to C, set clear flag equal to 1
	LDR 	R0, =ClearFlag_Cal
	MOV 	R2, #1
	STR		R2, [R0]
	B		skipToEnd
	
next2;KEY is NOT equal to C
	
	
	
	
	
	
	
	
	
	
	
	
end1



skipToEnd
	POP	{R0, R1, R2, R5}
	BX		LR
	
	
	
	
; Get_Operand2_Cal Subroutine- Similar to Get_Operand1_Cal
Get_Operand2_Cal
	; TO DO: Write the subroutine here.
	BX		LR
	LTORG

; Subroutine String_ASCII_BCD2Hex_Lib- Converts a string of BCD characters pointed to by R0
; to a hex equivalent value in R1
String_ASCII_BCD2Hex_Lib
	PUSH	{R0,R2, LR}
	MOV		R2, #0x00						; initialize R2
String_ASCII_BCD2Hex_Lib_Again
	MOV		R1, #0x00						; initialize R1
	LDRB	R1, [R0]						; R1 <- digit in the string
	ADD		R0, #1							; increment base address
	CMP		R1, #0x00
	BEQ		End_String_ASCII_BCD2Hex_Lib	;
	SUB		R1,	#0x30						; convert to decimal digit
	ADD		R2, R1							; R2 <-- R2 + R1
	MOV		R1, R2							; R1 <-- R2
	MOV		R3, #0x00
	LDRB	R3, [R0]
	CMP		R3, #0x00						; check the next digit in the string before multiplying by 10
	BEQ		End_String_ASCII_BCD2Hex_Lib	;
	MOV		R2, #10							; R2 <- 10
	MUL		R1, R2							; R1=10*R1
	MOV		R2, R1							; copy the result in R2
	B		String_ASCII_BCD2Hex_Lib_Again
End_String_ASCII_BCD2Hex_Lib	
	POP		{R0,R2, LR}
	BX		LR


; Subroutine Hex2DecChar_Lib- Converts a hex value in R1 into an ASCII string of BCD characters in location
; pointed to by R0
Hex2DecChar_Lib
	PUSH	{R0-R5, LR}
	MOV		R2, #0x20    			; blanking the content before writing the string the BCD digits
	MOV		R3, #Size_Cal
Blank_digit
	SUB		R3, #1
	STRB	R2, [R0, R3]			; writing a blank
	CMP		R3, #0x00
	BHI		Blank_digit
	STRB	R3, [R0, #Size_Cal]		; here R3 is NULL so we simply NULL the last byte of the string
	MOV		R3, #Size_Cal
Attach_digit	
	MOV		R2, R1					; quotient in R2
	CMP		R2, #10
	BLO		Last_digit
	MOV		R4, #10					; R4 is temporarily used to hold #10
	UDIV	R1, R2, R4				; R1=floor(R2/10)
	MUL		R5, R1, R4
	SUB		R4, R2, R5				; remainder in R4
	ADD		R4, #0x30				; ASCII
	SUB		R3, #1
	STRB	R4, [R0, R3]			; store the ASCII code of BCD digit
	CMP		R3, #0x00
	BEQ		End_Hex2DecChar_Lib		; typically this will not be executed unless we have an overflow (c.f. Lab7)
	B		Attach_digit
Last_digit							; here we store the quotient as the most significant BCD digit
	ADD		R2, #0x30
	SUB		R3, #1
	STRB	R2, [R0, R3]
End_Hex2DecChar_Lib
	POP		{R0-R5, LR}
	BX		LR
	
	
; Subroutine Clear - clears everything and makes the calculator ready for a new operation
Clear
	PUSH	{LR, R1, R0}
	BL 		Init_Vars_Cal
	LDR		R1, =0x00
	BL		Set_Position
	LDR		R0, =Blank_line_Cal
	BL		Display_Msg				; clear first line
	LDR		R1, =0x40
	BL		Set_Position
	BL		Display_Msg				; clear second line
	LDR		R1, =0x00
	BL		Set_Position
	LDR		R0, =Ready_Cal
	BL		Display_Msg				; display the ready '>' sign
	POP		{LR, R1, R0}
	BX		LR
	LTORG
	
; Subroutine Init_Vars_Cal - initializes variables and flags
Init_Vars_Cal
	PUSH	{LR, R1, R0}
	LDR		R0, =Mode_Cal
	MOV		R1, #0x00
	STR		R1, [R0]			; clear operation flag
	LDR		R0, =Operand1_Cal
	STR		R1, [R0]			; clear operand1
	LDR		R0, =Operand2_Cal
	STR		R1, [R0]			; clear operand2
	LDR		R0, =Result_Cal
	STR		R1, [R0]			; clear the result
	LDR		R0, =ErFlag_Cal
	STR		R1, [R0]			; clear the error flag
	POP		{LR, R1, R0}
	LDR		R0, =ClearFlag_Cal		; 
	STR		R1, [R0]			; clear the clear flag
	POP		{LR, R1, R0}
	BX		LR

; Get_Operation_Cal subroutine- Receives and displays the operation
Get_Operation_Cal
; TO DO: Write this subroutine here.
	BX		LR

; Operation_Cal Subroutine- Carries out the specified operation
Operation_Cal
; TO DO: Write the subroutine here.
	BX		LR
	
	
; Display_Result_Cal Subroutine- Display the final outcome
Display_Result_Cal
; TO DO: Write the subroutine here.
	BX		LR
	
	
Init_Clock
	; Bypass the PLL to operate at main 16MHz Osc.
	PUSH	{LR, R1, R0}
	LDR		R0, =SYSCTL_RCC_R
	LDR		R1, [R0]
	BIC		R1, #0x00400000 ; Clearing bit 22 (USESYSDIV)
	BIC		R1, #0x00000030	; Clearing bits 4 and 5 (OSCSRC) use main OSC
	ORR		R1, #0x00000800 ; Bypassing PLL
	
	STR		R1, [R0]
	POP		{LR, R1, R0}
	BX		LR

;Delay milliseconds
Delay1ms
	PUSH	{LR, R0, R3, R4}
	MOVS	R3, R0
	BNE		L1; if n=0, return
	BX		LR; return

L1	LDR		R4, =5334
			; do inner loop 5336 times (16 MHz CPU clock)
L2	SUBS	R4, R4,#1
	BNE		L2
	SUBS	R3, R3, #1
	BNE		L1
	POP		{LR, R0, R3, R4}
	BX		LR

	END