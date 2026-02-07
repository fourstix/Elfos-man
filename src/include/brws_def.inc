; -------------------------------------------------------------------
; Routines to support a screen editor based on the Kilo editor, 
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


;-------------------------------------------------------------------------------
; Uncomment to enable Debug code 
;-------------------------------------------------------------------------------
;#define  BRWS_DEBUG  1

;-------------------------------------------------------------------------------
; Default Screen Size Constants
;-------------------------------------------------------------------------------
#define DEF_LINES 24
#define DEF_COLS  80

;-------------------------------------------------------------------------------
; Maximum Line Size and Column Position 
;-------------------------------------------------------------------------------
#define MAX_LINE  124 
#define MAX_COL   123 
#define MAX_FNAME  19
#define MAX_INTSTR  5
#define MAX_TARGET 40

;-------------------------------------------------------------------------------
; Number of Buffers  
;-------------------------------------------------------------------------------
#define BUF_COUNT  32 

;-------------------------------------------------------------------------------
; One past Number of Buffers  
;-------------------------------------------------------------------------------
#define BUF_OVERFLOW  33 

;-------------------------------------------------------------------------------
; Number Lines in single Buffer 
;-------------------------------------------------------------------------------
#define BUF_LINES  120

;-------------------------------------------------------------------------------
; Number of Lines in all Buffers (32 * BUF_LINES)
;-------------------------------------------------------------------------------
#define BUF_TOTAL   3840

;-------------------------------------------------------------------------------
; Number Lines in middle of Buffer (BUF_LINES / 2) 
;-------------------------------------------------------------------------------
#define BUF_MIDDLE  60

;-------------------------------------------------------------------------------
; Editor State bits
;-------------------------------------------------------------------------------
#define DIRTY_BIT     $80
#define DIRTY_MASK    $7F
#define REFRESH_BIT   $40
#define REFRESH_MASK  $BF 
#define MODE_BIT      $20
#define MODE_MASK     $DF
#define NEWFILE_BIT   $10
#define NEWFILE_MASK  $EF
#define STATUS_BIT    $08
#define STATUS_MASK   $F7
#define ERROR_BIT     $01
#define ERROR_MASK    $FE

;---- Mask for clearing dirty and new file bits at same time (file saved)
#define SAVED_MASK    $6F
;---- Mask for clearing refresh and status bits at same time (screen updated)
#define SCREEN_MASK   $B7
#define SCREEN_UPDATE $48


;-------------------------------------------------------------------------------
; Utility routines used by browser
;-------------------------------------------------------------------------------
            extrn   set_window_size
            extrn   window_height
            extrn   window_width 
            extrn   window_size
            extrn   clear_screen
            extrn   set_cursor
            extrn   get_cursor
            extrn   move_cursor
            extrn   home_cursor
            extrn   scroll_up
            extrn   scroll_down
            extrn   scroll_left
            extrn   scroll_right
            extrn   refresh_screen
            extrn   refresh_line
            extrn   set_row_offset
            extrn   get_row_offset
            extrn   set_col_offset
            extrn   get_col_offset
            extrn   set_num_lines
            extrn   get_num_lines
            extrn   inc_num_lines
            extrn   dec_num_lines
            extrn   prt_status
            extrn   pad_line
            extrn   e_state
            extrn   work_buf
            extrn   num_buf
            extrn   set_status
            extrn   set_input
            extrn   begin_browse
            extrn   end_browse
            extrn   strstr
            extrn   prt_status_dbg
            extrn   prt_find_dbg
            extrn   brws_status
            extrn   clr_file_bits
            extrn   is_eof
            extrn   found_screen
            extrn   fbuf_cnt
            extrn   fbuf_idx
            extrn   count_buf
            extrn   get_count
            extrn   set_count
            extrn   set_status_cmd
            extrn   mark_buffer
            extrn   move_buffer
            extrn   next_buffer
            extrn   prev_buffer
            extrn   reset_buffers
            extrn   fbuf_offset
            extrn   get_buf_line
            extrn   buffer_msg
            extrn   set_buf_index
            extrn   top_buffer
            extrn   seek_screen
            extrn   check_buf_line


;-------------------------------------------------------------------------------
; Key handler routines used by browser
;-------------------------------------------------------------------------------

            extrn   do_browse
            extrn   do_home
            extrn   do_mode
            extrn   do_del 
            extrn   do_end
            extrn   do_pgup
            extrn   do_pgdn
            extrn   do_up
            extrn   do_down
            extrn   do_left
            extrn   do_rght
            extrn   do_backspace
            extrn   do_tab
            extrn   do_bktab
            extrn   do_enter
            extrn   do_return
            extrn   do_newline
            extrn   do_top
            extrn   do_bottom
            extrn   do_quit
            extrn   do_confirm
            extrn   do_where
            extrn   do_input
            extrn   do_goto
            extrn   do_find
            extrn   do_help  

;-------------------------------------------------------------------------------
; File routines used by browser
;-------------------------------------------------------------------------------            
                        
            extrn   find_eob
            extrn   find_line
            extrn   getcurln
            extrn   setcurln
            extrn   fname 
            extrn   load_buffer
            extrn   skip_lines
            extrn   find_string
            extrn   set_page
            extrn   check_page
            extrn    seek_lines
            extrn   fildes
            extrn   f_buffers
          
