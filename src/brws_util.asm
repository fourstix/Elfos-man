; -------------------------------------------------------------------
; A simple full screen browser based on the Kilo editor, 
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
            
            extrn   size_h
            extrn   size_w
            extrn   c_pos
            extrn   col_max
            extrn   num_lines
            extrn   row_offset
            extrn   col_offset
            extrn   temp_buf
            extrn   status_msg
            extrn   exit_msg
            extrn   status_cmd
            
; *******************************************************************
; ***                    Window Utilities                         ***
; *******************************************************************
            


;-------------------------------------------------------------------------------
;                      General Register Usage                     
;  r7 - Cursor position                                      
;  r8 - Current line                                         
;  r9 - cursor limits, window size, line counter
;  ra - Text buffer pointer, buffer line count
;  rb.1 - line size                                  
;  rb.0 - char position in line 
;  rc.0 - counter, dimension value (for count)                                           
;  rc.1 - column offset
;  rd - Destination pointer, parameter register
;  rf - General buffer pointer                               
;-------------------------------------------------------------------------------


          ;-------------------------------------------------------
          ; Name: begin_browse
          ;
          ; Initialize the screen and setup the application.
          ;
          ; Parameters: (None) 
          ; Uses:
          ;   rf - buffer pointer
          ;   re.1 - Elf/OS serial byte
          ;   fname - should be set by caller
          ; Returns: 
          ;   DF = 1, error DF = 0, no error
          ;   re.1 - serial echo bit off
          ;   r8 - current line number
          ;   r7 - cursor set to home position 
          ;-------------------------------------------------------

            proc  begin_browse
            push  rf              ; save registers
            push  rd
            push  rc 
                 
            ;------ Enable raw mode
            ghi   re              ; get Elf/OS serial byte
            ani   $fe             ; clear the echo bit
            phi   re              ; restore serial byte with echo off

            ;------ initialize screen window height and width
            call  set_window_size

            call  set_status_cmd  ; set the ANSI command for status location
                                    
            ;------ Load file to edit
            call  load_buffer     ; file text buffer
            lbnf  old_file        ; if file exists, we can browse it

            ;------ Show blank screen with error msg
            call  brws_status     ; set up initial sttus message           
            call  clear_screen    ; clear the screen
            call  refresh_screen  ; print buffer to screen

            ldi   1               ; show error and wait for key press
            plo   rc
            load  rf, err_msg     ; file not found message
            call  do_input              
            lbr   bk_err          ; exit program
            
old_file:   load  rf, e_state     ; check for out of memory error
            ldn   rf              ; get state byte
            ani   ERROR_BIT       ; check for error from loading file
            lbnz   bk_mem_out     ; if error, show error message and exit       

            call  find_eob        ; get the number of lines into r8
            call  set_num_lines   ; set the maximum line value in memory     
            ldi   0               ; set line counter to first line
            phi   r8
            plo   r8
            phi   rb              ; clear out line length and character position
            plo   rb

            call  setcurln        ; set the current line in text buffer
            call  set_row_offset  ; set row offset for the top of screen
            
            ;------ Set up default status msg
            call  brws_status     ; set up initial sttus message 
          
            call  clear_screen    ; clear the screen
            call  refresh_screen  ; print buffer to screen

            call  o_inmsg
            db 27,'[?25l',0       ; hide cursor        
            call  prt_status      ; print status line
            call  home_cursor     ; set cursor position in memory
            call  o_inmsg
              db 27,'[H',0        ; home cursor on scren
            call  o_inmsg
              db 27,'[?25h',0     ; show cursor        
            clc                   ; return without error  
            
bk_exit:    pop   rc              ; restore registers
            pop   rd
            pop   rf
            return
            
bk_mem_out: call  o_inmsg         ; show file error message
              db 'File too large for memory!',10,13,0
            
bk_err:     stc                   ; return with error 
            lbr   bk_exit
            
err_msg:      db 'Error: File not found.',0
            endp



            ;-------------------------------------------------------
            ; Name: end_browse
            ;
            ; Set the serial echo bit on to disable the raw mode, 
            ; and clear the screen before exiting the application.
            ;            
            ; Parameters: (None)
            ; Uses:
            ;   re.1 - Elf/OS serial byte
            ; Returns: 
            ;   re.1 - serial echo bit on
            ;-------------------------------------------------------
            proc  end_browse 
            ;------ Disable raw mode     
            ghi   re              ; get Elf/OS serial byte
            ori   $01             ; set the echo bit
            phi   re              ; restore serial byte with echo on
            call  clear_screen    ; clear the screen
            return
            endp
                    
            ;-------------------------------------------------------
            ; Name: set_window_size
            ;
            ; Get the screen size using the ANSI cursor commands, 
            ; and set the pos_y and pos_x byte values.
            ; 
            ; Parameters: (None)
            ; Uses:
            ;   rf - buffer pointer
            ;   rd - integer value
            ;   r7 - pointer to integer byte in memory
            ; Returns:
            ;   DF = 1 if error, 0 if no error
            ;-------------------------------------------------------
            proc    set_window_size
            push    rf            ; save registers used
            push    rd
            push    r7
            
            ;----- send ANSI commands to get size of screen window
            call    o_inmsg       ; set cursor to bottom right-most position
              db 27,'[999C',27,'[999B',0
            call    o_inmsg
              db 27,'[6n',0       ; query the cursor position
            call    o_inmsg      ; send newline to get response
              db 10,13,0
            load    rf, pos_y     ; get y position first
            call    o_readkey
            smi     27            ; check for escape
            lbnz    bad_resp      ; if bad response, just return          
            call    o_readkey
            smi     '['           ; check for CSI marker
            lbnz    bad_resp      ; if bad response, just return
            
rd_pos:     call    o_readkey     ; get char in position string
            str     r2            ; save character in M(X)
            ldi     'R'
            sd                    ; check for end of string
            lbz     rd_done       
            
            ldi     ';'           
            sd                    ; check for xy separator
            lbnz    put_char
            
            load    rf, pos_x     ; point to x value position
            lbr     rd_pos        ; get next character 
            
put_char:   ldx                   ; get char from M(X)
            str     rf            ; save in position buffer
            inc     rf            ; move to next position
            lbr     rd_pos

rd_done:    load    r7, size_h    ; set memory byte pointer
            load    rf, pos_y     ; convert y value string to byte
            call    f_atoi
            glo     rd            ; rd.0 contains integer value of y
            str     r7            ; save in memory

            load    r7, size_w    ; set memory byte pointer
            load    rf, pos_x     ; convert x value string to byte
            call    f_atoi        
            glo     rd            ; rd.0 contains integer value of x
            str     r7            ; save in memory
            
            clc                   ; clear DF to indicate success 
            lbr     sz_exit       ; and exit
            
bad_resp:   stc                   ; Set DF = 1, for error
sz_exit:    pop     r7            ; restore registers used
            pop     rd
            pop     rf
            return

pos_y:    db 0,0,0,0              ; position string for y            
pos_x:    db 0,0,0,0              ; position string for x
            endp


            ;-------------------------------------------------------
            ; Name: window_height
            ;
            ; Get the screen window height as a value in RC.
            ; 
            ; Parameters: (None)
            ; Uses:
            ;   rf - buffer pointer
            ; Returns:
            ;   rc.0 - height of screen 
            ;-------------------------------------------------------            
            proc    window_height
            push    rf
            
            load    rf, size_h    ; window height value
            ldn     rf            ; get byte value
            plo     rc            ; return value in rc.0
            
            pop     rf
            return
            endp

            ;-------------------------------------------------------
            ; Name: window_width
            ;
            ; Get the screen window width as a value in RC.
            ; 
            ; Parameters: (None)
            ; Uses:
            ;   rf - buffer pointer
            ; Returns:
            ;   rc.0 - width of screen 
            ;-------------------------------------------------------            
            proc    window_width
            push    rf
            
            load    rf, size_w    ; window width value
            ldn     rf            ; get byte value
            plo     rc            ; return x value in rc.0
            
            pop     rf
            return
            endp
            
            ;-------------------------------------------------------
            ; Name: window_size
            ;
            ; Get the screen window height and width in r9
            ; 
            ; Parameters: (None)
            ; Uses:
            ;   rf - buffer pointer
            ; Returns:
            ;   r9.1 - height of screen
            ;   r9.0 - width of screen 
            ;-------------------------------------------------------            
            proc    window_size
            push    rf

            load    rf, size_h    ; height value
            ldn     rf            ; get byte value
            phi     r9            ; return height in r9.1
            
            load    rf, size_w    ; width value
            ldn     rf            ; get byte value
            plo     r9            ; return width in r9.0
            
            pop     rf
            return
            endp

            ;-------------------------------------------------------
            ; Name: set_row_offset
            ;
            ; Save the text buffer line index for the top row of  
            ; the current screen in memory.
            ; 
            ; Parameters:
            ;   r8 - text buffer line index for top row
            ; Uses:
            ;   rf - buffer pointer
            ; Returns: (None)
            ;-------------------------------------------------------            
            proc  set_row_offset
            push  rf

            load  rf, row_offset  ; top line index
            ghi   r8              ; get high index byte
            str   rf            
            inc   rf              ; point to next byte
            glo   r8              ; get low index byte
            str   rf              ; save as top line index

            load  rf, e_state     ; set refresh bit
            ldn   rf              ; get editor state byte
            ori   REFRESH_BIT     
            str   rf

            pop   rf
            return
            endp

            ;-------------------------------------------------------
            ; Name: get_row_offset
            ;
            ; Get the text buffer line index for the top row of
            ; the current screen display.
            ; 
            ; Parameters: (None)
            ; Uses:
            ;   rf - buffer pointer
            ; Returns: (None)
            ;   r8 - text buffer line index for top row
            ;-------------------------------------------------------            
            proc  get_row_offset
            push  rf

            load  rf, row_offset  ; top line index
            lda   rf              ; get high index byte
            phi   r8            
            lda   rf              ; get low index byte
            plo   r8              ; r8 has line index for top row

            pop   rf
            return
            endp

            ;-------------------------------------------------------
            ; Name: set_col_offset
            ;
            ; Save the column offset index from the left of the 
            ; the current screen in memory.
            ; 
            ; Parameters:
            ;   rb.0 - character position
            ; Uses:
            ;   rf - buffer pointer
            ; Returns:
            ;   rc.1 - column offset index
            ;-------------------------------------------------------            
            proc  set_col_offset
            push  rf

            load  rf, size_w      ; window width value
            ldn   rf              ; get width
            smi   1               ; subtract one for one based index  
            str   r2              ; save at M(X)
            glo   rb              ; get char position
            sm                    ; subract width from character position 
            lbdf  set_off         ; if positive, new offset is difference
            ldi   0               ; if negative, set to 0
