;
;==================================================================================================
; DSKY NEXT GENERATION PKD (DISPLAY AND KEYBOARD) ROUTINES
;==================================================================================================
;
; A PKD CAN SHARE A PPI BUS WITH EITHER A PPIDE OR PPISD.
;   SEE PPI_BUS.TXT FOR MORE INFORMATION.
;
; LED SEGMENTS (BIT VALUES)
;
;	+--01--+
;	20    02
;	+--40--+
;	10    04
;	+--08--+  80
;
; KEY CODE MAP (KEY CODES) CSCCCRRR
;                          ||||||||
;                          |||||+++-- ROW
;                          ||+++----- COL
;                          |+-------- SHIFT
;                          +--------- CONTROL
;
;      _____C0_________C1_________C2_________C3__________C4____
;  R0 |	 $00 [D]    $08 [E]    $10 [F]    $18 [BO]   $20 [F4]
;  R1 |	 $01 [A]    $09 [B]    $11 [C]    $19 [GO]   $21 [F3]
;  R2 |	 $02 [7]    $0A [8]    $12 [9]    $1A [EX]   $22 [F2]
;  R3 |	 $03 [4]    $0B [5]    $13 [6]    $1B [DE]   $23 [F1]
;  R5 |	 $04 [1]    $0C [2]    $14 [3]    $1C [EN]  +$40 [SH]
;  R6 |	 $05 [FW]   $0D [0]    $15 [BK]   $1D [CL]  +$80 [CTL]
;
; LED BIT MAP (BIT VALUES)
;
;	$08	$09	$0A	$0B	$0C	$0D	$0E	$0F
;	---	---	---	---	---	---	---	---
;	01	01	01	01	01
;	02	02	02	02	02
;	04	04	04	04	04
;	08	08	08	08	08
;	10	10	10	10	10
;	20	20	20	20	20	L1	L2 	BUZZ
;
PKD_PPIA	.EQU 	PKDPPIBASE + 0	; PORT A
PKD_PPIB	.EQU 	PKDPPIBASE + 1	; PORT B
PKD_PPIC	.EQU 	PKDPPIBASE + 2	; PORT C
PKD_PPIX	.EQU 	PKDPPIBASE + 3	; PPI CONTROL PORT
;
PKD_PPIX_RD	.EQU	%10010010	; PPIX VALUE FOR READS
PKD_PPIX_WR	.EQU	%10000010	; PPIX VALUE FOR WRITES
;	
PKD_ROWS	.EQU	1		; DISPLAY ROWS	
PKD_COLS	.EQU	8		; DISPLAY COLUMNS
;
; PIO CHANNEL C:
;
;	7	6	5	4	3	2	1	0
;	RES	0	0	CS	CS	/RD	/WR	A0
;
; SETTING BITS 3 & 4 WILL ASSERT /CS ON 3279
; CLEAR BITS 1 OR 2 TO ASSERT READ/WRITE
;
PKD_PPI_IDLE	.EQU	%00000110
;
PKD_CMD_CLR	.EQU	%11011111		; CLEAR (ALL OFF)
PKD_CMD_CLRX	.EQU	%11010011		; CLEAR (ALL ON)
PKD_CMD_WDSP	.EQU	%10010000		; WRITE DISPLAY RAM
PKD_CMD_RDSP	.EQU	%01110000		; READ DISPLAY RAM
PKD_CMD_CLK	.EQU	%00100000		; SET CLK PRESCALE
PKD_CMD_FIFO	.EQU	%01000000		; READ FIFO
;
PKD_PRESCL	.EQU	PKDOSC/100000		; PRESCALER
;
	DEVECHO	"PKD: IO="
	DEVECHO	PKDPPIBASE
	DEVECHO	", SIZE="
	DEVECHO	PKD_COLS
	DEVECHO	"X"
	DEVECHO	PKD_ROWS
	DEVECHO	"\n"
;
;__PKD_PREINIT_____________________________________________________________________________________
;
;  CONFIGURE PARALLEL PORT AND INITIALIZE 8279
;__________________________________________________________________________________________________
;
;
; HARDWARE RESET 8279 BY PULSING RESET LINE
;
PKD_PREINIT:
;
	; RESET PRESENCE FLAG
	XOR	A			; ASSUME NOT PRESENT
	LD	(PKD_PRESENT),A		; SAVE IT
