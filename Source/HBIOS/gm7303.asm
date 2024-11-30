;
;==================================================================================================
; HARDWARE SUPPORT FOR GENESS MODULES 7303 STD BUS KEYBOARD/GM7303
;  - INCORPORATES HITACHI HD44780 AS 2 X 16 DISPLAY AND 24 KEY HEX KEYPAD
;==================================================================================================
; 
; Heavily derived from the lcd.asm driver, but forked because the 7303 card has keyboard 
; functionality as well.  Eventually will be used as a Z80/180 monitor tool
;
; The GM7303 supports an LCD display while the original has 2 DL1416 starburst displays. 
;==================================================================================================
;
; CARD FUNCTIONS:	(BASE_IO = 0x30)
;
; 20X2 LCD 		0X30 OUTPUT (D0-D7)
;			0X31 OUTPUT (D0 - LCD E)
;					(D1 - LCD R/W*)
;					(D2 - LCD RS)
; S1 & S2 INPUT	0x30 INPUT  (BIT 6,7)
; 8 OUTPUT LEDS	0x30 OUTPUT 
; KEYBOARD		0X30 OUTPUT (COLUMN BIT 0-3)
;			0X30 INPUT  (ROW BIT 0-5)
;
; GM7303 SCAN CODES ARE ONE BYTE: CCRRRRRR
; BITS 7-6 IDENTFY THE COLUMN OF THE KEY PRESSED
; BITS 5-0 ARE A BITMAP, WITH A BIT OFF TO INDICATE ROW KEY PRESSED
;    ROW INPUTS ARE HELD lOW (NOTING I/P OF ROW BUFFER IS INVERTING) 
;
;      ___Col0_______Col1______Col2_______Col3____
; Row5|	 $20 [14]   $60 [15]   $A0 [16]	  $E0 [17]
; Row4|	 $10 [10]   $50 [11]   $90 [12]	  $D0 [13]
; Row3|	 $08 [C]    $48 [D]    $88 [E]	  $C8 [F]
; Row2|	 $04 [8]    $44 [9]    $84 [A]	  $C4 [B]
; Row1|	 $02 [4]    $42 [5]    $82 [6]	  $C2 [7]
; Row0|	 $01 [0]    $41 [1]    $81 [2]	  $C1 [3]
;
;===================================================================================================
;
;  Date		Change
;  05Sep2024	Initial development - basic init functions
;  06Sep2024 	Working - Cleaned out functions that wont be used - TODO - Implement keyboard
;
;
GM7303_DATA	.EQU	GM7303BASE + 0	; WRITE
GM7303_CTRL	.EQU	GM7303BASE + 1	; WRITE
GM7303_KYBD	.EQU	GM7303BASE + 0	; READ/WRITE
;
GM7303_FUNC_CLEAR	.EQU	$01		; CLEAR DISPLAY
GM7303_FUNC_HOME	.EQU	$02		; HOME CURSOR & REMOVE ALL SHIFTING
GM7303_FUNC_ENTRY	.EQU	$04		; SET CUR DIR AND DISPLAY SHIFT
GM7303_FUNC_DISP	.EQU	$08		; DISP, CUR, BLINK ON/OFF
GM7303_FUNC_SHIFT	.EQU	$10		; MOVE CUR / SHIFT DISP
GM7303_FUNC_SET		.EQU	$20		; SET INTERFACE PARAMS
GM7303_FUNC_CGADR	.EQU	$40		; SET CGRAM ADRESS
GM7303_FUNC_DDADR	.EQU	$80		; SET DDRAM ADDRESS
;
	DEVECHO	"GM7303: IO="
	DEVECHO	GM7303BASE
	DEVECHO	"\n"
;
; HARDWARE RESET PRIOR TO ROMWBW CONSOLE INITIALIZATION
;
GM7303_PREINIT:
	
; TEST FOR PRESENCE...
	CALL	GM7303_DETECT		; PROBE FOR HARDWARE
	LD	A,(GM7303_PRESENT)	; GET PRESENCE FLAG
	OR	A			; SET FLAGS
	RET	Z			; BAIL OUT IF NOT PRESENT	

	; REGISTER DRIVER WITH HBIOS
	LD	BC,GM7303_DISPATCH
	CALL	DSKY_SETDISP
