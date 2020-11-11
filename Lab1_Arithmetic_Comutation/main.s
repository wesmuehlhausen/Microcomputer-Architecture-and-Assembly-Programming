;**********************************************************************************************
; Author: Wesley Muehlhausen
; Lab 1: Arithmetic Computation
; Date Created: September 21 2020
; Last Modified: September 21 2020
; Description: Simple arithemitc operations, using x, y, and z variables, equations shown above code...
; Inputs: Vx
; Outputs: Vy, Vz
;**********************************************************************************************
	AREA	MyData, DATA, READWRITE, ALIGN=2
Vx		RN		R7
Vy		DCB		0;
Vz		DCB		0;

	AREA	MyCode, CODE, READONLY, ALIGN=2
			EXPORT __main
__main

		;Vy = 7*Vx + 120
		MOV Vx, #8 ;init Vx
		MOV R1, Vx ;Make copy of Vx in R1
		LSL R1, R1, #3 ;Multiply by 8
		SUB R1, R1, Vx;; Changes from 8x to 7x
		ADD R1, R1, #120; add 120 to 
		LDR R3, =Vy  ;R0 is address of Vy
		STR R1, [R3]; Vy = R2
		
		;Vz = Vy/8 + 25
		MOV R4, R1 ;; put Vy in R4
		LSR R4, R4, #3 ;divide by 8
		ADD R4, R4, #25 ;add 25
		LDR R5, =Vz ;R5 is address of Vy
		STR R4, [R5] ;Vy = R4
		
		
		END
	