;
	; CHECK FOR PPI
	CALL	PKD_PPIDETECT		; TEST FOR PPI HARDWARE
	RET	NZ			; BAIL OUT IF NOT THERE
;
	; SETUP PPI TO IDLE STATE
	CALL	PKD_PPIIDLE
	LD	A,PKD_PPI_IDLE
	OUT	(PKD_PPIC),A
;
	; PULSE RESET SIGNAL ON 8279
	SET	7,A
	OUT	(PKD_PPIC),A
	RES	7,A
	OUT	(PKD_PPIC),A
;
	; INITIALIZE 8279
	CALL	PKD_REINIT
;
	; NOW SEE IF A PKD IS REALLY THERE...
	LD	A,$71
	LD	C,0
	CALL	PKD_PUTBYTE
	LD	C,0
	CALL	PKD_GETBYTE
	CP	$71
	RET	NZ			; BAIL OUT IF MISCOMPARE
;
	; RECORD HARDWARE PRESENT
	LD	A,$FF
	LD	(PKD_PRESENT),A
;
	; REGISTER DRIVER WITH HBIOS
	LD	BC,PKD_DISPATCH
	CALL	DSKY_SETDISP
;
	CALL	PKD_SHOWVER
;
	RET
;
PKD_REINIT:
	CALL	PKD_PPIIDLE
	; SET CLOCK SCALER TO 20
	LD	A,PKD_CMD_CLK | PKD_PRESCL
	CALL	PKD_CMD
	JP	PKD_RESET
;
PKD_SHOWVER:
	LD	HL,PKD_VERSTR
	LD	DE,PKD_BUF
	LD	BC,PKD_COLS
	LDIR
	LD	HL,PKD_BUF + 5
	LD	A,RMJ
	LD	A,(PKD_SEGMAP + RMJ)
	OR	$80
	LD	(HL),A
	INC	HL
	LD	A,(PKD_SEGMAP + RMN)
	OR	$80
	LD	(HL),A
	INC	HL
	LD	A,(PKD_SEGMAP + RUP)
	LD	(HL),A
;
	; DISPLAY VERSION ON PKD
	LD	C,0
	LD	B,8
	LD	HL,PKD_BUF
	CALL	PKD_PUTSTR
	RET
;
;__PKD_INIT________________________________________________________________________________________
;
;  DISPLAY DSKY INFO
;__________________________________________________________________________________________________
;
PKD_INIT:
	CALL	NEWLINE			; FORMATTING
	PRTS("PKD:$")			; FORMATTING
;
	PRTS(" IO=0x$")			; FORMATTING
	LD	A,PKDPPIBASE		; GET BASE PORT
	CALL	PRTHEXBYTE		; PRINT BASE PORT
;
	LD	A,(PKD_PRESENT)		; PRESENT?
	OR	A			; SET FLAGS
	JR	NZ,PKD_INIT1		; YES, CONTINUE
	PRTS(" NOT PRESENT$")		; NOT PRESENT
	RET
;
PKD_INIT1:
	CALL	PC_SPACE
	LD	A,PKD_COLS
	CALL	PRTDEC8
	LD	A,'X'
	CALL	COUT
	LD	A,PKD_ROWS
	CALL	PRTDEC8
	RET
;
; DSKY DEVICE FUNCTION DISPATCH ENTRY
;   A: RESULT (OUT), 0=OK, Z=OK, NZ=ERR
;   B: FUNCTION (IN)
;
PKD_DISPATCH:
	LD	A,B			; GET REQUESTED FUNCTION
	AND	$0F			; ISOLATE SUB-FUNCTION
	JP	Z,PKD_RESET		; RESET DSKY HARDWARE
	DEC	A	
	JP	Z,PKD_STAT		; GET KEYPAD STATUS
	DEC	A	
	JP	Z,PKD_GETKEY		; READ A KEY FROM THE KEYPAD
	DEC	A	
	JP	Z,PKD_SHOWHEX		; DISPLAY A 32-BIT BINARY VALUE IN HEX
	DEC	A	
	JP	Z,PKD_SHOWSEG		; DISPLAY SEGMENTS
	DEC	A	
	JP	Z,PKD_KEYLEDS		; SET KEYPAD LEDS
	DEC	A	
	JP	Z,PKD_STATLED		; SET STATUS LED
	DEC	A	
	JP	Z,PKD_BEEP		; BEEP DSKY SPEAKER
	DEC	A
	JP	Z,PKD_DEVICE		; DEVICE INFO
	DEC	A
	JP	Z,PKD_MESSAGE		; HANDLE MESSAGE
	DEC	A
	JP	Z,PKD_EVENT		; HANDLE EVENT
	SYSCHKERR(ERR_NOFUNC)
	RET
