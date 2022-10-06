;*************************************************************************************************
; Author: Wesley Muehlhausen
; Project: Lab10
; Program: Digital Clock with External Interrupt IRQ
; Date Created: November 17, 2020
;
; Description: this program will implement digital clock. The external interrupt will set
;	the clock tick.
; Inputs: the keypad
; Outputs: LCD
;*************************************************************************************************
; Register definitions
;***************************************************************************************
SYSCTL_RCC_R            EQU		0x400FE060
SYSCTL_RCGCTIMER_R      EQU		0x400FE604
SYSCTL_RCGCGPIO_R       EQU   	0x400FE608

NVIC_EN0_R              EQU   	0xE000E100
NVIC_PRI0_R             EQU   	0xE000E400


GPIO_PORTA_DIR_R        EQU   	0x40004400
GPIO_PORTA_DEN_R        EQU   	0x4000451C
GPIO_PORTA_DATA_R       EQU   	0x400043FC
GPIO_PORTA_IS_R         EQU   	0x40004404
GPIO_PORTA_IBE_R        EQU   	0x40004408
GPIO_PORTA_IEV_R        EQU   	0x4000440C
GPIO_PORTA_IM_R         EQU   	0x40004410
GPIO_PORTA_RIS_R        EQU   	0x40004414
GPIO_PORTA_MIS_R        EQU   	0x40004418
GPIO_PORTA_ICR_R        EQU   	0x4000441C
GPIO_PORTA_AFSEL_R      EQU   	0x40004420
GPIO_PORTA_AMSEL_R      EQU   	0x40004528

GPIO_PORTB_DATA_R       EQU   	0x400053FC
GPIO_PORTB_DIR_R        EQU   	0x40005400
GPIO_PORTB_DEN_R        EQU   	0x4000551C

GPIO_PORTC_DIR_R        EQU  	0x40006400
GPIO_PORTC_DATA_R       EQU  	0x400063FC
GPIO_PORTC_DEN_R        EQU  	0x4000651C

GPIO_PORTD_DATA_R       EQU 	0x400073FC
GPIO_PORTD_DIR_R        EQU 	0x40007400
GPIO_PORTD_DEN_R        EQU		0x4000751C

GPIO_PORTE_DIR_R        EQU 	0x40024400
GPIO_PORTE_DATA_R       EQU 	0x400243FC
GPIO_PORTE_DEN_R        EQU		0x4002451C

GPIO_PORTF_AFSEL_R      EQU   	0x40025420
GPIO_PORTF_DEN_R        EQU   	0x4002551C
GPIO_PORTF_AMSEL_R      EQU   	0x40025528
GPIO_PORTF_PCTL_R       EQU   	0x4002552C
	
TIMER0_CTL_R            EQU		0x4003000C
TIMER0_CFG_R            EQU  	0x40030000
TIMER0_TBMR_R           EQU  	0x40030008
TIMER0_TBILR_R          EQU  	0x4003002C
TIMER0_RIS_R            EQU  	0x4003001C
TIMER0_TBV_R            EQU  	0x40030054
TIMER0_ICR_R            EQU  	0x40030024
TIMER0_TBMATCHR_R       EQU  	0x40030034
;************************************************************
; Constants
;*************************************************************************************************
UP_HOUR		EQU	0x00	; display Hour, Minute, and Second
UP_MINUTE	EQU	0x01	; display Minute and Second
UP_SECOND	EQU	0x02	; display Second
UP_NO		EQU	0x03	; no display

POS_HOUR	EQU	0x44		; display position for Hour
POS_MINUTE	EQU	(POS_HOUR+3)	; display position for Minute
POS_SECOND	EQU	(POS_MINUTE+3)	; display position for Second

COLON		EQU	0x3A		; ASCII value for ":"
COL_POS1	EQU	(POS_HOUR+2)	;
COL_POS2	EQU	(POS_MINUTE+2)	;
;*************************************************************************************************
; ROM Data
;*************************************************************************************************
	AREA ROM, DATA, READONLY, ALIGN=2
Msg_hd	DCB		"US Pacific Zone", 0 ; message header

; RAM Data
;**************************************************************************************************
	AREA MyData, READWRITE, ALIGN=2
Xunit			DCD			0	; units digit is stored in X_unit
Xten			DCD			0	; tens digit is stored in X_ten	
Key_ASCII		DCD			0	; ASCII Key of the pressed key
RFlag			DCD			0	; read flag
Key				DCD			0	; key read from Port A
Hour			DCD			0	; BCD variable for hour
Minute			DCD			0	; BCD variable for Minute
Second			DCD			0	; BCD variable for Second
TCount			DCD			0	; keep count for 0.2s loop
Light			DCD			0	; shift bit light
TickCtr			DCD			0	; clock tick count
Second_Count	DCD			0	; second counter
DFlag			DCD			0	; display flag for Hour, Minute, and Second
TFlag			DCD			0	; timer flag
UFlag			DCD			0	; update flag
;	Code
;******************************************************************************************
	AREA	MyCode, CODE, READONLY, ALIGN=2
	EXPORT	__main
