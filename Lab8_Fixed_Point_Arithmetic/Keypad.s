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
MSG_POS					EQU		0x00
NUM_POS1				EQU		0x0D
NUM_POS2				EQU		NUM_POS1+1

; RAM variables
;******************************************************************************************
	AREA	RAMData, DATA,	ALIGN=2
Key_ASCII	SPACE	4	; ASCII value of the pressed key
RFlag		SPACE	4	; read flag
Key			SPACE	4	; value read from Port D
Xunit		DCD			0	; units digit is stored in X_unit
Xten		DCD			0	; tens digit is stored in X_ten	

; ROM data (Prompt message)
;******************************************************************************************
	AREA	ROMData, DATA, READONLY, ALIGN=2
Msg_prompt	DCB	"Key Entered: ", 0	;


; Lab6 Code
;******************************************************************************************
	THUMB
	AREA	MyCode, CODE, READONLY, ALIGN=2
	
	EXPORT	Init_Keypad
	EXPORT	Set_Position
	EXPORT  Read_Key 
	
	EXPORT  SplitNum
	EXPORT  WriteCMD
	EXPORT  Delay1ms
	
	EXPORT  Key_ASCII
	EXPORT  RFlag
	EXPORT  Key
	EXPORT  Xunit
	EXPORT  Xten
	EXPORT  NUM_POS1
	EXPORT  NUM_POS2
	
	IMPORT  Display_Char
; SetPrompt subroutine

; Initialize Keypad subroutine
Init_Keypad;;;---->
	; Port A is already initialized output by LCD port intiazlization
	; Here we do Port D only 
	PUSH	{LR, R1, R0}
	LDR		R0, =SYSCTL_RCGCGPIO_R	; Sending a clock to Port D
	LDR		R1, [R0]
	ORR		R1, #0x08
	STR		R1, [R0]
	
	LDR		R0, =GPIO_PORTD_DIR_R	; Lowest nibble of Port D is input
	LDR		R1, [R0]
	BIC		R1, #0x0F
	STR		R1, [R0]
	
	LDR		R0, =GPIO_PORTD_DEN_R	; Lowest nibble of Port D is digital
	LDR		R1, [R0]
	ORR		R1, #0x0F
	STR		R1, [R0]
	POP		{LR, R1, R0}
	BX		LR
	
	
	
	
; Subroutine Read_Key - reads two keys from the keypad
Read_Key ;;;---->
	PUSH	{LR, R1, R0}
	BL		Scan_Keypad	; reads the first digit and stores it in Key_ASCII
	
	LDR		R1, =NUM_POS1 ;set the position 
	BL		Set_Position
	
	LDR		R0, =Key_ASCII ;;display first digit
	LDRB	R1, [R0]
	BL 		Display_Char
	
	SUB		R1, #0x30
	LDR		R0, =Xten
	STR		R1, [R0]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
	
	BL		Scan_Keypad	; reads the second digit and stores it in Key_ASCII
	
	LDR		R1, =NUM_POS2 ;set the position 
	BL		Set_Position
	
	LDR		R0, =Key_ASCII ;display second digit
	LDRB	R1, [R0]
	BL 		Display_Char
	
	SUB		R1, #0x30
	LDR		R0, =Xunit
	STR		R1, [R0]
	
	POP		{LR, R1, R0}	
	BX		LR
	LTORG ; This is an assembler directive that instructs the assembler to assemble
		 ; the above code segment immediately (used when the code is long)
	
	
	
; Subroutine Scan_Keypad - scans the whole keypad for a key press
Scan_Keypad;;;---->
	PUSH	{LR, R1, R0}
	
jumpToStart
	
	BL		Scan_Col_0
	LDR		R0, =RFlag		; check the flag
	LDR		R1, [R0]
	CMP		R1, #0x01
	BEQ		jumpToEnd		;if flag equal to 1, jump to end
	
	BL		Scan_Col_1
	LDR		R0, =RFlag		; check the flag
	LDR		R1, [R0]
	CMP		R1, #0x01
	BEQ		jumpToEnd 		;if flag equal to 1, jump to end
	
	BL		Scan_Col_2
	LDR		R0, =RFlag		; check the flag
	LDR		R1, [R0]
	CMP		R1, #0x01
	BEQ		jumpToEnd 		;if flag equal to 1, jump to end
	
	BL		Scan_Col_3
	LDR		R0, =RFlag		; check the flag
	LDR		R1, [R0]
	CMP		R1, #0x00
	BEQ		jumpToStart 		;if flag equal to 0, jump to start
	
jumpToEnd
	
	POP		{LR, R1, R0}	
	BX		LR

