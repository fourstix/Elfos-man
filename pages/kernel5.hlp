Elf/OS API calls
Name          Function     Description
o_coldboot    0300h        Cold boot
o_wrmboot     0303h        Warm boot
o_open        0306h        Open file
o_close       0312h        Close file
o_write       030Ch        Write to file
o_read        0309h        Read from file
o_seek        030Fh        Change file position
o_delete      0318h        Delete a file
o_rename      031Bh        Rename a file
o_exec        031Eh        Execute a program
o_opendir     0315h        Open directory for reading
o_mkdir       0321h        Make directory
o_chdir       0324h        Change/Get current directory
o_rmdir       0327h        Remove directory
o_rdlump      032Ah        Read value from LAT table
o_wrlump      032Dh        Write value into LAT table
o_type        0330h        Passthrough to F_TYPE
o_msg         0333h        Passthrough to F_MSG
o_readkey     0336h        Passthrough to F_READKEY
o_input       0339h        Passhtrough to F_INPUT
o_execdef     0342h        Execute from default exec directory
o_setdef      0345h        Set default execution directory
o_inmsg       034Bh        Passthrough to F_INMSG
o_getdev      034Eh        Passthrough to F_GETDEV
o_gettod      0351h        Passthrough to F_GETTOD
o_settod      0354h        Passthrough to F_SETTOD
o_inputl      0357h        Passthrough to F_INPUTL
o_boot        035Ah        Passthrough to F_BOOT
o_tty         035Dh        Passthrough to F_TTY
o_setbd       0360h        Passthrough to F_SETBD
o_initcall    0363h        Passthrough to F_INITCALL
o_brktest     0366h        Passhthrough to F_BRKTEST
o~alloc       036Ch        Allocate memory on the heap
o_dealloc     036Fh        Deallocate heap memory
o_nbread      0375h        Passthrough to F_NBREAD
o_dirent      037Bh        Find DIRENT for path
o_lmptosec    0409h        Convert lump number to sector number
o_sectolmp    040Ch        Convert sector number to lump number
o_rdlump32    040Fh        Read 32-bit lump
o_relsec      0418h        Get relative sector for a file
o_wrlump32    0432h        Write 32-bit lump
o_trunc       046Ah        Truncate file

d_idereset    0444h        Passthrough to F_IDERESET
d_ideread     0447h        Passthrough to F_IDEREAD
d_idewrite    044Ah        Passthrough to F_IDEWRITE
d_reapheap    044Dh        Call heap reaper
d_progend     0450h        Captures execution between O_WRMBOOT and main loop
d_delchain    0453h        Delete a lump chain
d_savesys     0459h        Save sector in system DTA
d_allocau     045Eh        Allocate an AU
d_freedirent  046Dh        Find a free DIRENT

Elf/OS Kernel Information
Name          Description
k_fildes      Elf/OS File Descriptor Fileds
k_sector0     Elf/OS Sector Zero Information
k_memory      Elf/OS Kernel Memory Variables

Useful Memory Locations:

0400h  K_VER      - 3 bytes - Kernel version
0403h  K_BUILD    - 2 bytes - Kernel build number
0405h  K_BMONTH   - 1 byte  - Kernel build date Month
0406h  K_BDAY     - 1 byte  - Kernel build date Day
0407h  K_BYEAR    - 2 bytes - Kernel build date Year
0442h  K_HIMEM    - 2 bytes - Highest address of user space. depricated.
0465h  K_LOWMEM   - 2 bytes - Lowest memory heap can use
0467h  K_RETVAL   - 1 byte  - D at last program end
0468h  K_HEAP     - 2 bytes - Current bottom of heap
0470h  K_CLKFREQ  - 2 bytes - Clock frequency, not guaranteed to be set.
041Fh  K_DEF_LUMP - 4 bytes - First lump of default exec directory
0429h  K_MD_LUMP  - 4 bytes - First lump of master directory
0430h  K_CWD_LUMP - 4 bytes - First lump of current directory
0425h  K_LASTSEC  - 4 bytes - Sector currently in sys DTA

Elf/OS Error Codes:

01 - Attempt to write read-only file
02 - Invalid FILDES
03 - File is not executable
04 - Could not open file
05 - Memory low
06 - Attempt to seek negative position
07 - Invalid seek mode
08 - Invalid directory
09 - Invalid option
0A - Missing argument
0B - Argument format error
0C - File not found
0D - No data
0E - Could not create file/directory
0F - Disk full
10 - File not open
11 - Invalid filename
12 - Attempt to open directory invalid
13 - Relative path not allowd
14 - Invalid Elf/OS version
15 - Position past end of file
16 - Overlay name not found
17 - Invalid overlay number
18 - OCB not initialized
19 - Too many arguments provided
1a - Destination not a directory
1b - Feature not present
1c - Unknown disk
1d - Invalid Heap block
FF - Unclassified error

Elf/OS v5 Directory Entry Fields

DIRENT
------
byte   description
0-3    First AU, 0=free entry
4-5    eof byte
6      flags1
       1 - file is a subdir
       2 - file is executable
       4 - This bit is set to indicate file is write protected
       8 - This bit is set to indicate file is hidden
      16 - This bit is set to indicate file has been written to

7-8    Date (see coding below)
9-10   Time (see coding below)
11     supplementary flags
12-31  filename

Byte 07h   Byte 08h
7654 3210  7654 3210
|______||____||____|
  YEAR    MO    DY

Byte 09h   Byte 0Ah
7654 3210  7654 3210
|____||______||____|
  HR    MIN    SEC/2

FILDES
------
0-3   - Current Offset
4-5   - DTA
6-7   - EOF byte
8     - Flags
        1 - sector has been written to
        2 - file is read only
        4 - currently have last lump
        8 - descriptor is open
       16 - file has been written to
       32 - Extended FILDES
       64 - reserved
      128 - currently have last sector
9-12  - Dir Sector
13-14   - Dir Offset
15-18 - Current Sector

Extended FILDES
19    - Drive number
20    - Drive fstype

sector 0 data:

    Offset        Meaning
    100h-103h     This entry contains the total number of sectors on the
                  disk device.  The most significant byte of the sector
                  count is in 100h, least significant in 103h.  The Elf/OS
                  kernel does not actually use this entry, it is only used
                  by FSGEN when the filesystem is being crated.
    104h          This entry contains the filesystem type for the disk.  So
                  far all versions of Elf/OS support only filesystem type 1
                  which is Elf/OS 16-bit LAT.
    105h-106h     This entry specifies in which sector the master directory
                  begins.  Normally the first lump of the Common Data Area
                  is the master directory, but this need not be.  As long
                  as the sector number is within the first 64k sectors of
                  the disk the master directory can exist in any lump.
    107h          Number of sectors the preboot loader should load
    108h-109h     Reserved.  Not currently used by Elf/OS
    10Ah          This entry specifies how many sectors a lump comprises.
                  Normally Elf/OS uses 8 sectors per lump, or 4kbytes per
                  lump.  All versions prior to 0.2.7 could only use 8
                  sectors per lump.  Starting with 0.2.7 any power of 2 can
                  be used for the lump size.
    10Bh-10Ch     In type 1 filesystems, this entry specifies how many AUs
                  (Allocation Units, which are synonomous with lumps) exist
                  on the disk.
    10Bh-10Eh     In non type 1 filesystems, this entry specifies how many AUs
                  exist on the disk.
    110h-113h     full 32-bit sector where master directory starts
    12Ch-14Ch     This area comprises the directory entry (or DIRENT) for the
                  master directory