__main
	BL		Init_Hardware_Lab10				; initialize system clock, LCD, Keypad, LEDs, and Timer 0B.
	BL		Init_Vars_Clock					; initialize all flags and variables
	BL		Init_Time						; initialize time
	MOV		R1, #0x00
	BL		Set_Position
	LDR		R0, =Msg_hd
	BL		Display_Msg
	BL		Config_PA7						; configure PA7 for external interrupt

Loop
	BL		Set_Time
	BL		Timer_Clock		; timer check
	BL		Update_Clock		; update time
	BL		Display_Clock		; display time
	B		Loop		; 

; Subroutine Init_Hardware_Lab10
Init_Hardware_Lab10
	PUSH	{LR}
	BL		Init_Clock
	BL		Init_Timer0
	BL		Init_LEDs
	BL		Init_LCD
	BL		Init_Keypad
	POP		{LR}
	BX		LR
	
; Subroutine Init_Clock
Init_Clock
	; Bypass the PLL to operate at internal osc. over 4, i.e., 4 MHz Osc. (Different from previous labs)
	PUSH	{LR, R1, R0}
	LDR		R0, =SYSCTL_RCC_R
	LDR		R1, [R0]
	BIC		R1, #0x00400000 ; Clearing bit 22 (USESYSDIV)
	ORR		R1, #0x00000020	; setting bits 4-5 for internal OSC/4
	BIC		R1, #0x00000010	; clearing bit 4  (OSCSRC) for OSC/4
	ORR		R1, #0x00000800 ; Bypassing PLL
	STR		R1, [R0]
	POP		{LR, R1, R0}
	BX		LR

Init_Timer0
	; Timer0-B is configured as a 16 bit timer to generate a 100 Hz signal on PF1
	PUSH	{R0-R2, LR}
	LDR		R0, =SYSCTL_RCGCTIMER_R 	; selecting Timer 0
	MOV		R1, #0x01
	STR		R1, [R0]
	
	LDR		R0, =SYSCTL_RCGCGPIO_R		; activating Ports A,B, F (Friendly Code)
	LDR		R1, [R0]
	ORR		R1, #0x23
	STR		R1, [R0]
	
	
	LDR		R0, =GPIO_PORTF_DEN_R		; enable digital function of PF1
	LDR		R1, [R0]
	ORR		R1, #0x02
	STR		R1, [R0]
	
	LDR		R0, =GPIO_PORTF_AFSEL_R     ; enabling alternate function of PF1
	LDR		R1, [R0]
	ORR		R1, #0x02
	STR		R1, [R0]
	
	
	LDR		R0, =GPIO_PORTF_PCTL_R		; slecting the T0PCC1 function (sending 0111 on field 7:4)
	LDR		R1, [R0]					
	ORR		R1, #0x70
	BIC		R1, #0x80
	STR		R1, [R0]

	
; initializing the timer
	
	; ensure the timer B is disabled
	LDR		R0, =TIMER0_CTL_R			; clearing bit 8 of TIMER0_CTL_R
	LDR		R1, [R0]
	BIC		R1, #0x00000100
	STR		R1, [R0]
	
	; config for 16-bit counting 
	LDR		R0, =TIMER0_CFG_R
	MOV		R1, #0x04
	STR		R1, [R0]
	
	; configure the timer mode register for periodic PWM mode
	LDR		R0, =TIMER0_TBMR_R
	LDR		R1, [R0]
	LDR		R2, =0x00000C0A
	ORR		R1, R2
	;BIC		R1, #0x00					; TBMR field is set to 0x02
	STR		R1, [R0]
	
	; loading the count value 
	LDR		R0, =TIMER0_TBILR_R 
	LDR		R1, =0x9C40;				; equivalent of 40*10^3 decimal
									; counting value under a 4 MHz clock
	STR		R1, [R0]
	
	; setting the match value to 0
	LDR		R0, =TIMER0_TBMATCHR_R
	LDR		R1, =0x4E20;0xF0F0;0x8C40;				; half the ILR value for balanced clock duty cycle
	STR		R1, [R0]
	
	; enabling the timer
	LDR		R0, =TIMER0_CTL_R			; setting bit 8 of TIMER0_CTL_R
	LDR		R1, [R0]
	ORR		R1, #0x00000100
	STR		R1, [R0]
	POP		{R0-R2, LR}
	BX		LR