;
; RESET DSKY -- CLEAR RAM AND FIFO
;
PKD_RESET:
	LD	A,PKD_CMD_CLR
	CALL	PKD_CMD
;	
	; 8259 TAKES ~160US TO CLEAR RAM DURING WHICH TIME WRITES TO
	; DISPLAY RAM ARE INHIBITED.  HIGH BIT OF STATUS BYTE IS SET
	; DURING THIS WINDOW.  TO PREVENT A DEADLOCK, A LOOP COUNTER
	; IS USED TO IMPLEMENT A TIMEOUT.
	LD	B,0			; TIMEOUT LOOP COUNTER
PKD_RESET1:
	PUSH	BC			; SAVE COUNTER
	CALL	PKD_ST			; GET STATUS BYTE
	POP	BC			; RECOVER COUNTER
	BIT	7,A			; BIT 7 IS DISPLAY RAM BUSY
	JR	Z,PKD_RESET2		; MOVE ON IF DONE
	DJNZ	PKD_RESET1		; LOOP TILL TIMEOUT
;
PKD_RESET2:
	RET
;
;  CHECK FOR KEY PRESS, SAVE RAW VALUE, RETURN STATUS
;
PKD_STAT:
	CALL	PKD_ST
	AND	$0F			; ISOLATE THE CUR FIFO LEN
	RET
;
;  WAIT FOR A DSKY KEYPRESS AND RETURN
;
PKD_GETKEY:
	CALL	PKD_STAT
	JR	Z,PKD_GETKEY		; LOOP IF NOTHING THERE
	LD	A,PKD_CMD_FIFO
	CALL	PKD_CMD
	CALL	PKD_DIN
	XOR	%11000000		; FLIP POLARITY OF SHIFT/CTL BITS
	PUSH	AF			; SAVE VALUE
	AND	$3F			; STRIP SHIFT/CTL BITS FOR LOOKUP
	LD	B,28			; SIZE OF DECODE TABLE
	LD	C,0			; INDEX
	LD	HL,PKD_KEYMAP		; POINT TO BEGINNING OF TABLE
PKD_GETKEY1:
	CP	(HL)			; MATCH?
	JR	Z,PKD_GETKEY2		; FOUND, DONE
	INC	HL
	INC	C			; BUMP INDEX
	DJNZ	PKD_GETKEY1		; LOOP UNTIL EOT
	POP	AF			; FIX STACK
	LD	A,$FF			; NOT FOUND ERR, RETURN $FF
	RET
PKD_GETKEY2:
	; RETURN THE INDEX POSITION WHERE THE SCAN CODE WAS FOUND
	; THE ORIGINAL SHIFT/CTRL BITS ARE RESTORED
	POP	AF			; RESTORE RAW VALUE
	AND	%11000000		; ISOLATE SHIFT/CTRL BITS
	OR	C			; COMBINE WITH INDEX VALUE
	LD	E,A			; PUT IN E FOR RETURN
	XOR	A			; SIGNAL SUCCESS
	RET
;
; DISPLAY HEX VALUE FROM DE:HL
;
PKD_SHOWHEX:
	LD	BC,PKD_TMP32		; POINT TO HEX BUFFER
	CALL	ST32			; STORE 32-BIT BINARY THERE
	LD	HL,PKD_TMP32		; FROM: BINARY VALUE (HL)
	LD	DE,PKD_BUF		; TO: SEGMENT BUFFER (DE)
	CALL	PKD_BIN2SEG		; CONVERT
	LD	HL,PKD_BUF		; POINT TO SEGMENT BUFFER
	LD	B,PKD_COLS		; LENGTH TO DISPLAY
	LD	C,0			; STARTING POSITION
	CALL	PKD_PUTSTR		; DO IT
	XOR	A			; SUCCESS
	RET				; AND RETURN