set_off:    str   r2              ; save in M(X)            
            load  rf, col_offset  ; top line index
            ghi   rc              ; get current offset
            sm                    ; did it change?
            lbz   so_exit         ; if no change, just exit   
            ldx                   ; get offset
            phi   rc              ; set col offset
            str   rf              ; save in memory
            load  rf, e_state     ; set refresh bit
            ldn   rf
            ori   REFRESH_BIT
            str   rf
so_exit:    pop   rf
            return
            endp

            ;-------------------------------------------------------
            ; Name: get_col_offset
            ;
            ; Get the text buffer line index for the top row of
            ; the current screen display.
            ; 
            ; Parameters: (None)
            ; Uses:
            ;   rf - buffer pointer
            ; Returns: (None)
            ;   rc.1 - column offset for current screen
            ;-------------------------------------------------------            
            proc  get_col_offset
            push  rf

            load  rf, col_offset  ; column offset index
            lda   rf              ; get column byte
            phi   rc            

            pop   rf
            return
            endp
                          
            
            ;-------------------------------------------------------
            ; Name: set_num_lines
            ;
            ; Set the number of rows to the number of lines 
            ; in the text buffer
            ; 
            ; Parameters: 
            ;   r8 - maximum line number 
            ; Uses:
            ;   rf - buffer pointer
            ; Returns: (None)
            ;-------------------------------------------------------            
            proc  set_num_lines
            push  rf

            load  rf, num_lines   ; point to maximum line value
            ghi   r8
            str   rf
            inc   rf
            glo   r8
            str   rf  
            pop   rf
            return
            endp


            ;-------------------------------------------------------
            ; Name: get_num_lines
            ;
            ; Get the maximum number of lines from memory
            ; 
            ; Parameters: (None) 
            ; Uses:
            ;   rf - buffer pointer
            ; Returns: 
            ;   r9 - current line maximum (line limit)
            ;-------------------------------------------------------            
            proc  get_num_lines
            push  rf

            load  rf, num_lines   ; point to maximum line value
            lda   rf
            phi   r9
            ldn   rf
            plo   r9
            pop   rf
            return
            endp
            
            ;-------------------------------------------------------
            ; Name: inc_num_lines
            ;
            ; Increment the maximum number of lines in memory
            ; 
            ; Parameters: (None) 
            ; Uses:
            ;   rf - buffer pointer
            ; Returns: 
            ;   r9 - maximum number of lines (incremented)
            ;-------------------------------------------------------            
            proc  inc_num_lines
            push  rf

            load  rf, num_lines   ; point to maximum line value
            lda   rf
            phi   r9
            ldn   rf
            plo   r9
            inc   r9              ; increase count
            glo   r9              ; save low byte of new count
            str   rf
            dec   rf              ; back up rf to high byte
            ghi   r9  
            str   rf              ; save high byte of new count

            pop   rf
            return
            endp

            ;-------------------------------------------------------
            ; Name: dec_num_lines
            ;
            ; Decrement the maximum number of lines in memory
            ; 
            ; Parameters: (None) 
            ; Uses:
            ;   rf - buffer pointer
            ; Returns: 
            ;   r9 - maximum number of lines (decremented)
            ;-------------------------------------------------------            
            proc  dec_num_lines
            push  rf

            load  rf, num_lines   ; point to maximum line value
            lda   rf
            phi   r9
            ldn   rf
            plo   r9
            
            ghi   r9              ; check for zero
            lbnz  dnl_cont        ; if non zero continue
            glo   r9
            lbz   dnl_exit        ; if zero, don't decrement further
            
dnl_cont:   dec   r9              ; decrease count
            glo   r9              ; save low byte of new count
            str   rf
            dec   rf              ; back up rf to high byte
            ghi   r9  
            str   rf              ; save high byte of new count

dnl_exit:   pop   rf
            return
            endp

            ;-------------------------------------------------------
            ; Name: is_eof
            ;
            ; Determine if line index points to the end of file
            ; 
            ; Parameters:
            ;   r8 - current line index
            ; Uses:
            ;   rf - buffer pointer
            ; Returns: 
            ;   DF = 1, current line at end of file
            ;   DF = 0, current line within file
            ;   r9 - number of lines above eof
            ;-------------------------------------------------------            
            proc  is_eof
            push  rf
            load  rf, num_lines   ; point to maximum line value

            lda   rf              ; get high byte of maximum line value
            phi   r9
            lda   rf              ; get low byte of maximum line value
            plo   r9              ; r9 has maximum line value (eof)
            
            sub16 r9,r8           ; subtract current line from maximum number 
            lbnf  eof_true        ; if negative, somehow went beyond eof
            ghi   r9              ; check difference for zero
            lbnz  eof_false       ; non-zero means current line within file
            glo   r9
            lbnz  eof_false
eof_true:   stc                   ; if zero, current line at the end of file 
            lbr   eof_exit 
            
eof_false:  clc 
eof_exit:   pop   rf
            return
            endp
            
            ;-------------------------------------------------------
            ; Name: clear_screen
            ;
            ; Send the ANSI sequences to clear the screen and 
            ; home the cursor
            ; 
            ; Parameters: (None)
            ; Uses: (None)
            ; Returns: (None)
            ;-------------------------------------------------------            
            proc  clear_screen
            call  o_inmsg
              db 27,'[2J',0           ; erase display
            call  o_inmsg
              db 27,'[H',0            ; home cursor
            return
            endp 


            ;-------------------------------------------------------
            ; Name: scroll_up
            ;
            ; Calculate the row offset after the current line is  
            ; moved up towards the top of the file
            ; 
            ; Parameters: 
            ;   r8 - current line
            ; Uses:
            ;   rf - buffer pointer
            ;   r9 - row offset value
            ; Returns: 
            ;   rc.1 - column offset 
            ;   rb.1 - size of line 
            ;   rb.0 - character position clipped to end of line
            ;   r7.1 - updated cursor y position
            ;   r7.0 - updated cursor x position 
            ;-------------------------------------------------------            
            proc  scroll_up
            push  rf
            push  r9
            
            call  set_col_offset  ; set the column offset
            load  rf, row_offset  ; top line index
            lda   rf              ; get high byte
            phi   r9            
            ldn   rf              ; get low index byte
            plo   r9
            
            copy  r8, rf          ; copy current line for arithmetic
            sub16 rf, r9          ; subtract row offset from current line
            ldi   0               ; set DF value for no scroll 
            lbdf  no_upscrl       ; if current row >= row offset, no scroll
            call  set_row_offset  ; set row offset to current line
no_upscrl:  call  set_cursor      ; update cursor position
            pop  r9               ; restore registers
            pop  rf 
            return
            endp

            ;-------------------------------------------------------
            ; Name: scroll_down
            ;
            ; Calculate the row offset after the current line is  
            ; moved down towards the bottom of the file
            ; 
            ; Parameters: 
            ;   r8 - current row
            ; Uses:
            ;   rf - buffer pointer
            ;   r9 - row offset value
            ;   rc.0 - screen rows
            ; Returns: 
            ;   rb.0 - character position clipped to end of line
            ;   r7.1 - updated cursor y position
            ;   r7.0 - updated cursor x position 
            ;-------------------------------------------------------            
            proc  scroll_down
            push  rf              ; save registers used
            push  rc
            push  r9
            push  r8
          
            call  set_col_offset  ; set the column offset
            load  rf, row_offset  ; top line index
            lda   rf              ; get high byte
            phi   r9            
            ldn   rf              ; get low index byte
            plo   r9
              
            load  rf, size_h      ; height value
            ldn   rf              ; get byte value
            smi   2               ; subtract one for status line, and one for zero index
            plo   rc              ; save bottom line index
            
            str   r2              ; put on-screen rows in M(X)
            glo   r9              ; get low byte of row offset
            add                   ; add rows on-screen to row offset
            plo   r9              ; update low byte of sum 
            ghi   r9              ; update high byte with carry flag
            adci  0
            phi   r9              ; r9 = row offset + on-screen rows (bottom line)
          
            sub16 r9, r8          ; compare bottom index to current line
            ldi   0               ; set DF value for no scroll
            lbdf  no_dnscrl       ; bottom line >= current line we are okay
            
            push  r8              ; save r8 for arithmetic
            glo   rc              ; get screen rows
            str   r2              ; save in M(X)
            glo   r8              ; get low byte of row index
            sm                    ; subtract screen rows from current line
            plo   r8              ; save low byte
            ghi   r8              ; adjust highbyte for borrow
            smbi  0
            phi   r8              ; row offset = current line - screen rows
            call  set_row_offset  ; save new row offset
            pop   r8              ; restore r8 after arithmetic