; Subroutine Scan_Col_0 - scans column 0
;******************************************************************************************
Scan_Col_0
	PUSH	{LR, R1, R0}
	MOV		R1, #0x04	; PA2 = 1 but PA3-PA5 are 0's
	LDR		R0, =GPIO_PORTA_DATA_R
	STR		R1, [R0]
	
	BL		Read_PortD	;
	LDR		R0, =RFlag		; check the flag
	LDR		R1, [R0]
	CMP		R1, #0x00
	BEQ		Scan_Col_0_done	; No Key press on Col_0
	
	LDR		R0, =Key
	LDR		R1, [R0]
	AND		R1, #0x0F	; we care only about the low 4 pins of port D
	CMP		R1, #0x01	; check for Row 0
	BEQ		Found_key_1
	CMP		R1, #0x02	; check for Row 1
	BEQ		Found_key_4
	CMP		R1, #0x04	; check for Row	2
	BEQ		Found_key_7
	CMP		R1, #0x08	; check for Row 3
	BEQ		Found_key_star
	B		Scan_Col_0_done	;
Found_key_1
	LDR		R0, =Key_ASCII ;if 1 is found
	MOV		R1, #0x31
	STR		R1, [R0]
	B		Scan_Col_0_done	; 
Found_key_4
	LDR		R0, =Key_ASCII;if 4 is found
	MOV		R1, #0x34
	STR		R1, [R0]
	B		Scan_Col_0_done	;
Found_key_7
	LDR		R0, =Key_ASCII;if 7 is found
	MOV		R1, #0x37
	STR		R1, [R0]
	B		Scan_Col_0_done	;
Found_key_star
	LDR		R0, =Key_ASCII;if * is found
	MOV		R1, #0x2A
	STR		R1, [R0]
Scan_Col_0_done
	POP		{LR, R1, R0}
	BX		LR
	
; Subroutine Scan_Col_1 - scans column 1
;******************************************************************************************
Scan_Col_1
	; Similar to Scan_Col_0 but with minor modifications
	PUSH	{LR, R1, R0}
	MOV		R1, #0x08; PA3=1 and PA2, PA4, PA5 are 0's	
	LDR		R0, =GPIO_PORTA_DATA_R
	STR		R1, [R0]
	
	BL		Read_PortD	;
	LDR		R0, =RFlag		; check the flag
	LDR		R1, [R0]
	CMP		R1, #0x00
	BEQ		Scan_Col_1_done	;
	
	LDR		R0, =Key
	LDR		R1, [R0]
	AND		R1, #0x0F	; we care only about the low nibble of port D
	CMP		R1, #0x01	; check for Row 0
	BEQ		Found_key_2
	CMP		R1, #0x02	; check for Row 1
	BEQ		Found_key_5
	CMP		R1, #0x04	; check for Row	2
	BEQ		Found_key_8
	CMP		R1, #0x08	; check for Row 3
	BEQ		Found_key_0
	B		Scan_Col_1_done	;
Found_key_2
	LDR		R0, =Key_ASCII;if 2 is found
	MOV		R1, #0x32
	STR		R1, [R0]
	B		Scan_Col_1_done	; 
Found_key_5
	LDR		R0, =Key_ASCII;if 5 is found
	MOV		R1, #0x35
	STR		R1, [R0]
	B		Scan_Col_1_done	;
Found_key_8
	LDR		R0, =Key_ASCII;if 8 is found
	MOV		R1, #0x38
	STR		R1, [R0]
	B		Scan_Col_1_done	;
Found_key_0
	LDR		R0, =Key_ASCII;if 0 is found
	MOV		R1, #0x30
	STR		R1, [R0]
Scan_Col_1_done
	POP		{LR, R1, R0}
	BX		LR

; Subroutine Scan_Col_2 - scans column 2
;******************************************************************************************
Scan_Col_2
	PUSH	{LR, R1, R0}
	MOV		R1, #0x10 ;PA4=1 and PA2, PA3, PA5 are 0's
	LDR		R0, =GPIO_PORTA_DATA_R
	STR		R1, [R0]
	
	BL		Read_PortD	;
	LDR		R0, =RFlag		; check the flag
	LDR		R1, [R0]
	CMP		R1, #0x00
	BEQ		Scan_Col_2_done	;
	
	LDR		R0, =Key
	LDR		R1, [R0]
	AND		R1, #0x0F	; we care only about the low nibble of port 
	CMP		R1, #0x01	; check for Row 0
	BEQ		Found_key_3
	CMP		R1, #0x02	; check for Row 1
	BEQ		Found_key_6
	CMP		R1, #0x04	; check for Row	2
	BEQ		Found_key_9
	CMP		R1, #0x08	; check for Row 3
	BEQ		Found_key_pound
	B		Scan_Col_2_done	;