;
; DRAW DISPLAY USING DEBUG ALPHABET
; HL = SOURCE BUFFER
;
PKD_SHOWSEG:
	; CONVERT FROM DBG ALPHABET TO SEG CODES
	LD	B,PKD_COLS		; DO FOR ALL CHARS
	LD	DE,PKD_BUF		; DESTINATION BUFFER
PKD_SHOWSEG1:
	LD	A,(HL)			; GET SOURCE VALUE
	INC	HL			; BUMP FOR NEXT TIME
	PUSH	AF			; SAVE IT
	AND	$80			; ISOLATE HI BIT (DP)
	LD	C,A			; SAVE IN C
	POP	AF			; RECOVER ORIGINAL
	AND	$7F			; REMOVE HI BIT (DP)
	PUSH	HL			; SAVE IT
	LD	HL,PKD_SEGMAP		; POINT TO XLAT MAP
	CALL	ADDHLA			; OFFSET BY VALUE
	LD	A,(HL)			; GET NEW VALUE
	OR	C			; RECOMBINE WITH DP BIT
	LD	(DE),A			; SAVE IT
	INC	DE			; BUMP PTR
	POP	HL			; RESTORE SOURCE PTR
	DJNZ	PKD_SHOWSEG1		; LOOP TILL DONE
;	
	; DISPLAY CONVERTED BUFFER
	LD	C,0			; STARTING DISPLAY POSITION
	LD	B,PKD_COLS		; NUMBER OF CHARS
	LD	HL,PKD_BUF		; BUFFER
	CALL	PKD_PUTSTR		; DO IT
	XOR	A			; SIGNAL SUCCESS
	RET
;
;
;
PKD_KEYLEDS:
	CALL	PKD_PUTLED		; DO IT
	XOR	A			; SIGNAL SUCCESS
	RET
;
;
;
PKD_STATLED:
	LD	A,$0D			; PORT FOR FIRST LED
	ADD	A,D			; ADD LED NUM
	LD	C,A			; PUT IN C
	LD	A,E			; LED STATE INDICATOR
	OR	A			; SET FLAGS
	JR	NZ,PKD_STATLED1		; HANDLE "ON"
;
	; TURN LED OFF
	PUSH	BC			; SAVE LED NUM
	CALL	PKD_GETBYTE		; GET CUR VALUE
	AND	~$20			; BIT 5 OFF
	JR	PKD_STATLED2		; FINISH UP
;
PKD_STATLED1:
	; TURN LED ON
	PUSH	BC			; SAVE LED NUM
	CALL	PKD_GETBYTE		; GET CUR VALUE
	OR	$20			; BIT 5 ON
;
PKD_STATLED2:
	POP	BC			; RECOVER LED NUM
	CALL	PKD_PUTBYTE		; PUT NEW VALUE
	XOR	A			; SIGNAL SUCCESS
	RET
;
; BEEP THE SPEAKER ON THE PKD
;
PKD_BEEP:
	PUSH	BC
	LD 	C,$0F
	CALL	PKD_GETBYTE
	OR 	$20
	LD 	C,$0F
	CALL	PKD_PUTBYTE
;
	; TIMER
	PUSH	HL
	LD 	HL,$8FFF
PKD_BEEP1:
	DEC 	HL
	LD 	A,H
	CP 	0
	JR 	NZ,PKD_BEEP1
	POP 	HL
	LD 	C,$0F
	CALL	PKD_GETBYTE
	AND	$DF
	LD 	C,$0F
	CALL	PKD_PUTBYTE
	POP	BC
	XOR	A			; SIGNAL SUCCESS
	RET
;
; DEVICE INFORMATION
;
PKD_DEVICE:
	LD	D,DSKYDEV_PKD		; D := DEVICE TYPE
	LD	E,0			; E := PHYSICAL DEVICE NUMBER
	LD	H,0			; H := MODE
	LD	L,PKDPPIBASE		; L := BASE I/O ADDRESS
	XOR	A			; SIGNAL SUCCESS
	RET