; Subroutine Init_LEDs	(PB3-PB0)
Init_LEDs
	;*************************************************************
	;*************************************************************
	;*************************************************************
	;*************************************************************
	; Write the subroutine Init_LEDs to initialize the 4 LEDs
	; connected to port B pins PB3-PB0. Make sure you initialize
	; the LEDs through a friendly code.
	PUSH	{R0-R2, LR}
	
	LDR		R0,=SYSCTL_RCGCGPIO_R
	LDR		R1, [R0] 
	ORR 	R1, R1, #0x02 ;00000010 for port B
	STR 	R1, [R0]
	NOP
	NOP
	LDR		R0, =GPIO_PORTB_DIR_R
	LDR 	R1, [R0]
	ORR 	R1, #0x0F ; output on PF2
	STR 	R1, [R0]
	LDR 	R0, =GPIO_PORTB_DEN_R ; 7) enable on PF2
	LDR 	R1, [R0]
	ORR 	R1, #0x0F ; 1 means enable digital I/O
	STR 	R1, [R0]		
	
	POP		{R0-R2, LR}
	;*************************************************************
	;*************************************************************
	;*************************************************************
	;*************************************************************

; Subroutine Init_LCD
Init_LCD
	PUSH	{LR, R1, R0}
	LDR		R0,=SYSCTL_RCGCGPIO_R
	LDR		R1, [R0]
	ORR		R1, #0x15
	STR		R1, [R0]
	LDR		R0, =GPIO_PORTA_DIR_R
	LDR		R1, [R0]
	ORR		R1, #0x3C; Pins PTA2-PTA5 are outputs
	STR		R1, [R0]
	LDR		R0, =GPIO_PORTC_DIR_R
	LDR		R1, [R0]
	ORR		R1, #0x40; Pin PC6 is output
	STR		R1, [R0]
	LDR		R0,	=GPIO_PORTE_DIR_R
	LDR		R1, [R0]
	ORR		R1, #0x01; Pin PE0 is output
	STR		R1, [R0]
	LDR		R0, =GPIO_PORTA_DEN_R
	LDR		R1, [R0]
	ORR		R1, #0xFF; PORTA's signals are digital
	STR		R1, [R0]
	LDR		R0, =GPIO_PORTC_DEN_R; PORTC's signals are digital
	STR		R1, [R0]
	LDR		R0, =GPIO_PORTE_DEN_R; PORTE's signals are digital
	STR		R1, [R0]
	
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
	POP		{LR, R1, R0}
 	BX		LR	
	LTORG
	
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
	POP		{LR, R1, R0}
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
	POP		{LR, R1,R0}
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

; Subroutine Set_Blink_ON: sets the blink on at the character indicated by R1
Set_Blink_ON
	PUSH	{LR, R1, R0}
	MOV		R1, #0x0D
	BL		SplitNum
	BL		WriteCMD
	MOV		R1, R0
	BL		WriteCMD
	MOV		R0, #0x01
	BL		Delay1ms
	POP		{LR, R1, R0}
	BX		LR

; Subroutine Set_Blink_OFF: sets the blink off 
Set_Blink_OFF
	PUSH	{LR, R1, R0}
	MOV		R1, #0x0C
	BL		SplitNum
	BL		WriteCMD
	MOV		R1, R0
	BL		WriteCMD
	MOV		R0, #0x01
	BL		Delay1ms
	POP		{LR, R1, R0}
	BX		LR

; Initialize Keypad subroutine
Init_Keypad
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

; Subroutine Scan_Keypad - scans the whole keypad for a key press
Scan_Keypad
	PUSH	{LR, R1, R0}
Scan_Keypad_Again 
	BL		Scan_Col_0	; PA2 = 1, scan the rows
	LDR		R0, =RFlag
	LDR		R1, [R0]		; check the flag
	CMP		R1, #0x00
	BNE		End_Scan_Keypad	;
	BL		Scan_Col_1	; PA3 = 1, scan the rows
	LDR		R0, =RFlag		; check the flag
	LDR		R1, [R0]
	CMP		R1, #0x00
	BNE		End_Scan_Keypad	;
	BL		Scan_Col_2	; PA4 = 1, scan the rows
	LDR		R0, =RFlag		; check the flag
	LDR		R1, [R0]
	CMP		R1, #0x00
	BNE		End_Scan_Keypad	;
	BL		Scan_Col_3	; PA5 = 1, scan the rows
	LDR		R0, =RFlag		; check the flag
	LDR		R1, [R0]
	CMP		R1, #0x00
	BNE		End_Scan_Keypad	;
	B		Scan_Keypad_Again;
End_Scan_Keypad
	POP		{LR, R1, R0}
	BX		LR

