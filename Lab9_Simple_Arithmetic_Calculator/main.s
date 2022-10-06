;*************************************************************************************************
; Author: Kevin Wolff, Wesley Muehlhausen, Johnathan Arnott
; Project: Lab9
; Program: 16-bit Caculator
; Date Created: November 8, 2020
; Description: this program will implement a calculator. 
; Inputs: the keypad
; Outputs: LCD
;*************************************************************************************************


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
	
	IMPORT  Delay1ms		
	IMPORT	Init_LCD_Ports
	IMPORT	Init_LCD
	IMPORT	Init_Keypad
	IMPORT	Set_Position
	IMPORT	Display_Msg
	IMPORT	Display_Char 
	IMPORT 	SYSCTL_RCC_R
	IMPORT	Scan_Keypad


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
	PUSH	{LR, R0-R2}
	LDR		R1, =POS_Operand_msg_Cal		; Prompt for operand1
	BL		Set_Position
	LDR		R0, =Operand1_msg_Cal
	BL		Display_Msg
	LDR		R1, =POS_Operand1_Cal			; Set position to display input operand
	BL		Set_Position
	MOV		R2, #0							; Initialize counter i = 0
GL1	BL		Scan_Keypad						; Read Key
	LDR		R1, =Key_ASCII
	LDR		R1, [R1]
	CMP		R1, #POUND_SIGN					; #?
	BNE		GS0
	CMP		R2, #0
	BLS		GL1								; if not i>0 go back to read key
	B		GN1
GS0	CMP		R1, #LetterC					; C?
	BNE		GS1
	LDR		R0, =ClearFlag_Cal				; Clear flag = 1 and end if C
	MOV		R1, #1
	STR		R1, [R0]
	B		GE
GS1	CMP		R1, #0x30							; if not >= 0 go back to read key
	BLO		GL1
	CMP		R1, #0x39							; if not <= 9 go back to read key
	BHI		GL1
	LDR		R0, =Buffer_Number				; Store into buffer + i
	STR		R1, [R0, R2]
	MOV		R0, R1							; Display key on LCD, do I increment the position?
	BL		Display_Char
	ADD		R2, #1							; i = i + 1
	CMP		R2, #Size_Cal
	BNE		GL1
GN1	LDR		R0, =Buffer_Number				; Store NULL in Buffer + i
	MOV		R1, #0x00
	STR		R1, [R0, R2]
	BL		String_ASCII_BCD2Hex_Lib		; Convert number in Buffer to Hex
	LDR		R0, =Operand1_Cal				; Store hex into operand1
	STR		R1, [R0]
	;ADD		R2, #1							; Set position for operation 
	ADD		R2, #POS_Operand1_Cal
	LDR		R1, =POS_Operation_Cal
	STR		R2, [R1]
	ADD		R2, #1							; Set position for operand2
	LDR		R1, =POS_Operand2_Cal
	STR		R2, [R1]
	
	
GE	POP		{LR, R0-R2}
	BX		LR
	
	
; Get_Operand2_Cal Subroutine- Similar to Get_Operand1_Cal
Get_Operand2_Cal
	PUSH	{LR, R0-R2}
	LDR		R1, =POS_Operand_msg_Cal		; Prompt for operand1
	BL		Set_Position
	LDR		R0, =Operand2_msg_Cal
	BL		Display_Msg
	LDR		R1, =POS_Operand2_Cal			; Set position to display input operand
	LDR		R1, [R1]
	BL		Set_Position
	MOV		R2, #0							; Initialize counter i = 0
GL2	BL		Scan_Keypad						; Read Key
	LDR		R1, =Key_ASCII
	LDR		R1, [R1]
	CMP		R1, #POUND_SIGN					; #?
	BNE		GG0
	CMP		R2, #0
	BLS		GL2								; if not i>0 go back to read key
	B		GN2
GG0	CMP		R1, #LetterC					; C?
	BNE		GG1
	LDR		R0, =ClearFlag_Cal				; Clear flag = 1 and end if C
	MOV		R1, #1
	STR		R1, [R0]
	B		GE2
GG1	CMP		R1, #0x30							; if not >= 0 go back to read key
	BLO		GL2
	CMP		R1, #0x39							; if not <= 9 go back to read key
	BHI		GL2
	LDR		R0, =Buffer_Number				; Store into buffer + i
	STR		R1, [R0, R2]
	MOV		R0, R1							; Display key on LCD, do I increment the position?
	BL		Display_Char
	ADD		R2, #1							; i = i + 1
	CMP		R2, #Size_Cal
	BNE		GL2
GN2	LDR		R0, =Buffer_Number				; Store NULL in Buffer + i
	MOV		R1, #0x00
	STR		R1, [R0, R2]
	BL		String_ASCII_BCD2Hex_Lib		; Convert number in Buffer to Hex
	LDR		R0, =Operand2_Cal				; Store hex into operand1
	STR		R1, [R0]
GE2	POP 	{LR, R0-R2}
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
	LDR		R0, =ClearFlag_Cal		; 
	STR		R1, [R0]			; clear the clear flag
	POP		{LR, R1, R0}
	BX		LR