;
; MESSAGE HANDLER
;
PKD_MESSAGE:
	LD	A,C			; GET MESSAGE ID
	ADD	A,A			; WORD OFFSET
	LD	HL,PKD_MSGTBL		; START OF MESSAGE TABLE
	CALL	ADDHLA			; ADD OFFSET
	LD	A,(HL)			; SAVE LSB
	INC	HL			; BUMP TO MSB
	LD	H,(HL)			; GET MSB
	LD	L,A			; GET LSB
;
	; HL HAS POINTER TO MESSAGE
	LD	C,0			; STARTING DISPLAY POSITION
	LD	B,PKD_COLS		; NUMBER OF CHARS
	CALL	PKD_PUTSTR		; DISPLAY IT
	XOR	A			; SIGNAL SUCCESS
	RET
;
; EVENT HANDLER
;
PKD_EVENT:
	LD	A,C			; EVENT ID
	OR	A			; 0=CPUSPD
	JR	Z,PKD_EVT_CPUSPD	; HANDLE CPU SPD CHANGE
	DEC	A			; 1=DSKACT
	JR	Z,PKD_EVT_DSKACT	; HANDLE DISK ACTIVITY
	XOR	A
	RET
;
; CPU SPEED CHANGE
;
PKD_EVT_CPUSPD:
	XOR	A
	RET
;
; DISK ACTIVITY
;
PKD_EVT_DSKACT:
;
	; USE DISK UNIT NUMBER FOR MSB
	LD	A,(HB_DSKUNIT)		; GET DISK UNIT NUM
	LD	(HB_DSKADR+3),A		; REPLACE HIGH BYTE W/ DISK #
;
	; CONVERT TO SEGMENT DISPLAY
	LD	HL,HB_DSKADR		; INPUT POINTER
	LD	DE,PKD_BUF		; BUF FOR OUTPUT
	CALL	PKD_BIN2SEG		; CONVERT TO SEG DISPLAY
;
	; DECIMAL POINT FOR DISK UNIT SEPARATION
	LD	HL,PKD_BUF+1		; SECOND CHAR OF DISP
	SET	7,(HL)			; TURN ON DECIMAL PT
;
	; DECIMAL POINT TO INDICATE WRITE ACTION
	LD	A,(HB_DSKFUNC)		; GET CURRENT I/O FUNCTION
	CP	BF_DIOWRITE		; IS IT A WRITE?
	JR	NZ,PKD_EVT_DSKACT2	; IF NOT, SKIP
	LD	HL,PKD_BUF+7		; POINT TO CHAR 7
	SET	7,(HL)			; SET WRITE DOT
;
PKD_EVT_DSKACT2:
	; UPDATE DISPLAY
	LD	HL,PKD_BUF		; SEG DISPLAY BUF TO HL
	LD	B,PKD_COLS
	LD	C,0
	CALL	PKD_PUTSTR
;
	XOR	A
	RET
;
;__PKD_PPIDETECT___________________________________________________________________________________
;
;  PROBE FOR PPI HARDWARE
;__________________________________________________________________________________________________
;
PKD_PPIDETECT:
;
	; TEST FOR PPI EXISTENCE
	; WE SETUP THE PPI TO WRITE, THEN WRITE A VALUE OF ZERO
	; TO PORT A (DATALO), THEN READ IT BACK.  IF THE PPI IS THERE
	; THEN THE BUS HOLD CIRCUITRY WILL READ BACK THE ZERO. SINCE
	; WE ARE IN WRITE MODE, AN IDE CONTROLLER WILL NOT BE ABLE TO
	; INTERFERE WITH THE VALUE BEING READ.
	CALL	PKD_PPIWR
;
	LD	C,PKD_PPIA		; PPI PORT A
	XOR	A			; VALUE ZERO
	OUT	(C),A			; PUSH VALUE TO PORT
	IN	A,(C)			; GET PORT VALUE
	OR	A			; SET FLAGS
	RET				; AND RETURN
;
;__KEYMAP_TABLE____________________________________________________________________________________
;
PKD_KEYMAP:
	; POS	$00  $01  $02  $03  $04  $05  $06  $07
	; KEY   [0]  [1]  [2]  [3]  [4]  [5]  [6]  [7]
	.DB	$0D, $04, $0C, $14, $03, $0B, $13, $02
;
	; POS	$08  $09  $0A  $0B  $0C  $0D  $0E  $0F
	; KEY   [8]  [9]  [A]  [B]  [C]  [D]  [E]  [F]
	.DB	$0A, $12, $01, $09, $11, $00, $08, $10