;
; INITIALISE LCD
	CALL	GM7303_RESETLCD		; RESET THE LCD
	PUSH 	HL
	LD	HL,GM7303_INIT_TBL
	LD	D,04H			; 4 BYTES TO SEND
NEXT_INIT:
	LD	A,(HL)			; GET COMMAND
	OUT	(GM7303_DATA),A		; WRITE TO TO DISPLAY
	CALL	CMD_STROBE		; COMMAND STROBE
	PUSH	DE
	LD	DE,5000/16		; WAIT >4MS, WE USE 5MS
	CALL	VDELAY			; DO IT
	POP	DE
	INC	HL
	DEC	D			; (D)=00 -> COMMAND
	JR	NZ,NEXT_INIT		;   NO - DO NEXT INIT COMMAND
	POP  HL
;
; PUT SOMETHING ON THE DISPLAY
	LD	DE,GM7303_STR_BAN	; DISPLAY BANNER
	CALL	GM7303_OUTDS

; SECOND LINE
	LD	HL,$0100		; ROW 2, COL 0
	CALL	GM7303_GOTORC
	LD	DE,GM7303_STR_CFG	; DISPLAY CONFIG
	CALL	GM7303_OUTDS

	XOR	A			; SIGNAL SUCCESS
	RET				; DONE
;
; POST CONSOLE INITIALIZATION
;
GM7303_INIT:
	CALL	NEWLINE			; FORMATTING
	PRTS("GM7303: IO=$")
	LD	A,GM7303BASE
	CALL	PRTHEXBYTE
;
	LD	A,(GM7303_PRESENT)	; GET PRESENCE FLAG
	OR	A			; SET FLAGS
	JR	Z,GM7303_INIT1		; HANDLE NOT PRESENT
	XOR	A			; SIGNAL SUCCESS
	RET				; DONE
;
GM7303_INIT1:
	PRTS(" NOT PRESENT$")
	OR	$FF
	RET


GM7303_DISPATCH:
	LD	A,B			; GET REQUESTED FUNCTION
	AND	$0F			; ISOLATE SUB-FUNCTION
	JP	Z,GM7303_RESET		; RESET DSKY HARDWARE
	DEC	A	
	JP	Z,GM7303_STAT		; GET KEYPAD STATUS
	DEC	A	
	JP	Z,GM7303_GETKEY		; READ A KEY FROM THE KEYPAD
	DEC	A	
	JP	Z,GM7303_SHOWHEX	; DISPLAY A 32-BIT BINARY VALUE IN HEX
	DEC	A	                
	;;;JP	Z,GM7303_SHOWASCII	; DISPLAY ASCII TEXT
	JP	Z,GM7303_SHOWSEG	; DISPLAY SEGMENT MAPPED TEXT
	DEC	A	
	JP	Z,GM7303_KEYLEDS	; SET KEYPAD LEDS
	DEC	A	
	JP	Z,GM7303_STATLED	; SET STATUS LED
	DEC	A	
	JP	Z,GM7303_BEEP		; BEEP DSKY SPEAKER
	DEC	A
	JP	Z,GM7303_DEVICE		; DEVICE INFO
	DEC	A
	JP	Z,GM7303_MESSAGE	; HANDLE MESSAGE
	DEC	A
	JP	Z,GM7303_EVENT		; HANDLE EVENT
	SYSCHKERR(ERR_NOFUNC)
	RET

;
; RESET 7303 -- CLEAR AND HOME LCD
;
GM7303_RESET:
GM7303_CLEAR:
	LD	A,GM7303_FUNC_CLEAR	; CLEAR SCREEN COMMAND
	CALL	GM7303_COMMAND		; SEND IT 
	JP	GM7303_CLEARDELAY	; LONG DELAY FOR CLEAR - RETURN HAPPENS IN STROBE ROUTINE
;
;  CHECK FOR KEY PRESS, SAVE RAW VALUE, RETURN STATUS
;
GM7303_STAT:
	LD	A,(GM7303_KEYBUF)	; GET CURRENT BUF VAL
	CP	$FF			; $FF MEANS WE ARE WAITING FOR PREV KEY TO BE RELEASED
	JR	Z,GM7303_STAT1		; CHECK FOR PREV KEY RELEASE
	OR	A			; DO WE HAVE A SCAN CODE BUFFERED ALREADY?
	RET	NZ			; IF SO, WE ARE DONE
	JR	GM7303_STAT2		; OTHERWISE, DO KEY CHECK
	