; Get_Operation_Cal subroutine- Receives and displays the operation
Get_Operation_Cal
; TO DO: Write this subroutine here.
	PUSH	{LR, R0-R2}
	LDR		R1, =POS_Operation_msg_Cal		; Prompt for operation
	BL		Set_Position
	LDR		R0, =Operation_msg_Cal
	BL		Display_Msg
	LDR		R1, =POS_Operation_Cal			; Set position to display input operand
	LDR		R1, [R1]
	BL		Set_Position
	
GL3	BL		Scan_Keypad						; Read Key
	LDR		R1, =Key_ASCII
	LDR		R1, [R1]
	CMP		R1, #LetterA					;A?
	BNE		GO1
	MOV		R2, #0x2B						;Sign = + in ascii
	B		OM
GO1	CMP		R1, #LetterB					;B?
	BNE		GO2
	MOV		R2, #0x2D						;Sign = - in ascii
	B		OM
GO2	CMP		R1, #ASTERISK					;*?
	BNE		GO3
	MOV		R2, R1							;Sign = * in ascii
	B		OM
GO3	CMP		R1, #LetterD					;D?
	BNE		GO4
	MOV		R2, #0x2F						;Sign = / in ascii
	B		OM
GO4	CMP		R1, #LetterC					;C?
	BNE		GL3
	LDR		R0, =ClearFlag_Cal				;clear flag = 1
	MOV		R1, #1
	STR		R1, [R0]
	B		OE
OM	LDR		R0, =Mode_Cal					; Mode = Key
	STR		R1, [R0]
	MOV		R1, R2							; Display sign
	BL		Display_Char
OE	POP		{LR, R0-R2}
	BX		LR

; Operation_Cal Subroutine- Carries out the specified operation
Operation_Cal
; TO DO: Write the subroutine here.
	PUSH	{LR, R0-R2}
	LDR		R2, =Mode_Cal
	LDR		R2, [R2]
	CMP		R2, #LetterA		;Addition?
	BNE		OC1
	LDR		R0, =Operand1_Cal	;Compute addition
	LDR		R1, [R0]
	LDR		R0, =Operand2_Cal
	LDR		R0, [R0]
	ADD		R1, R1, R0
	LDR		R0, =Result_Cal		;Store result
	STR		R1, [R0]
	B		CV					;Go to overflow check
OC1	CMP		R2, #LetterB		;Subtraction?
	BNE		OC2
	LDR		R0, =Operand1_Cal	;Compute subtraction
	LDR		R1, [R0]
	LDR		R0, =Operand2_Cal
	LDR		R0, [R0]
	CMP		R1, R0				;Operand1 < Operand2?
	BHS		SG
	B		SV
SG	SUB		R1, R1, R0
	LDR		R0, =Result_Cal		;Store result
	STR		R1, [R0]
	B		CV
OC2	CMP		R2, #LetterD		;Division?
	BNE		OC3
	LDR		R0, =Operand1_Cal	;Compute division
	LDR		R1, [R0]
	LDR		R0, =Operand2_Cal
	LDR		R0, [R0]
	CMP		R0, #0
	BEQ		SV
	UDIV	R1, R1, R0
	LDR		R0, =Result_Cal		;Store result
	STR		R1, [R0]
	B		CV
OC3	LDR		R0, =Operand1_Cal	;Compute multiplication
	LDR		R1, [R0]
	LDR		R0, =Operand2_Cal
	LDR		R0, [R0]
	MUL		R1, R1, R0
	LDR		R0, =Result_Cal		;Store result
	STR		R1, [R0]
	B		CV
CV	MOV		R0, #0xFFFF			;Overflow?
	CMP		R1, R0				
	BLS		CE
SV	LDR		R0, =ErFlag_Cal		;Error flag = 1
	MOV		R1, #1
	STR		R1, [R0]
CE	POP		{LR, R0-R2}
	BX		LR
	
	
; Display_Result_Cal Subroutine- Display the final outcome
Display_Result_Cal
; TO DO: Write the subroutine here.
	PUSH	{LR, R0, R1}
	LDR		R0, =ErFlag_Cal			
	LDR		R1, [R0]
	CMP		R1, #1					;Error flag = 1?
	BEQ		DEM
	LDR		R1, =Result_Cal			;Convert from Hex (R1) to ASCII string in Buffer (R0)
	LDR		R1, [R1]
	BL		Hex2DecChar_Lib
	LDR		R1, =POS_Result_Cal		;Set position
	BL		Set_Position
	BL		Display_Msg				;Display buffer
	B		DRE
DEM	MOV		R1, #0					;Error flag = 0
	LDR		R1, =POS_Error_msg_Cal		;Set position
	BL		Set_Position
	LDR		R0, =Error_msg_Cal
	BL		Display_Msg
	STR		R1, [R0]
	MOV		R0, #2000				;Wait 2 seconds
	BL		Delay1ms
	BL		Clear					;Clear the display
	LDR		R0, =ClearFlag_Cal		;Clear flag = 1
	MOV		R1, #1
	STR		R1, [R0]
DRE	POP		{LR, R0, R1}
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


	END