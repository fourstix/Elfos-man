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

            extrn   textbuf
            extrn   curline
            extrn   k_dta
            extrn   readln
            extrn   readbyte
            extrn   k_char
            extrn   skipln

            
            ;-------------------------------------------------------
            ; Name: find_eob
            ;
            ; Find the end of the text buffer
            ;
            ; Returns: 
            ;   DF = 0, buffer within memory limit
            ;   DF = 1, out of memory (buffer overflow)
            ;   r8 - Line number     
            ;   ra - pointer to line at end of buffer
            ;-------------------------------------------------------       
            proc  find_eob   
            load  ra, textbuf
            ldi   0             ; setup count
            phi   r8
            plo   r8
            
feob_lp:    lda   ra            ; get count
            lbz   feob_done     ; jump if end was found
            str   r2
            glo   ra
            add
            plo   ra
            ghi   ra
            adci  0
            phi   ra
            inc   r8            ; increment line count
            lbr   feob_lp
feob_done:  dec   ra            ; move back to end of buffer byte
            return              ; and return
            endp

            ;-------------------------------------------------------
            ; Name: setcurln
            ;
            ; Set current line to specified value            
            ; Parameters: 
            ;   r8 - line number to set as current
            ; Uses:
            ;   rf - pointer to current line byte
            ; Returns: (None)
            ;-------------------------------------------------------       
            proc  setcurln
            push  rf            ; save consumed register
            load  rf, curline   ; point to current line
            ghi   r8            ; write new current line
            str   rf
            inc   rf
            glo   r8
            str   rf
            pop   rf            ; recover consumed register
            return              ; and return
            endp

            ;-------------------------------------------------------
            ; Name: getcurln
            ;
            ; Get the current line number            
            ; Parameters: (None) 
            ; Uses:
            ;   rf - pointer to current line byte
            ; Returns:
            ;   r8 - line number to set as current
            ;-------------------------------------------------------       
            proc  getcurln
            push  rf            ; save consumed register
            load  rf,curline    ; point to current line
            lda   rf            ; get current line number
            phi   r8
            lda   rf
            plo   r8
            pop   rf            ; restore register
            return              ; and return
            endp
                       
            ;-------------------------------------------------------
            ; Name: find_line
            ;
            ; Set current line to specified value            
            ; Parameters: 
            ;   r8 - line number to find
            ; Uses:
            ;   rc - counter for lines
            ; Returns: 
            ;   DF = 0, if found
            ;   DF = 1, if not found
            ;   ra - pointer to line in buffer
            ;-------------------------------------------------------       
            proc  find_line
            push  rc            ; save consumed regsiter
            load  ra, textbuf   ; point to text buffer
            ghi     r8          ; get line number
            phi     rc
            glo     r8
            plo     rc
findlp:     ghi     rc
            lbnz    notfound
            glo     rc          ; see if count is zero
            lbz     found       ; jump if there
notfound:   lda     ra
            lbz     fnderr      ; jump if end of buffer was reached
            str     r2          ; prepare for add
            glo     ra          ; add to address
            add
            plo     ra
            ghi     ra
            adci    0
            phi     ra
            dec     rc          ; decrement count
            lbr     findlp      ; and check line
found:      ldi     0           ; signal line found
            shr
            lbr     fnd_done    ; and return to caller
fnderr:     dec     ra
            ldi     1           ; signal end of buffer reached
            shr
fnd_done:   pop     rc          ; restore register            
            return              ; return to caller
            endp


            ;-------------------------------------------------------
            ; Name: find_string
            ;
            ; Find a text string within the buffer
            
            ; Parameters: 
            ;   r8 - current line
            ;   rd - target string
            ;   rb.0 - character position
            ; Uses:
            ;   rf - pointer to buffer with text bytes
            ;   rc.0 - count of bytes, index of found string
            ;   r9.1 - original character position
            ; Returns:
            ;   DF = 1, match found
            ;   DF = 0, no match found
            ;   r8 - line with match
            ;   rb.0 - character position
            ;-------------------------------------------------------       
            proc  find_string
            push  rf              ; save registers
            push  rd
            push  rc
            push  r9
            
            glo   rb              ; get character position
            phi   r9              ; save in r9.1 in case never found

          
            call  find_line       ; find current line in r8
