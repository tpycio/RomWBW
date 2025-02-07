;
;==================================================================================================
;   ROMWBW PLATFORM CONFIGURATION DEFAULTS FOR PLATFORM: ZETA
;==================================================================================================
;
; THIS FILE DEFINES THE DEFAULT CONFIGURATION SETTINGS FOR THE PLATFORM
; INDICATED ABOVE. THIS FILE SHOULD *NOT* NORMALLY BE CHANGED.	INSTEAD,
; YOU SHOULD OVERRIDE SETTINGS YOU WANT USING A CONFIGURATION FILE IN
; THE CONFIG DIRECTORY UNDER THIS DIRECTORY.
;
; THIS FILE SHOULD *NOT* NORMALLY BE CHANGED.  IT IS MAINTAINED BY THE
; AUTHORS OF ROMWBW.  TO OVERRIDE SETTINGS YOU SHOULD USE A
; CONFIGURATION FILE IN THE CONFIG DIRECTORY UNDER THIS DIRECTORY.
;
; ROMWBW USES CASCADING CONFIGURATION FILES AS INDICATED BELOW:
;
; cfg_MASTER.asm			- MASTER: CONFIGURATION FILE DEFINES ALL POSSIBLE ROMWBW SETTINGS
; |
; +-> cfg_<platform>.asm		- PLATFORM: DEFAULT SETTINGS FOR SPECIFIC PLATFORM
;     |
;     +-> Config/<plt>_std.asm		- BUILD: SETTINGS FOR EACH OFFICIAL DIST BUILD
;         |
;         +-> Config/<plt>_<cust>.asm	- USER: CUSTOM USER BUILD SETTINGS
;
; THE TOP (MASTER CONFIGURATION) FILE DEFINES ALL POSSIBLE ROMWBW
; CONFIGURATION SETTINGS. EACH FILE BELOW THE MASTER CONFIGURATION FILE
; INHERITS THE CUMULATIVE SETTINGS OF THE FILES ABOVE IT AND MAY
; OVERRIDE THESE SETTINGS AS DESIRED.
;
; OTHER THAN THE TOP MASTER FILE, EACH FILE MUST "#INCLUDE" ITS PARENT
; FILE (SEE #INCLUDE STATEMENT BELOW).  THE TOP TWO FILES SHOULD NOT BE
; MODIFIED.  TO CUSTOMIZE YOUR BUILD SETTINGS YOU SHOULD MODIFY THE
; DEFAULT BUILD SETTINGS (Config/<platform>_std.asm) OR PREFERABLY
; CREATE AN OPTIONAL CUSTOM USER SETTINGS FILE THAT INCLUDES THE DEFAULT
; BUILD SETTINGS FILE (SEE EXAMPLE Config/SBC_user.asm).
;
; BY CREATING A CUSTOM USER SETTINGS FILE, YOU ARE LESS LIKELY TO BE
; IMPACTED BY FUTURE CHANGES BECAUSE YOU WILL BE INHERITING MOST
; OF YOUR SETTINGS WHICH WILL BE UPDATED BY AUTHORS AS ROMWBW EVOLVES.
;
; *** WARNING: ASIDE FROM THE MASTER CONFIGURATION FILE, YOU MUST USE
; ".SET" TO OVERRIDE SETTINGS.  THE ASSEMBLER WILL ERROR IF YOU ATTEMPT
; TO USE ".EQU" BECAUSE IT WON'T LET YOU REDEFINE A SETTING WITH ".EQU".
;
#DEFINE PLATFORM_NAME	"Zeta", " [", CONFIG, "]"	; TEXT LABEL OF THIS CONFIG IN STARTUP MESSAGES
#DEFINE	BOOT_DEFAULT	"H"		; DEFAULT BOOT LOADER CMD FOR EMPTY CMD LINE
#DEFINE AUTO_CMD	""		; AUTO CMD WHEN BOOT_TIMEOUT IS ENABLED
#DEFINE DEFSERCFG	SER_38400_8N1 | SER_RTS		; DEFAULT SERIAL CONFIGURATION
;
#INCLUDE "cfg_MASTER.asm"
;
PLATFORM	.SET	PLT_ZETA	; PLT_[SBC|ZETA|ZETA2|N8|MK4|UNA|RCZ80|RCEZ80|RCZ180|EZZ80|SCZ180|GMZ180|DYNO|RCZ280|MBC|RPH|Z80RETRO|S100|DUO|HEATH|EPITX|MON|STDZ180|NABU|FZ80]
CPUFAM		.SET	CPU_Z80		; CPU FAMILY: CPU_[Z80|Z180|Z280|EZ80]
BIOS		.SET	BIOS_WBW	; HARDWARE BIOS: BIOS_[WBW|UNA]
BATCOND		.SET	FALSE		; ENABLE LOW BATTERY WARNING MESSAGE
HBIOS_MUTEX	.SET	FALSE		; ENABLE REENTRANT CALLS TO HBIOS (ADDS OVERHEAD)
USELZSA2	.SET	TRUE		; ENABLE FONT COMPRESSION
TICKFREQ	.SET	50		; DESIRED PERIODIC TIMER INTERRUPT FREQUENCY (HZ)
;
BOOT_TIMEOUT	.SET	-1		; AUTO BOOT TIMEOUT IN SECONDS, -1 TO DISABLE, 0 FOR IMMEDIATE
BOOT_DELAY	.SET	0		; FIXED BOOT DELAY IN SECONDS PRIOR TO CONSOLE OUTPUT
BOOT_PRETTY	.SET	FALSE		; BOOT WITH PRETTY PLATFORM NAME
BT_REC_TYPE	.SET	BT_REC_NONE	; BOOT RECOVERY METHOD TO USE: BT_REC_[NONE|FORCE|SBCB0|SBC1B|SBCRI|DUORI]
AUTOCON		.SET	TRUE		; ENABLE CONSOLE TAKEOVER AT LOADER PROMPT
;
CPUSPDCAP	.SET	SPD_FIXED	; CPU SPEED CHANGE CAPABILITY SPD_FIXED|SPD_HILO
CPUSPDDEF	.SET	SPD_HIGH	; CPU SPEED DEFAULT SPD_UNSUP|SPD_HIGH|SPD_LOW
CPUOSC		.SET	8000000		; CPU OSC FREQ IN MHZ
INTMODE		.SET	0		; INTERRUPTS: 0=NONE, 1=MODE 1, 2=MODE 2, 3=MODE 3 (Z280)
;
RAMSIZE		.SET	512		; SIZE OF RAM IN KB (MUST MATCH YOUR HARDWARE!!!)
ROMSIZE		.SET	512		; SIZE OF ROM IN KB (MUST MATCH YOUR HARDWARE!!!)
APP_BNKS	.SET	$FF		; BANKS TO RESERVE FOR APP USE ($FF FOR AUTO SIZING)
MEMMGR		.SET	MM_SBC		; MEMORY MANAGER: MM_[SBC|Z2|N8|Z180|Z280|MBC|RPH|MON|EZ512]
MPCL_RAM	.SET	$78		; SBC MEM MGR RAM PAGE SELECT REG (WRITE ONLY)
MPCL_ROM	.SET	$7C		; SBC MEM MGR ROM PAGE SELECT REG (WRITE ONLY)
;
RTCIO		.SET	$70		; RTC LATCH REGISTER ADR
;
KIOENABLE	.SET	FALSE		; ENABLE ZILOG KIO SUPPORT
KIOBASE		.SET	$80		; KIO BASE I/O ADDRESS
;
CTCENABLE	.SET	FALSE		; ENABLE ZILOG CTC SUPPORT
;
PCFENABLE	.SET	FALSE		; ENABLE PCF8584 I2C CONTROLLER
PCFBASE		.SET	$F0		; PCF8584 BASE I/O ADDRESS
;
EIPCENABLE	.SET	FALSE		; EIPC: ENABLE Z80 EIPC (Z84C15) INITIALIZATION
;
SKZENABLE	.SET	FALSE		; ENABLE SERGEY'S Z80-512K FEATURES
;
WDOGMODE	.SET	WDOG_NONE	; WATCHDOG MODE: WDOG_[NONE|EZZ80|SKZ]
;
FPLED_ENABLE	.SET	FALSE		; FP: ENABLES FRONT PANEL LEDS
FPLED_IO	.SET	$00		; FP: PORT ADDRESS FOR FP LEDS
FPLED_INV	.SET	FALSE		; FP: LED BITS ARE INVERTED
FPLED_DSKACT	.SET	TRUE		; FP: ENABLES DISK I/O ACTIVITY ON FP LEDS
FPSW_ENABLE	.SET	FALSE		; FP: ENABLES FRONT PANEL SWITCHES
FPSW_IO		.SET	$00		; FP: PORT ADDRESS FOR FP SWITCHES
FPSW_INV	.SET	FALSE		; FP: SWITCH BITS ARE INVERTED
;
DIAGLVL		.SET	DL_CRITICAL	; ERROR LEVEL REPORTING
;
LEDENABLE	.SET	FALSE		; ENABLES STATUS LED (SINGLE LED)
LEDMODE		.SET	LEDMODE_RTC	; LEDMODE_[STD|SC|RTC|NABU]
LEDPORT		.SET	RTCIO		; STATUS LED PORT ADDRESS
LEDDISKIO	.SET	TRUE		; ENABLES DISK I/O ACTIVITY ON STATUS LED
;
DSKYENABLE	.SET	FALSE		; ENABLES DSKY FUNCTIONALITY
DSKYDSKACT	.SET	TRUE		; ENABLES DISK ACTIVITY ON DSKY DISPLAY
ICMENABLE	.SET	FALSE		; ENABLES ORIGINAL DSKY ICM DRIVER (7218)
ICMPPIBASE	.SET	$60		; BASE I/O ADDRESS OF ICM PPI
PKDENABLE	.SET	FALSE		; ENABLES DSKY NG PKD DRIVER (8259)
PKDPPIBASE	.SET	$60		; BASE I/O ADDRESS OF PKD PPI
PKDOSC		.SET	3000000		; OSCILLATOR FREQ FOR PKD (IN HZ)
H8PENABLE	.SET	FALSE		; ENABLES HEATH H8 FRONT PANEL
LCDENABLE	.SET	FALSE		; ENABLE LCD DISPLAY
LCDBASE		.SET	$DA		; BASE I/O ADDRESS OF LCD CONTROLLER
GM7303ENABLE	.SET	FALSE		; ENABLES THE GM7303 BOARD WITH 16X2 LCD
;
BOOTCON		.SET	0		; BOOT CONSOLE DEVICE
SECCON		.SET	$FF		; SECONDARY CONSOLE DEVICE
CRTACT		.SET	FALSE		; ACTIVATE CRT (VDU,CVDU,PROPIO,ETC) AT STARTUP
VDAEMU		.SET	EMUTYP_ANSI	; VDA EMULATION: EMUTYP_[TTY|ANSI]
VDAEMU_SERKBD	.SET	$FF		; VDA EMULATION: SERIAL KBD UNIT #, OR $FF FOR HW KBD
ANSITRACE	.SET	1		; ANSI DRIVER TRACE LEVEL (0=NO,1=ERRORS,2=ALL)
PPKTRACE	.SET	1		; PPK DRIVER TRACE LEVEL (0=NO,1=ERRORS,2=ALL)
KBDTRACE	.SET	1		; KBD DRIVER TRACE LEVEL (0=NO,1=ERRORS,2=ALL)
PPKKBLOUT	.SET	KBD_US		; PPK KEYBOARD LANGUAGE: KBD_[US|DE]
KBDKBLOUT	.SET	KBD_US		; KBD KEYBOARD LANGUAGE: KBD_[US|DE]
MKYKBLOUT	.SET	KBD_US		; KBD KEYBOARD LANGUAGE: KBD_[US|DE]
KBDINTS		.SET	FALSE		; ENABLE KBD (PS2) KEYBOARD INTERRUPTS
;
DSRTCENABLE	.SET	TRUE		; DSRTC: ENABLE DS-1302 CLOCK DRIVER (DSRTC.ASM)
DSRTCMODE	.SET	DSRTCMODE_STD	; DSRTC: OPERATING MODE: DSRTCMODE_[STD|MFPIC|K80W]
DSRTCCHG	.SET	FALSE		; DSRTC: FORCE BATTERY CHARGE ON (USE WITH CAUTION!!!)
;
DS1501RTCENABLE	.SET	FALSE		; DS1501RTC: ENABLE DS-1501 CLOCK DRIVER (DS1501RTC.ASM)
DS1501RTC_BASE	.SET	$50		; DS1501RTC: I/O BASE ADDRESS
;
BQRTCENABLE	.SET	FALSE		; BQRTC: ENABLE BQ4845 CLOCK DRIVER (BQRTC.ASM)
BQRTC_BASE	.SET	$50		; BQRTC: I/O BASE ADDRESS
;
INTRTCENABLE	.SET	FALSE		; ENABLE PERIODIC INTERRUPT CLOCK DRIVER (INTRTC.ASM)
;
RP5RTCENABLE	.SET	FALSE		; RP5C01 RTC BASED CLOCK (RP5RTC.ASM)
;
HTIMENABLE	.SET	FALSE		; ENABLE SIMH TIMER SUPPORT
SIMRTCENABLE	.SET	FALSE		; ENABLE SIMH CLOCK DRIVER (SIMRTC.ASM)
;
DS7RTCENABLE	.SET	FALSE		; DS7RTC: ENABLE DS-1307 I2C CLOCK DRIVER (DS7RTC.ASM)
DS7RTCMODE	.SET	DS7RTCMODE_PCF	; DS7RTC: OPERATING MODE: DS7RTCMODE_[PCF]
;
DS5RTCENABLE	.SET	FALSE		; DS5RTC: ENABLE DS-1305 SPI CLOCK DRIVER (DS5RTC.ASM)
;
SSERENABLE	.SET	FALSE		; SSER: ENABLE SIMPLE SERIAL DRIVER (SSER.ASM)
SSERCFG		.SET	SER_9600_8N1	; SSER: SERIAL LINE CONFIG
SSERSTATUS	.SET	$FF		; SSER: STATUS PORT
SSERDATA	.SET	$FF		; SSER: DATA PORT
SSERIRDY	.SET	%00000001	; SSER: INPUT READY BIT MASK
SSERIINV	.SET	FALSE		; SSER: INPUT READY BIT INVERTED
SSERORDY	.SET	%00000010	; SSER: OUTPUT READY BIT MASK
SSEROINV	.SET	FALSE		; SSER: OUTPUT READY BIT INVERTED
;
DUARTENABLE	.SET	FALSE		; DUART: ENABLE 2681/2692 SERIAL DRIVER (DUART.ASM)
;
UARTENABLE	.SET	TRUE		; UART: ENABLE 8250/16550-LIKE SERIAL DRIVER (UART.ASM)
UARTCNT		.SET	1		; UART: NUMBER OF CHIPS TO DETECT (1-8)
UARTOSC		.SET	1843200		; UART: OSC FREQUENCY IN MHZ
UARTINTS	.SET	FALSE		; UART: INCLUDE INTERRUPT SUPPORT UNDER IM1/2/3
UART4UART	.SET	FALSE		; UART: SUPPORT 4UART ECB BOARD
UART4UARTBASE	.SET	$C0		; UART: BASE IO ADDRESS OF 4UART ECB BOARD
UART0BASE	.SET	$68		; UART 0: REGISTERS BASE ADR
UART0CFG	.SET	DEFSERCFG	; UART 0: SERIAL LINE CONFIG
UART1BASE	.SET	$FF		; UART 1: REGISTERS BASE ADR
UART1CFG	.SET	SER_300_8N1	; UART 1: SERIAL LINE CONFIG
UART2BASE	.SET	$FF		; UART 2: REGISTERS BASE ADR
UART2CFG	.SET	DEFSERCFG	; UART 2: SERIAL LINE CONFIG
UART3BASE	.SET	$FF		; UART 3: REGISTERS BASE ADR
UART3CFG	.SET	DEFSERCFG	; UART 3: SERIAL LINE CONFIG
UART4BASE	.SET	$FF		; UART 4: REGISTERS BASE ADR
UART4CFG	.SET	DEFSERCFG	; UART 4: SERIAL LINE CONFIG
UART5BASE	.SET	$FF		; UART 5: REGISTERS BASE ADR
UART5CFG	.SET	DEFSERCFG	; UART 5: SERIAL LINE CONFIG
UART6BASE	.SET	$FF		; UART 6: REGISTERS BASE ADR
UART6CFG	.SET	DEFSERCFG	; UART 6: SERIAL LINE CONFIG
UART7BASE	.SET	$FF		; UART 7: REGISTERS BASE ADR
UART7CFG	.SET	DEFSERCFG	; UART 7: SERIAL LINE CONFIG
;
ASCIENABLE	.SET	FALSE		; ASCI: ENABLE Z180 ASCI SERIAL DRIVER (ASCI.ASM)
;
Z2UENABLE	.SET	FALSE		; Z2U: ENABLE Z280 UART SERIAL DRIVER (Z2U.ASM)
;
ACIAENABLE	.SET	FALSE		; ACIA: ENABLE MOTOROLA 6850 ACIA DRIVER (ACIA.ASM)
;
SIOENABLE	.SET	FALSE		; SIO: ENABLE ZILOG SIO SERIAL DRIVER (SIO.ASM)
;
XIOCFG		.SET	DEFSERCFG	; XIO: SERIAL LINE CONFIG
;
VDUENABLE	.SET	FALSE		; VDU: ENABLE VDU VIDEO/KBD DRIVER (VDU.ASM)
CVDUENABLE	.SET	FALSE		; CVDU: ENABLE CVDU VIDEO/KBD DRIVER (CVDU.ASM)
GDCENABLE	.SET	FALSE		; GDC: ENABLE 7220 GDC VIDEO/KBD DRIVER (GDC.ASM)
TMSENABLE	.SET	FALSE		; TMS: ENABLE TMS9918 VIDEO/KBD DRIVER (TMS.ASM)
TMSMODE		.SET	TMSMODE_NONE	; TMS: DRIVER MODE: TMSMODE_[SCG|N8|MSX|MSXKBD|MSXMKY|MBC|COLECO|DUO|NABU]
TMS80COLS	.SET	FALSE		; TMS: ENABLE 80 COLUMN SCREEN, REQUIRES V9958
TMSTIMENABLE	.SET	FALSE		; TMS: ENABLE TIMER INTERRUPTS (REQUIRES IM1)
VGAENABLE	.SET	FALSE		; VGA: ENABLE VGA VIDEO/KBD DRIVER (VGA.ASM)
VRCENABLE	.SET	FALSE		; VRC: ENABLE VGARC VIDEO/KBD DRIVER (VRC.ASM)
SCONENABLE	.SET	FALSE		; SCON: ENABLE S100 CONSOLE DRIVER (SCON.ASM)
EFENABLE	.SET	FALSE		; EF: ENABLE EF9345 VIDEO DRIVER (EF.ASM)
FVENABLE	.SET	FALSE		; FV: ENABLE FPGA VGA VIDEO DRIVER (FV.ASM)
;
MDENABLE	.SET	TRUE		; MD: ENABLE MEMORY (ROM/RAM) DISK DRIVER (MD.ASM)
MDROM		.SET	TRUE		; MD: ENABLE ROM DISK
MDRAM		.SET	TRUE		; MD: ENABLE RAM DISK
MDTRACE		.SET	1		; MD: TRACE LEVEL (0=NO,1=ERRORS,2=ALL)
MDFFENABLE	.SET	FALSE		; MD: ENABLE FLASH FILE SYSTEM
;
FDENABLE	.SET	TRUE		; FD: ENABLE FLOPPY DISK DRIVER (FD.ASM)
FDMODE		.SET	FDMODE_ZETA	; FD: DRIVER MODE: FDMODE_[DIO|ZETA|ZETA2|DIDE|N8|DIO3|RCSMC|RCWDC|DYNO|EPFDC|MBC]
FDCNT		.SET	1		; FD: NUMBER OF FLOPPY DRIVES ON THE INTERFACE (1-2)
FDTRACE		.SET	1		; FD: TRACE LEVEL (0=NO,1=FATAL,2=ERRORS,3=ALL)
FDMAUTO		.SET	TRUE		; FD: AUTO SELECT DEFAULT/ALTERNATE MEDIA FORMATS
FD0TYPE		.SET	FDT_3HD		; FD 0: DRIVE TYPE: FDT_[3DD|3HD|5DD|5HD|8]
FD1TYPE		.SET	FDT_3HD		; FD 1: DRIVE TYPE: FDT_[3DD|3HD|5DD|5HD|8]
;
RFENABLE	.SET	FALSE		; RF: ENABLE RAM FLOPPY DRIVER
;
IDEENABLE	.SET	FALSE		; IDE: ENABLE IDE DISK DRIVER (IDE.ASM)
;
PPIDEENABLE	.SET	FALSE		; PPIDE: ENABLE PARALLEL PORT IDE DISK DRIVER (PPIDE.ASM)
PPIDETRACE	.SET	1		; PPIDE: TRACE LEVEL (0=NO,1=ERRORS,2=ALL)
PPIDECNT	.SET	1		; PPIDE: NUMBER OF PPI CHIPS TO DETECT (1-3), 2 DRIVES PER CHIP
PPIDE0BASE	.SET	$60		; PPIDE 0: PPI REGISTERS BASE ADR
PPIDE0A8BIT	.SET	FALSE		; PPIDE 0A (MASTER): 8 BIT XFER
PPIDE0B8BIT	.SET	FALSE		; PPIDE 0B (SLAVE): 8 BIT XFER
;
SDENABLE	.SET	FALSE		; SD: ENABLE SD CARD DISK DRIVER (SD.ASM)
SDMODE		.SET	SDMODE_PPI	; SD: DRIVER MODE: SDMODE_[JUHA|N8|CSIO|PPI|UART|DSD|MK4|SC|MT|USR|PIO|Z80R|EPITX|FZ80|GM|EZ512|K80W]
SDPPIBASE	.SET	$60		; SD: BASE I/O ADDRESS OF PPI FOR PPI MODDE
SDCNT		.SET	1		; SD: NUMBER OF SD CARD DEVICES (1-2), FOR DSD/SC/MT ONLY
SDTRACE		.SET	1		; SD: TRACE LEVEL (0=NO,1=ERRORS,2=ALL)
SDCSIOFAST	.SET	FALSE		; SD: ENABLE TABLE-DRIVEN BIT INVERTER IN CSIO MODE
SDMTSWAP	.SET	FALSE		; SD: SWAP THE LOGICAL ORDER OF THE SPI PORTS OF THE MT011
;
CHENABLE	.SET	FALSE		; CH: ENABLE CH375/376 USB SUPPORT
;
PRPENABLE	.SET	FALSE		; PRP: ENABLE ECB PROPELLER IO BOARD DRIVER (PRP.ASM)
;
PPPENABLE	.SET	FALSE		; PPP: ENABLE ZETA PARALLEL PORT PROPELLER BOARD DRIVER (PPP.ASM)
PPPBASE		.SET	$60		; PPP: PPI REGISTERS BASE ADDRESS
PPPSDENABLE	.SET	TRUE		; PPP: ENABLE PPP DRIVER SD CARD SUPPORT
PPPSDTRACE	.SET	1		; PPP: SD CARD TRACE LEVEL (0=NO,1=ERRORS,2=ALL)
PPPCONENABLE	.SET	TRUE		; PPP: ENABLE PPP DRIVER VIDEO/KBD SUPPORT
;
ESPENABLE	.SET	FALSE		; ESP: ENABLE ESP32 IO BOARD DRIVER (ESP.ASM)
;
HDSKENABLE	.SET	FALSE		; HDSK: ENABLE SIMH HDSK DISK DRIVER (HDSK.ASM)
;
PIOENABLE	.SET	FALSE		; PIO: ENABLE ZILOG PIO DRIVER (PIO.ASM)
;
LPTENABLE	.SET	FALSE		; LPT: ENABLE CENTRONICS PRINTER DRIVER (LPT.ASM)
;
PPAENABLE	.SET	FALSE		; PPA: ENABLE IOMEGA ZIP DRIVE (PPA) DISK DRIVER (PPA.ASM)
;
IMMENABLE	.SET	FALSE		; IMM: ENABLE IOMEGA ZIP PLUS DRIVE (IMM) DISK DRIVER (IMM.ASM)
;
SYQENABLE	.SET	FALSE		; SYQ: ENABLE SYQUEST SPARQ DISK DRIVER (SYQ.ASM)
;
PIO_4P		.SET	FALSE		; PIO: ENABLE PARALLEL PORT DRIVER FOR ECB 4P BOARD
PIO_ZP		.SET	FALSE		; PIO: ENABLE PARALLEL PORT DRIVER FOR ECB ZILOG PERIPHERALS BOARD (PIO.ASM)
PIO_SBC		.SET	FALSE		; PIO: ENABLE PARALLEL PORT DRIVER FOR 8255 CHIP
PIOSBASE	.SET	$60		; PIO: PIO REGISTERS BASE ADR FOR SBC PPI
;
UFENABLE	.SET	FALSE		; UF: ENABLE ECB USB FIFO DRIVER (UF.ASM)
;
SN76489ENABLE	.SET	FALSE		; SN: ENABLE SN76489 SOUND DRIVER
AY38910ENABLE	.SET	FALSE		; AY: ENABLE AY-3-8910 / YM2149 SOUND DRIVER
SPKENABLE	.SET	FALSE		; SPK: ENABLE RTC LATCH IOBIT SOUND DRIVER (SPK.ASM)
;
DMAENABLE	.SET	FALSE		; DMA: ENABLE DMA DRIVER (DMA.ASM)
DMABASE		.SET	$E0		; DMA: DMA BASE ADDRESS
DMAMODE		.SET	DMAMODE_NONE	; DMA: DMA MODE (NONE|ECB|Z180|Z280|RC|MBC|DUO)
;
YM2612ENABLE	.SET	FALSE		; YM2612: ENABLE YM2612 DRIVER
VGMBASE		.SET	$C0		; YM2612: BASE ADDRESS FOR VGM BOARD (YM2612/SN76489s/CTC)