no_dnscrl:  call  set_cursor      ; adjust the cursor position
            pop   r8              ; restore registers used
            pop   r9  
            pop   rc
            pop   rf
            return
            endp

            ;-------------------------------------------------------
            ; Name: scroll_left
            ;
            ; Calculate the column offset after the character   
            ; position is moved towards the beginning of the line.
            ; 
            ; Parameters: 
            ;   rb.0 - character position
            ;   rc.1 - column offset
            ; Uses:
            ;   rf - buffer pointer
            ; Returns: 
            ;   rc.1 - column offset 
            ;-------------------------------------------------------            
            proc  scroll_left
            push  rf              ; save register used
            load  rf, col_offset  ; horizontal index
            ldn   rf              ; get col offset 
            str   r2              ; save offset in M(X)
            glo   rb              ; get char position value
            sm                    ; subtract offset from Ex
            lbdf  no_lfscrl       ; if char position > col_offset, no scroll
            glo   rb              ; get the char position
            str   rf              ; set column offset to current char position
            phi   rc              ; set rc.1 to column offset
            load  rf, e_state     ; set refresh bit
            ldn   rf
            ori   REFRESH_BIT
            str   rf
no_lfscrl:  call  set_cursor      ; update cursor position
            pop   rf              ; restore register
            return 
            endp 


            ;-------------------------------------------------------
            ; Name: scroll_right
            ;
            ; Calculate the column offset after the character   
            ; position is moved towards the end of the line.
            ; 
            ; Parameters: 
            ;   rb.0 - character position
            ; Uses:
            ;   rf - buffer pointer
            ; Returns: 
            ;   DF = 0, if no scrolling occurred
            ;   DF = 1, if scrolling occurred 
            ;   rc.1 - column offset 
            ;-------------------------------------------------------            
            proc  scroll_right
            push  rf              ; save register used
            load  rf, col_offset  ; horizontal index
            ldn   rf              ; get col offset 
            str   r2              ; save offset in M(X)
            load  rf, size_w      ; window width value
            ldn   rf              ; get width value
            add                   ; add width to column offset
            smi   1               ; subtract one for 1 based index
            str   r2              ; save sum as edge of screen in M(X)      
            glo   rb              ; get char position value
            sd                    ; subtract char position from edge of screen
            lbdf  no_rtscrl       ; if char position < edge of screen, no scroll
            ldn   rf              ; get screen width
            smi   1               ; subtract one for right-most position
            str   r2              ; save in M(x)            
            glo   rb              ; get the char position
            sm                    ; subtract right-most position from char position            
            phi   rc              ; set rc.1 to column offset
            load  rf, col_offset  ; update column offset in memory
            ghi   rc              ; get new column offset
            str   rf              ; set column offset to difference
            load  rf, e_state     ; set refresh bit
            ldn   rf
            ori   REFRESH_BIT
            str   rf
              
no_rtscrl:  call  set_cursor      ; update cursor position
            pop   rf              ; restore register
            return 
            endp 

            ;-------------------------------------------------------
            ; Name: found_screen
            ;
            ; Calculate the row offset and column offset for 
            ; the screen after a string is found.
            ; 
            ; Parameters: 
            ;   rd - target string found
            ;   r8 - current row
            ; Uses:
            ;   rf - buffer pointer
            ;   r9 - row offset value
            ;   rc - screen rows
            ;   rc.0 - counter
            ; Returns: 
            ;   rc.1 - column offset
            ;   rb.1 - line size 
            ;   rb.0 - character position 
            ;   r7.1 - updated cursor y position
            ;   r7.0 - updated cursor x position 
            ;-------------------------------------------------------            
            proc  found_screen
            push  rf              ; save registers used
            push  rd
            push  r9

            load  rf, size_w      ; screen width 
            ldn   rf              ; get byte value
            smi   1               ; subtract one for zero index
            plo   rc              ; save width
            phi   r9              ; also save width in r9.1 as default 

ms_subt:    lda   rd              ; subtract length of target string
            lbz   ms_clmn         ; calculate column offset when done
            dec   rc              ; subtract length from width
            lbr   ms_subt  
            
ms_clmn:    glo   rb              ; get current character position
            str   r2              ; save in M(X) for arithmetic
            plo   r9              ; save in r9.0 to restore

            glo   rc              ; get remaining size of line
            sm                    ; check character position
            lbdf  ms_nocoff       ; if remaining len >= char position, no offset
            ghi   r9              ; get remaining length
            plo   rd              ; set column offset to remaining length
            lbr   ms_coff

ms_nocoff:  ldi   0
            plo   rd
ms_coff:    load  rf, col_offset  ; top line index
            glo   rd              ; get calculated column offset
            str   rf              ; save as new column offset
                  
            ldi   0               ; set row offset to zero initially
            phi   r9            
            plo   r9

            ldi   0               ; set high byte of counter to zero
            phi   rc
              
            load  rf, size_h      ; height value
            ldn   rf              ; get byte value
            smi   1               ; subtract one for zero index
            plo   rc              ; save bottom line index
  
            
            copy  r8, rd          ; copy current line to remaining line 
ms_subrow:  sub16 rd, rc          ; compare remaining line to screen width
            lbnf  ms_done         ; if remaining line < screen height, we are done
            add16 r9, rc          ; adjust row offset by screen height
            lbr   ms_subrow       ; keep going until done
            
ms_done:    load  rf, row_offset  ; save new row offset in r9
            ghi   r9              ; get high row offset byte
            str   rf            
            inc   rf              ; point to next byte
            glo   r9              ; get low row offset byte
            str   rf              ; save as top line index

            load  rf, col_offset  
            ldn   rf              ; get calculated column offset
            phi   rc              ; set rc.1 to new column offset
            
            call  find_line       ; get the current line
            ldn   ra              ; get size of current line
            smi   2               ; adjust for one past last character
            lbdf  ms_size         ; if positive, set length
            ldi   0               ; if negative, set length to zero
ms_size:    phi   rb              ; set rb.1 to new size
            
            call  set_cursor      ; adjust the cursor position
            pop   r9              ; restore registers used
            pop   rd
            pop   rf
            return
            endp


            ;-------------------------------------------------------
            ; Name: seek_screen
            ;
            ; Calculate the row offset for the screen after 
            ; a line is found in a buffer.
            ; 
            ; Parameters: 
            ;   r8 - current row
            ; Uses:
            ;   rf - buffer pointer
            ;   r9 - row offset value
            ;   rc - screen rows
            ;   rc.0 - counter
            ; Returns: 
            ;   rb.1 - line size 
            ;   rb.0 - character position of zero
            ;   r7.1 - updated cursor y position
            ;   r7.0 - updated cursor x position 
            ;-------------------------------------------------------            
            proc  seek_screen
            push  rf              ; save registers used
            push  rc
            push  r9

            load  rf, col_offset  ; set column offset
            ldi   0               ; column offset is zero after seek
            str   rf              ; save as new column offset
                  
            ldi   0               ; set row offset to zero initially
            phi   r9            
            plo   r9
            plo   rb              ; set column position to zero       
            
            ldi   0               ; set high byte of counter to zero
            phi   rc
              
            load  rf, size_h      ; height value
            ldn   rf              ; get byte value
            smi   1               ; subtract one for zero index
            plo   rc              ; save bottom line index
  
            
            copy  r8, rf          ; copy current line to remaining line 
ss_subrow:  sub16 rf, rc          ; compare remaining line to screen height
            lbnf  ss_done         ; if remaining line < screen height, we are done
            add16 r9, rc          ; adjust row offset by screen height
            lbr   ss_subrow       ; keep going until done
            
ss_done:    load  rf, row_offset  ; save new row offset in r9
            ghi   r9              ; get high row offset byte
            str   rf            
            inc   rf              ; point to next byte
            glo   r9              ; get low row offset byte
            str   rf              ; save as top line index

            load  rf, col_offset  
            ldn   rf              ; get calculated column offset
            phi   rc              ; set rc.1 to new column offset
            
            call  find_line       ; get the current line
            ldn   ra              ; get size of current line
            smi   2               ; adjust for one past last character
            lbdf  ss_size         ; if positive, set length
            ldi   0               ; if negative, set length to zero
ss_size:    phi   rb              ; set rb.1 to new size
            
            call  set_cursor      ; adjust the cursor position
            pop   r9              ; restore registers used
            pop   rc
            pop   rf
            return
            endp
            
            ;-------------------------------------------------------
            ; Name: refresh_screen
            ;
            ; Send the ANSI sequences and text to refresh the screen
            ; 
            ; Parameters: (None)
            ; Uses: 
            ;   rd - line pointer
            ;   rc.0 - line counter
            ; Returns: (None)
            ;-------------------------------------------------------            
            proc  refresh_screen
            push  rf
            push  rd

            ldi   0               ; clear out char counter
            phi   rd
            plo   rd                          
            
            call  o_inmsg
              db 27,'[?25l',0     ; hide cursor        

            call  o_inmsg
              db 27,'[H',0        ; home cursor

            call  getcurln          
            push  r8              ; save current line for later
            
            call  get_row_offset  ; set the current line for the top row
            call  find_line       ; set r8 and ra for top row line in text buffer    

            call  window_height   ; set up counter for lines
            dec   rc              ; skip one line for status

            call  get_col_offset  ; get the column offset into rc.1
            
