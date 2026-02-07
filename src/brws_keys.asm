; -------------------------------------------------------------------
; A simple full screen browse based on the Kilo editor, 
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

; *******************************************************************
; ***                       Key Handlers                          ***
; *******************************************************************

            ;-------------------------------------------------------
            ; Name: do_browse
            ;
            ; Read a key and dispatch it to the appropriate 
            ; key handler until Ctrl+Q is pressed.
            ;-------------------------------------------------------       
            proc  do_browse
            ; reads character until ctrl+q is typed  
            
c_loop:     call  o_readkey       ; get a keyvalue 
            str   r2              ; save char at M(X)
        
            ; Check for printable or control char
            ; values (0-31 or 127) control
        
chk_c:      ldi   27              ; check for escape char immediately
            sd                    ; if c = <esc>
            lbz   c_esc           ; process escape sequence
            ldi   ' '             ; check for bottom of printable char
            sd                    ; DF = 1, means space or higher
            lbnf  c_ctrl          ; jump if not printable
            smi   95              ; check for DEL
            lbz   c_ctrl          ; 127 is a control char
        
c_prt:      load  rf, c_rpt       ; get repeated character
            ldn   rf          
            sm                    ; check for match with repeat 
            lbz   c_rptd          ; if match, repeated char
            ldi   0               ; otherwise clear repeated char
            str   rf
            lbr   c_loop          ; ignore everything else  
            
c_rptd:     ldx                   ; get character and check for repeated arrows
            smi   'A'             ; check for <ESC>A VT-52 sequence
            lbnf  c_unkn          ; anything below 'A' is unknown
            lbz   c_up            ; process Up Arrow key            
            smi   1               ; check for <Esc>B
            lbz   c_dwn           ; process Down Arrow key
            smi   1               ; check for <Esc>C
            lbz   c_rght          ; process Right Arrow key  
            smi   1               ; check for <Esc>D
            lbz   c_left          ; process Left Arrow key
            lbnz  c_unkn          ; Anything else is an unknown sequence

                