; Subroutine Read_PortD - reads from Port D and implements debouncing key 
;	press
Read_PortD	
	PUSH	{R0-R2, LR}			
	LDR		R0,	=RFlag		; reset the RFlag
	MOV		R1, #0x00
	STR		R1, [R0]
	LDR		R0,	=GPIO_PORTD_DATA_R		; read from Port D
	LDR		R1, [R0]
	LDR		R0, =Key
	STR		R1, [R0] ; save R1 into a temporary variable
	ANDS	R1, #0x0F
	BEQ		Done_Keypad; check for a low value

	MOV		R0, #90		; add 90ms delay for
	BL		Delay1ms	; debouncing the switch
	
	LDR		R0, =GPIO_PORTD_DATA_R		; read from Port D
	LDR		R2, [R0]
	AND		R2, #0x0F
	CMP		R1, R2			; compare R1 and R2
	BNE		Done_Keypad	;
	LDR		R0, =RFlag		; set the flag
	LDR		R1, [R0]
	ADD		R1, #0x01
	STR		R1, [R0]
Done_Keypad
	POP 	{R0-R2,LR}
	BX		LR
	
	LTORG
; Subroutine Scan_Col_0 - scans column 0
;******************************************************************************************
Scan_Col_0
	PUSH	{LR, R1, R0}
	MOV		R1, #0x04	; PA2 = 1
	LDR		R0, =GPIO_PORTA_DATA_R
	STR		R1, [R0]
	
	BL		Read_PortD	;
	LDR		R0, =RFlag		; check the flag
	LDR		R1, [R0]
	CMP		R1, #0x00
	BEQ		Scan_Col_0_done	;
	
	LDR		R0, =Key
	LDR		R1, [R0]
	AND		R1, #0x0F	; we care only about the low nibble of port 
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
	LDR		R0, =Key_ASCII
	MOV		R1, #0x31
	STR		R1, [R0]
	B		Scan_Col_0_done	; 
Found_key_4
	LDR		R0, =Key_ASCII
	MOV		R1, #0x34
	STR		R1, [R0]
	B		Scan_Col_0_done	;
Found_key_7
	LDR		R0, =Key_ASCII
	MOV		R1, #0x37
	STR		R1, [R0]
	B		Scan_Col_0_done	;
Found_key_star
	LDR		R0, =Key_ASCII
	MOV		R1, #0x2A
	STR		R1, [R0]
Scan_Col_0_done
	POP		{LR, R1, R0}
	BX		LR
	
; Subroutine Scan_Col_1 - scans column 1
;******************************************************************************************
Scan_Col_1
	PUSH	{LR, R1, R0}
	MOV		R1, #0x08	; PA3 = 1
	LDR		R0, =GPIO_PORTA_DATA_R
	STR		R1, [R0]
	
	BL		Read_PortD	;
	LDR		R0, =RFlag		; check the flag
	LDR		R1, [R0]
	CMP		R1, #0x00
	BEQ		Scan_Col_1_done	;
	
	LDR		R0, =Key
	LDR		R1, [R0]
	AND		R1, #0x0F	; we care only about the low nibble of port 
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
	LDR		R0, =Key_ASCII
	MOV		R1, #0x32
	STR		R1, [R0]
	B		Scan_Col_1_done	; 
Found_key_5
	LDR		R0, =Key_ASCII
	MOV		R1, #0x35
	STR		R1, [R0]
	B		Scan_Col_1_done	;
Found_key_8
	LDR		R0, =Key_ASCII
	MOV		R1, #0x38
	STR		R1, [R0]
	B		Scan_Col_1_done	;
Found_key_0
	LDR		R0, =Key_ASCII
	MOV		R1, #0x30
	STR		R1, [R0]
Scan_Col_1_done
	POP		{LR, R1, R0}
	BX		LR

; Subroutine Scan_Col_2 - scans column 2
;******************************************************************************************
Scan_Col_2
	PUSH	{LR, R1, R0}
	MOV		R1, #0x10	; PA4 = 1
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
	LDR		R0, =Key_ASCII
	MOV		R1, #0x33
	STR		R1, [R0]
	B		Scan_Col_0_done	; 
Found_key_6
	LDR		R0, =Key_ASCII
	MOV		R1, #0x36
	STR		R1, [R0]
	B		Scan_Col_0_done	;
Found_key_9
	LDR		R0, =Key_ASCII
	MOV		R1, #0x39
	STR		R1, [R0]
	B		Scan_Col_0_done	;
Found_key_pound
	LDR		R0, =Key_ASCII
	MOV		R1, #0x23
	STR		R1, [R0]
Scan_Col_2_done
	POP		{LR, R1, R0}
	BX		LR
	
; Subroutine Scan_Col_3 - scans column 3
;******************************************************************************************
Scan_Col_3
	PUSH	{LR, R1, R0}
	MOV		R1, #0x20	; PA5 = 1
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
	LDR		R0, =Key_ASCII
	MOV		R1, #0x41
	STR		R1, [R0]
	B		Scan_Col_3_done	; 
Found_key_B
	LDR		R0, =Key_ASCII
	MOV		R1, #0x42
	STR		R1, [R0]
	B		Scan_Col_3_done	;