prt_lines:  call  o_inmsg
              db 27,'[2K',0       ; erase line

            ghi   rc              ; get column offset
            adi   2               ; add two for the CRLF at eol
            str   r2              ; save column offset +2  into M(X)
            ldn   ra              ; get size of line
            lbz   rf_done         ; if we hit the end of buffer we are done
            sm                    ; subtract column offset +2 from line size
            lbnf  ln_skp          ; if line size - (column offset +2) < 0, skip line
            
            ghi   rc              ; get column offset
            str   r2              ; save column offset into M(X)                        
            lda   ra              ; get size again
            sm                    ; calculate difference, line size - column offset            
            plo   rd              ; set up character counter with difference
            ghi   rc              ; get column offset
            str   r2              ; save column offset in M(X)
            glo   ra              ; adjust line buffer ptr by offset
            add
            plo   ra              ; save adjust low byte
            ghi   ra              ; add carry flag into high byte
            adci  0
            phi   ra              ; ra now points to first character on-screen
              
ln_lp:      lda   ra              ; get character
            call  o_type          ; print on screen
            dec   rd              ; count down characters in line
            glo   rd              ; check counter for end of line
            lbnz  ln_lp           ; keep going for all characters on screen  
            
            lbr   ln_cont         ; continue  on
            
ln_skp:     lda   ra              ; ra points to size, so get size
            str   r2              ; save in M(X)
            glo   ra              ; add size to ra to advance to next line
            add
            plo   ra              ; update low byte
            ghi   ra              ; add carry into high byte
            adci  0
            phi   ra              ; update high byte
            
            call  o_inmsg         ; output CRLF to skip line
              db 10,13,0

ln_cont:    inc   r8              ; add one to current line value

            dec   rc              ; count down
            glo   rc              ; check counter
            lbnz  prt_lines       ; if zero done with text buffer  

rf_done:    
        
#ifdef BRWS_DEBUG
            call  prt_status_dbg  ; print debug status each time
#endif

            call  get_cursor      ; restore cursor
            call  move_cursor     ; position cursor
                
            call  o_inmsg
              db 27,'[?25h',0     ; show cursor        

            pop   r8              ; restore current line
            call  setcurln
            call  find_line       ; point ra to current line in buffer 
            lbdf  rf_err          ; if not found, set to zero 
            ldn   ra              ; get line size
            smi   2               ; subtract 2 for CRLF
            lbdf  rf_size         ; if positive, set length
rf_err:     ldi   0               ; if negative, set length to zero
rf_size:    phi   rb              ; save line size in rb.1
            load  rf, e_state     ; get editor state and clear refresh flag
            ldn   rf
            ani   REFRESH_MASK    ; clear refresh bit and status bit
            str   rf              ; save back in memory 

            pop   rd              ; restore registers used
            pop   rf
            return
            endp 

; *******************************************************************
; ***                    Cursor Utilities                         ***
; *******************************************************************

            ;-------------------------------------------------------
            ; Name: get_cursor
            ;
            ; Get the cursor position
            ; 
            ; Parameters: (None)
            ; Uses:
            ;   rf - buffer pointer
            ; Returns:
            ;   r7.1 - cursor y position (row)
            ;   r7.0 - cursor x position (column) 
            ;-------------------------------------------------------            
            proc    get_cursor
            push    rf

            load    rf, c_pos     ; cursor position value
            lda     rf            ; get y byte value
            phi     r7            ; return c_y in r9.1
            
            ldn     rf            ; get x byte value
            plo     r7            ; return c_x in r9.0
            
            pop     rf
            return
            endp
            
            ;-------------------------------------------------------
            ; Name: home_cursor
            ;
            ; Set the cursor position to home at row 1, column 1.
            ; 
            ; Parameters: (None)
            ; Uses:
            ;   rf - buffer pointer
            ; Returns:
            ;   r7 - cursor position set to row 1, column 1 (home)
            ;-------------------------------------------------------            
            proc    home_cursor
            push    rf

            load    rf, c_pos     ; cursor position value
            ldi     1             ; c_y home value is 1
            str     rf            ; save as cursor y position
            inc     rf            ; point to cursor x value
            str     rf            ; c_x home value is 1
            phi     r7            ; set R7.1 for home cursor position
            plo     r7            ; set R7.1 for home cursor position

            pop     rf
            return
            endp

            ;-------------------------------------------------------
            ; Name: set_cursor   
            ;
            ; Set the cursor position in memory after the 
            ; current line has been moved.
            ; 
            ; Parameters: 
            ;   rb.0 - current character position
            ;   r8 - current line
            ; Uses:
            ;   rf - buffer pointer
            ;   r9 - row offset
            ; Returns:
            ;   r7.1 - updated cursor y position (row)
            ;   r7.0 - updated cursor x position (column) 
            ;-------------------------------------------------------            
            proc  set_cursor
            push  rf              ; save registers used
            push  r9
            push  r8              ; save current line
          
            call  getcurln        ; set r8 to current line
            
            load  rf, row_offset  ; top line index
            lda   rf              ; get high index byte
            phi   r9            
            lda   rf              ; get low index byte
            plo   r9              ; r8 has the row offset
            
            sub16 r8, r9          ; subtract row offset from current line
            glo   r8              ; r8.0 =  current line - row offset
            adi    1              ; cursor values begin at 1, not 0
            phi   r7              ; set cursor y position
            
            load  rf, col_offset  ; horizontal index
            ldn   rf              ; get col offset 
            str   r2              ; save offset in M(X)
            glo   rb              ; get character position value
            sm                    ; subtract offset from char position
            adi   1               ; cursor values begin at 1, not 0
            plo   r7              ; set cursor x position
            
            load    rf, c_pos     ; cursor position value
            ghi     r7            ; get c_y value in r7.1
            str     rf            ; save as cursor y position
            inc     rf            ; point to cursor x value
            glo     r7            ; get c_x value in r7.0
            str     rf            ; save as cursor x position

            pop     r8
            pop     r9
            pop     rf
            return
            endp


            ;-------------------------------------------------------
            ; Name: move_cursor
            ;
            ; Move the cursor on screen
            ; 
            ; Parameters: (None)
            ;   r7 - cursor position
            ; Uses:
            ;   rf - buffer pointer
            ;   rd - hex value to convert
            ; Returns: (None)
            ;-------------------------------------------------------            
            proc    move_cursor
            push    rf
            push    rd
            
            ldi     0             ; set up rd for int to ASCII conversion
            phi     rd
            ghi     r7            ; get the cursor y value 
            plo     rd            ; save for conversion to integer
            load    rf, pos_y
            call    f_uintout
            ldi     0             ; make sure ASCII value terminated as string
            str     rf

            ldi     0             ; set up rd for int to ASCII conversion
            phi     rd
            glo     r7            ; get the cursor x value 
            plo     rd            ; save for conversion to integer
            load    rf, pos_x
            call    f_uintout
            ldi     0             ; make sure ASCII value terminated as string
            str     rf
            
            call    o_inmsg       ; send CSI for ANSI command
              db 27,'[',0
            
            load    rf, pos_y     ; send ASCII y value
            call    o_msg

            call    o_inmsg       ; send ANSI value separator
              db ';',0

            load    rf, pos_x     ; send ASCII x value
            call    o_msg

            call    o_inmsg       ; send end of ANSI command to move cursor
              db 'H',0

            pop     rd
            pop     rf
            return
pos_x:        db 0,0,0,0,0
pos_y:        db 0,0,0,0,0              
            endp

; *******************************************************************
; ***            Editor Configuration Variables                   ***
; *******************************************************************
                                              
            ;-------------------------------------------------------
            ; Name: size_h
            ;
            ; Height of screen as byte value. 
            ;-------------------------------------------------------            
            proc    size_h
              db DEF_LINES
            endp
            
            ;-------------------------------------------------------
            ; Name: size_w
            ;
            ; Width of screen as byte value. 
            ;-------------------------------------------------------            
            proc    size_w
              db DEF_COLS
            endp

            ;-------------------------------------------------------
            ; Name: c_pos
            ;
            ; Cursor position: y (column) and x (row) 
            ; Note: These values are one based for ANSI
            ;-------------------------------------------------------            
            proc    c_pos
c_y:          db 1              ; 1 to Height (size_h)
c_x:          db 1              ; 1 to Width (size_w) 
            endp

            ;-------------------------------------------------------
            ; Name: col_max
            ;
            ; Maximum size of columns displayed on screen
            ;-------------------------------------------------------            
            proc    col_max
cl_max:       db 0               ; Max line length
            endp
            
            ;-------------------------------------------------------
            ; Name: num_lines
            ;
            ; Number of lines in text buffer
            ;-------------------------------------------------------            
            proc    num_lines
ln_max:      dw 0               ; Number of rows 
            endp
            
            
            ;-------------------------------------------------------
            ; Name: row_offset
            ;
            ; Represents the index for the text line at the top of
            ; the current screen.  This value is zero based like
            ; the text buffer line index.
            ;-------------------------------------------------------                        
            proc    row_offset 
top_ln_idx:   dw    0           ; row index for top line of screen            
            endp  


            ;-------------------------------------------------------
            ; Name: col_offset
            ;
            ; Represents the index for the text column from the 
            ; left of the current screen.  This value is zero based.
            ;-------------------------------------------------------                        
            proc    col_offset 
col_idx:      db    0           ; row index for top line of screen            
            endp  


            ;-------------------------------------------------------
            ; Name: e_state
            ;
            ; Represents the state of the editor.
            ;-------------------------------------------------------                        
            proc    e_state 
ed_state:    db    0           ; editor state bits            
            endp  

; *******************************************************************
; ***                    Debug Utilities                         ***
; *******************************************************************

#ifdef BRWS_DEBUG
            ;-------------------------------------------------------
            ; Name: prt_status_dbg
            ;
            ; Print a debug message at the bottom of the screen.
            ;-------------------------------------------------------                        
            proc  prt_status_dbg
            push  r9
            push  r8              ; save current line
          