GM7303_STAT1:
	; WAITING FOR PREVIOUS KEY RELEASE
	CALL	GM7303_KEY		; SCAN
	JR	Z,GM7303_STAT2		; IF ZERO, PREV KEY RELEASED, CONTINUE
	XOR	A			; SIGNAL NO KEY PRESSED
	RET				; AND DONE

GM7303_STAT2:
	CALL	GM7303_KEY		; SCAN
	LD	(GM7303_KEYBUF),A	; SAVE RESULT
	RET				; RETURN WITH ZF SET APPROPRIATELY
;
;
; WAIT FOR A GM7303 KEYPRESS AND RETURN     
;
GM7303_GETKEY:
	CALL	GM7303_STAT		; CHECK STATUS
	JR	Z,GM7303_GETKEY		; LOOP IF NOTHING READY
	LD	A,(GM7303_KEYBUF)
	LD	B,24			; SIZE OF DECODE TABLE
	LD	C,0			; INDEX
	LD	HL,GM7303_KEYMAP	; POINT TO BEGINNING OF TABLE
GM7303_GETKEY1:
	CP	(HL)			; MATCH?
	JR	Z,GM7303_GETKEY2	; FOUND, DONE
	INC	HL
	INC	C			; BUMP INDEX
	DJNZ	GM7303_GETKEY1		; LOOP UNTIL EOT
GM7303_GETKEY1A:
	LD	A,$FF			; NOT FOUND ERR, RETURN $FF
	RET
GM7303_GETKEY2:
	LD	A,$FF			; SET KEY BUF TO $FF
	LD	(GM7303_KEYBUF),A	; DO IT
	; RETURN THE INDEX POSITION WHERE THE SCAN CODE WAS FOUND
	LD	E,C			; RETURN INDEX VALUE
	XOR	A			; SIGNAL SUCCESS
	RET
;
; DISPLAY HEX VALUE FROM DE:HL
; To be written <--- DRJ

GM7303_SHOWHEX:
	RET
	

GM7303_DISP_2N_HEX:			;  DISPLAY N 2HEX VALUES FROM
	CALL	GM7303_DISP_2HEX        ;  MEMORY ON 2N DISPLAYS 
	DEC	C
	JP	NZ,GM7303_DISP_2N_HEX
	RET

GM7303_DISP_2HEX:		;  DISPLAY 2 HEX CHARACTERS IN MEMORY LOCATIONS
	LD	D,(HL)		;  (HL), IN DISPLAY POSITIONS (E),(E)+1
	CALL	GM7303_DISP_HEX
	INC	E
	LD	A,(HL)
	RRC	A
	RRC	A
	RRC	A
	RRC	A
	LD	D,A
	CALL	GM7303_DISP_HEX
	INC	E
	INC	HL		;  (E)EXIT=(E)+2   (WAS INX H)
	RET			;  (HL)EXIT=(HL)+1
	
GM7303_DISP_HEX:
	LD	A,D		;  DISPLAY LEAST SIGNIFICANT HEX DIGIT IN REGISTER D
	CALL	GM7303_HEX_ASC
	LD	D,A
	JP	GM7303_OUTD
	
GM7303_HEX_ASC:
	AND	$0F		;  CONVERT LSD IN REG A TO ASCII
	CP	$0A		;  IS A>9
	JP	C,GM7303_NUM_TEST
	ADD	A,$B7		;  YES - CONVERT TO C1-C6
	RET			;  EXIT
GM7303_NUM_TEST:	             
	ADD	A,$B0		;  NO, CONVERT TO B0-B9
	RET			;  EXIT	

GM7303_SHOWSEG:
	; CONVERT FROM SEG ALPHABET TO DISPLAY CODES
	LD	B,8			; DO FOR ALL CHARS
	LD	DE,GM7303_BUF		; DESTINATION BUFFER