fs_nextln:  lda   ra              ; ra points to size of line to search
            lbz   fs_notfnd       ; if end of buffer, we never found it

            plo   rc              ; set up count
            load  rf, work_buf    ; set pointer to working buffer
fs_copy:    lda   ra              ; get a byte from the current line
            str   rf              ; put in working buffer 
            inc   rf              ; move pointer to next position
            dec   rc              ; count down
            glo   rc              ; check counter
            lbnz  fs_copy         ; keep going until count exhausted

            ldi   0               ; remove CRLF at end
            dec   rf
            str   rf              ; replace LF with null
            dec   rf              
            str   rf              ; replace CR with null
            
            load  rf, work_buf    ; set pointer back to beginning of source
            glo   rb              ; get original character position
            lbz   fs_search       ; if no offset, search the whole string

            str   r2              ; save cursor position in M(X)
            glo   rf              ; get low byte of buffer pointer
            add                   ; add cursor position to low byte
            plo   rf              ; save updated low byte
            ghi   rf              ; get high byte of buffer pointer
            adci  0               ; add carry to high byte
            phi   rf              ; update high byte of the buffer
            
fs_search:  call  strstr          ; check to see if string is in source
            lbdf  fs_found        ; we found it, exit with line value
            inc   r8              ; increment line count to next line
            ldi   0
            plo   rb              ; set cursor position to zero for next line
            lbr   fs_nextln       ; continue searching buffer
            
fs_found:   glo   rc              ; get offset of matching string
            str   r2              ; save offset in M(X)
            glo   rb              ; get current search position in line
            add                   ; add in offset
            plo   rb              ; set as current character for result
            call  setcurln        ; save matching line in r8 as current line
            stc                   ; set DF = 1, to indicate match 
            lbr   fs_exit
            
fs_notfnd:  call  getcurln        ; restore r8 to current line index
            ghi   r9              ; get original character position
            plo   rb              ; restore character position
            clc                   ; clear DF to indicate not found  
            
fs_exit:    pop   r9              ; restore registers
            pop   rc
            pop   rd
            pop   rf
            return 
            endp
                                   
            ;-------------------------------------------------------
            ; Name: load_buffer
            ;
            ; Open a file and read it into the text buffer
            
            ; Parameters: (file name in fname buffer) 
            ; Uses:
            ;   rf - pointer to text bytes
            ;   rd - pointer to file descripter
            ;   rc.0 - byte count
            ;   rb.1 - page limit
            ;   ra - line count
            ;   r7.0 - flags register
            ; Returns:
            ;   ra.0 = count of lines
            ;   DF = 1 - new file
            ;   DF = 0 - file loaded into buffer
            ;   (ERROR_BIT set if out of memory error)
            ;-------------------------------------------------------                       
            proc  load_buffer
            push  rf            ; save registers used    
            push  rd
            push  rc
            push  rb
            push  r7  

            load  rf, k_heap    ; check heap address
            ldn   rf            ; get page for bottom of heap
            smi   1             ; set memory limit to one page below
            phi   rb            ; save page limit in rb.1
            
            load  rf, fname
            load  rd, fildes    ; point to file descriptor     
            ldi   0             ; flags
            plo   r7
            call  o_open        ; attempt to open the file
            lbdf  new_kfile     ; jump if file does not exist
            
            call  move_buffer   ; move to buffer location in file
            load  rf, textbuf   ; point to text buffer
            load  ra, 0         ; clear line counter
            
loadlp:     push  rf            ; save buffer address
            inc   rf            ; point to position after length
            call  readln        ; read next line
            lbdf  loadeof       ; jump if eof was found