Found_key_C
	LDR		R0, =Key_ASCII
	MOV		R1, #0x43
	STR		R1, [R0]
	B		Scan_Col_3_done	;
Found_key_D
	LDR		R0, =Key_ASCII
	MOV		R1, #0x44
	STR		R1, [R0]
Scan_Col_3_done
	POP		{LR, R1, R0}
	BX		LR
	LTORG
	
; Subroutine Config_PA7 configuring PA7 for -ve edge trigger and requesting interrupt 
Config_PA7
	PUSH	{LR, R1, R0}
	CPSID	I								; disabling interrupts
	;*************************************************************
	;*************************************************************
	;*************************************************************
	;*************************************************************
	;*************************************************************
	; Write the Config_PA7 subroutine for -ve edge trigger
	LDR R0, =SYSCTL_RCGCGPIO_R ; activate clock for PortF
	LDR R1, [R0]
	ORR R1, #0x01		;0x01 for port A
	STR R1, [R0]
	;LDR R0, =TickCtr    ;FallingEdges ;Initialize counter
	;MOV R1, #0
	;STR R1, [R0]
	LDR R0, =GPIO_PORTA_DIR_R
	LDR R1, [R0]
	BIC R1, #0x80 ; PA7 is an input
	STR R1, [R0]
	LDR R0, =GPIO_PORTA_DEN_R
	LDR R1, [R0]
	ORR	R1, #0x80 ; Enable digital I/O on PF4
	STR R1, [R0]
	LDR R0, =GPIO_PORTA_AFSEL_R
	LDR R1, [R0]
	BIC R1, #0x80 ; disable alternate function
	STR R1, [R0]
	LDR R0, =GPIO_PORTA_IS_R
	LDR R1, [R0]
	BIC R1, #0x80 ; edge-sensitive
	STR R1, [R0]
	LDR R0, =GPIO_PORTA_IBE_R
	LDR R1, [R0] ; not on both edges
	BIC R1, #0x80
	STR R1, [R0]
	LDR R0, =GPIO_PORTA_IEV_R
	LDR R1, [R0]
	BIC R1, #0x80 ; falling edge trigger
	STR R1, [R0]
	LDR R0, =GPIO_PORTA_ICR_R
	LDR R1, [R0]
	ORR R1, #0x80 ; clearing interrupts for PA7
	STR R1, [R0]
	LDR R0, =GPIO_PORTA_IM_R
	LDR R1, [R0]
	ORR R1, #0x80 ; arm an interrupt on PA7
	STR R1, [R0]
	LDR R0, =NVIC_PRI0_R ;;set priority
	LDR R1, [R0]
	BIC R1, #0x000000FF
	ORR R1, #0x00000020 ; priority level 1
	STR R1, [R0]
	LDR R0, =NVIC_EN0_R   ;enable interrupt
	LDR R1, [R0]
	ORR R1, #0x00000001 ; enabling interrupts on Port A
	STR R1, [R0]
	;*************************************************************
	;*************************************************************
	;*************************************************************
	;*************************************************************
	;*************************************************************
	;*************************************************************
	CPSIE	I								; enabling interrupts	
	POP		{LR, R1, R0}
	BX		LR

; Subroutine Init_Time - clears time variables
;*************************************************************************************************
Init_Time
	PUSH	{LR, R1, R0}
	LDR		R0, =Hour
	MOV		R1, #0x23   	; set Hour to 23
	STR		R1, [R0]
	LDR		R0, =Minute
	MOV		R1, #0x59		; set Minute to 59
	STR		R1, [R0]
	LDR		R0, =Second		
	MOV		R1, #0x55		; set Second to 55
	STR		R1, [R0]
	POP		{LR, R1, R0}
	BX		LR
; Subroutine Init_Vars_Clock - initializes variables and flags
;*************************************************************************************************
Init_Vars_Clock
	PUSH	{LR, R1, R0}
	LDR		R0, =TCount			; keep count for 0.25s loop
	MOV		R1, #0x00
	STR		R1, [R0]
	MOV		R1, #0x01
	LDR		R0, =Light			; shift bit light
	STR		R1, [R0]
	LDR		R0, =DFlag
	MOV		R1, #UP_HOUR
	STR		R1, [R0]			; set the display flag for Hour, Minute, and Second
	MOV		R1, #0x00
	LDR		R0, =TFlag
	STR		R1, [R0]			; clear timer flag
	LDR		R0, =UFlag
	STR		R1, [R0]			; update flag
	LDR		R0, =TickCtr		
	STR		R1, [R0]			; clear the clock tick count
	POP		{LR, R1, R0}
	BX		LR