GM7303_SHOWSEG1:
	LD	A,(HL)			; GET SOURCE VALUE
	INC	HL			; BUMP FOR NEXT TIME
	AND	$7F			; REMOVE HI BIT (DP)
	PUSH	HL			; SAVE IT
	LD	HL,GM7303_SEGMAP	; POINT TO XLAT MAP
	CALL	ADDHLA			; OFFSET BY VALUE
	LD	A,(HL)			; GET NEW VALUE
	LD	(DE),A			; SAVE IT
	INC	DE			; BUMP PTR
	POP	HL			; RESTORE SOURCE PTR
	DJNZ	GM7303_SHOWSEG1		; LOOP TILL DONE
;	
	; DISPLAY CONVERTED BUFFER
	LD	HL,GM7303_BUF		; BUFFER
	; FALL THRU


GM7303_SHOWASCII:		; DISPLAY AN ASCII STRING ON THE GM7303 DISPLAY
				; ENTER WITH HL- DATA TO PRINT (NULL TERMINATED)
	PUSH	HL		; SAVE THE POINTER TO THE STRING
	CALL	GM7303_CLEAR	; CLEAR THE DISPLAY
	POP 	DE		; OUTDS EXPECTS STRING POINTER IN DE
	CALL	GM7303_OUTDS
	XOR	A		; RETURN SUCCESS	
	RET
;
;
;
GM7303_KEYLEDS:
GM7303_STATLED:
GM7303_BEEP:
	XOR	A			; UNSUPPORTED ROUTINES - PRETEND SUCCESS
	RET
;
; DEVICE INFORMATION
;
GM7303_DEVICE:
	LD	D,DSKYDEV_GM7303	; D := DEVICE TYPE
	LD	E,0			; E := PHYSICAL DEVICE NUMBER
	LD	H,0			; H := MODE
	LD	L,GM7303BASE		; L := BASE I/O ADDRESS
	XOR	A			; SIGNAL SUCCESS
	RET
;
; MESSAGE HANDLER
;
GM7303_MESSAGE:
	LD	A,C			; GET MESSAGE ID
	ADD	A,A			; WORD OFFSET
	LD	HL,GM7303_MSGTBL		; START OF MESSAGE TABLE
	CALL	ADDHLA			; ADD OFFSET
	LD	A,(HL)			; SAVE LSB
	INC	HL			; BUMP TO MSB
	LD	H,(HL)			; GET MSB
	LD	L,A			; GET LSB
	JR	GM7303_SHOWASCII	; SHOW MESSAGE AND RETURN
;
; EVENT HANDLER
;
GM7303_EVENT:
	LD	A,C			; EVENT ID
	OR	A			; 0=CPUSPD
	JR	Z,GM7303_EVT_CPUSPD	; HANDLE CPU SPD CHANGE
	DEC	A			; 1=DSKACT
	JR	Z,GM7303_EVT_DSKACT	; HANDLE DISK ACTIVITY
	XOR	A
	RET
;
; CPU SPEED CHANGE
;
GM7303_EVT_CPUSPD:
	XOR	A
	RET
;
; DISK ACTIVITY
;
; CALLED FROM HBIOS RIGHT BEFORE A DISK ACCESS
;
; FORMAT: "Dsk99 R:12345678"
;          0123456789012345
;
GM7303_EVT_DSKACT:
;
	PUSH	HL
	LD	HL,$0100		; ROW 1, COL 0
	CALL	GM7303_GOTORC		; SET DISPLAY ADDRESS
	POP	HL
;
	LD	DE,GM7303_STR_IO	; PREFIX
	CALL	GM7303_OUTDS		; SEND TO DISPLAY (COLS 0-5)

	LD	A,(HB_DSKUNIT)		; GET DISK UNIT NUM
	CALL	GM7303_DSKACT_BYTE	; SEND TO DISPLAY (COLS 6-7) HEX???
;
	LD	A,' '			; SEPARATOR
	CALL	GM7303_OUTD		; SEND TO DISPLAY (COL 8)
;
	LD	A,(HB_DSKFUNC)		; ACTIVE DISK FUNCTION
	CP	BF_DIOWRITE		; WRITE?
	LD	A,'W'			; ASSUME WRITE
	JR	Z,GM7303_DSKACT0	; GO AHEAD
	LD	A,'R'			; OTHERWISE READ
GM7303_DSKACT0:
	CALL	GM7303_OUTD		; SEND CHAR (COL 10)

	LD	A,':'			; SEPARATOR
	CALL	GM7303_OUTD		; SEND TO DISPLAY (COL 11)