loadnz:     ldi   13            ; write cr/lf to buffer
            str   rf
            inc   rf
            ldi   10
            str   rf
            inc   rc            ; add 2 characters
            inc   rc
            pop   rf            ; recover buffer address
            glo   rc            ; get count
            str   rf            ; and write to buffer
            inc   rf            ; move buffer to next line position
            str   r2
            glo   rf
            add
            plo   rf
            ghi   rf
            adci   0
            phi   rf
            inc   ra            ; bump line count
            
            ;----- check to see if we are out of memory after reading line
            ghi   rf            ; check page for next line address
            str   r2            ; save in M(X)
            ghi   rb            ; get memory page limit 
            sm                  ; current page - limit 
            lbz  loaderr        ; at page limit, may not have enough memory for next line
  
            ; check for max line count for buffer
            glo   ra
            smi   BUF_LINES
            lbnz  loadlp        ; load up to maximum of lines

            call  count_buf     ; increment the buffer count, if needed
            call  mark_buffer   ; save location of next buffer 

            lbr   loaddn
            
loadeof:    pop   rf            ; recover buffer address
            glo   rc            ; see if bytes were read
            lbz   loaddn        ; jump if not

            ldi   13            ; write cr/lf to buffer
            str   rf
            inc   rf
            ldi   10
            str   rf
            inc   rc            ; add 2 characters
            inc   rc
            glo   rc            ; get count
            str   r2
            glo   rf
            add
            plo   rf
            ghi   rf
            adci  0
            phi   rf
loaddn:     ldi   0             ; write termination
            str   rf
            call  o_close       ; close the file
            clc                 ; clear the DF flag
new_kfile:  pop   r7            ; restore registers
            pop   rb
            pop   rc
            pop   rd
            pop   rf
            return
            
loaderr:    ldi   0             ; write termination
            str   rf
            call  o_close       ; close the file
            load  rf, e_state   ; get state byte
            ldn   rf
            ori   ERROR_BIT     ; set ERROR_BIT
            str   rf            ; save 
            clc                   
            lbr   new_kfile     ; exit
            endp

            
            ;-------------------------------------------------------
            ; Name: readln
            ;
            ; Read a line from a file into the text buffer
            ;
            ; Parameters
            ;   rf - pointer to text buffer
            ; Uses:
            ;   rc - byte count    
            ; Returns:
            ;   DF = 0, line read 
            ;   DF = 1, end of file encountered
            ;-------------------------------------------------------            
            proc  readln
            ldi   0             ; set byte count
            phi   rc
            plo   rc
readln1:    call  readbyte      ; read a byte
            lbdf  readlneof     ; jump on eof

            plo   re            ; keep a copy
            smi   10            ; look for first newline
            lbz   readln2       ; go to possible blank line
            smi   22            ; look for anything else below a space
            lbnf  readln1       ; skip over any other control characters
            lbr   readln3       ; otherwise, process printable characters
            
readln2:    call  readbyte      ; read a byte
            lbdf  readlneof     ; jump on eof

            plo   re            ; keep a copy
            smi   10            ; look for second newline
            lbz   readln4       ; exit on blank line
            smi   22            ; look for anything else below a space
            lbnf  readln2       ; skip over any other control characters
                            
readln3:    glo   re            ; recover byte
            str   rf            ; store into buffer
            inc   rf            ; point to next position
            inc   rc            ; increment character count
            call  readbyte      ; read next byte
            lbdf  readlneof     ; jump if end of file
            plo   re            ; keep a copy of read byte
            smi   32            ; make sure it is positive
            lbdf  readln3       ; loop back on valid characters
readln4:    ldi   0             ; signal valid read
readlncnt:  shr                 ; shift into DF
            return              ; and return to caller
readlneof:  ldi   1             ; signal eof
            lbr   readlncnt
            endp

            ;-------------------------------------------------------
            ; Name: readbyte
            ;
            ; Read a byte from a file into the character buffer
            ;
            ; Parameters
            ;   rf - pointer to text buffer
            ; Uses:
            ;   rc - byte count    
            ; Returns:
            ;   DF = 0, byte read 
            ;   DF = 1, end of file encountered
            ;-------------------------------------------------------
            proc  readbyte
            push  rf
            push  rc
            load  rf, k_char
            ldi   0
            phi   rc
            ldi   1
            plo   rc
            call  o_read
            glo   rc
            lbz   readbno
            ldi   0
readbcnt:   shr
            load  rf, k_char
            ldn   rf
            plo   re
            pop   rc
            pop   rf
            glo   re
            return
