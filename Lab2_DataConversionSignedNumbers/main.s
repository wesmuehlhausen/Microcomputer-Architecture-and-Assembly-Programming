
;*************************************************************************************
; Author: John Tadrous	
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

N		EQU		100	; maximum size of the arrays

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

; Set_Length - sets the length of the array by getting the binary equivalent
; of the two-digit BCD number in R1 and store it in Length in the memory
; Note Length is a one byte value defined in the RAM.
Set_Length
	PUSH {R2, R3, R5}		;save values, not r1 though
	MOV	R5, R1				;assign 23 to R5
	MOV R2, R5				;put another copy in r2
	AND R5, #0x0000000F		;get unit digit
	LSR	R2, #4				;get tens digit
	MOV	R3, R2			
	LSL	R2, #1
	ADD	R2, R3, LSL
	ADD R2, R5			;add digits together
	MOV	R1, R2			;store in r1
	POP{R2, R3, R5}
	
	BX		LR


; Clear_All_Arrays - initializes the N possible elements of the arrays to zeros 
Clear_Arrays
	PUSH	{LR, R2, R0}
	; clear the array A
	LDR		R0, =ArrayA		; R0 gets the array address 
	MOV		R2, #N			; R2 gets the max array size
	BL		Reset_Array		; Reset_Array is a subroutine that takes the base
							; address of the array to be cleared in R0
							; and the max number of elements N in R2 and clears the array
	
	; clear the array	;
	; TO DO: use the subroutine Reset_Array to clear the other
	; two arrays ArrayB and ArrayC
	POP		{LR, R2, R0}	
	BX		LR

; Reset_Array - initializes all elements of the array to zeros
;	input: R2 <- length of the array
;	R0 <- address of the array
;*************************************************************************************
Reset_Array
	PUSH	{R0-R2, LR}			; save the value of relevant registers
	MOV		R1, #0x00			; zeros to clear the array
Reset_Again
	SUBS	R2, #1
	BEQ		Reset_done
	STRB	R1, [R0]		   ; clear the element
	ADD		R0, #1				; point to the next element
	B	Reset_Again	;

Reset_done
	STRB	R1, [R0]		; clear the last element
	POP 	{R0-R2, LR}			; restore the value of pushed registers
	BX		LR

; Set_ArrayA - sets the array A
Set_ArrayA
	PUSH	{R0-R4, LR}		; push relevant registers
	; TO DO: R0 points to ArrayA's first element (base address)
	; TO DO: R1 has the index - initialize it to 0
	; TO DO: Load the length of the array in R4 (two instructions)

Set_ArrayA_Again
	; TO DO: Add 5 to the current index and store the result in R2
	STRB	R2, [R0,R1]		; ArrayA[i] <- i + 5
	; TO DO: Increment the current index by 1
	; TO DO: Compare the new index with the value of Length in R4
	; TO DO: Branch to Set_ArrayA_Again if the loop condition is true	
	
	POP		{R0-R4, LR}	; restore the registers	
	BX		LR

; Set_ArrayB - sets the array B
Set_ArrayB
	PUSH	{R0-R4, LR}		; push relevant registers
	; TO DO: Set R0 to point to the base address of ArrayB
	; TO DO: R1 is the current index - initialize it to 0
	; TO DO: Load the length of the array in R4 (two instructions)
	
Set_ArrayB_Again
	MOV		R2, R1			; R2 <- R1 (index)
	LSRS	R2, #1			; pushing the rightmost bit in the carry flag
	BCC		Even_index		; carry clear implies an even index
	; TO DO: Compute R2=2*current index
	STRB	R2, [R0, R1]	; ArrayB[i] <- 2 * i, i is odd

Even_index
	; TO DO: Increment the current index by 1
	; TO DO: Compare the new index with the value of Length in R4
	; TO DO: Branch to Set_ArrayB_Again if the loop condition is true
	
	POP		{R0-R4, LR}
	BX		LR

; Set_ArrayC - sets the array C
;*************************************************************************************
Set_ArrayC
	PUSH	{R0-R5, LR}
							
	; TO DO: Store the base address of arrays ArrayA, ArrayB and ArrayC
	; in memory locations PtrA, PtrB and PtrC respectively. This step requires 
	; a number of instructions.
							
	; TO DO: Use R1 as the current iteration index- initialize it to 0
	
Set_ArrayC_Again
	LDR		R0, =PtrA		; Load the current element from ArrayA
	LDR		R4, [R0]		; in R2. First fetch the pointer from PtrA in R4
	LDRB	R2, [R4]		; then get the element in R2
	
	ADD		R4, #1			; Update pointer for ArrayA
	STR		R4, [R0]
	
	; TO DO: Use the same approach as above to load the current element
	; from ArrayB into R5 and update pointer PtrB for the next element (5 instructions)
	
	; TO DO: Add the current element of ArrayB to the current element 
	; of ArrayA and keep the result in R2
		
	; TO DO: Use pointer PtrC to write the value in R2 into the current element of
	; ArrayC and update PtrC for the next element (5 instructions)
		
	LDR		R0, =Length
	LDRB	R4, [R0]
	; TO DO: Increment the current index by 1
	; TO DO: Compare the new index with the value of Length in R4
	; TO DO: Branch to Set_ArrayC_Again if the loop condition is true
	
	
	POP		{R0-R5, LR}
	BX		LR
	
	END