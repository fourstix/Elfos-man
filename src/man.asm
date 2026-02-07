; -------------------------------------------------------------------
; A simple full screen editor based on the Kilo editor,
; a small text editor in less than 1K lines of code
; written by Salvatore Sanfilippo aka antirez
; available at https://github.com/antirez/kilo
; and described step-by-step at the website
; https://viewsourcecode.org/snaptoken/kilo/index.html
; -------------------------------------------------------------------
; Also based on the Elf/OS edit program written by Michael H Riley
; available https://github.com/rileym65/Elf-Elfos-edit
; -------------------------------------------------------------------
; Copyright 2025 by Gaston Williams
; -------------------------------------------------------------------
; Based on software written by Michael H Riley
; Thanks to the author for making this code available.
; Original author copyright notice:
; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

#include include/ops.inc
#include include/bios.inc
#include include/kernel.inc
#include include/brws_def.inc

            org     2000h
start:      br      main


; Build information

ever

db    'Copyright 2025 by Gaston Williams',0


; Main code starts here, check provided argument
main:       lda   ra              ; move past any spaces
            smi   ' '
            lbz   main
            dec   ra              ; move back to non-space character
            load  rf,tname        ; point to filename storage
fnamelp:    lda   ra              ; get byte from filename
            str   rf              ; store int buffer
            inc   rf
            smi   33              ; look for space or less
            lbdf  fnamelp         ; loop back until done
            dec   rf              ; point back to termination byte
            ldi   0               ; and write terminator
            str   rf

            load  rf,tname        ; point to filename storage
            ldn   rf              ; get byte from argument
            lbnz  br_good         ; jump if filename given

            call  o_inmsg         ; otherwise display usage message
              db  'Usage: man topic',10,13,0
            return                ; and return to os


br_good:    call  o_inmsg
              db 'Loading...',10,13,0

            load  rf, tpath       ; strcpy  '/man/' + topic
            load  rd, fname       ; into file name buffer
            call  f_strcpy        ; rd points to end of string in buffer
            load  rf, tend        ; concat extension to filename
            call  f_strcpy        ; fname now has '/man/topic.hlp'

            ;---- debugging print file name
            load  rf, fname
            call  o_msg
            call  o_inmsg
              db 10,13,0


            call  begin_browse
            lbdf  br_exit          ; If file not found error, just exit

            ;----- read and process keys until Ctrl+X is pressed
            call  do_browse

br_exit:    call  end_browse

            return                ; return to Elf/OS
tpath:      db '/man/'
tname:      ds 20
tend:       db '.hlp',0

            ;------ define end of execution block
            end     start