;            call  o_inmsg
;              db 27,'[25;1H',0    ; set cursor for status line

            load  rf, status_cmd  ; move cursor down to status line
            call  o_msg
                          
            copy  rb, rd          ; copy current line for conversion           
            load  rf, rb_hex
            call  f_hexout4

            call  get_col_offset  ; get cursor value in memory
            ldi   0               ; get cursor variable
            phi   rd
            ghi   rc              ; get cursor y position
            plo   rd
            load  rf, col_nmbr
            call  f_uintout
            ldi   0               ; make sure null at end of string
            str   rf    
                    
            call  getcurln        ; get text buffer current line
            copy  r8, rd          ; copy text line for conversion           
            load  rf, line_nmbr
            call  f_uintout
            ldi   0               ; make sure null at end of string
            str   rf    

            call  get_row_offset  ; get the row offset
            copy  r8, rd          ; copy row offset for conversion           
            load  rf, off_nmbr
            call  f_uintout
            ldi   0               ; make sure null at end of string
            str   rf    
            
            call  get_num_lines   ; get the max number of lines
            copy  r9, rd          ; copy max lines for conversion           
            load  rf, lmt_nmbr
            call  f_uintout
            ldi   0               ; make sure null at end of string
            str   rf    
            
            call  get_cursor      ; get cursor value in memory
            ldi   0               ; get cursor variable
            phi   rd
            ghi   r7              ; get cursor y position
            plo   rd
            load  rf, cy_nmbr
            call  f_uintout
            ldi   0               ; make sure null at end of string
            str   rf    
            

            ldi   0               ; get cursor variable
            phi   rd
            glo   r7              ; get cursor x position
            plo   rd
            load  rf, cx_nmbr
            call  f_uintout
            ldi   0               ; make sure null at end of string
            str   rf    

            load  rf, e_state     ; get the editor state byte
            ldn   rf
            plo   rd              ; copy state byte for conversion           
            load  rf, state_hex
            call  f_hexout2
            
            load  rf, stat_begin
            call  o_msg

            load  rf, rb_hex
            call  o_msg
            
            load  rf, line_lbl
            call  o_msg

            load  rf, line_nmbr
            call  o_msg

            load  rf, off_lbl
            call  o_msg

            load  rf, off_nmbr
            call  o_msg

            load  rf, col_lbl
            call  o_msg

            load  rf, col_nmbr
            call  o_msg

            load  rf, cy_lbl
            call  o_msg

            load  rf, cy_nmbr
            call  o_msg
            
            load  rf, cx_lbl
            call  o_msg

            load  rf, cx_nmbr
            call  o_msg

            load  rf, lmt_lbl
            call  o_msg

            load  rf, lmt_nmbr
            call  o_msg

            load  rf, state_lbl
            call  o_msg

            load  rf, state_hex
            call  o_msg

            load  rf, stat_end
            call  o_msg
            pop   r8
            pop   r9
            return
            
             
stat_begin:   db 27,'[37;44m^X=Exit *RB: ',0
rb_hex:       db 0,0,0,0,0
line_lbl:     db ' Ln: ',0
line_nmbr:    db 0,0,0,0,0,0 
off_lbl:      db ' Roff: ',0           
off_nmbr:     db 0,0,0,0,0,0
col_lbl:      db ' Coff: ',0
col_nmbr:     db 0,0,0,0,0,0
cy_lbl:       db ' cy: ',0            
cy_nmbr:      db 0,0,0,0,0,0 
cx_lbl:       db ' cx: ',0 
cx_nmbr:      db 0,0,0,0,0,0
lmt_lbl:      db ' #Ln: ',0 
lmt_nmbr:     db 0,0,0,0,0,0
state_lbl:    db ' E: ',0
state_hex:    db 0,0,0
stat_end:     db  27,'*',27,'[0m',0            

            endp  

            ;-------------------------------------------------------
            ; Name: prt_find_dbg
            ;
            ; Print a debug message at the bottom of the screen.
            ;-------------------------------------------------------                        
            proc  prt_find_dbg
            push  rf
            push  rd
            push  r8              ; save current line
          
            call  o_inmsg
              db 27,'[25;1H',0    ; set cursor for status line
                        
            copy  r8, rd          ; copy line index for conversion           
            load  rf, idx_hex
            call  f_hexout4

            ldi   0               ; get cursor variable
            phi   rd
            glo   rb              ; get column index
            plo   rd
            load  rf, clmn_nmbr
            call  f_uintout
            ldi   0               ; make sure null at end of string
            str   rf    
                    
;            call  get_row_offset  ; get the row offset
;            copy  r8, rd          ; copy row offset for conversion           
;            load  rf, off_nmbr
;            call  f_uintout
;            ldi   0               ; make sure null at end of string
;            str   rf    
            
;            call  get_num_lines   ; get the max number of lines
;            copy  r9, rd          ; copy max lines for conversion           
;            load  rf, lmt_nmbr
;            call  f_uintout
;            ldi   0               ; make sure null at end of string
;            str   rf    
            
            call  get_cursor      ; get cursor value in memory
            ldi   0               ; get cursor variable
            phi   rd
            ghi   r7              ; get cursor y position
            plo   rd
            load  rf, y_nmbr
            call  f_uintout
            ldi   0               ; make sure null at end of string
            str   rf    
            

            ldi   0               ; get cursor variable
            phi   rd
            glo   r7              ; get cursor x position
            plo   rd
            load  rf, x_nmbr
            call  f_uintout
            ldi   0               ; make sure null at end of string
            str   rf    

;            load  rf, e_state     ; get the editor state byte
;            ldn   rf
;            plo   rd              ; copy state byte for conversion           
;            load  rf, state_hex
;            call  f_hexout2
            
            load  rf, dbg_begin
            call  o_msg

            load  rf, idx_hex
            call  o_msg
            
            load  rf, clmn_lbl
            call  o_msg

            load  rf, clmn_nmbr
            call  o_msg

  ;          load  rf, off_lbl
  ;          call  o_msg

  ;          load  rf, off_nmbr
  ;          call  o_msg

  ;          load  rf, col_lbl
  ;          call  o_msg

  ;          load  rf, col_nmbr
  ;          call  o_msg

            load  rf, y_lbl
            call  o_msg

            load  rf, y_nmbr
            call  o_msg
            
            load  rf, x_lbl
            call  o_msg

            load  rf, x_nmbr
            call  o_msg

;            load  rf, lmt_lbl
;            load  rf, state_hex
;            call  o_msg

;            load  rf, lmt_nmbr
;            call  o_msg

;            load  rf, state_lbl
;            call  o_msg

;            call  o_msg

            load  rf, dbg_end
            call  o_msg
            pop   r8
            pop   rd
            pop   rf
            return
            
             
dbg_begin:    db 27,'[37;44m *Found at Index: ',0
idx_hex:      db 0,0,0,0,0
clmn_lbl:     db ' Col: ',0
clmn_nmbr:    db 0,0,0,0,0,0 
;off_lbl:      db ' Roff: ',0           
;off_nmbr:     db 0,0,0,0,0,0
;col_lbl:      db ' Coff: ',0
;col_nmbr:     db 0,0,0,0,0,0
y_lbl:       db ' cy: ',0            
y_nmbr:      db 0,0,0,0,0,0 
x_lbl:       db ' cx: ',0 
x_nmbr:      db 0,0,0,0,0,0
;lmt_lbl:      db ' #Ln: ',0 
;lmt_nmbr:     db 0,0,0,0,0,0
;state_lbl:    db ' E: ',0
;state_hex:    db 0,0,0
dbg_end:     db  27,'*',27,'[0m',0            

            endp  
#endif

; *******************************************************************
; ***                 Status Message Utilities                    ***
; *******************************************************************

            ;-------------------------------------------------------
            ; Name: prt_status
            ;
            ; Print a status message at the bottom of the screen.
            ;-------------------------------------------------------                        
            proc  prt_status
            push  rf
          
            load  rf, status_cmd  ; move cursor to status line
            call  o_msg

            call  o_inmsg         ; set text colors to white on blue
              db 27,'[37;44m',0

            load  rf, status_msg  ; print the status message
            call  o_msg
              
            pop   rf
            return 
            endp

            ;-------------------------------------------------------
            ; Name: set_status
            ;
            ; Set the status message text at the bottom of 
            ; the screen.
            ;
            ; Parameters: 
            ;   rF - source msg text
            ; Uses:
            ;   rd - destination pointer
            ;   rc - character counter
            ; Returns: (None)
            ;-------------------------------------------------------                        
            proc  set_status
            push  rd
            push  rc
            
            call  window_width    ; get width in rc.0
            load  rd, status_msg  ; point to destination buffer
             
ps_copy:    lda   rf              ; get a character from message source string
            lbz   ps_fill         ; if reach end of string, pad with spaces
            str   rd
            inc   rd
            dec   rc              ; count down
            glo   rc              ; check counter if at eol
            lbz   ps_end          ; if we reach window length, stop adding characters
            lbr   ps_copy         ; keep going until end of string or window length
                     
ps_fill:    ldi   ' '             ; pad rest of buffer with spaces
            str   rd
            inc   rd
            dec   rc
            glo  rc  
            lbnz ps_fill          ; keep going to end of window length
            
ps_end:     ldi   27              ; end message with 27,'[0m',0
            str   rd
            inc   rd
            ldi   '['
            str   rd
            inc   rd
            ldi   '0'
            str   rd
            inc   rd
            ldi   'm'
            str   rd
            inc   rd
            ldi   0
            str   rd 
            
            pop   rc
            pop   rd
            return
            endp  
  
            ;-------------------------------------------------------
            ; Name: set_input
            ;
            ; Set the status message text with the current input
            ; string at the bottom of the screen.
            ;
            ; Parameters: 
            ;   rF - source msg text
            ; Uses:
            ;   rd - destination pointer
            ;   rc - character counter
            ; Returns: (None)
            ;-------------------------------------------------------                        
            proc  set_input
            push  rf
            push  rd
            push  rc
            
            call  window_width    ; get width in rc.0
            load  rd, status_msg  ; point to destination buffer
             