c_esc:      load  rf, c_rpt       ; clear repeated character
            ldi   0               ; for new escape sequence
            str    rf

            call  o_readkey       ; get control sequence introducer character
            str   r2              ; save character at M(X)  
            smi   '['             ; check for csi escape sequence
            lbz   sq_csi          ; <Esc>[ is a valid ANSI sequence

            ldx                   ; get character and check for VT-52 arrows
            smi   'A'             ; check for <ESC>A VT-52 sequence
            lbnf  c_unkn          ; anything below 'A' is unknown
            lbz   c_up            ; process Up Arrow key            
            smi   1               ; check for <Esc>B
            lbz   c_dwn           ; process Down Arrow key
            smi   1               ; check for <Esc>C
            lbz   c_rght          ; process Right Arrow key  
            smi   1               ; check for <Esc>D
            lbz   c_left          ; process Left Arrow key
            lbnz  c_unkn          ; Anything else is an unknown sequence
        
sq_csi:     call  o_readkey       ; get csi character
            stxd                  ; save character on stack
            smi   'A'             ; check for 3 character sequence
            lbdf  sq_ok           ; A and above are 3 character

            call  o_readkey       ; get closing ~ for 4 char sequence
            smi   '~'
            lbz   sq_ok           ; properly closed continue

            irx                   ; pop char from stack into D
            ldx 
            lbr   c_unkn          ; print unknown escape seq message
        
sq_ok:      irx                   ; get character from stack 
            ldx
            smi   49              ; check for <Esc>[1~ sequence
            lbz   c_home          ; process Home key
            smi   3               ; check for <Esc>[4~ sequence
            lbz   c_end           ; process End key
            smi   1               ; check for <Esc>[5~ sequence
            lbz   c_pgup          ; process PgUp key
            smi   1               ; check for <Esc>[6~ sequence
            lbz   c_pgdn          ; process PgDn key
            smi   11              ; check for <Esc>[A
            lbnf  c_unkn          ; Unknown sequence
            lbz   c_up            ; process Up Arrow key
            smi   1               ; check for <Esc>[B
            lbz   c_dwn           ; process Down Arrow key
            smi   1               ; check for <Esc>[C
            lbz   c_rght          ; process Right Arrow key  
            smi   1               ; check for <Esc>[D
            lbz   c_left          ; process Left Arrow key
            smi   22              ; check for <Esc>[Z
            lbz   c_bktab         ; process Shift-Tab 
            lbr   c_unkn          ; Anything else is unknown
                
c_ctrl:     load  rf, c_rpt       ; clear repeated character
            ldi   0               ; for control sequence
            str    rf

            ldx                   ; get control character at M(X)
            smi   2               ; check for Ctrl-B (Home)
            lbz   c_home
            smi   2               ; check for Ctrl-D (Down)
            lbz   c_dwn  
            smi   1               ; check for Ctrl-E (End)
            lbz   c_end  
            smi   1               ; check for Ctrl-F (Find)
            lbz   c_find
            smi   1               ; check for Ctrl-G (Go to Line)
            lbz   c_goto
            smi   1               ; check for Ctrl-H (Backspace)
            lbz   c_left          ; treat backspace as left arrow
            smi   1               ; check for Ctrl-I (Tab)
            lbz   c_tab
            smi   1               ; check for Ctrl-J (Left)
            lbz   c_left
            smi   1               ; check for Ctrl-K (Right)
            lbz   c_rght  
            smi   1               ; check for Ctrl-L (Left)
            lbz   c_left
            smi   1               ; check for Ctrl-M (Enter)
            lbz   c_enter
            smi   1               ; check for Ctrl-N (Down)
            lbz   c_dwn
            smi   1               ; check for Ctrl-O (PgDn)  
            lbz   c_pgdn
            smi   1               ; check for Ctrl-P (PgUp)
            lbz   c_pgup
            smi   2               ; check for Ctrl-R (Right Arrow)
            lbz   c_rght
            smi   2               ; check for Ctrl-T (Top of File)
            lbz   c_top          
            smi   1               ; check for Ctrl-U (Up)
            lbz   c_up
            smi   2               ; check for Ctrl-W (Where)
            lbz   c_where
            smi   1               ; check for Ctrl-X (Exit)
            lbz   c_exit
            smi   2               ; check for Ctrl-Z (End of File)
            lbz   c_bottom
            smi   4               ; check for Ctrl-^
            lbz   c_help
            smi   1               ; check for Ctrl-?
            lbz   c_help
           
            lbr   c_loop          ; ignore any unknown chracters  

            ;----- Control key actions
c_tab:      call  do_tab
            lbr   c_update
            
c_enter:    call  do_enter
            lbr   c_update

c_top:      call  do_top
            lbr   c_update

c_bottom:   call  do_bottom
            lbr   c_update

            ;----- 4 character CSI escape sequences
c_home:     call  do_home
            lbr   c_update

c_end:      call  do_end
            lbr   c_update

c_pgup:     call  do_pgup
            lbr   c_update      

c_pgdn:     call  do_pgdn
            lbr   c_update

c_find:     call  do_find
            lbdf  c_update        ; if found, update display                   
            lbr   c_loop          ; otherwise, just continue
            
c_goto:     call  do_goto
            lbr   c_update        ; update display                   
            
c_where:    call  do_where        ; show file location line and column
            lbr   c_loop          ; continue processing                   

#ifdef  BRWS_DEBUG           
c_unkn:     call  o_type          ; show unknown character in D
            call  o_inmsg         ; indicate not terminated properly
              db    '<?>',0
            lbr   c_loop          ; continue processing                   
#else 
c_unkn:     lbr   c_loop          ; continue processing                   
#endif

c_help:     call  do_help         ; show help information
            lbr   c_update        ; refresh screen after help text
            
;-----  3 character csi escape sequences
c_up:       call  do_up
            load  rf, c_rpt       ; set repeated character
            ldi   'A'             ; for up arrow ^[AAAA
            str    rf
            lbr   c_update
            
c_dwn:      call  do_down            
            load  rf, c_rpt       ; set repeated character
            ldi   'B'             ; for down arrow ^[BBBB
            str    rf
            lbr   c_update

c_rght:     call  do_rght
            load  rf, c_rpt       ; set repeated character
            ldi   'C'             ; for right arrow ^[CCCC
            str    rf
            lbr   c_update

c_left:     call  do_left
            load  rf, c_rpt       ; set repeated character
            ldi   'D'             ; for left arrow ^[DDDD
            str    rf
            lbr   c_update

c_bktab:    call  do_bktab
            lbr   c_update

            ;---- check refresh flag and update screen or move cursor
c_update:   load  rf, e_state     ; check refresh bit
            ldn   rf              ; get state byte
            ani   ERROR_BIT       ; check for error
            lbnz   c_error        ; if error, show message and exit       

            ldn   rf              ; get state byte again
            ani   REFRESH_BIT     ; check for refresh
            lbz   c_move          ; if no refrsh, just move cursor                        
c_redraw:   call  refresh_screen
            lbr   c_loop    

c_move:     call  o_inmsg
              db 27,'[?25l',0     ; hide cursor
#ifdef BRWS_DEBUG                  
            call  prt_status_dbg  ; always show debug status line              
#else 
            call  o_inmsg         ; reset cursor for move
              db 27,'[H',0

            load  rf, e_state     ; check refresh bit
            ldn   rf
            ani   STATUS_BIT      ; zero out all other bits, but status
            lbz   cm_cursor       ; if not status update, just move cursor
            
            call  brws_status     ; update the status message
            call  prt_status      ; update the status line
            load  rf, e_state     ; clear status bit after update
            ldn   rf
            ani   STATUS_MASK     ; clear bit
            str   rf              ; save updated editor state byte
                         
#endif

 cm_cursor: call  get_cursor
            call  move_cursor     ; move to new position
            call  o_inmsg
              db 27,'[?25h',0     ; show cursor        
            lbr   c_loop

c_error:    load  rf, mem_err     ; show out of memory error
            call  do_confirm
              
c_exit:     return
c_rpt:        db 0                ; repeated character
mem_err:      db '*** Error: Out of Memory ***',0            
            endp   
                           
            
            ;-------------------------------------------------------
            ; Name: do_home
            ;
            ; Handle the action when the Home key is pressed
            ; Parameters: 
            ;   rb.0 - current character position
            ; Uses: (None)
            ; Returns:
            ;   rb.0 - current character position
            ;-------------------------------------------------------                      
            proc  do_home
            ldi   0             ; set char position to far left
            plo   rb     
            call  scroll_left   ; update the cursor position
            return
            endp

            ;-------------------------------------------------------
            ; Name: do_end
            ;
            ; Handle the action when the End key is pressed
            ; Parameters:
            ;  rb.1 - current line length
            ;  rb.0 - current cursor position
            ; Uses:
            ; Returns:
            ;  rb.0 - updated cursor position
            ;-------------------------------------------------------                       
            proc  do_end
            ghi   rb            ; get the line length
            plo   rb            ; set character position to end of line
            call  scroll_right  ; update cursor position
            return
            endp

            ;-------------------------------------------------------
            ; Name: do_pgup
            ;
            ; Handle the action when the Page Up key is pressed
            ; Parameters: (None) 
            ; Uses:
            ;   r9 - window size
            ;   r8 - current line
            ; Returns:
            ;   r8 - current line 
            ;-------------------------------------------------------                                  
            proc  do_pgup
            call  getcurln
            glo   r8                ; check for top of buffer
            lbnz  pup_cont          ; if r8 is non-zero, continue
            ghi   r8          
            lbnz  pup_cont          ; if not top of file move up
            
            ;-------------------------------------------------------                                  
            ; If at top of buffer, move to previous buffer  
            ;-------------------------------------------------------                                  
            call  prev_buffer 
            lbdf  pup_skip          ; if no more buffers just skip
  
            call  refresh_screen
            call  brws_status       ; restore the normal status messae
            call  prt_status
            return                  ; if we loaded a new buffer we're done      

pup_cont:   call  window_size       ; get the window dimensions
            ghi   r9                ; get the window size in rows
            smi   2                 ; subtract 1 for status line            
            str   r2                ; save rows in M(X)
            glo   r8                ; get low byte of top line
            sm                      ; subtract row size from from top row
            plo   r8
            ghi   r8                ; adjust high byte for borrow
            smbi  0                 ; subtract borrow from hi byte
            phi   r8          
            lbdf  pup_ok            ; if positive, then top row is valid

            ldi   0                 ; if negative, set top row to zero
            phi   r8
            plo   r8 
pup_ok:     call  setcurln          ; save the current line
            call  find_line         ; get the current line
            ldn   ra                ; get size of current line
            smi   2                 ; adjust for one past last character
            lbdf  pup_size          ; if positive, set length
            ldi   0                 ; if negative, set length to zero
pup_size:   phi   rb                ; set rb.1 to new size
            call  scroll_up         ; set top row to new value
pup_skip:   return                  ; top row is new current row
            endp

            ;-------------------------------------------------------
            ; Name: do_pgdn
            ;
            ; Handle the action when the Page Down key is pressed
            ; Parameters: 
            ; Uses:
            ;   r9 - window size
            ;   r8 - current line
            ; Returns:
            ;   r8 - current line 
            ;-------------------------------------------------------                                  
            proc do_pgdn
            call  getcurln        ; get the current line
            call  window_size     ; get the window dimensions
            ghi   r9              ; get the window size in rows
            smi   2               ; subtract one for status line, another for index
            str   r2              ; save rows in M(X)
            glo   r8              ; get low byte of top line
            add                   ; add row size from to top row
            plo   r8
            ghi   r8              ; adjust high byte for carry
            adci  0               ; add carry to hi byte
            phi   r8
            call  find_line       ; check to see if line is valid
            lbnf  pdwn_ok         ; r8 is valid, so we are okay

            ;-------------------------------------------------------                                  
            ; If bottom of buffer, move to next buffer  
            ;-------------------------------------------------------                                  
            call  next_buffer 
            lbdf  pdwn_last       ; if no more buffers move to end

            ldi   0               ; set to bottom of screen
            phi   r8              ; from top line of buffer
            call  window_size     ; get the window dimensions
            ghi   r9              ; get the window size in rows
            smi   2               ; subtract one for status line
            plo   r8              ; set to bottom row on screen
            
            call  get_num_lines   ; get number of lines in r9
            dec   r9              ; line index is one less than number of lines
            sub16 r9, r8          ; make enough lines in buffer for screen
            lbdf  pdwn_good       ; we're good so draw it
            call  get_num_lines   ; otherwise move to last line in buffer
            dec   r9          
            copy  r9, r8          ; set current line to last line  

pdwn_good:  call  setcurln        ; set the current line in text buffer
            call  set_cursor      ; move cursor to current line
            call  find_line       ; find the line
            ldn   ra              ; get the line size of new current line
            smi   2               ; subtract CRLF
            lbdf  pdwn_sz       
            ldi   0               ; if less than zero, set to zero
pdwn_sz:    phi   rb              ; set line size for new line

            call  o_inmsg
              db 27,'[2J',0       ; clear display

            call  refresh_screen  ; redraw screen
            call  brws_status     ; restore the normal status messae
            call  prt_status
            return                ; if we loaded a new buffer we're done      
            
pdwn_last:  call  find_eob        ; otherwise find the end of current buffer
            dec   r8              ; go back to last text line
            call  find_line       ; get the last line
pdwn_ok:    call  setcurln        ; set the new currentline
            ldn   ra              ; get the line size of new current line
            smi   2               ; subtract CRLF
            lbdf  pdwn_size       
            ldi   0               ; if less than zero, set to zero
pdwn_size:  phi   rb              ; set line size for new line
            call  scroll_down     ; calculate new row offset
            return
            endp

            ;-------------------------------------------------------
            ; Name: do_up
            ;
            ; Handle the action when the Up Arrow key is pressed
            ; Parameters:
            ;   r8 - current line number
            ; Uses: (None)
            ; Returns:
            ;   r8 - updated line number
            ;   rb.1 - new line size
            ;-------------------------------------------------------                                  
            proc  do_up
            glo   r8                ; check for top of buffer
            lbnz  up_cont           ; if r8 is non-zero, continue
            ghi   r8          
            lbnz  up_cont           ; if r8 is non-zero, continue
            
            ;-------------------------------------------------------                                  
            ; If at top of buffer, move to previous buffer  
            ;-------------------------------------------------------                                  
            call  prev_buffer 
            lbdf  up_skip           ; if no more buffers just skip
  
            call  find_eob          ; move down to last line in buffer
            dec   r8                ; go back to last text line
            call  find_line         ; get the last line
up_ok:      call  setcurln          ; set the new currentline
            ldn   ra                ; get the line size of new current line
            smi   2                 ; subtract CRLF
            lbdf  up_sz       
            ldi   0                 ; if less than zero, set to zero
up_sz:      phi   rb                ; set line size for new line
            call  scroll_down       ; calculate new row offset 
    
            call  refresh_screen
            call  brws_status       ; restore the normal status messae
            call  prt_status
            return                  ; if we loaded a new buffer we're done      

up_cont:    dec   r8                ; move current line up one
            call  setcurln          ; save current line in memory
            call  find_line         ; point ra to new line
            ldn   ra                ; get size of new line (including CRLF)
            smi   2                 ; adjust for one past last character
            lbdf  up_size           ; if positive, set the length
            ldi   0                 ; if negative, set length to zero
up_size:    phi   rb                ; set rb.1 to new size
            call  scroll_up         ; update row offset
up_skip:    return
            endp
            
            ;-------------------------------------------------------
            ; Name: do_down
            ;
            ; Handle the action when the Down Arrow key is pressed
            ; Parameters:
            ;   r8 - current line number
            ; Uses:
            ;   r9 - number of rows in text buffer
            ; Returns:
            ;   r8 - updated line number
            ;-------------------------------------------------------                                  
            proc  do_down
            push  r9                  ; save scratch register
            call  get_num_lines       ; get the maximum lines
            dec   r9                  ; adjust to eliminate blank line
            call  getcurln            ; get current line
            sub16 r8,r9               ; check current line against limit
            lbnf  dwn_move            ; if current line < number lines, move down                

            ;-------------------------------------------------------                                  
            ; If bottom of buffer, move to next buffer  
            ;-------------------------------------------------------                                  
            call  next_buffer 
            lbdf  dwn_skip            ; if no more buffers, no move
  
            ldi   0
            phi   r8              ; set to top line of buffer
            plo   r8
            call  setcurln        ; set the current line in text buffer
            call  set_row_offset  ; set row offset for the top of screen
            call  set_cursor
            call  find_line       ; find the line
            ldn   ra              ; get the line size of new current line
            smi   2               ; subtract CRLF
            lbdf  dwn_sz       
            ldi   0               ; if less than zero, set to zero
dwn_sz:     phi   rb              ; set line size for new line

            call  o_inmsg
              db 27,'[2J',0           ; erase display
  
            call  refresh_screen
            call  brws_status         ; restore the normal status messae
            call  prt_status
            pop   r9
            return                    ; if we loaded a new buffer we're done      

dwn_move:   call  getcurln
            inc   r8                  ; move current line down one
            call  setcurln            ; save current line in memory
            call  find_line           ; point ra to new line
            ldn   ra                  ; get size of new line (including CRLF)
            smi   2                   ; adjust for one past last character
            lbdf  dwn_size            ; if positive set the length      
            ldi   0                   ; if negative, set length to zero
dwn_size:   phi   rb                  ; set rb.1 to new size
            call  scroll_down         ; update row offset
            
dwn_end:    pop   r9                  ; restore current line
            return

dwn_skip:   call  getcurln            ; restore r8 
            lbr   dwn_end             ; and exit            
            endp

            ;-------------------------------------------------------
            ; Name: do_left
            ;
            ; Handle the action when the Left Arrow key is pressed
            ;
            ; Parameters:
            ;   rb.0 - current character position
            ; Uses: (None)
            ; Returns:
            ;   rb.0 - updated character position
            ;-------------------------------------------------------                                  
            proc  do_left
            glo   rb            ; get current character column
            lbz   lft_up        ; move up if at left-most column
            dec   rb            ; update character column
            call  scroll_left   ; scroll if needed, update cursor position
            lbr   lft_exit

lft_up:     glo   r8            ; check for top of file
            lbnz  lft_up2       ; if r8 is non-zero, continue
            ghi   r8          
            lbz   lft_exit      ; if r8 = 0, then don't move up

lft_up2:    call  do_up         ; move up to end of previous line
            ghi   rb            ; get length of next line
            plo   rb            ; set char position to maximum
            call  scroll_right  ; move to end of line
lft_exit:   return
            endp
            
            ;-------------------------------------------------------
            ; Name: do_rght
            ;
            ; Handle the action when the Right Arrow key is pressed
            ;
            ; Parameters:
            ;   rb.1 - line size
            ;   rb.0 - current character position
            ; Uses:
            ; Returns:
            ;   rb.0 - updated character position
            ;-------------------------------------------------------                                                
            proc do_rght
            ghi   rb            ; get the line size
            lbz   rght_dwn      ; move down if empty line
            str   r2            ; save line size in M(X)
            glo   rb            ; get the current position
            sm                  ; subtract line size from char position
            lbdf  rght_dwn      ; move to beginning of next line
            inc   rb            ; otherwise increment char position
            call  scroll_right  ; scroll if needed, and adjust cursor              
            return
rght_dwn:   ldi   0             ; move to beginning column
            plo   rb
            call  do_down       ; move down to next line
            return              ; and exit
            endp


            ;-------------------------------------------------------
            ; Name: do_enter
            ;
            ; Handle the action when the Enter key is pressed
            ;-------------------------------------------------------                                                
            proc  do_enter
ent_over:   call  do_down       ; move down to next line
ent_ins:    ldi   0             ; move to beginning column
            plo   rb
            return         
            endp

            ;-------------------------------------------------------
            ; Name: do_tab
            ; Handle the action when the Tab key is pressed
            ;
            ; Parameters:
            ;  rb.1 - current line length
            ;  rb.0 - current cursor position
            ; Uses:
            ;  r9 - scratch register
            ; Returns:
            ;  rb.0 - updated cursor position
            ;-------------------------------------------------------                                                
            proc do_tab
            push  r9              ; save scratch register
            glo   rb              ; get the current position
            adi   4               ; add 4 to move past current tab stop
            ani   $FC             ; mask sum to snap to next tab stop
            plo   r9              ; save in scratch register
            smi   MAX_LINE        ; get line length
            lbdf  tab_exit        ; if (tab stop >= max line length), don't move cursor

tab_move:   glo   r9              ; get next tab stop
            plo   rb              ; update cursor column
            call  scroll_right  
tab_exit:   pop   r9
            return
            endp

            ;-------------------------------------------------------
            ; Name: do_bktab
            ; Handle the action when the Tab key is pressed
            ;
            ; Parameters:
            ;  rb.1 - current line length
            ;  rb.0 - current character position
            ; Uses: (None)
            ; Returns:
            ;  rb.0 - updated character position
            ;-------------------------------------------------------                                                
            proc do_bktab
            glo   rb            ; get the character column value
            smi   1             ; subtract 1 to move before current tab stop
            lbnf  btab_end      ; if negative, ignore back tab
            ani   $FC           ; mask sum to snap to previous tab stop
            plo   rb            ; update character position
            call  scroll_left   ; update position 
btab_end:   return
            endp
            

            ;-------------------------------------------------------
            ; Name: do_top
            ;
            ; Handle the action when the Ctrl-T key is pressed
            ;-------------------------------------------------------                                                
            proc  do_top
            push  rf              ; save register used
            load  rf, e_state     ; set refresh bit
            ldn   rf              ; get editor state byte
            ori   REFRESH_BIT     
            str   rf

            call  getcurln
            glo   r8                ; check for top of buffer
            lbnz  top_cont          ; if r8 is non-zero, continue
            ghi   r8          
            lbnz   top_cont          ; if r8 = 0, then don't move up

            ;-------------------------------------------------------                                  
            ; If at top of buffer, move to previous buffer  
            ;-------------------------------------------------------                                  
            call  prev_buffer 
            lbdf  top_skip          ; if no more buffers just skip
            
            ldi   0                 ; set current line to top
            phi   r8
            plo   r8
            call  set_row_offset    ; set row offset for the top of screen            
            call  setcurln          ; save the current line
            call  find_line         ; get the current line
            ldn   ra                ; get size of current line
            smi   2                 ; adjust for one past last character
            lbdf  top_sz            ; if positive, set length
            ldi   0                 ; if negative, set length to zero
top_sz:     phi   rb                ; set rb.1 to new size
            call  scroll_up         ; set top row to new value
            
            call  refresh_screen
            call  brws_status       ; restore the normal status messae
            call  prt_status
            pop   rf                ; restore register
            return                  ; if we loaded a new buffer we're done      

top_cont:   ldi   0                 ; if negative, set top row to zero
            phi   r8
            plo   r8 
            call  set_row_offset    ; set row offset for the top of screen            
            call  setcurln          ; save the current line
            call  find_line         ; get the current line
            ldn   ra                ; get size of current line
            smi   2                 ; adjust for one past last character
            lbdf  top_size          ; if positive, set length
            ldi   0                 ; if negative, set length to zero
top_size:   phi   rb                ; set rb.1 to new size
            call  scroll_up         ; set top row to new value
top_skip:   ldi   0                 ; set char position to far left
            plo   rb     
            call  scroll_left       
            call  home_cursor       ; set cursor position for home
            pop   rf
            return
            endp

            ;-------------------------------------------------------
            ; Name: do_bottom
            ;
            ; Handle the action when the Ctrl-Z key is pressed
            ;-------------------------------------------------------                                                
            proc  do_bottom
            push  rf                ; save register used
            push  r9                ; save scratch register
          
            load  rf, e_state       ; set refresh bit
            ldn   rf                ; get editor state byte
            ori   REFRESH_BIT     
            str   rf
            
            call  get_num_lines     ; get the maximum lines
            dec   r9                ; line index is one less than number of lines
            call  getcurln          ; get current line
            sub16 r8,r9             ; check current line against limit
            lbnf  db_move           ; if current line < number lines, just move down        
            

            ;-------------------------------------------------------                                  
            ; If bottom of buffer, move to next buffer  
            ;-------------------------------------------------------                                  
            call  next_buffer 
            lbdf  db_exit           ; if no more buffers, no move
  
  
            call  set_row_offset      ; set row offset for the top of screen
            call  set_cursor

            call  o_inmsg
              db 27,'[2J',0         ; erase display

            call  brws_status       ; restore the normal status messae
            call  prt_status
            
db_move:    call  get_num_lines     ; get total number of lines in r8
            dec   r9                ; line index is one less than number of lines
            copy  r9,r8             ; set current line to last line
            call  setcurln          ; save the current line
            call  find_line         ; get the current line
            ldn   ra                ; get size of current line
            smi   2                 ; adjust for one past last character
            lbdf  bot_size          ; if positive, set length
            ldi   0                 ; if negative, set length to zero
bot_size:   phi   rb                ; set rb.1 to new size
            ghi   rb                ; set char position to end of last line
            plo   rb  
            call  scroll_down       ; set top row to new value
            clc 
db_exit:    pop   r9
            pop   rf
            return 
            endp
            
            ;-------------------------------------------------------
            ; Name: do_where
            ; Show the character position in the file
            ;
            ; Parameters:
            ;  rb.1 - current line length
            ;  rb.0 - current character position
            ;  r8 -   current row
            ; Uses: 
            ;  r9 -   total number of lines
            ; Returns:
            ;  rb.0 - updated cursor position
            ;-------------------------------------------------------                                                
            proc  do_where
            push  rf              ; save registers
            push  rd
            push  r9
            
            ldi   0               ; set up rd for converting column index
            phi   rd
            glo   rb              ; copy column index for conversion
            plo   rd
            inc   rd              ; add one to index
            load  rf, num_buf     ; put result in number buffer
            call  f_uintout       ; convert to integer ascii string
            ldi   0               ; make sure null terminated
            str   rf              
            
            load  rd, work_buf    ; set destination pointer to work buffer 
            load  rf, dw_coltxt    
dw_hdr:     lda   rf              ; copy column header into msg buffer
            lbz   dw_cnumbr         
            str   rd
            inc   rd
            lbr   dw_hdr

dw_cnumbr:  load  rf, num_buf
dw_cnum:    lda   rf              ; copy column number into msg buffer
            lbz   dw_ln           ; add text before line
            str   rd
            inc   rd
            lbr   dw_cnum

dw_ln:      load  rf, dw_lntxt      
dw_line:    lda   rf              ; copy line label into msg buffer
            lbz   dw_lnumbr       ; then add line number
            str   rd
            inc   rd
            lbr   dw_line


dw_lnumbr:  push  rd              ; save msg pointer
            call  getcurln        ; get current line index
            copy  r8, r9          ; copy current line to convert to buffer value
            call  get_buf_line    ; convert to line value in buffer
            copy  r9, rd          ; copy index for conversion to ask        
            inc   rd              ; add one to index
            load  rf, num_buf     
            call  f_uintout       ; convert to integer ascii string
            ldi   0               ; make sure null terminated
            str   rf              
            pop   rd              ; restore msg pointer
            
            load  rf, num_buf     
dw_lnum:    lda   rf              ; copy line number into msg buffer
            lbz   dw_show        
            str   rd
            inc   rd
            lbr   dw_lnum            

dw_show:    ldi   0               ; make sure message ends in null
            str   rd
            load  rf, work_buf    ; show the location message
            call  set_status      ; in the status bar
            call  prt_status      
            call  get_cursor      ; restore cursor after status message update
            call  move_cursor

            load  rf, e_state     ; set status bit
            ldn   rf
            ori   STATUS_BIT      ; set bit to reset status after showing msg
            str   rf
            
            pop   r9              ; restore registers
            pop   rd
            pop   rf
            return
dw_coltxt:    db 'Column ',0
dw_lntxt:     db ', Line ',0
            endp

            ;-------------------------------------------------------
            ; Name: do_goto
            ; Go to the line number entered by the user.
            ;
            ; Parameters:
            ;  rb.1 - current line length
            ;  rb.0 - current character position
            ;  r8 -   current row
            ; Uses:
            ;  rf - buffer pointer
            ;  rd - destination pointer, line number
            ;  rc.0 - character limit
            ;  ra - line count
            ;  r9 - scratch register
            ; Returns:
            ;  rb.1 - current line length
            ;  rb.0 - current character position
            ;  r8 -   current row
            ;-------------------------------------------------------                                                
            proc  do_goto
            push  rf              ; save registers
            push  rd
            push  rc
            push  ra
            push  r9               
            
            ldi   0               ; set up character count
            phi   rc
            ldi   MAX_INTSTR      ; up to 5 characters in integer (0 to 65536)
            plo   rc
            load  rf, dg_prmpt    ; set prompt to enter line number
            load  rd, work_buf    ; point to working buffer for input            
            call  do_input        ; prompt user for line number
            lbnf  dg_exit         ; if nothing entered, just exit
            
            copy  r8, r9          ; save original row index in r9
            load  rf, work_buf    ; convert string in work buffer to integer  
            call  f_atoi          ; convert ASCII string to integer in rd
            lbdf  dg_notfnd       ; DF = 1, means non-numeric string
            ghi   rd
            lbnz  dg_find
            glo   rd
            lbz   dg_notfnd       ; Zero is not a valid line number 
            
            call  check_buf_line  ; check to see if line in buffer
            lbdf  dg_current      ; if in buffer, don't load new buffer
            
            
dg_find:    load  rf, dg_seeking  ; show not found message
            call  set_status      ; in the status bar
            call  prt_status      
            
            ghi   rd              ; check for number < BUF_LINES
            lbnz  dg_seek         ; > BUF_LINES, seek line
            glo   rd
            plo   re              ; save in scratch register
            smi   BUF_LINES + 1   ; check for buffer limit
            lbdf  dg_seek         ; if line not in zero buffer, seek to line
            
            
dg_begin:   call  reset_buffers   ; clear buffers to reload buffer zero
            call  load_buffer     ; load zero buffer at beginning
            
            dec   rd              ; line index is one less than line number            
            copy  rd, r8          ; set line index to new value
            
dg_current: call  find_line       ; find line in buffer
            lbdf  dg_notfnd       ; DF = 1, means line not found in text buffer

            call  setcurln        ; save the current line
            ldn   ra              ; get size of new line (including CRLF)
            smi   2               ; adjust for one past last character
            lbdf  dg_size         ; if positive set the length      
            ldi   0               ; if negative, set length to zero
dg_size:    phi   rb              ; set rb.1 to new size
            
dg_move:    sub16 r8, r9          ; did we move up or down?            
            lbdf  dg_down         ; if new line > old line index, we went down
            
dg_up:      call  getcurln        ; otherwise we went up, restore r8
            call  scroll_up       ; update row offset
            call  clear_screen    ; clear screen
            call  refresh_screen  ; refresh the screen
            lbr   dg_exit         
            
dg_down:    call  getcurln        ; restore r8
            call  scroll_down     ; update row offset
            call  clear_screen    ; clear screen
            call  refresh_screen  ; refresh clean
            lbr   dg_exit         

dg_seek:    copy  rd, ra          ; copy line number to seek
            sub16 ra, BUF_MIDDLE  ; adjust line number to be in middle of buffer
            call  seek_lines      ; seek to new buffer
            lbdf  dg_missed       ; DF means EOF encountered 
            
            sub16 ra, BUF_LINES   ; convert lines to offset (can be negative)
            load  rf, fbuf_offset ; update offset for first buffer
            ghi   ra
            str   rf
            inc   rf
            glo   ra
            str   rf              ; fbuf_offset is now set
             
            load  rf, buffer_msg  ; show buffering message
            call  set_status      ; in the status bar
            call  prt_status      
                        
            call  load_buffer     ; load the buffer with line
            
            copy  ra, r8          ; set number of lines in buffer
            call  set_num_lines     
            sub16 ra, BUF_MIDDLE  ; check for sufficent lines in buffer
            lbnf  dg_missed       ; DF = 0, means too few lines 
            
            load  r8, BUF_MIDDLE  ; load line in middle of buffer
            dec   r8              ; convert to index
            call  setcurln        ; set current line to line index
            call  seek_screen     ; set line to middle of screen
            call  clear_screen    ; clear screen
            call  refresh_screen  ; refresh clean
            lbr   dg_exit
               
dg_missed:  load  rf, dg_noline   ; show buffering message
            call  set_status      ; in the status bar
            call  prt_status
              
            load  rd, 1           ; reload line 1      
            lbr   dg_begin        ; load the beginning of file            
            
dg_notfnd:  copy  r9, r8          ; restore r8 to original value
            load  rf, dg_noline   ; show not found message
            call  set_status      ; in the status bar
            call  prt_status      
            call  get_cursor      ; restore cursor after status message update
            call  move_cursor
            
dg_exit:    load  rf, e_state     ; set status bit
            ldn   rf
            ori   STATUS_BIT      ; set bit to reset status after showing msg
            str   rf

            pop   r9              ; restore registers used
            pop   ra
            pop   rc
            pop   rd
            pop   rf
            clc                   ; clear error flag before return
            return 
            
dg_prmpt:     db 'Enter line number to go to: ',0
dg_noline:    db 'Line number not found.',0 
dg_seeking:   db 'Seeking line...',0 
            endp 


            ;-------------------------------------------------------
            ; Name: do_find
            ; Find a string of text entered by the user.
            ;
            ; Parameters:
            ;  rb.0 - current character position
            ;  r8 -   current row
            ; Uses:
            ;  rc.0 - character limit
            ;  r9 - scratch register
            ; Returns:
            ;  DF = 1, string found
            ;  DF = 0, not found
            ;  r8   - updated line position
            ;  rb.0 - updated cursor position
            ;-------------------------------------------------------                                                
            proc  do_find
            push  rf              ; save registers
            push  rd
            push  rc
            push  r9               

            ldi   0               ; set up character count
            phi   rc
            ldi   MAX_TARGET      ; up to 40 characters in filename
            plo   rc
            load  rf, df_prmpt    ; set prompt to enter search string
            call  do_input        ; prompt user to enter string
            lbnf  df_nosrch       ; if nothing entered, don't do search
            
            load  rf, work_buf    ; set source string to input
            load  rd, df_target   ; point destination to target buffer            
            call  f_strcpy        ; copy string into target buffer
              
            copy  r8, r9          ; save current line in case not found
            glo   rb              ; get character position in case not found
            phi   rc              ; save character position in rc.1
            
            load  rd, df_target   ; make sure rd points to target

df_next:    call  find_string     ; find the string in buffer
            lbdf  df_found 

df_ask:     load  rf, df_nbuff    ; set prompt to try next buffer
            call  do_confirm
            lbnf  df_none         ; if negative, don't search again
            
            call  next_buffer
            lbnf  df_nbsrch       ; if next buffer available, search it
            
            load  rf, df_redo     ; ask if we want to reset to top
            call  do_confirm
            lbnf  df_none         ; if negative, don't search again
            
            call  top_buffer      ; reset to beginning of file
            lbdf  df_single       ; if only one buffer, just reset to top 
                       
df_nbsrch:  ldi   0               
            phi   r8              ; set current line to zero
            plo   r8
            plo   rb              ; set cursor position to Zero
            plo   r9              ; clear saved position
            phi   r9
            phi   rc
            call  clear_screen    ; clear screen
            call  refresh_screen  ; r8, and rb.0 are reset
            
            call  find_string     ; search from the top
            lbdf  df_found
            lbr   df_ask          ; show not found message

df_single:  ldi   0
            phi   r8              ; set current line to zero
            plo   r8
            plo   rb              ; set cursor position to Zero
            call  find_string     ; search from the top
            lbdf  df_found
            lbr   df_ask          ; show not found message

df_found:   load  rd, df_target   ; set destination to target string            
            call  found_screen    ; recalculate row and column offsets
                        
            call  o_inmsg
               db 27,'[2J',0      ; erase display and show found string        
            call  refresh_screen  ; r8, and rb.0 are set found string
            call  get_cursor      ; get the cursor
            call  move_cursor     ; position cursor at found string
            call  o_inmsg
              db 27,'[30;43m',0   ; set colors to black on yellow text
            load  rf, df_target   ; print target string over found text 
            call  o_msg           ; to highlight found string
            call  o_inmsg
              db  27,'[0m',0      ; set text back to normal     
            load  rf, df_again    ; set prompt to search again
            call  do_confirm
            lbnf  df_done         ; if negative, don't search again

            inc   rb              ; otherwise, move to next character position
            lbr   df_next         ; and search for next string occurence
                          
df_done:    load  rf, e_state     ; set refresh bit
            ldn   rf              ; get editor state byte
            ori   REFRESH_BIT     
            str   rf

            stc
            lbr   df_exit

df_none:    copy  r9, r8          ; restore current line
            ghi   rc              ; restore character position
            plo   rb
df_nosrch:  clc                   ; DF = 0, not found 
df_exit:    pop   r9
            pop   rc
            pop   rd
            pop   rf
            return 
df_prmpt:     db 'Enter text to find: ',0
df_again:     db 'Found. Search again (Y/N)?',0
df_redo:      db 'Not Found. Search again from the top (Y/N)?',0            
df_nbuff:     db 'Not Found. Search next buffer (Y/N)?',0            
df_target:    ds MAX_TARGET+1             
              db 0
            endp 
                        
; *******************************************************************
; ***                 Control Key Handlers                        ***
; *******************************************************************

            ;-------------------------------------------------------
            ; Name: do_confirm
            ;
            ; Display a prompt and then read a key to check if 
            ; y or Y for a yes response was pressed.
            ; Parameters: (None) 
            ; Uses: 
            ;   rf - pointer to prompt string
            ; Returns: 
            ;   DF = 1, a 'Y' or 'y' was pressed
            ;   DF = 0, any other key was pressed      
            ;-------------------------------------------------------       
            proc  do_confirm        
            call  set_status
            call  prt_status      
                        
            call  o_readkey     ; get a keyvalue response 
            stxd                ; save char on stack
            call  brws_status   ; restore status message
            call  prt_status    ; update status message
            call  get_cursor    ; restore cursor after questions
            call  move_cursor   ; position cursor
            irx                 ; get response from stack
            ldx 
            smi   'Y'           ; check for positive response
            lbz   dc_yes
            smi   $20           ; lower case letters are 32 characters from upper case
            lbz   dc_yes
            ldx                 ; get character again from M(X)
            smi   27            ; check for escape character (ANSI sequence)
            lbnz  dc_no 
            call  o_readkey     ; eat ansi sequences
            smi   '['           ; check for csi escape sequence
            lbnz  dc_no         ; Anything but <Esc>[ is not ANSI, so done
                    
            call  o_readkey     ; eat next character
            smi   'A'           ; check for 3 character sequence (arrows)
            lbdf  dc_no         ; A and above are 3 character, so we are done
            
            call  o_readkey     ; eat closing ~ for 4 char sequence (PgUp, PgDn, Home, End)
dc_no:      clc                 ; DF = 0, means No response
            lbr   dc_exit
dc_yes:     stc                 ; DF = 1, means Yes response
dc_exit:    return
            endp
            
            
            ;-------------------------------------------------------
            ; Name: do_input
            ;
            ; Display a prompt and read keys for user input 
            ; until a non-printable key or a limit is reached.
            ;
            ; Parameters: 
            ;   rf - pointer to prompt string
            ;   rc.0 - number of keys to read
            ; Uses: 
            ;   rd - destination buffer
            ; Returns: 
            ;   DF = 1, input entered
            ;   DF = 0, no input
            ;-------------------------------------------------------  
            proc  do_input                                
            push  rd            ; save registers
            
            load  rd, work_buf  ; set destination to working buffer
            ldi   0
            str   rd            ; set buffer to empty string
            
di_read:    call  set_input     ; show prompt with current input
            call  prt_status      

            call  o_readkey     ; get a key value response
            str   r2            ; save at M(X) 
            smi   32            ; check for control character (below space)
            lbnf  di_end
            ldx                 ; get character
            smi   127           ; check for DEL or non-ascii (above DEL)
            lbdf  di_end
            ldx                 ; get character
            str   rd            ; save in buffer
            inc   rd            ; save in buffer
            ldi   0             ; put null at end of input
            str   rd
            dec   rc            ; count down 
            glo   rc
            lbnz  di_read       ; keep going until count exhausted
            
di_end:     call  get_cursor    ; restore cursor after questions
            call  move_cursor   ; position cursor
            load  rd, work_buf  ; set buffer back to work buffer               
            ldn   rd            ; get first character
            lbz   di_none       ; if null, no input
            stc                 ; DF = 1, for input
            lbr   di_exit       
di_none:    clc                 ; DF = 0, for no input
di_exit:    pop   rd            ; restore register
            return
            endp

            ;-------------------------------------------------------
            ; Name: do_help
            ;
            ; Show help information on screen
            ; Parameters: (None)
            ; Uses: 
            ;  rf - buffer pointer
            ; Returns: (None)
            ;-------------------------------------------------------                       
            proc  do_help
            push  rf              ; save register

            load  rf, e_state     ; set refresh bit
            ldn   rf              ; get editor state byte
            ori   REFRESH_BIT     
            str   rf              ; refresh after showing help text

            call  o_inmsg
              db 27,'[?25l',0     ; hide cursor        

            call    o_inmsg       ; position cursor at 4,4
              db 27,'[4;0H',0
              
            call  o_inmsg
              db 27,'[30;43m',0   ; set colors to black on yellow text
              
            load  rf, hlp_txt1    ; print first line of text
            call  o_msg  

            load  rf, hlp_txt2    ; print next line of text
            call  o_msg  

            load  rf, hlp_txt3    ; print next line of text
            call  o_msg  

            load  rf, hlp_txt4    ; print next line of text
            call  o_msg  

            load  rf, hlp_txt5    ; print next line of text
            call  o_msg  

            load  rf, hlp_prmpt

            call  do_confirm      ; prompt to dismiss
            clc                   ; clear DF after prompt
            
            call  o_inmsg
              db  27,'[0m',0      ; set text back to normal     

            call  o_inmsg
                db  27,'[2J',0    ; clear text     
            call   refresh_screen ; redraw screen
            call  brws_status     ; update the status message
            call  prt_status      ; update the status line  
            pop   rf              ; restore register  
            return
            
hlp_txt1:     db '+--------------------------------+-------------------------------------+',13,10
              db '| ^B, Home     Beginning of line | ^P, PgUp     Page Up                |',13,10
              db '| ^D, ^N, Down Move cursor Down  | ^X           Exit                   |',13,10,0
hlp_txt2:     db '| ^E, End      End of line       | ^K,^R, Right Move cursor Right      |',13,10
              db '| ^F           Find text string  | ^T           Top, previous buffer   |',13,10
              db '| ^G           Go to line number | ^U, Up       Move cursor Up         |',13,10,0
hlp_txt3:     db '| ^I, Tab      Move to next tab  | ^W           Show Where in file     |',13,10
              db '| ^K, ^L, Left Move cursor Left  | ^Z           Bottom, next buffer    |',13,10,0
hlp_txt4:     db '| ^M, Enter    Next line         | ^], Shift+Tab  Move to prevous tab  |',13,10,0
hlp_txt5:     db '| ^O, PgDn     Page Down         | ^?, ^^       Show this help text    |',13,10
              db '+--------------------------------+-------------------------------------+',13,10,0
hlp_prmpt:    db ' Press any key',0                            
            endp
            
            
#ifdef  BRWS_DEBUG
            ;-------------------------------------------------------
            ; Unknown Control key handler - print the hex value
            ; of the control key pressed.
            ; Parameters: 
            ;   rd.0 - control key value
            ; Uses: 
            ;   rf - buffer pointer
            ; Returns: (None)       
            ;-------------------------------------------------------
            proc  do_ctrl
            push    rf              ; save register used
            load    rf, hex_buf     ; point rf to hex buffer
            call    f_hexout2
        
            load    rf, hex_str     ; show string with hex value
            call    o_msg
            pop     rf              ; restore register
            return
            
hex_str:  db 10,13,'{'
hex_buf:  db 0,0
          db '}',0                        
            endp
#endif