;
	; POS	$10  $11  $12  $13  $14  $15  $16  $17
	; KEY   [FW] [BK] [CL] [EN] [DE] [EX] [GO] [BO]
	.DB	$05, $15, $1D, $1C, $1B, $1A, $19, $18

	; POS	$18  $19  $1A  $1B
	; KEY   [F4] [F3] [F2] [F1]
	.DB	$23, $22, $21, $20
;
;==================================================================================================
; PKD OUTPUT ROUTINES
;==================================================================================================
;
; SEND DSKY COMMAND BYTE IN REGISTER A
; TRASHES BC
;
PKD_CMD:
	LD	B,$01
	JR	PKD_DOUT2
;
; SEND DSKY DATA BYTE IN REGISTER A
; TRASHES BC
;
PKD_DOUT:
	LD	B,$00
;
PKD_DOUT2:
;
	; SAVE INCOMING DATA BYTE
	PUSH	AF
;
	; SET PPI LINE CONFIG TO WRITE MODE
	CALL	PKD_PPIWR
;
	; SETUP
	LD	C,PKD_PPIC
;
	; SET ADDRESS FIRST
	LD	A,PKD_PPI_IDLE
	OR	B
	OUT	(C),A
;
	; ASSERT 8279 /CS
	SET	3,A
	SET	4,A
	OUT	(C),A
;
	; PPIC WORKING VALUE TO REG B NOW
	LD	B,A
;
	; ASSERT DATA BYTE VALUE
	POP	AF
	OUT	(PKD_PPIA),A
;
	; PULSE /WR
	RES	1,B
	OUT	(C),B
	NOP			; MAY NOT BE NEEDED
	SET	1,B
	OUT	(C),B
;
	; DEASSERT /CS
	RES	3,B
	RES	4,B
	OUT	(C),B
;
	; CLEAR ADDRESS BIT
	RES	0,B
	OUT	(C),B
;
	; DONE
	CALL	PKD_PPIIDLE
	RET
;
;==================================================================================================
; PKD INPUT ROUTINES
;==================================================================================================
;
; RETURN DSKY STATUS VALUE IN A
; TRASHES BC
;
PKD_ST:
	LD	B,$01
	JR	PKD_DIN2
;
; RETURN NEXT DATA VALUE IN A
; TRASHES BC
;
PKD_DIN:
	LD	B,$00
;
PKD_DIN2:
	; SET PPI LINE CONFIG TO READ MODE
	CALL	PKD_PPIRD
;
	; SETUP
	LD	C,PKD_PPIC
;
	; SET ADDRESS FIRST
	LD	A,PKD_PPI_IDLE
	OR	B
	OUT	(C),A
;
	; ASSERT 8279 /CS
	SET	3,A
	SET	4,A
	OUT	(C),A
;
	; PPIC WORKING VALUE TO REG B NOW
	LD	B,A
;
	; ASSERT /RD
	RES	2,B
	OUT	(C),B
;
	; GET VALUE
	IN	A,(PKD_PPIA)
;
	; DEASSERT /RD
	SET	2,B
	OUT	(C),B
;
	; DEASSERT /CS
	RES	3,B
	RES	4,B
	OUT	(C),B
;
	; CLEAR ADDRESS BIT
	RES	0,B
	OUT	(C),B
;
	; DONE
	CALL	PKD_PPIIDLE
	RET
;
;==================================================================================================
; PKD UTILITY ROUTINES
;==================================================================================================
;
; BLANK PKD DISPLAY  (WITHOUT USING CLEAR)
;
PKD_BLANK:
	LD	A,PKD_CMD_WDSP
	CALL	PKD_CMD
	LD	B,16
PKD_BLANK1:
	PUSH	BC
	LD	A,$FF
	CALL	PKD_DOUT
	POP	BC
	DJNZ	PKD_BLANK1
	RET
;
; WRITE A RAW BYTE VALUE TO DSKY DISPLAY RAM
; AT LOCATION IN REGISTER C, VALUE IN A.
;
PKD_PUTBYTE:
	PUSH	BC
	PUSH	AF
	LD	A,C
	ADD	A,PKD_CMD_WDSP
	CALL	PKD_CMD
	POP	AF
	XOR	$FF
	CALL	PKD_DOUT
	POP	BC
	RET