; Subroutine Set_Time - sets Hour, Minute, or Second
;*************************************************************************************************
Set_Time
	PUSH	{R0-R2, LR}
	;*************************************************************
	;*************************************************************
	;*************************************************************
	;*************************************************************
	;*************************************************************
	; Complete this part of Set_Time subroutine as specified
	; in the flowchart.
	LDR		R0, =GPIO_PORTD_DATA_R
	LDR		R1, [R0]
	AND		R1, R1, #0x0E   ;and with 0000.1110 to get values of PD1-PD3
	CMP		R1, #0		;compare with 0 
	BEQ		skipToEnd1		;if equal to 0, skip to end
	CPSID	I				;disable interrupts
	MOV		R1, #0		;Clear Flags
	LDR		R0, =TFlag
	STR		R1, [R0]			
	LDR		R0, =UFlag
	STR		R1, [R0]		
	LDR		R0, =TickCtr		
	STR		R1, [R0]
	LDR		R0, =GPIO_PORTD_DATA_R  ;Get data from Port D
	LDR		R1, [R0]
	MOV		R2, R1					;Put copy of R1 in R2
	AND		R2, #0x08				;Isolate the value in SW2 = PD3 = 00001000 = 0x09
	CMP		R2, #0x08				;If it is true
	BEQ		SW2
	MOV		R2, R1					;Put copy of R1 in R2
	AND		R2, #0x04				;Isolate the value in SW3 = PD2 = 00000100 = 0x04
	CMP		R2, #0x04				;If it is true
	BEQ		SW3
	B		SW4
	B		TimSet_Next
	;*************************************************************
	;*************************************************************
	;*************************************************************
	;*************************************************************
	;*************************************************************
	;*************************************************************
SW2
    BL		Set_Hour	; set the Hour
	B		TimSet_Next	;	
SW3
    BL		Set_Minute	; set the Minute
	B		TimSet_Next	;
SW4
    BL		Set_Second	;
TimSet_Next
	CPSIE	I			; turn on interrupt
TimeSet_End
	MOV		R0, #100
	BL		Delay1ms
skipToEnd1
	POP		{R0-R2, LR}
	BX		LR

	LTORG
; the binary values of input keys in Xten and Xunit locations
Read_Key
	PUSH	{LR, R1, R0}
;	LDR		R1, =NUM_POS1	;
;	BL		Set_Position	;
	BL		Scan_Keypad	; read the first digit
	LDR		R0, =Key_ASCII	;
	LDR		R1, [R0]
	BL		Display_Char	; display the first digit
    SUB		R1, #0x30		; get the binary value of key
	LDR		R0, =Xten
	STRB	R1, [R0]
;	LDR		R1,	=NUM_POS2	;
;	BL		Set_Position	;
	BL		Scan_Keypad	; read the second digit
	LDR		R0, =Key_ASCII	;
	LDR		R1, [R0]
	BL		Display_Char	; display the second digit
	SUB		R1, #0x30
	LDR		R0, =Xunit
	STRB	R1, [R0]
	POP		{LR, R1, R0}	
	BX		LR

; Subroutine Set_Hour: input 2-digit hour from keypad
Set_Hour
	PUSH	{LR, R1, R0}
Set_Hour_Again
	MOV		R1, #POS_HOUR		;
	BL		Set_Position		; set the position of the Hour digit
	BL		Set_Blink_ON		; set the blink ON
	LDR		R0, =1000			; Delay 1 second before accepting value
	BL		Delay1ms
	BL		Read_Key			; read values from the keypad
	LDR		R0, =Xten			; check tens value
	LDRB	R1, [R0]
	CMP		R1, #0x02
	BHI		Set_Hour_Again
	BLO		Hour_Units_Full
	LDR		R0, =Xunit
	LDRB	R1, [R0]
	CMP		R1, #0x03
	BHI		Set_Hour_Again
	B		Save_Hour
Hour_Units_Full
	LDR		R0, =Xunit
	LDRB	R1, [R0]
	CMP		R1, #0x09
	BHI		Set_Hour_Again
Save_Hour
	LDR		R0, =Xten
	LDRB	R1, [R0]
	LSL		R1, #4				
	LDR		R0, =Xunit
	LDRB	R0, [R0]			
	ORR		R1, R0				
	LDR		R0, =Hour
	STR		R1, [R0]
	BL		Set_Blink_OFF		; set the blink ON	
	POP		{LR, R1, R0}
	BX		LR

; Set_Minute - sets the Minutes
;*************************************************************************************************
Set_Minute
	PUSH	{LR, R1, R0}
Set_Minute_Again
	MOV		R1, #POS_MINUTE		;
	BL		Set_Position		; set the position of the Minute digit
	BL		Set_Blink_ON		; set the blink ON
	LDR		R0, =1000			; Delay 1 second before accepting value
	BL		Delay1ms
	BL		Read_Key			; read values from the keypad
	LDR		R0, =Xten			; check tens value
	LDRB	R1, [R0]
	CMP		R1, #0x05
	BHI		Set_Minute_Again
	LDR		R0, =Xunit
	LDRB	R1, [R0]
	CMP		R1, #0x09
	BHI		Set_Minute_Again
