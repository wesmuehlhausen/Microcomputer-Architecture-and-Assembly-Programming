
;*************************************************************************************
; Project: Lab 4
; Program: Indexed Addressing and Pointers
; Date Created: March 16, 2017
; Date Modified: October 7, 2017, By Wesley Muehlhausen
;				 Modified Set_ArrayC to use pointers in RAM to access ArrayA, ArrayB & ArrayC
;				 Modified on February 16, 2019, by J. Tadrous 
; Description: this program will manipulate arrays using pointers
; Inputs: none
; Outputs: none
;*************************************************************************************

N		EQU		100	; maximum size of the arrays 0x64

; Defining length, pointers, and arrays
	AREA	MyData, DATA, READWRITE, ALIGN=2
		
Length	DCB		0	; Length of arrays
PtrA	SPACE	4	; Pointer for ArrayA
PtrB	SPACE	4	; Pointer for ArrayB
PtrC	SPACE	4	; Pointer for ArrayC
ArrayA	SPACE	N	; the arrayA
ArrayB	SPACE	N	; the arrayB
ArrayC	SPACE	N	; the arrayC


	AREA	MyCode, CODE, READONLY, ALIGN=2
	EXPORT	__main
		  

__main
	MOV		R1, #0x23	; A two-digit BCD number representing Length
	BL		Set_Length	; set the length of the arrays
	BL		Clear_Arrays; clear all arrays
	BL		Set_ArrayA	; set the array A
	BL		Set_ArrayB	; set the array B
	BL		Set_ArrayC	; set the array C
Stop
	B		Stop

;set the length of the arrays. input: 23-BCD output 17-BINARY
Set_Length
	PUSH {R2, R3, R5}		;save values, not r1 though
	MOV	R5, R1				;assign 23 to R5
	MOV R2, R5				;put another copy in r2
	AND R5, #0x0000000F		;get unit digit
	LSR	R2, #4				;get tens digit
	MOV	R3, R2			
	LSL	R2, #1
	ADD	R2, R3, LSL #3
	ADD R2, R5			;add digits together
	MOV	R1, R2			;store in r1
	POP{R2, R3, R5}
	BX		LR


; Clear_All_Arrays - initializes all items to zero
Clear_Arrays
		PUSH	{R0-R4}
		MOV		R3, #0	;index
		MOV		R4, #0  ;clear value
loop	LDR		R2, =ArrayA		;for ArrayA, clear by setting value to zero at i (R3)
		STRB	R4, [R2, R3]	
		LDR		R2, =ArrayB		;for ArrayB, clear by setting value to zero at i (R3)
		STRB	R4, [R2, R3]
		LDR		R2, =ArrayC		;for ArrayC, clear by setting value to zero at i (R3)
		STRB	R4, [R2, R3]
		ADD		R3, #1 			;incriment
		CMP		R3, #100		;while index is less than 100, loop again
		BLO		loop
		
		POP	{R0-R4}	
		BX		LR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Set_ArrayA - sets the array A
Set_ArrayA
		PUSH	{R0-R4}
		
		LDR		R2, =ArrayA
		MOV		R3, #0			;INDEX set to 0
		MOV		R4, #0			;R4 is set to 0
loop2	ADD		R4, R3, #5		;Set R4 = index + 5
		STRB	R4, [R2, R3]	;Set Array[i] = R4
		ADD		R3, #1			;incriment
		CMP		R3, R1			;if index < 100 (R1), loop through
		BLO		loop2
		
		POP		{R0-R4}	; restore the registers	
		BX		LR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Set_ArrayB - sets the array B
Set_ArrayB
		PUSH	{R0-R5}
	
		LDR		R2, =ArrayB		;Set Array B
		MOV		R3, #0			;INDEX set to 0
loopx	
		MOV		R5, R3			;copy of index
		LSRS	R5, R5, #1		;logic shift right to get carry bit
		BCC		evenCarry	
		MOV		R5, R3
		LSL		R4, R5, #1			;IF ODD
		STRB	R4, [R2, R3]		
		B		skip		
evenCarry						;IF EVEN
		MOV		R4, #0
		STRB	R4, [R2, R3]	;else: if odd, set to zero
skip

		ADD		R3, #1			;incriment and loop if under 100
		CMP		R3, R1
		BLO		loopx
		
		POP		{R0-R5}
		BX		LR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Set_ArrayC - sets the array C
;*************************************************************************************
Set_ArrayC
	PUSH	{R0-R5}
	MOV		R3, #0
	
	;Store arrayA base address in mem loc PtrA and init PtrA
	LDR 	R2, =ArrayA
	LDR		R0, =PtrA	
	STR		R2, [R0]
	
	;Store arrayB base address in mem loc PtrB and init PtrB
	LDR 	R2, =ArrayB
	LDR		R0, =PtrB
	STR		R2, [R0]
	
	;Store arrayC base address in mem loc PtrC and init PtrC
	LDR		R2, =ArrayC
	LDR		R0, =PtrC
	STR		R2, [R0]
	
loop10

	MOV		R4, #0		
	
	;Add the current element of ArrayA to the current element 
	; of ArrayA and keep the result in R2
	LDR		R2, =PtrA
	LDR		R0, [R2]   ; R0 is the index of the array
	LDRB	R5, [R0]   ; put value of ArrayA[i] in R5
	ADD		R4, R4, R5 ; add value of ArrayA[i] to R4
	ADD		R0, #1     ;set index of ArrayA for next loop
	STR		R0, [R2]   ;incriment index
	
	;Add the current element of ArrayB to the current element 
	; of ArrayA and keep the result in R2
	LDR		R2, =PtrB
	LDR		R0, [R2]
	LDRB	R5, [R0]
	ADD		R4, R4, R5	;add arrayB[i] to R4
	ADD		R0, #1
	STR		R0, [R2]
	
	;Use pointer PtrC to write the value in R2 into the current element of
	; ArrayC and update PtrC for the next element
	LDR		R2, =PtrC
	LDR		R0, [R2]
	STRB	R4, [R0]	;arrayC[i] = A + B
	ADD		R0, #1
	STR		R0, [R2]
	ADD		R3, #1       ;index for entire loop
	
	;if index is less than length is
	CMP		R3, R1
	BLO		loop10
	
	POP		{R0-R5}
	BX		LR
	
	END