;
	LD	HL,HB_DSKADR+3		; INPUT POINTER
	LD	B,4			; DO 4 BYTES
;
GM7303_DSKACT1:
	LD	A,(HL)			; GET BYTE
	CALL	GM7303_DSKACT_BYTE	; SEND TO DISPLAY (COLS 12-19)
	DEC	HL			; DEC PTR
	DJNZ	GM7303_DSKACT1		; DO ALL 4 BYTES
;
GM7303_DSKACT_Z:
	RET
;;
GM7303_DSKACT_BYTE:
	PUSH	AF			; SAVE BYTE
	RRCA				; DO TOP NIBBLE FIRST
	RRCA
	RRCA
	RRCA
	CALL	HEXCONV		; CONVERT NIBBLE TO ASCII
	CALL	GM7303_OUTD		; SEND TO DISPLAY
	POP	AF			; RECOVER CURRENT BYTE
	CALL	HEXCONV		; CONVERT NIBBLE TO ASCII
	CALL	GM7303_OUTD		; SEND TO DISPLAY
	RET				; DONE

;
;__GM7303_KEY___________________________________________________________________________________________
;
;  CHECK FOR KEY PRESS W/ DEBOUNCE
;____________________________________________________________________________________________________
;
GM7303_KEY:
	CALL	GM7303_SCAN		; INITIAL KEY PRESS SCAN
	LD	E,A			; SAVE INITIAL SCAN VALUE
GM7303_KEY1:
	; MAX BOUNCE TIME FOR OMRON B3F IS 3MS
	PUSH	DE			; SAVE DE
	LD	DE,300			; ~3MS DELAY
	CALL	VDELAY			; DO IT
	CALL	GM7303_SCAN		; REPEAT SCAN
	POP	DE			; RESTORE DE
	RET	Z			; IF NOTHING PRESSED, DONE
	CP	E			; SAME?
	JR	GM7303_KEY2		; YES, READY TO RETURN
	LD	E,A			; OTHERWISE, SAVE NEW SCAN VAL
	JR	GM7303_KEY1		; AND LOOP UNTIL STABLE VALUE
GM7303_KEY2:
	OR	A			; SET FLAGS BASED ON VALUE
	RET				; AND DONE
;
;__GM7303_SCAN__________________________________________________________________________________________
;
;  SCAN KEYPAD AND RETURN RAW SCAN CODE (RETURNS ZERO IF NO KEY PRESSED)
;____________________________________________________________________________________________________
;
GM7303_SCAN:   
	LD	B,4			; 4 COLUMNS
	LD	C,$01			; FIRST COLUMN
	LD	E,0			; INITIAL COL ID
GM7303_SCAN1:
	LD	A,C			; COL TO A
	AND	$0F			; DON'T CHANGE THE LCD CONTROL BITS
	OUT	(GM7303_KYBD),A		; ACTIVATE COL
	IN	A,(GM7303_KYBD)		; READ ROW BITS
	AND	$3F			; MASK, WE ONLY HAVE 6 ROWS, 
					;   OTHERS USED FOR STATUS SWITCHES
	JR	NZ,GM7303_SCAN2		; IF NOT ZERO, GOT SOMETHING
	RLC	C			; NEXT COL
	INC	E			; BUMP COL ID
	DJNZ	GM7303_SCAN1		; LOOP THROUGH ALL COLS
	XOR	A			; NOTHING FOUND, RETURN ZERO
	RET
GM7303_SCAN2:
	RRC	E			; MOVE COL ID
	RRC	E			; ... TO HIGH BITS 6 & 7
	OR	E			; COMBINE WITH ROW
	RET
	
;
;_ _TABLE_____________________________________________________________________________________________________________
;
GM7303_KEYMAP:
	; POS	$00  $01  $02  $03  $04  $05  $06  $07
	; KEY   [0]  [1]  [2]  [3]  [4]  [5]  [6]  [7]
	.DB	$01, $41, $81, $C1, $02, $42, $82, $C2
;                                                  
	; POS	$08  $09  $0A  $0B  $0C  $0D  $0E  $0F
	; KEY   [8]  [9]  [A]  [B]  [C]  [D]  [E]  [F]
	.DB	$04, $44, $84, $C4, $08, $48, $88, $C8