Save_Minute
	LDR		R0, =Xten
	LDRB	R1, [R0]
	LSL		R1, #4
	LDR		R0, =Xunit
	LDRB	R0, [R0]			
	ORR		R1, R0				
	LDR		R0, =Minute
	STR		R1, [R0]
	BL		Set_Blink_OFF		; set the blink ON	
	POP		{LR, R1, R0}
	BX		LR


; Set_Minute - sets the Minutes
;*************************************************************************************************
Set_Second
	PUSH	{LR, R1, R0}
Set_Second_Again
	MOV		R1, #POS_SECOND		;
	BL		Set_Position		; set the position of the Second digit
	BL		Set_Blink_ON		; set the blink ON
	LDR		R0, =1000			; Delay 1 second before accepting value
	BL		Delay1ms
	BL		Read_Key			; read values from the keypad
	LDR		R0, =Xten			; check tens value
	LDRB	R1, [R0]
	CMP		R1, #0x05
	BHI		Set_Second_Again
	LDR		R0, =Xunit
	LDRB	R1, [R0]
	CMP		R1, #0x09
	BHI		Set_Second_Again
Save_Second
	LDR		R0, =Xten
	LDRB	R1, [R0]
	LSL		R1, #4				
	LDR		R0, =Xunit
	LDRB	R0, [R0]			
	ORR		R1, R0				
	LDR		R0, =Second
	STR		R1, [R0]
	BL		Set_Blink_OFF		; set the blink ON	
	POP		{LR, R1, R0}
	BX		LR
	
; Subroutine Timer_Clock - sets the light and UFlag
;*************************************************************************************************
Timer_Clock
	PUSH	{LR, R1, R0}
	LDR		R0, =TFlag
	LDR		R1, [R0]
	CMP		R1, #0x00		; check the TFlag
	BEQ		Timer_End	;
	
	MOV		R1, #0x00
	STR		R1, [R0] 		; clear the TFlag
	LDR		R0, =TCount		;
	LDR		R1, [R0]
	ADD		R1, #0x01
	STR		R1, [R0]
	CMP		R1, #04			; check for 1 second
	BHS		Set_UFlag		;
	LDR		R0, =Light		; shift left Light
	LDR		R1, [R0]
	LSL		R1, #01
	STR		R1, [R0]
	B		Set_Light	;
Set_UFlag
	LDR		R0, =UFlag		; set the UFlag
	LDR		R1, [R0]
	ADD		R1, #0x01
	STR		R1, [R0]
	LDR		R0, =TCount		; reset the time count
	MOV		R1, #0x00
	STR		R1, [R0]
	LDR		R0, =Light		; set the light to right most bit
	MOV		R1, #0x01
	STR		R1, [R0]
Set_Light
	LDR		R0, =Light
	LDR		R1, [R0]
	LDR		R0, =GPIO_PORTB_DATA_R
	STR		R1, [R0]					; turn on the current LED	;
Timer_End
	POP		{LR, R1, R0}
	BX		LR

; Subroutine Update_Clock - updatess the time
;*************************************************************************************************
Update_Clock
	PUSH	{LR, R1, R0}
	LDR		R0, =UFlag		; check the update flag
	LDR		R1, [R0]
	CMP		R1, #0x00
	BEQ		Update_End	;
	
	MOV		R1, #0x00
	LDR		R0, =UFlag					; clear the update flag
	STR		R1, [R0]
	
	MOV		R1, #UP_SECOND
	LDR		R0, =DFlag;
	STR		R1, [R0]
	
	LDR		R0, =Second
	LDR		R1, [R0]					; R1 <- Second
	BL		Inc_with_Adjustment
	LDR		R0, =Second
	STR		R1, [R0]					; update Second
	CMP		R1,	#0x60		;
	BLO		Update_End	;
			
	; update Minute, 60 second have lasted
	MOV		R1, #UP_MINUTE
	LDR		R0, =DFlag
	STR		R1, [R0]
	
	LDR		R0, =Second					; Reset the Second
	MOV		R1, #0x00
	STR		R1, [R0]
	LDR		R0, =Minute
	LDR		R1, [R0]					; R1 <- Minute
	BL		Inc_with_Adjustment 		; Increment Minute
	LDR		R0, =Minute
	STR		R1, [R0]					; update Minute
	CMP		R1, #0x60		;
	BLO		Update_End	;
	
	; update Hour, 60 minute has lasted
	MOV		R1, #UP_HOUR
	LDR		R0,	=DFlag
	STR		R1, [R0]
	
	LDR		R0, =Minute
	MOV		R1, #0x00
	STR		R1, [R0]			 		; Reset the Minute
	LDR		R0, =Hour
	LDR		R1, [R0]					; R1 <- Hour
	BL		Inc_with_Adjustment			; Increment Hour
	LDR		R0, =Hour
	STR		R1, [R0]					; update Hour
	CMP		R1,	#0x24					
	BLO		Update_End	
	LDR		R0, =Hour					; reset the Hour
	MOV		R1, #0x00
	STR		R1, [R0]