si_copy:    lda   rf              ; get a character from message source string
            lbz   si_pad          ; if reach end of string, pad with space
            str   rd
            inc   rd
            dec   rc              ; count down
            glo   rc              ; check counter if at eol
            lbz   si_end          ; if we reach window length, stop adding characters
            lbr   si_copy         ; keep going until end of string or window length
            
si_pad:     ldi   ' '             ; add one space 
            str   rd
            inc   rd
            dec   rc              ; count down
            glo   rc              ; check counter if at eol
            lbz   si_end          ; if we reach window length, stop adding characters
            
            load  rf, work_buf    ; point to current input string
si_inp:     lda   rf              ; get a character from input string
            lbz   si_fill         ; if reach end of string, fill with spaces
            str   rd
            inc   rd
            dec   rc              ; count down
            glo   rc              ; check counter if at eol
            lbz   si_end          ; if we reach window length, stop adding characters
            lbr   si_inp          ; keep going until end of input or window length
                     
si_fill:    ldi   ' '             ; pad rest of buffer with spaces
            str   rd
            inc   rd
            dec   rc
            glo   rc  
            lbnz  si_fill          ; keep going to end of window length
            
si_end:     ldi   27              ; end message with 27,'[0m',0
            str   rd
            inc   rd
            ldi   '['
            str   rd
            inc   rd
            ldi   '0'
            str   rd
            inc   rd
            ldi   'm'
            str   rd
            inc   rd
            ldi   0
            str   rd 
            
            pop   rc
            pop   rd
            pop   rf
            return
            endp  

            ;-------------------------------------------------------
            ; Name: brws_status
            ;
            ; Set up a default status message.
            ; 
            ; Parameters: (None)
            ; Uses:
            ;   rf - buffer pointer
            ;   rd - integer value
            ;   rc - length of file name
            ; Returns:
            ;-------------------------------------------------------
            proc  brws_status
            push  rf
            push  rd
            push  rc 
            
            ;------ exit prompt comes first
            load  rf, exit_msg
            load  rd, work_buf
ds_prompt:  lda   rf 
            lbz   ds_fname        ; copy save prompt into buffer
            str   rd
            inc   rd
            lbr   ds_prompt
                            
ds_fname:   load  rf, fname       ; copy filename into status message 
            ldi   20
            plo   rc              ; limit to 20 characters
ds_fnloop:  lda   rf        
            lbz   ds_newfile      ; quit if end of string
            str   rd              ; put character in string
            inc   rd
            dec   rc              ; count down
            glo   rc
            lbnz  ds_fnloop       ; keep going until count exhausted
              
            
ds_newfile: load  rf, e_state     ; check new file bit
            ldn   rf              ; get editor state byte
            ani   NEWFILE_BIT     ; zero out all but new file bit
            lbz   ds_done         ; if bit is zero, skip new file message       
            
            load  rf, ds_newmsg   ; show new file message
ds_newloop: lda   rf 
            lbz   ds_done      
            str   rd              ; copy new file msg into buffer
            inc   rd
            lbr   ds_newloop
            
ds_done:    ldi   0
            str   rd              ; make sure string ends in null

            load  rf, work_buf    ; set status message to default message  
            call  set_status      ; set the status message
       
            pop   rc              ; restore registers
            pop   rd
            pop   rf 
            return 
ds_newmsg:    db ' Error: Not Found',0
            endp
            
; *******************************************************************
; ***                    String Utilities                         ***
; *******************************************************************

            ;-------------------------------------------------------
            ; Name: strstr
            ;
            ; Find a target string within a source string.
            ;
            ; Parameters: 
            ;   rf - pointer to source string (haystack)
            ;   rd - pointer to target string (needle)
            ; Uses:
            ;   rf - source string pointer
            ;   rd - target string pointer
            ;   rc - offset value
            ;   rb - scratch register for target
            ;   r9 - scratch register for source
            ; Returns:
            ;   DF = 0, string not found (rf = 0, rc = 0) 
            ;   DF = 1, string found
            ;   rf - points to target string within source string
            ;   rc - offset to target string within source string
            ;-------------------------------------------------------            
            proc  strstr
            push  rd          ; save registers used
            push  rb          
            push  r9 

            ldi   0           ; set index to zero
            plo   rc
            phi   rc
            copy  rf, r9      ; save original source pointer  
            copy  rd, rb      ; save original target pointer
            lda   rd          ; get first character of target
            lbz   ss_found    ; if first target character is null, consider found
            str   r2          ; save target character in M(X) for comparison
            
ss_firstc:  lda   rf          ; get first character from source
            lbz   ss_notfnd   ; if no more source characters, not found
            sm                ; compare target character with source chracter 
            lbz   ss_match    ; if match look for rest of target string
            inc   rc          ; bump index for next source character
            lbr   ss_firstc   ; repeat to check next source character
            
ss_match:   lda   rd          ; get next character of target
            lbz   ss_found    ; if we no more target characters, we found it
            str   r2          ; save target character in M(X) for comparison         

            lda   rf          ; get second character in source
            lbz   ss_notfnd   ; if we run out of source characters, not found
            sm                ; compare source character to target
            lbz   ss_match    ; if matched, keep checking
            
            copy  r9, rf      ; if no match, restore source pointer 
            inc   rc          ; move index to next character location
            add16 rf, rc      ; move source pointer to next location
            
            copy  rb, rd      ; if no match, restore target pointer
            lda   rd          ; get first target character
            str   r2          ; save in M(X) for comparison
            lbr   ss_firstc   ; repeat to check next source character
            
ss_found:   copy  rb, rd      ; restore target pointer
            copy  r9, rf      ; restore source pointer
            add16 rf, rc      ; move source pointer to matching location
            stc               ; DF = 1, means target found in source
            lbr   ss_exit   

ss_notfnd:  ldi   0           ; set rf to NULL
            plo   rf
            phi   rf
            plo   rc          ; set index to 0
            phi   rc
            clc               ; DF = 0, means not found
ss_exit:    pop   r9          ; restore sratch registers
            pop   rb
            pop   rd  
            return 
            endp

            ;-------------------------------------------------------
            ; Name: set_status_cmd
            ;
            ; Set the ANSI status line cursor command in the buffer
            ;
            ; Parameters:
            ; Uses:
            ;   rd - number to convert 
            ;   r9 - screen height and width
            ;   rf - buffer pointer
            ;-------------------------------------------------------            
            proc  set_status_cmd
            push  rf                  ; save registers
            push  rd
            push  r9
            
            call  window_size         ; get window size values in r9
            
            load  rf, status_cmd      ; write to status command buffer
            ldi   27                  ; write escape to ANSI command
            str   rf                  
            inc   rf
            ldi   '['                 ; write CSI character to ANSI command
            str   rf
            inc   rf
            ldi   0                   ; set up for integer conversion
            phi   rd                  ; height is single byte value
            ghi   r9                  ; get window height value
            adi   01                  ; ANSI is one based, adjust for last line
            plo   rd                  ; rd now has integer value for status line
            call  f_uintout           ; convert height to ASCII string
            
            ldi   ';'                 ; print rest of ANSI command string
            str   rf
            inc   rf
            ldi   '1'                 ; cursor at column one of status line
            str   rf
            inc   rf
            ldi   'H'                 ; H ends the ANSI cursor command
            str   rf
            inc   rf
            ldi   0                   ; print null at end of command string
            str   rf            
             
            pop   r9                  ; restore registers
            pop   rd
            pop   rf
            return 
            endp
            
            ;-------------------------------------------------------
            ; Name: set_count
            ;
            ; Set the buffer count
            ;
            ; Parameters: 
            ;    D - value to set
            ; Uses:
            ;   rf - destination pointer
            ; Returns: (None)
            ;-------------------------------------------------------                        
            proc  set_count
            plo   re                  ; save value in scratch register
            push  rf
            load  rf, fbuf_cnt        ; point to flag location
            glo   re                  ; get value
            str   rf                  ; save in memory
            pop   rf  
            return 
            endp
  

            ;-------------------------------------------------------
            ; Name: get_count
            ;
            ; Get the buffer count
            ;
            ; Parameters: 
            ;    (None)
            ; Uses:
            ;   rf - destination pointer
            ; Returns: 
            ;   D - value of count
            ;-------------------------------------------------------                        
            proc  get_count
            push  rf
            load  rf, fbuf_cnt        ; point to count location
            ldn   rf                  ; get count from memory
            plo   re                  ; save count in scratch register
            pop   rf                  
            glo   re                  ; get value from scratch register
            return 
            endp

            ;-------------------------------------------------------
            ; Name: count_buf
            ;
            ; Check to see if the current buffer is at the buffer
            ; count value, and increment the buffer count, if needed
            ;
            ; Parameters: 
            ;    (None)
            ; Uses:
            ;   rf - destination pointer
            ; Returns: 
            ;   D - new buffer count
            ;   DF = 1, roll-over occured
            ;   DF = 0, no roll-over
            ;-------------------------------------------------------                        
            proc  count_buf
            push  rf
            load  rf, fbuf_idx        ; get the current buffer
            ldn   rf                  ; get index for current buffer
            str   r2                  ; save in M(X)
            plo   re                  ; save in scratch register                        
            load  rf, fbuf_cnt        ; point to count location
            ldn   rf                  ; get count
            sm                        ; check to see if current buffer is last
            lbnz  cb_done             ; if not at last buffer, don't increment
            
            ldn   rf                  ; get current count
            adi   1                   ; increment count for next buffer
            plo   re                  ; save in scratch register
            smi   BUF_OVERFLOW        ; check for roll-over (D - (n+1) >= 0)
            lbnf  cb_okay             ; negative, means no roll-over
            
            ldi   1                   ; roll-over to first buffer
            plo   re                  ; update scratch register              