;
; READ A RAW BYTE VALUE FROM DSKY DISPLAY RAM
; AT LOCATION IN REGISTER C, VALUE RETURNED IN A
;
PKD_GETBYTE:
	PUSH	BC
	LD	A,C
	ADD	A,PKD_CMD_RDSP
	CALL	PKD_CMD
	CALL	PKD_DIN
	XOR	$FF
	POP	BC
	RET
;
; WRITE A STRING OF RAW BYTE VALUES TO DSKY DISPLAY RAM
; AT LOCATION IN REGISTER C, LENGTH IN B, ADDRESS IN HL.
;
PKD_PUTSTR:
	PUSH	BC
	LD	A,C
	ADD	A,PKD_CMD_WDSP
	CALL	PKD_CMD
	POP	BC
;
PKD_PUTSTR1:
	LD	A,(HL)
	XOR	$FF
	INC	HL
	PUSH	BC
	CALL	PKD_DOUT
	POP	BC
	DJNZ	PKD_PUTSTR1
	RET
;
; READ A STRING OF RAW BYTE VALUES FROM DSKY DISPLAY RAM
; AT LOCATION IN REGISTER C, LENGTH IN B, ADDRESS IN HL.
;
PKD_GETSTR:
	PUSH	BC
	LD	A,C
	ADD	A,PKD_CMD_RDSP
	CALL	PKD_CMD
	POP	BC
;
PKD_GETSTR1:
	PUSH	BC
	CALL	PKD_DIN
	POP	BC
	XOR	$FF
	LD	(HL),A
	INC	HL
	DJNZ	PKD_GETSTR1
	RET
;
; UPDATE THE KEYPAD KEY LEDS.  HL POINTS TO AN 8 BYTE BITMAP BUFFER
; THAT DEFINES ALL KEYPAD LED VALUES.  THE ENTIRE MATRIX IS UPDATED.
;
PKD_PUTLED:
	PUSH	AF
	PUSH	BC
	LD 	C,8
PKD_PUTLED_1:
	LD 	A,(HL)
	PUSH 	BC
	CALL	PKD_PUTBYTE
	POP 	BC
	INC 	C
	INC	HL
	LD 	A,C
	CP	$10
	JP 	NZ,PKD_PUTLED_1
	POP	BC
        POP	AF
	RET
;
;==================================================================================================
; PKD LINE CONTROL ROUTINES
;==================================================================================================
;
; SETUP PPI FOR WRITING: PUT PPI PORT A IN OUTPUT MODE
; AVOID REWRTING PPIX IF ALREADY IN OUTPUT MODE
;
PKD_PPIWR:
	PUSH	AF
;
	; CHECK FOR WRITE MODE
	LD	A,(PKD_PPIX_VAL)
	CP	PKD_PPIX_WR
	JR	Z,PKD_PPIWR1
;
	; SET PPI TO WRITE MODE
	LD	A,PKD_PPIX_WR
	OUT	(PKD_PPIX),A
	LD	(PKD_PPIX_VAL),A
;
	; RESTORE PORT C (MAY NOT BE NEEDED)
	LD	A,PKD_PPI_IDLE
	OUT	(PKD_PPIC),A
;
PKD_PPIWR1:
;
	POP	AF
	RET
;
; SETUP PPI FOR READING: PUT PPI PORT A IN INPUT MODE
; AVOID REWRTING PPIX IF ALREADY IN INPUT MODE
;
PKD_PPIRD:
	PUSH	AF
;
	; CHECK FOR READ MODE
	LD	A,(PKD_PPIX_VAL)
	CP	PKD_PPIX_RD
	JR	Z,PKD_PPIRD1
;
	; SET PPI TO READ MODE
	LD	A,PKD_PPIX_RD
	OUT	(PKD_PPIX),A
	LD	(PKD_PPIX_VAL),A
;
PKD_PPIRD1:
	POP	AF
	RET
;
; RELEASE USE OF PPI
;
PKD_PPIIDLE:
	JR	PKD_PPIRD		; SAME AS READ MODE
