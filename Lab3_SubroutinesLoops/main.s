;**********************************************************************************************
; Author: Wesley Muehlhausen
; Lab 3: Subroutines and 
; Date Created: September 30 2020
; Last Modified: September 30 2020
; Description: Using subroutines, push/pop, loops, and if else statements 
;			   in order to do bcd->binary, abs value, and parity-adder
; Inputs: X, N 
; Outputs: R6, R8, R9, R10
;**********************************************************************************************
	AREA	MyData, DATA, READWRITE, ALIGN=2
X		RN		R5
N		RN		R7

	AREA	MyCode, CODE, READONLY, ALIGN=2
			EXPORT __main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
bcd_to_binary  ;turns bcd number into binary
		PUSH 	{R1,R2,R3}	;save origional values
		
		MOV	R5, #0x26		;assign BCD value 26 to X
		MOV	R1, R5			;R1 <- X value
		MOV	R2, R1			;R2 <- X value
		AND	R1, #0x0000000F	;[R1: UNIT] 
		LSR	R2, #4			;[R2: TENS] 
		MOV	R3, R2			;copy tens digit (R2)
		LSL	R2, #1			;R2 * 2
		ADD	R2, R3, LSL #3	;R2 = [2(R2) + 8(R2) = 10(R2)]
		ADD	R2, R1			;R2 = Tens + Unit
		MOV	R6, R2			;put value of R2 into R6	
		
		POP 	{R1,R2,R3}	;restore
		BX		LR
		
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
absolute_value	;finds the absolute value of a decimal number
		PUSH 	{R0,R1,R2}	;save origional values

		MOV	R1, R7			;copy value of N into R1		
		CMP	R1, #0			;if number >= 0, keep value and put in R8
		BLT	next1			
		MOV R8, R1			
		B next2				;skip to end if here
next1
							;if number < 0, do 2’s complement
		NEG	R2, R1			;2’s complement of R1 and stores in R2
		MOV R8, R2
next2	
		POP 	{R0,R1,R2}	;return origional values
		BX		LR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

parity_adder	;goes through numbers 1-100, if odd: add to R9, if even: add to R10
		
		PUSH 	{R4, R6}	;store values

		MOV		R4, #0
loop	CMP		R4, #100 	;for loop 0 to 99
		BHI		exit	 	;exit
		MOV 	R6, R4		;tmp variable for R4
		
		LSRS 	R6, #1		;Get carry bit
		BCC		next3 		;IF the digit is 0 (EVEN)
		ADD 	R10, R10, R4 ;add value to even total
		B		next4		;ELSE the digit 
next3
		ADD 	R9, R9, R4	;if it was odd, end up here
next4

		ADD		R4, R4, #1		;incriment
		B 		loop
exit
		POP 	{R4, R6}	;restore values
		BX		LR
		
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
__main
		MOV	R7, #0xFFFFFFF1			;set value to N
		BL		bcd_to_binary		;call functions
		BL		absolute_value
		BL		parity_adder
		
		
		END
	