cb_okay:    glo   re                  ; get value from scratch register            
            str   rf                  ; save new count in memory
            
cb_done:    pop   rf
            glo   re                  ; get value for return
            return 
            endp

            ;-------------------------------------------------------
            ; Name: mark_buffer
            ;
            ; Save next buffer location in memory
            ;
            ; Parameters: 
            ;    (None)
            ; Uses:
            ;   rf - destination pointer
            ;   rd - fldes pointer
            ;   rc - flags for seek
            ;   rc.0 - counter
            ;   r8:r7 - file position
            ;
            ; Returns: 
            ;   DF
            ;-------------------------------------------------------                        
            proc  mark_buffer
            push  rf                  ; save registers used
            push  rd
            push  rc
            push  r8
            push  r7
            
            ldi   $00                 ; clear out r7, r8               
            plo   r7                  ; set seek offset to zero
            phi   r7
            plo   r8
            phi   r8
            phi   rc                  ; clear out hi byte of flags 
            ldi   1                   ; flag for current position
            plo   rc                  ; set RC to seek from EOF
            load  rd, fildes          ; set file descriptor for seek
            call  o_seek              ; seek end of file
            lbdf  mrk_err             ; DF = 1 means seek error            
            
            load  rf, fbuf_cnt        ; point to count location
            ldn   rf                  ; get count
            lbz   mrk_err             ; zero is reserved for beginning of file
            plo   rc                  ; set counter, should be non-zero

            load  rf, f_buffers       ; point to buffers table  
mrk_lp:     dec   rc                  ; count down to zero (one based)
            glo   rc                  ; check count
            lbz   mrk_ptr             ; new location at table
            
            ADD16 rf, $04             ; each position is 4 bytes
            lbr   mrk_lp              ; move and check counter  
            
mrk_ptr:    ghi   r8                  ; get hi byte of hi word of position
            str   rf                  ; save position byte in memory
            inc   rf                  ; move to next byte
            glo   r8                  ; get lo byte of hi word of position
            str   rf                  ; save position byte in memory
            inc   rf                  ; move to next byte
            ghi   r7                  ; get hi byte of lo word of position
            str   rf                  ; save position byte in memory
            inc   rf                  ; move to next byte
            glo   r7                  ; get lo byte of lo word of position
            str   rf                  ; save position byte in memory
            inc   rf                  ; move to next byte
            clc                       ; clear DF flag for no error
                        
mrk_exit:   pop   r7                  ; restore registers
            pop   r8
            pop   rc
            pop   rd
            pop   rf  
            return 
mrk_err:    stc                       ; set DF to indicate error
            lbr   mrk_exit            ; exit with an error
            endp

            ;-------------------------------------------------------
            ; Name: move_buffer
            ;
            ; Move the file position to the next location.
            ;
            ; Parameters: 
            ;    (None, File descripter set by previous open)
            ; Uses:
            ;   rf - destination pointer
            ;   rd - fldes pointer
            ;   rc - flags for seek
            ;   rc.0 - counter for buffer table 
            ;   r8:r7 - file position
            ;
            ; Returns: 
            ;    DF = 1 if error, 0 if no error
            ;-------------------------------------------------------                        
            proc  move_buffer
            push  rf                  ; save registers used
            push  rd
            push  rc
            push  r8
            push  r7

            clc                       ; clear DF in case of skip
            load  rf, fbuf_idx        ; point to current buffer
            ldn   rf                  ; get count
            lbz   mvb_skip            ; buffer 0 is beginning of file 
            plo   rc                  ; set counter to buffer index          

            load  rf, f_buffers       ; point to buffers table  
mvb_lp:     dec   rc                  ; count down to zero (one based)
            glo   rc                  ; check count
            lbz   mvb_seek            ; rf points to new location in table
            
            ADD16 rf, $04             ; each position entry is 4 bytes
            lbr   mvb_lp              ; move pointer and check counter  

mvb_seek:   lda   rf                  ; get hi byte of hi word for position
            phi   r8
            lda   rf                  ; get lo byte of hi word for position
            plo   r8
            lda   rf                  ; get hi byte of lo word for position
            phi   r7
            lda   rf                  ; get lo byte of lo word for position
            plo   r7                  ; R8:R7 now points to file position for buffer
            
            ldi   0                   ; set flags to seek from beginning of file
            phi   rc
            plo   rc                  
            load  rd, fildes          ; set pointer to file descripter
            call  o_seek              ; move to file position (DF set by seek on error)
            
mvb_skip:   pop   r7                  ; restore registers
            pop   r8
            pop   rc
            pop   rd
            pop   rf  
            return                    
            endp

            ;-------------------------------------------------------
            ; Name: next_buffer
            ;
            ; Set index to the next buffer location and load.
            ;
            ; Parameters: 
            ;    (None)
            ; Uses:
            ;   rf - destination pointer
            ;   ra - line count
            ; Returns:
            ;    rb.0 - current character position
            ;    r8 - current line 
            ;    DF = 1 if error (no more buffers)
            ;    DF = 0 if no error (next buffer)
            ;-------------------------------------------------------                        

            proc  next_buffer
            push  rf                  ; save registers used
            push  ra
            push  r9
            
            load  rf, fbuf_cnt        ; get the count
            ldn   rf          
            str   r2                  ; save count in MX
            
            load  rf, fbuf_idx
            ldn   rf
            sd                        ; subtract index from count
            lbz   nb_last             ; if idx = count, we are at last buffer
            lbdf  nb_okay             ; if index < count, we are okay to increment
        
                                      ; if index > count, we rolled over
            ldi    1                  ; set index to 1          
            str   rf
            load  rf, fbuf_offset     ; increment offset for roll-over
            lda   rf             
            phi   r9
            ldn   rf                  ; rf points to lower byte of offset
            plo   r9                  ; r9 now has previous offset value
            add16 r9,BUF_TOTAL        ; add total number of lines for roll-over
            glo   r9                  ; get lo byte of sum
            str   rf                  ; store as buffer offset
            dec   rf                  ; move back to hi byte
            ghi   r9                  ; get hi byte of sum  
            str   rf                  ; store as buffer offset
            lbr   nb_load             ; continue loading
            
nb_okay:    ldn   rf                  ; get index
            adi   1                   ; increment index
            str   rf                  ; save for load

nb_load:    load  rf, buffer_msg      ; show a message 
            call  set_status          
            call  prt_status          
            
            call  load_buffer         ; load new buffer
            copy  ra, r8              ; copy number of lines in buffer 
            call  set_num_lines       ; set the maximum line value in memory
            ;----- set position in calling logic     
            ldi   0                   ; set line counter to first line
            phi   r8
            plo   r8
            
            call  setcurln            ; set the current line in text buffer
            call  find_line
            ldn   ra                  ; get size of current line
            smi   2                   ; adjust for one past last character
            lbdf  nb_size             ; if positive, set length
            ldi   0                   ; if negative, set length to zero
nb_size:    phi   rb                  ; set rb.1 to new size
            call  set_row_offset      ; set row offset for the top of screen
            call  set_cursor
            clc                       ; clear DF flag for return
            lbr   nb_done
            
nb_last:    stc
nb_done:    pop   r9
            pop   ra
            pop   rf
            return                    
            endp

            ;-------------------------------------------------------
            ; Name: prev_buffer
            ;
            ; Set index to the previous buffer location and load.
            ;
            ; Parameters: 
            ;    (None)
            ; Uses:
            ;   rf - destination pointer
            ;   r9 - last line index
            ; Returns: 
            ;    DF = 1 if error (no previous buffer to load)
            ;    DF = 0 if no error (previous buffer)
            ;-------------------------------------------------------                        
            proc  prev_buffer
            push  rf                  ; save registers used
            push  r9
            
            load  rf, fbuf_cnt        ; get the count
            ldn   rf          
            lbz   pb_none             ; if no buffers, just exit
            str   r2                  ; save in M(X)            
            
            load  rf, fbuf_idx
            ldn   rf
            lbz   pb_none             ; buffer zero is always beginning of file
            
            sd                        ; cnt - idx >= 0, is okay (cnt >= idx)
            lbdf  pb_okay             ; otherwise, we rolled over and can't move back            
            call  reset_buffers       ; so reset all buffers to beginning of file
            lbr   pb_load             ; and load beginning of file into buffer zero
                        
pb_okay:    ldn   rf                  ; get index
            smi   1                   ; decrement index
            str   rf                  ; save for load
            lbnz  pb_load             ; if not zero, load previous buffer
            call  reset_buffers       ; reset and load beginning of file

pb_load:    load  rf, buffer_msg      ; show buffering message 
            call  set_status          
            call  prt_status          
            
            call  load_buffer         ; load new buffer
            copy  ra, r8              ; copy number of lines in buffer 
            call  set_num_lines       ; set the maximum line value in memory  
            
            call  get_num_lines       ; get total number of lines in r9
            dec   r9                  ; line index is one less than number of lines
            copy  r9,r8               ; set current line to last line
            
            call  window_size       ; get the window dimensions
            ghi   r9                ; get the window size in rows
            smi   2                 ; subtract 1 for status line            
            str   r2                ; save rows in M(X)
            glo   r8                ; get low byte of top line
            sm                      ; subtract row size from from top row
            plo   r8
            ghi   r8                ; adjust high byte for borrow
            smbi  0                 ; subtract borrow from hi byte
            phi   r8          
            lbdf  pb_ok            ; if positive, then top row is valid
            
            ldi   0                 ; if negative, set top row to zero
            phi   r8
            plo   r8 