;
;==================================================================================================
; UTILTITY FUNCTIONS
;==================================================================================================
;
; CONVERT 32 BIT BINARY TO 8 BYTE HEX SEGMENT DISPLAY
;
;	HL: ADR OF 32 BIT BINARY
;	DE: ADR OF DEST LED SEGMENT DISPLAY BUFFER (8 BYTES)
;
PKD_BIN2SEG:
	LD	B,4			; 4 BYTES OF INPUT
	LD	A,B			; PUT IN ACCUM
	CALL	ADDHLA			; PROCESS FROM END (LITTLE ENDIAN)
PKD_BIN2SEG1:
	DEC	HL			; DEC PTR (LITTLE ENDIAN)
	LD	A,(HL)			; HIGH NIBBLE
	RRCA \ RRCA \ RRCA \ RRCA	; ROTATE BITS
	CALL	PKD_BIN2SEG_NIB	; CONVERT NIBBLE INTO OUTPUT BUF
	LD	A,(HL)			; LOW NIBBLE
	CALL	PKD_BIN2SEG_NIB	; CONVERT NIBBLE INTO OUTPUT BUF
	DJNZ	PKD_BIN2SEG1		; LOOP FOR ALL INPUT BYTES
	RET				; DONE
;
PKD_BIN2SEG_NIB:
	PUSH	HL			; SAVE HL
	LD	HL,PKD_SEGMAP		; POINT TO SEG MAP TABLE
	AND	$0F			; ISOLATE LOW NIBBLE
	CALL	ADDHLA			; OFFSET INTO TABLE
	LD	A,(HL)			; LOAD VALUE FROM TABLE
	POP	HL			; RESTORE HL
	LD	(DE),A			; SAVE VALUE TO OUTPUT BUF
	INC	DE			; BUMP TO NEXT OUTPUT BYTE
	RET				; DONE
;
;==================================================================================================
; STORAGE
;==================================================================================================
;
PKD_PPIX_VAL	.DB	0		; PPIX SHADOW REG
PKD_PRESENT	.DB	0		; HARDWARE PRESENT FLAG
PKD_BUF		.FILL	PKD_COLS
PKD_TMP32	.FILL	4,0		; TEMP DWORD
;
PKD_VERSTR	.DB	$76,$7F,$30,$3F,$6D,$00,$00,$00	; "HBIOS   "
;
PKD_SEGMAP:
;
	; POS	$00  $01  $02  $03  $04  $05  $06  $07
	; GLYPH '0'  '1'  '2'  '3'  '4'  '5'  '6'  '7'

	.DB	$3F, $06, $5B, $4F, $66, $6D, $7D, $07
;
	; POS	$08  $09  $0A  $0B  $0C  $0D  $0E  $0F
	; GLYPH	'8'  '9'  'A'  'B'  'C'  'D'  'E'  'F'
	.DB	$7F, $67, $77, $7C, $39, $5E, $79, $71
;
	; POS	$10  $11  $12  $13  $14  $15  $16  $17  $18  $19  $1A
	; GLYPH	' '  '-'  '.'  'P'  'o'  'r'  't'  'A'  'd'  'r'  'G'
	.DB	$00, $40, $00, $73, $5C, $50, $78, $77, $5E, $50, $3D

;
PKD_MSGTBL:
	.DW	PKD_MSG_LDR_SEL
	.DW	PKD_MSG_LDR_BOOT
	.DW	PKD_MSG_LDR_LOAD
	.DW	PKD_MSG_LDR_GO
	.DW	PKD_MSG_MON_RDY
	.DW	PKD_MSG_MON_BOOT
;
PKD_MSG_LDR_SEL		.DB	$7F,$5C,$5C,$78,$53,$00,$00,$00	; "Boot?   "
PKD_MSG_LDR_BOOT	.DB	$7F,$5C,$5C,$78,$80,$80,$80,$00	; "Boot... "
PKD_MSG_LDR_LOAD	.DB	$38,$5C,$5F,$5E,$80,$80,$80,$00	; "Load... "
PKD_MSG_LDR_GO		.DB	$3D,$5C,$80,$80,$80,$00,$00,$00	; "Go...   "
PKD_MSG_MON_RDY		.DB	$40,$39,$73,$3E,$00,$3E,$73,$40	; "-CPU UP-"
PKD_MSG_MON_BOOT	.DB	$7F,$5C,$5C,$78,$82,$00,$00,$00	; "Boot!   "
