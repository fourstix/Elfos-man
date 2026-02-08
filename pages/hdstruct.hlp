Hard Disk Structure
The hard disk is used in LBA mode, therefore all sector addresses are LBA addresses.

File System Layout
Sector 	Description
0 	Boot Sector
1 - 16 	Kernel Image (8k)
17 - AS 	Alloction Table
AS+1 - AS+8 	Master Directory
AS+9 - 	Data Sectors

AS is computed as (total_sectors/sectors_per_au)/entries_per_sector + 17

total_sectors - Total number of sectors on disk
sectors_per_au - Number of sectors per allocation unit (default 8, 4k AUs)
entries_per_sector = 256 when less than 65535 allocation units, otherwise 128

The allocation table is setup as AU chain. The directory entry for a file specifies the first AU number. The allocation table then has a pointer to the next AU for a file. There are 2 special AU codes:
0FFFFh 	Unavailable AU
0FEFEh 	End of chain

Boot Sector Layout
Byte Offset 	Description>
0-255 	Boot code
256-259 	Total sector count on disk
260 	File system type (1=elfos, others are undefined)
261-264 	First sector of Master Directory
265-266 	Size of AU in sectors
267-270 	Number of AUs

Directory structure:
--------------------
byte   description
0-3    First Sector, 0=free entry
4-5    eof byte
6      flags1
       0 - file is a subdir
7-8    Packed date
9-10   Packed time
11-31  filename

Date format:              Time Format:
------------              ------------
7654 3210  7654 3210      7654 3210  7654 3210
|_______|____|_____|      |____||______||____|
  YEAR    MO     DY         HR    MIN    SEC/2

Boot Sector Code

; ************************************
; *** Define disk boot sector      ***
; *** This runs at 100h            ***
; *** Expects to be called with R0 ***
; ************************************
call:      equ     0ffe0h
ret:       equ     0fff1h
scall:     equ     r4
sret:      equ     r5
boot:      ghi     r0                  ; get current page
           phi     r3                  ; place into r3
           ldi     low bootst          ; boot start code
           plo     r3
           sep     r3                  ; transfer control
bootst:    ldi     high call           ; setup call vector
           phi     r4
           ldi     low call
           plo     r4
           ldi     high ret            ; setup return vector
           phi     r5
           ldi     low ret
           plo     r5
           ldi     0                   ; setup an initial stack
           phi     r2
           ldi     0f0h
           plo     r2
           ldi     1                   ; setup sector address
           plo     r7
           ldi     3                   ; starting page for kernel
           phi     rf                  ; place into read pointer
           ldi     0
           plo     rf
           sex     r2                  ; set stack pointer
bootrd:    glo     r7                  ; save R7
           stxd
           ldi     0                   ; prepare other registers
           phi     r7
           plo     r8
           ldi     0e0h
           phi     r8
           sep     scall               ; call bios to read sector
           dw      f_ideread
           irx                         ; recover R7
           ldxa
           plo     r7
           inc     r7                  ; point to next sector
           glo     r7                  ; get count
           smi     17                  ; was last sector (16) read?
           bnz     bootrd              ; jump if not
           ldi     3                   ; setup jump to os
           phi     r0
           ldi     0
           plo     r0
           sep     r0                  ; jump to os

Program to initiate boot from HD

           org     0
           ldi     0
           phi     r2
           ldi     0ffh
           plo     r2
           sex     r2
           lbr     0ff00h