readbno:    ldi   1
            lbr   readbcnt
            endp

            ;-------------------------------------------------------
            ; Name: skipln
            ;
            ; Read a line from a file without saving to a buffer
            ;
            ; Parameters
            ;   (none)
            ; Uses:
            ;   rc - byte count    
            ; Returns:
            ;   DF = 0, line read 
            ;   DF = 1, end of file encountered
            ;-------------------------------------------------------            
            proc  skipln
            ldi   0             ; set byte count
            phi   rc
            plo   rc
skipln1:    call  readbyte      ; read a byte
            lbdf  skiplneof     ; jump on eof

            plo   re            ; keep a copy
            smi   10            ; look for first newline
            lbz   skipln2       ; go to possible blank line
            smi   22            ; look for anything else below a space
            lbnf  skipln1       ; skip over any other control characters
            lbr   skipln3       ; otherwise, process printable characters
            
skipln2:    call  readbyte      ; read a byte
            lbdf  skiplneof     ; jump on eof
            plo   re            ; keep a copy
            
            smi   10            ; look for second newline
            lbz   skipln4       ; exit on blank line
            smi   22            ; look for anything else below a space
            lbnf  skipln2       ; skip over any other control characters
                            
skipln3:    call  readbyte      ; read next byte
            lbdf  skiplneof     ; jump if end of file
            plo   re            ; keep a copy of read byte
            smi   32            ; make sure it is positive
            lbdf  skipln3       ; loop back on valid characters
skipln4:    ldi   0             ; signal valid read
skiplncnt:  shr                 ; shift into DF
            return              ; and return to caller
skiplneof:  ldi   1             ; signal eof
            lbr   skiplncnt
            endp

            ;-------------------------------------------------------
            ; Name: seek_lines
            ;
            ; Open a file and read it to skip over lines
            
            ; Parameters: (file name in fname buffer) 
            ;   ra - line count
            ; Uses:
            ;   rf - pointer to text bytes
            ;   rd - pointer to file descripter
            ;   rc.0 - byte count
            ;   r7.0 - flags register
            ; Returns:
            ;   DF = 1 - EOF occured before all lines skipped
            ;   DF = 0 - all lines skipped, buffer marked
            ;-------------------------------------------------------                       
            proc  seek_lines
            push  rf            ; save registers used    
            push  rd
            push  rc
            push  ra
            push  r7  

            load  rf, fname
            load  rd, fildes    ; point to file descriptor     
            ldi   0             ; flags
            plo   r7
            call  o_open        ; attempt to open the file
            lbdf  skip_err      ; jump if file does not exist
                        
skiplp:     call  skipln        ; skip next line
            lbdf  skipeof       ; jump if eof was found

            dec   ra            ; bump line count
            ; check for max line count for buffer
            ghi   ra
            lbnz  skiplp        ; skip to maximum of lines
            glo   ra
            lbnz  skiplp        ; skip up to maximum of lines
            
            ;---------------------------------------------------------
            ; mark new location as first buffer 
            ;---------------------------------------------------------
            
            call  reset_buffers ; reset all the buffers to zero
            call  count_buf     ; increment the buffer count
            call  mark_buffer   ; save location of next buffer 
            ldi   1             
            call  set_buf_index ; set index to first buffer
            
            lbr   skipdn
            
skipeof:    call  o_close       ; close the file
            stc                 ; set DF to indicate EOF error 
            lbr   skip_err
            
skipdn:     call  o_close       ; close the file
            clc                 ; clear the DF flag
            
skip_err:   pop   r7            ; restore registers
            pop   ra
            pop   rc
            pop   rd
            pop   rf
            return
            endp
            
            ; ***************************************
            ; ***      File and Data Buffers      ***
            ; ***************************************
            
            proc  fname
              ds      80        ; file name
            endp
              
            proc  fildes
              db      0,0,0,0   ; file descriptor
              dw      k_dta
              db      0,0
              db      0
              db      0,0,0,0
              dw      0,0
              db      0,0,0,0
            endp  

            proc  curline
              dw      0         ; current line variable
            endp

            proc  k_char
              db      0         ; character read from file
            endp  

            proc  k_dta
             ds      512        ; data transfer area  
            endp 
                     
            ; text buffer format
            ; byte size of line (0 if end of buffer)
.link .align para               
            proc  textbuf
              db      0
            endp