Update_End
	POP		{LR, R1, R0}
	BX		LR

Inc_with_Adjustment
	PUSH	{LR, R0}
	MOV		R0, R1
	AND		R0, R0, #0x0F
	CMP		R0, #0x09
	BNE		No_Adjustment
	ADD		R1, R1, #0x06
No_Adjustment	
	ADD		R1, R1, #0x01
	POP		{LR, R0}
	BX		LR
	
; Subroutine Display_Clock - displays the time
;*************************************************************************************************
Display_Clock
	PUSH	{LR, R1, R0}
	LDR		R0, =DFlag		; check the display flag
	LDR		R1, [R0]
	CMP		R1, #UP_NO		;
	BEQ		Display_End	;			
	CMP		R1,	#UP_HOUR	;
	BEQ		Disp_All	;			
	CMP		R1, #UP_MINUTE	;
	BEQ		Disp_MNSC	;	
	CMP		R1,	#UP_SECOND	;
	BEQ		Disp_Sec	;	
	B		Display_End	;		
Disp_All
	MOV		R1,	#POS_HOUR	; set the display position for Hour
	BL		Set_Position	;
	LDR		R0,	=Hour
	LDR		R1, [R0]
	BL		SplitNum       ; R1 <- MS, R0 <- LS
	ADD		R1, R1,	#0x30		; convert to ASCII
	BL		Display_Char	; display the tenth digit of Hour
	MOV		R1,R0
	ADD		R1,	R1,	#0x30		; convert to ASCII
	BL		Display_Char	; display the unit digit of Hour
	MOV		R1, #COLON
	BL	Display_Char	; display the colon			
Disp_MNSC
	MOV		R1,	#POS_MINUTE	; set the display position for Minute
	BL		Set_Position;
	LDR		R0, =Minute
	LDR	R1, [R0]
	BL		SplitNum       ; R1 <- MS, R0 <- LS
	ADD		R1,	R1,	#0x30		; convert to ASCII
	BL		Display_Char	; display the tenth digit of Minute
	MOV		R1,	R0
	ADD		R1, R1,	#0x30		; convert to ASCII
	BL		Display_Char; display the unit digit of Minute
	MOV		R1, #COLON		;
	BL		Display_Char	; display the colon	
Disp_Sec
	MOV		R1,	#POS_SECOND	; set the display position for Second
	BL		Set_Position
	LDR		R0,	=Second
	LDR		R1, [R0]
	BL		SplitNum       		; R1 <- MS, R0 <- LS
	ADD		R1,	R1, #0x30		; convert to ASCII
	BL		Display_Char		; display the tenth digit of Minute
	MOV		R1, R0
	ADD		R1, R1, #0x30		; convert to ASCII
	BL		Display_Char		; display the unit digit of Minute
	LDR		R0, =DFlag
	MOV		R1, #UP_NO
	STR		R1, [R0]			; reset the display flag
Display_End
	POP		{LR, R1, R0}
	BX		LR


GPIOA_Handler
	EXPORT	GPIOA_Handler [WEAK]
	;*************************************************************
	;*************************************************************
	;*************************************************************
	;*************************************************************
	;*************************************************************
	; Write the GPIOA_Handler here. Follow the flochart
	;Generate 100 inturrupt/second
	;Set TFlag every 25/100
	PUSH 	{R0-R1, LR}
	
	LDR	R0, =GPIO_PORTA_ICR_R
	LDR R1, [R0]
	ORR	R1, #0x80
	STR	R1, [R0]
	
	LDR	R0, =TickCtr
	LDR	R1, [R0]
	ADD	R1, #1
	STR	R1, [R0]
	CMP R1, #25
	BLO skipToEnd2
	MOV	R1, #0
	STR	R1, [R0]
	LDR	R0, =TFlag
	MOV	R1, #1
	STR	R1, [R0]
	
skipToEnd2
	POP 	{R0-R1, LR}
	BX 		LR
	;*************************************************************
	;*************************************************************
	;*************************************************************
	;*************************************************************
	;*************************************************************

;**************************************************************************************************	
;Delay milliseconds
Delay1ms
	PUSH	{LR, R0, R3, R4}
	MOVS	R3, R0
	BNE		L1; if n=0, return
	BX		LR; return

L1	LDR		R4, =1334
			; do inner loop 1334 times (4 MHz CPU clock)
L2	SUBS	R4, R4,#1
	BNE		L2
	SUBS	R3, R3, #1
	BNE		L1
	POP		{LR, R0, R3, R4}
	BX		LR
	END