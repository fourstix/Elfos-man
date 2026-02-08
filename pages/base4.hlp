Elf/OS v4 and Mini-DOS Base Utilities

More information is available via the help command or additional man pages.

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

DUMP - Dump memory contents to disk
Usage: dump [options]

Notes: dump will prompt for the starting address, ending address, and
       the name of the file to dump to.

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

INSTALL - Package installer
Usage: install

Notes: This program is similar to option 4 of the Elf/OS installer.  It
       reads an INSTALL package header located at 8000h in memory and asks
       to install each program found in the header.

KREAD - Kernel image reader
Usage: kread file  - Read currently installed kernel and write to file

Note: The file created by KREAD is suitable for use with the SYS command


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


PATCH - Apply program patches
Usage: patch file
             file  - Patch control file

Notes: The patch control file is formatted as follows:
         Line 1      - Filename of file to be patched
         Line 2      - Either R for relative mode, or first data line
         Line 3 ...  - Remaining data lines

       Data lines are formatted as first 4 hex digits, address to start
       patching, followed by a list of 2 hex digits for the bytes to
       write at the specified address.

       Relative mode first reads the file's execution header to determine
       file offsets.  The addresses used in the data lines are the memory
       addresses instead of the file offset.

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

SEDIT - Hard disk sector editor
Usage: sedit

Notes: After sedit is loaded you will get a '>' prompt.
       The Q command will Quit back to Elf/OS


SETBOOT - Install the 16-sector sector 0 boot loader.
Usage: setboot

Notes: Use after installing the Secondary Boot Loader boot2.bin.
       See 'help boot2' for more information.

SETBOOT2 - Install the faster 2-sector sector 0 boot loader.
Usage: setboot2

Notes: Use after installing the Secondary Boot Loader boot2.bin.
       See 'help boot2' for more information.
       Use setboot to restore the default 16-sector sector 0 boot loader.


SHELL - Integrated shell utility.
Usage: shell

Note: This version contains the following command aliases:
      cd (chdir), cp (copy), rm (del), ls (dir), md (mkdir),
      rn (rename), rd (rmdir), cat (type)

STAT - Show file statistics
Usage: stat file


SYS - Install kernel
Usage: SYS file   - Write the kernel image from file to the system

Note: Extreme care must be used when using this command.  If file does not
      contain a valid kernel image then your disk will become unbootable.
      If an error occurs during the process then your disk will likely
      become unbootable.
      It would be a good idea to use KREAD to read your existing kernel
      before using SYS to write a new one, just in case you need to return
      to the prior kernel version.

TOUCH - Touch a file
Usage: touch file

Touching a file will set its A flag as well as setting the file's
date/time to the current system date/time.

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