pb_ok:      call  setcurln          ; save the current line
            call  find_line         ; get the current line
            ldn   ra                ; get size of current line
            smi   2                 ; adjust for one past last character
            lbdf  pb_size           ; if positive, set length
            ldi   0                 ; if negative, set length to zero
pb_size:    phi   rb                ; set rb.1 to new size
            call  scroll_up         ; set top row to new value
   
            call  set_row_offset    ; set row offset for the top of screen
            call  set_cursor
            clc                     ; clear DF flag for return
            lbr   pb_done           ; exit routine
            
pb_none:    stc                     ; signal that no buffer was loaded
pb_done:    pop   r9
            pop   rf  
            return                    
            endp

            ;-------------------------------------------------------
            ; Name: top_buffer
            ;
            ; Set index to the zero buffer location and load.
            ;
            ; Parameters: 
            ;    (None)
            ; Uses:
            ;   rf - destination pointer
            ;   r9 - last line index
            ; Returns: 
            ;    DF = 1 if error (already at beginning of file)
            ;    DF = 0 if no error 
            ;-------------------------------------------------------                        
            proc  top_buffer
            push  rf                  ; save registers used
            push  r9
            
            load  rf, fbuf_cnt        ; get the count
            ldn   rf          
            lbz   tb_none             ; if no buffers, just exit
            str   r2                  ; save in M(X)            
            
            load  rf, fbuf_idx
            ldn   rf
            lbz   tb_none             ; buffer zero is always beginning of file
            
            call  reset_buffers       ; so reset all buffers to beginning of file

            load  rf, buffer_msg      ; show buffering message 
            call  set_status          
            call  prt_status          
            
            call  load_buffer         ; load new buffer
            copy  ra, r8              ; copy number of lines in buffer 
            call  set_num_lines       ; set the maximum line value in memory  
            
            ldi   0                   ; set top row to zero
            phi   r8
            plo   r8 
tb_ok:      call  setcurln          ; save the current line
            call  find_line         ; get the current line
            ldn   ra                ; get size of current line
            smi   2                 ; adjust for one past last character
            lbdf  tb_size           ; if positive, set length
            ldi   0                 ; if negative, set length to zero
tb_size:    phi   rb                ; set rb.1 to new size
            call  scroll_up         ; set top row to new value
   
            call  set_row_offset    ; set row offset for the top of screen
            call  set_cursor
            clc                     ; clear DF flag for return
            lbr   tb_done           ; exit routine
            
tb_none:    stc                     ; signal that no buffer was loaded
tb_done:    pop   r9
            pop   rf  
            return                    
            endp

            ;-------------------------------------------------------
            ; Name: reset_buffers
            ;
            ; Reset buffer values to beggining of file (buffer zero)
            ;
            ; Parameters: 
            ;   (None)
            ; Uses:
            ;   rf - destination pointer
            ; Returns: 
            ;   (None)
            ;   fbuf_cnt and fbuf_idx are set to 0
            ;   fbuf_offset is set to buffer size
            ;-------------------------------------------------------                        
            proc  reset_buffers
            push  rf                  ; save registers used

            load  rf, fbuf_offset     ; reset buffer offset
            ldi   0                   ; clear hi byte
            str   rf                  
            inc   rf                  ; clear lo byte
            str   rf                  ; update offset in memory

            load  rf, fbuf_cnt        ; reset buffer count to zero
            ldi   0                   ; clear buffer count
            str   rf                  ; update buffer count in memory

            load  rf, fbuf_idx        ; reset buffer index to zero
            ldi   0                   ; clear buffer index
            str   rf                  ; update buffer index in memory
            
            pop   rf  
            return                    
            endp

            ;-------------------------------------------------------
            ; Name: get_buf_line
            ;
            ; Get the line number of a line in a buffer
            ;
            ; Parameters: 
            ;   r9 - current line number
            ; Uses:
            ;   rf - destination pointer
            ;   rc - counter
            ;   
            ; Returns: 
            ;   r9 - absolute line number
            ;-------------------------------------------------------                        
            proc  get_buf_line
            push  rf                  ; save registers used
            push  rc
            
            
            load  rf, fbuf_idx        ; adjust line number for full buffers
            ldn   rf                  ; get buffer index from memory
            lbz   gbl_done            ; buffer zero is           
            plo   rc                  ; put in counter                                  
            
gbl_lp:     dec   rc                  ; count down buffer index
            ADD16 r9, BUF_LINES       ; add number of lines in full buffer
            glo   rc                  ; check the count
            lbnz  gbl_lp              ; keep going until out of buffers

            load  rf, fbuf_offset     ; adjust line number for roll-overs
            lda   rf                  ; get roll count from memory
            phi   rc                  ; put in offset register
            ldn   rf
            plo   rc                  ; rc has offset for buffer 1
            
            ADD16 r9, rc              ; add offset to absolute value

gbl_done:   pop   rc                  ; restore registers used
            pop   rf  
            return                    
            endp


            ;-------------------------------------------------------
            ; Name: check_buf_line
            ;
            ; Check to see if a line number is a line in a buffer
            ;
            ; Parameters: 
            ;   rd - new line number
            ;   r8 - current row number
            ; Uses:
            ;   rf - destination pointer
            ;   r8 - copy of current row
            ;   r9 - starting line of buffer
            ;   
            ; Returns: 
            ;   DF = 1, line in buffer
            ;   DF = 0, line not in buffer
            ;   r8 - updated row number (original row, if not in buffer)
            ;-------------------------------------------------------                        
            proc  check_buf_line
            push  rf                  ; save registers used
            push  rd
            push  rc            
            push  r9
            
            load  r9, 1               ; line 0 is at start of buffer
            call  get_buf_line        ; convert to absolute line
            
            copy  r8, rc              ; save back up copy of current row
            copy  rd, r8              ; set new line value
            sub16 r8, r9              
            lbnf  cbl_nfnd            ; if less than start of buffer, not found 

            ghi   r8                  ; check to see if row past end of buffer
            lbnz  cbl_nfnd            ; if row past end of buffer, not found

            glo   r8                  
            smi   BUF_LINES+1         ; check with one line past buffer
            lbdf  cbl_nfnd            ; if past buffer, not found

            stc                       ; indicate line found
            lbr   cbl_exit            ; exit with r8 set to new row

cbl_nfnd:   copy  rc,r8               ; restore original row value
            clc                       ; clear DF to indicate not found

cbl_exit:   pop   r9                  ; restore registers used
            pop   rc                  
            pop   rd
            pop   rf  
            return                    
            endp

            ;-------------------------------------------------------
            ; Name: set_buf_index
            ;
            ; Set the current buffer index
            ;
            ; Parameters: 
            ;   D - current buffer index
            ; Uses:
            ;   rf - destination pointer
            ;   
            ; Returns: 
            ;   (None)
            ;-------------------------------------------------------                        
            proc  set_buf_index
            plo   re                  ; save value in scratch register
            push  rf                  ; save registers used
            
            
            load  rf, fbuf_idx        ; adjust line number for full buffers
            glo   re                  ; get value from scratch register
            str   rf                  ; store as new index
            pop   rf                  ; restore registers
            return                    
            endp

; *******************************************************************
; ***                   Strings and Buffers                       ***
; *******************************************************************

            ;-------------------------------------------------------
            ; Name: exit_msg
            ;
            ; Status message to save files. 
            ;-------------------------------------------------------            
            proc  exit_msg
save_txt:     db  '^X=Exit ^?=Help ',0
            endp

            ;-------------------------------------------------------
            ; Name: buffer_msg
            ;
            ; Status message to load new buffer. 
            ;-------------------------------------------------------            
            proc  buffer_msg
buffer_txt:   db  'Buffering...',0
            endp


            ;-------------------------------------------------------
            ; Name: status_msg
            ;
            ; Buffer for editing the current status message
            ;-------------------------------------------------------            
            proc  status_msg
status_txt:   ds  128
            endp

            
            ;-------------------------------------------------------
            ; Name: line_buf
            ;
            ; Buffer for editing the current line of text
            ;-------------------------------------------------------            
            proc  line_buf
ln_buf:       ds  128
            endp

            ;-------------------------------------------------------
            ; Name: work_buf
            ;
            ; Buffer for utility routines
            ;-------------------------------------------------------            
            proc  work_buf
wrk_buf:      ds  128
            endp

            ;-------------------------------------------------------
            ; Name: file_buf
            ;
            ; Buffer offsets for browsing a large file
            ;-------------------------------------------------------            
            proc  f_buffers
fl_buf:       ds  128                 ; the rest are tbd
            endp

            ;-------------------------------------------------------
            ; Name: fbuf_cnt
            ;
            ; Count of buffers used to browse a large file
            ;-------------------------------------------------------            
            proc  fbuf_cnt
fb_cnt:       db  0
            endp
            
            ;-------------------------------------------------------
            ; Name: fbuf_idx
            ;
            ; Current buffer in use to browse a large file
            ;-------------------------------------------------------            
            proc  fbuf_idx
fb_idx:       db  0
            endp

            ;-------------------------------------------------------
            ; Name: fbuf_offset
            ;
            ; Roll-over count for buffers when browsing a large file
            ;-------------------------------------------------------            
            proc  fbuf_offset
fb_off:       dw  0
            endp

            ;-------------------------------------------------------
            ; Name: num_buf
            ;
            ; Buffer for number conversions
            ;-------------------------------------------------------            
            proc  num_buf
nmbr_buf:     db 0,0,0,0,0,0
            endp

            ;-------------------------------------------------------
            ; Name: status_cmd
            ;
            ; Buffer for ANSI status cursor command
            ;-------------------------------------------------------            
            proc  status_cmd
stat_cmd:     ds 10
            endp