Found_key_3
	LDR		R0, =Key_ASCII;if 3 is found
	MOV		R1, #0x33
	STR		R1, [R0]
	B		Scan_Col_0_done	; 
Found_key_6
	LDR		R0, =Key_ASCII;if 6 is found
	MOV		R1, #0x36
	STR		R1, [R0]
	B		Scan_Col_0_done	;
Found_key_9
	LDR		R0, =Key_ASCII;if 9 is found
	MOV		R1, #0x39
	STR		R1, [R0]
	B		Scan_Col_0_done	;
Found_key_pound
	LDR		R0, =Key_ASCII;if # is found
	MOV		R1, 0x23
	STR		R1, [R0]
Scan_Col_2_done
	POP		{LR, R1, R0}
	BX		LR
	
; Subroutine Scan_Col_3 - scans column 3
;******************************************************************************************
Scan_Col_3
	PUSH	{LR, R1, R0}
	MOV		R1, #0x20;   PA5=1 and PA2-PA4 are 0's
	LDR		R0, =GPIO_PORTA_DATA_R
	STR		R1, [R0]
	
	BL		Read_PortD	;
	LDR		R0, =RFlag		; check the flag
	LDR		R1, [R0]
	CMP		R1, #0x00
	BEQ		Scan_Col_3_done	;
	
	LDR		R0, =Key
	LDR		R1, [R0]
	AND		R1, #0x0F	; we care only about the low nibble of port 
	CMP		R1, #0x01	; check for Row 0
	BEQ		Found_key_A
	CMP		R1, #0x02	; check for Row 1
	BEQ		Found_key_B
	CMP		R1, #0x04	; check for Row	2
	BEQ		Found_key_C
	CMP		R1, #0x08	; check for Row 3
	BEQ		Found_key_D
	B		Scan_Col_3_done	;
Found_key_A
	LDR		R0, =Key_ASCII;if A is found
	MOV		R1, #0x41
	STR		R1, [R0]
	B		Scan_Col_3_done	; 
Found_key_B
	LDR		R0, =Key_ASCII;if B is found
	MOV		R1, #0x42
	STR		R1, [R0]
	B		Scan_Col_3_done	;
Found_key_C
	LDR		R0, =Key_ASCII;if C is found
	MOV		R1, #0x43
	STR		R1, [R0]
	B		Scan_Col_3_done	;
Found_key_D
	LDR		R0, =Key_ASCII;if D is found
	MOV		R1, #0x44
	STR		R1, [R0]
Scan_Col_3_done
	POP		{LR, R1, R0}
	BX		LR
	
	
	
	
	
	
; Subroutine Read_PortD - reads from Port D and implements debouncing key 
;	press
Read_PortD	
    ; Follows the flowchart in the lab guide
	PUSH	{R0-R2,LR}			
	;******************************************
	;Reset the RFlag.
	LDR R0, =RFlag
    LDRB R1, [R0]
    MOV R1, #0x00
    STR R1, [R0]
	
	;******************************************
	;Read PortD into R1, and store R1
	; in the memory location Key.
	LDR R0, =GPIO_PORTD_DATA_R
	LDR R1, [R0]
	LDR R0, =Key
	STR R1, [R0]
	;******************************************
	;1) check the carry if 1 or 0
	ANDS    R1, #0x0F
	BEQ		skipToEnd
	
	;2) delay 90 ms
	MOV		R0, #90
	BL		Delay1ms
	
	;3) Read Port D into R2
	LDR R0, =GPIO_PORTD_DATA_R
	LDR R2, [R0]
	AND R2, #0x0F
	CMP	R1, R2
	BNE skipToEnd
	
	;4) RFlag = 0
	LDR R0, =RFlag
    LDRB R1, [R0]
    MOV R1, #0x01
    STR R1, [R0]
	
skipToEnd	
	POP 	{R0-R2,LR}
	BX		LR
		
	
; Set_Position - sets the position for displaying data in LCD

Set_Position ;;;---->
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

	

; WriteCMD - sends a command (lower 4 bits) in ACCA to LCD
WriteCMD ;;;---->
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

SplitNum ;;;---->
	PUSH	{LR}
	MOV		R0, R1
	AND		R0, #0x0F		; mask the upper 4 bits
	LSR		R1,	R1, #4 		
	POP		{LR}
	BX		LR

; Init_LCD - initializes LCD according to the initializing sequence indicated
;	  by the manufacturer


	
;Delay milliseconds
Delay1ms ;;;---->
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



		