;                                                  
	; POS	$10  $11  $12  $13  $14  $15  $16  $17
	; KEY   [FW] [BK] [CL] [EN] [DE] [EX] [GO] [BO]
	.DB	$10, $50, $90, $D0, $20, $60, $A0, $E0
	


; DETECT PRESENCE OF GM7303 CONTROLLER 
; WE CAN'T USE CONTROLLER RAM AS THE GM7303 DOES NOT SUPPORT LCD READS
; SIMPLY TEST FOR THE EXISTANCE OF BUS PULLDOWN AT THE SWITCH PORT
;
GM7303_DETECT:
	IN	A,(GM7303_DATA)	; GET VALUE OF DATA INPUTS 
	CP	00			; GM7303 PULLS DATA TO GROUND
	JR	Z,GM7303_AVAILABLE
GM7303_MISSING:
	LD	A,00
	LD	(GM7303_PRESENT),A
	RET
GM7303_AVAILABLE:
	LD	A,$FF
	LD	(GM7303_PRESENT),A
	RET
;
; DELAY ROUTINE - SHORT
;
GM7303_DELAY:
	PUSH	AF
	PUSH	DE
	LD	DE,3	; WAIT PERIOD
	CALL	VDELAY	; DO IT
	POP	DE
	POP	AF
	RET	
;
; CLEAR DELAY ROUTINE - LONG
;
GM7303_CLEARDELAY:
	PUSH	AF
	PUSH	DE
	LD	DE,140	; WAIT PERIOD
	CALL	VDELAY	; DO IT
	POP	DE
	POP	AF
	RET	

	
CMD_STROBE:		;  Send a command to the LCD
	LD	A,01H	;  (A) = (X,X,X,X,X,RS,R/W*, E)
			;  SET R/W* LINE low (BIT 1=0)
			;  SET RS line LOW FOR COMMAND (BIT 2=0)
			;  SET ENABLE LINE HIGH (BIT 0=1)
	; CARRY ON THROUGH THE STROBE ROUTINE
STROBE:
	OR	01H             ;  SET ENABLE LINE HIGH (BIT 0=1)
	OUT 	(GM7303_CTRL),A
	CALL	GM7303_DELAY
	
	XOR	01H             ;  SET ENABLE LINE LOW (BIT 0=0)
	OUT 	(GM7303_CTRL),A
	CALL	GM7303_DELAY
	RET                   ;  EXIT
								   
GM7303_OUTD:			; OUTPUT ASCII CHARACTER TO LCD DISPLAY
				; CHAR IN A
	AND	07FH
	OUT 	(GM7303_DATA),A	; OUTPUT TO THE DATA PORT
				;    AND STROBE IT IN
DATA_STROBE:
	LD	A,04H		; SET R/W* LINE low (BIT 1=0)
				; SET RS line HIGH FOR DATA (BIT 2=1)
				; (A) = (X,X,X,X,X,RS,R/W*, E)
	JP	STROBE		; DO THE STROBE  
				; RETURN THROUGH THE STROBE ROUTINE
	
GM7303_COMMAND:			; OUTPUT COMMAND TO 7303 MODULE LCD
	OUT	(GM7303_DATA),A	; WRITE TO TO DISPLAY
	JP	CMD_STROBE	; COMMAND STROBE (STROBE ROUTING LETS US RETURN)
	
; SEND DATA STRING
; DE=STRING ADDRESS, NULL TERMINATED
;
GM7303_OUTDS:
	LD	A,(DE)		; NEXT BYTE TO SEND
	OR	A		; SET FLAGS
	RET	Z		; DONE WHEN NULL REACHED
	INC	DE		; BUMP POINTER
	CALL	GM7303_OUTD	; SEND IT
	JR	GM7303_OUTDS	; LOOP AS NEEDED
;
; GOTO ROW(H),COL(L)
;
GM7303_GOTORC:
	PUSH	HL			; SAVE INCOMING
	LD	A,H			; ROW # TO A
	LD	HL,GM7303_ROWS		; POINT TO ROWS TABLE
	CALL	ADDHLA			; INDEX TO ROW ENTRY
	LD	A,(HL)			; GET ROW START
	POP	HL			; RECOVER INCOMING
	ADD	A,L			; ADD COLUMN
	ADD	A,GM7303_FUNC_DDADR	; ADD SET DDRAM COMMAND
	JR	GM7303_COMMAND		; AND SEND IT
