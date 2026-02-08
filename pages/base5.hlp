Elf/OS v5 Base Utilities

More information is available via the help command or additional man pages.

BTCHECK - Check boot sector integrity
Usage: btcheck [options]
       -s = Set integrity value

CHDIR - Change/View current directory
Usage: chdir       - Show current directory
       chdir path  - Change current directory to specified path

CHMOD - Change file flags
Usage: chmod [options] filename

CLS - Clear screen
Usage: cls

COPY - Copy a file
Usage: copy [options] src dest
      src          - Filename of file to copy
      dest         - Destination pathname

CREATE - Create a disk file
Usage: create [options] filename

CRC - Display CRC-16 value for a file
Usage: CRC file  - Compute and show CRC-16 for file

DATE - Get/set system date/time
Usage: date                      - Show current date/time
       date mm/dd/yyyy           - Set date

DEL - Delete a file
Usage: del pathname
       pathname    - Pathname of file to delete

DIR - Show directory
Usage: dir [options] [path]

DO - Run a script file
Usage: do scriptfile

DUMP - Dump memory contents to disk
Usage: dump [options]

Notes: dump will prompt for the starting address, ending address, and
       the name of the file to dump to.

ECHO - Echo message to terminal
Usage: echo message

ECHOON - Turn on terminal echo flag
Usage: echoon

ECHOOFF - Turn off terminal echo flag
Usage: echooff

EDIT - Edit an ASCII file
Usage: edit file
            file - File to edit.  The file will be created
                   if it does not exist.

Notes: Once edit is running you will get a '>' prompt.
             Q - Exit to Elf/OS

EXEC - Execute a program already in memory
Usage: exec addr
            addr   - Address to begin execution at

FREE - Show disk usage
Usage: free

Notes: This program will show the total number of AUs per disk as well
       as how many AUs are currently free.

FSCK - File System Check
Usage: fsck           - scan current disk and report errors
       fsck -f        - scan current disk and fix any errors

Notes: See fsck man page for more info.

HALT - Halt the system
Usage: halt

HEAP - Heap operations tool
Usage: heap [options]

HELP - View help pages
Usage:
  help                - List topics contained in base help library
  help topic          - Show help on the specified topic
  help cat:topic      - Show help on topic from specific category
  help cat:           - Show topics contained within a category
  help -c             - List available categories

HEXDUMP - Show contents of a file in hex format
Usage: hexdump file
               file - File to show the contents of

HIMEM - Show/Set High Memory pointer
Usage: himem       - Show current high memory pointer
       himem addr  - Set high memory pointer to addr

ICALC - A 16-bit integer calculator
Usage: icalc

Notes: After icalc is loaded you will get a '>' prompt.
       The command :bye will return to Elf/OS

       See icalc man page for more info.

LBR - Manage a group of files as a library
Usage:
  Add files to library:       lbr a libname file [file ... ]
  List files in library:      lbr l libname
  Extract files from library: lbr e libname

Notes: .lbr is assumed as the filetype for libname and should NOT be included
in the names in the above commands.

LOAD - Load an executable file into memory without executing it
Usage: load file
            file   - File to load into memory

Notes: After loading the file, the start address and exec address for
       the program will be displayed.

MINIMON - Mini monitor for changing/viewing memory
Usage: minimon

Notes: After minimon is loaded you will get a '>' prompt.
       The command / will return to Elf/OS

MKDIR - Make directory
Usage: mkdir path
             path  - Name of directory to create

MOVE - Move a file
Usage: copy src dest
      src          - Filename of file to copy
      dest         - Destination pathname

This command moves a file from one directory to another.  src
must be a file and dest must be a directory

NVR - Mini monitor for changing/viewing non-volitile memory
Usage: nvr

Notes: After nvr is loaded you will get a 'NVR>' prompt.
       The command / will return to Elf/OS

       Not all systems have NV memory.  If the system does not have
       any NV memory then this program will exit in error.

PROMPT - Show a message and then wait for input
Usage: prompt message


REBOOT - Reboot Elf/OS
Usage: reboot

RENAME - Rename a file
Usage: rename old new
              old  - Old filename
              new  - New filename

Notes: rename cannot be used to move a file from one directory to another,
       you must use the copy command to move a file.

RETVAL - Show the exit value from the last program run
Usage: retval

RMDIR - Remove a directory
Usage: rmdir path
             path  - Path of directory to remove

Notes: The directory must be empty to remove it.

SAVE - Save memory contents to executable file
Usage: save

Notes: save will prompt for the starting address in memory, the ending
       address in memory, the execution address, and the filename to save to.

SCANDIR - Scan a directory and fix invalid file names
Usage: scandir dirname

Notes:  Scandir will scan a directory and replace invalid characters in filenames
        with an underscore. so for example if you had a file called '/file' after
        running scandir the file will be named '_file'.  This will allow you to
        again access files that for whatever reason have invalid characters in
        their names.

        This tool only scans the specified directory, not the whole file system.

SEDIT - Hard disk sector editor
Usage: sedit

Notes: After sedit is loaded you will get a '>' prompt.
       The Q command will Quit back to Elf/OS

SETBAUD - Set termina baud rate
Usage: setbaud

STAT - Show file statistics
Usage: stat file

SYSINFO - Show system information
Usage: sysinfo

TOUCH - Touch a file
Usage: touch file

Touching a file will set its A flag as well as setting the file's
date/time to the current system date/time.

TRUNC - Change a file's size
Usage: trunc file size
                  size   - file size as specified in bytes

Note: trunc changes the file's size, this could be smaller than its
      current size or larger than the file's current size.  After
      successful completion of trunc, the destination file will have
      the specified size.


TYPE - Show the contents of an ASCII file
Usage: type file
            file   - file to display the contents of

VER - Display version information
Usage: VER file   - Show version of specified file
       VER        - Show Elf/OS kernel version

Note:  A file must have a proper VER ID block for VER to show proper data

VISUAL02 - Visual/02 debugger
Usage: Visual02
Notes: After Visual/02 is loaded you will get a '>' prompt.
       The command E will Exit to Elf/OS

XR - XMODEM receiver
Usage: XR [options] file  - Receive XMODEM data and write to specified file

Notes: XR will wait about 20 seconds before sending the initial NAK, the
sender must be ready to send the file before this time elapses.  Currently
XR will not send any additional NAKs if the first one is not responded to.

XS - XMODEM sender
Usage: XS file   - Send file using XMODEM protocol
