;
;==================================================================================================
; SCC DRIVER (SERIAL PORT)
;==================================================================================================
;
;  SETUP PARAMETER WORD:
;  +-------+---+-------------------+ +---+---+-----------+---+-------+
;  |       |RTS| ENCODED BAUD RATE | |DTR|XON|  PARITY   |STP| 8/7/6 |
;  +-------+---+---+---------------+ ----+---+-----------+---+-------+
;    F   E   D   C   B   A   9   8     7   6   5   4   3   2   1   0
;       -- MSB (D REGISTER) --           -- LSB (E REGISTER) --

SCC_DEBUG		.EQU	FALSE
;
SCC_NONE		.EQU	0		; UNKNOWN OR NOT PRESENT
SCC_SCC			.EQU	1		; Z85C30 SCC
SCC_ESCC		.EQU	2		; Z85230 ESCC

SCC0B_CMD		.EQU	SCC0BASE + $00	;I/O ADDRESS OF CONTROL REGISTER B
SCC0A_CMD		.EQU	SCC0BASE + $01	;I/O ADDRESS OF CONTROL REGISTER A
SCC0B_DAT		.EQU	SCC0BASE + $02	;I/O ADDRESS OF DATA REGISTER B
SCC0A_DAT		.EQU	SCC0BASE + $03	;I/O ADDRESS OF DATA REGISTER A