;

; 		LCD CONTROLLER MANUAL RESET METHOD
;
GM7303_RESETLCD:
	LD	A,GM7303_FUNC_SET | %11000    ;   8 BIT INTERFACE, COMMAND MODE, 2 LINES
	OUT	(GM7303_DATA),A
	LD	A,01            ;  SET ENABLE LINE HIGH (BIT 0=1)
	OUT 	(GM7303_CTRL),A
	LD	DE,5000/16	; WAIT >40MS, WE USE 50MS
	CALL	VDELAY		; DO IT
	LD	A,00            ;  SET ENABLE LINE LOW (BIT 0=0)
	OUT 	(GM7303_CTRL),A

	LD	A,01            ;  SET ENABLE LINE HIGH (BIT 0=1)
	OUT 	(GM7303_CTRL),A
	LD	DE,500/16	; WAIT >4MS, WE USE 5MS
	CALL	VDELAY		; DO IT
	LD	A,00            ;  SET ENABLE LINE LOW (BIT 0=0)
	OUT 	(GM7303_CTRL),A

	LD	A,01            ;  SET ENABLE LINE HIGH (BIT 0=1)
	OUT 	(GM7303_CTRL),A
	LD	DE,500/16	; WAIT >4MS, WE USE 5MS
	CALL	VDELAY		; DO IT
	LD	A,00            ;  SET ENABLE LINE LOW (BIT 0=0)
	OUT 	(GM7303_CTRL),A
	RET

;
; DATA STORAGE
;
GM7303_PRESENT	.DB	0	; NON-ZERO WHEN HARDWARE DETECTED
;
GM7303_BUF	.FILL	8	; USED BY SHOWSEG
		.DB	0	; NULL TERMINATOR FOR ABOVE
;
; KBD WORKING STORAGE
;
GM7303_KEYBUF	.DB	0
;
;
GM7303_ROWS	.DB	$00,$40	; ROW START INDEX FOR 2 LINE DISPLAY
;
GM7303_INIT_TBL:	; TABLE OF INITIALISATION COMMANDS FOR THE LCD
	.DB 38H	;   8 BIT OPERATION, 2 LINE DISPLAY, 8X5 FONT
	.DB 0EH	;   TURN ON DISPLAY, CURSOR AND BLINK
	.DB 06H	;   SET CURSOR MOVE FROM LEFT TO RIGHT
	.DB 01H	;   CLEAR DISPLAY
;
GM7303_STR_BAN	.DB	"RomWBW ", BIOSVER, 0
GM7303_STR_CFG	.DB	"Build:", CONFIG, 0
GM7303_STR_IO	.DB	"Dsk", 0
;
GM7303_SEGMAP:
;
	; POS	$00  $01  $02  $03  $04  $05  $06  $07
	; GLYPH '0'  '1'  '2'  '3'  '4'  '5'  '6'  '7'
	.DB	"01234567"
;
	; POS	$08  $09  $0A  $0B  $0C  $0D  $0E  $0F
	; GLYPH	'8'  '9'  'A'  'B'  'C'  'D'  'E'  'F'
	.DB	"89ABCDEF"
;
	; POS	$10  $11  $12  $13  $14  $15  $16  $17  $18  $19  $1A
	; GLYPH	' '  '-'  '.'  'P'  'o'  'r'  't'  'A'  'd'  'r'  'G'
	.DB	" -.PortAdrG"
;
GM7303_MSGTBL:
	.DW	GM7303_MSG_LDR_SEL
	.DW	GM7303_MSG_LDR_BOOT
	.DW	GM7303_MSG_LDR_LOAD
	.DW	GM7303_MSG_LDR_GO
	.DW	GM7303_MSG_MON_RDY
	.DW	GM7303_MSG_MON_BOOT
;
GM7303_MSG_LDR_SEL	.DB	"Ready",0
GM7303_MSG_LDR_BOOT	.DB	"Boot...",0
GM7303_MSG_LDR_LOAD	.DB	"Load...",0
GM7303_MSG_LDR_GO	.DB	"Go...",0
GM7303_MSG_MON_RDY	.DB	"-CPU UP-",0
GM7303_MSG_MON_BOOT	.DB	"Boot!",0
