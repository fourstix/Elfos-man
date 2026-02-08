# Elfos-man
A Simple man page program for Elf/OS and Mini-DOS for viewing help files and
documentation through a browser written in 1802 Assembly language and based on the Elf/OS or Mini-DOS [browser](https://github.com/fourstix/Elfos-browse) program.

Platform
--------
The Elf/OS man program was written for an 1802 based Microcomputer running the [Elf/OS](https://github.com/rileym65/ElfosV5) operating system or the [Mini/DOS](https://github.com/dmadole/MiniDOS-kernel) operating system, such as the [Pico/Elf](http://www.elf-emulation.com/picoelf.html) by Mike Riley or the [1802-Mini](https://github.com/dmadole/1802-Mini) by David Madole or the [AVI Elf II](https://github.com/awasson/AVI-ELF-II) by Ed Keefe. A lot of information and software for the Pico/Elf, the 1802-Mini and the AVI Elf II can be found on the [Elf-Emulation](http://www.elf-emulation.com/) website and in the [COSMAC ELF Group](https://groups.io/g/cosmacelf) at groups.io.

The Elf/OS man program source files were assembled and linked with updated versions of the Asm-02 assembler and Link-02 linker by Mike Riley. The updated versions required to assemble and link this code are available at [fourstix/Asm-02](https://github.com/fourstix/Asm-02) and [fourstix/Link-02](https://github.com/fourstix/Link-02).


Elf/OS Man Program Description
------------------------------
Usage:  man *topic*

The man program will open the file *topic.hlp* in the _/man_ directory and load the file into the text buffer.   The user may use the browser commands listed below to browse the information file, and then close the man browser with the Alt-X command.

Topics
-------

* man          - The default man page file
* base4        - List of Base Utility programs for Elf/OS v4 and Mini-DOS
* base5        - List of Base Utility programs for Elf/OS v5
* intro        - Introduction to Elf/OS v4
* hdstruct     - Hard disk structure for Elf/OS v4
* inside       - Information about Elf/OS v4 Internals
* kernel5      - Kernel API for Elf/OS v5
* bios         - Bios information for Elf/OS and Mini-DOS
* rcbasic      - RC/Basic documentation
* icalc	       - Elf/OS v5 integer calculator
* fsck         - Elf/OS v5 file system checker
* scandir      - Elf/OS v5 directory scan and fix utility


Elf/OS Man Browser Commands
----------------------------
<table>
<tr><th>Keys</th><th>Command</th></tr>
<tr><td>Ctrl+B, Home</td><td>Move to the Beginning of line</td></tr>
<tr><td>Ctrl+D, Ctrl-N, Down</td><td>Move cursor Down</td></tr>
<tr><td>Ctrl+E, End</td><td>Move to End of line</td></tr>
<tr><td>Ctrl+F</td><td>Find text</td></tr>
<tr><td>Ctrl+G</td><td>Go to line number</td></tr
<tr><td>Ctrl+I, Tab</td><td>Move forward to next tab stop</td></tr>
<tr><td>Ctrl+L, Ctrl-J, Left</td><td>Move cursor Left</td></tr>
<tr><td >Ctrl+M, Enter</td><td>Move down to the next line.</td></tr>
<tr><td>Ctrl+O, PgDn</td><td>Next screen</td></tr>
<tr><td>Ctrl+P, PgUp</td><td>Previous screen</td></tr>
<tr><td>Ctrl+X</td><td>Exit</td></tr>
<tr><td>Ctrl+R, Ctrl-K, Right</td><td>Move cursor Right</td></tr>
<tr><td>Ctrl+T</td><td>Move to Top of file or buffer</td></tr>
<tr><td>Ctrl+U, Up</td><td>Move cursor Up</td></tr>
<tr><td>Ctrl+W</td><td>show Where cursor is located in file</td></tr>
<tr><td>Ctrl+Z</td><td>Move to bottom of file or buffer</td></tr>
<tr><td>Ctrl+], Shift+Tab</td><td>Move back to previous tab stop</td></tr>
<tr><td>Ctrl+?, Ctrl-^ (See Note)</td><td>Show help information</td></tr>
</table>

Note:  On older DEC video terminals the Ctrl+_ key combination replaces the Ctrl+? combination key for help.  Some emulators may support one or the other or both.

Text Limits
-----------
* Lines can have up to 124 characters per line
* Tabs are defined as 4 character tab stops (1, 5, 9, etc.)


File Buffers
------------
* Files of any size can be viewed
* Buffers are used to view files larger than 120 lines
* The man program can track up to 32 buffer locations in the file
* The man program will seek the next buffer location and load up to 120 lines into memory
* Buffer location tracking will roll over after 32 so that buffer 33 is the first buffer location
* Moving backwards, past the first tracked buffer location, will rewind to buffer zero
* The zero buffer is always the beginning of the file
* Moving backwards from buffer 1 (or 33, 65, etc.) will always rewind to the beginning of the file

Key Character Sequences
-----------------------
These key character sequences follow the VT102 terminal specification.  In the table below,
{ESC} is the Escape control character, ASCII 27, hex value $1B.  Should one of these keys not
behave as expected, you may need to configure your terminal program to return the expected
key character sequence. Note that the Delete key can have either one of two possible sequences.

<table>
<tr><th>Key</th><th>Character Sequence</th></tr>
<tr><td rowspan="2">Up (Arrow)</td><td>{ESC}[A</td></tr>
<tr><td>{ESC}A (See Note)</td></tr>
<tr><td rowspan="2">Down (Arrow)</td><td>{ESC}[B</td></tr>
<tr><td>{ESC}B (See Note)</td></tr>
<tr><td rowspan="2">Right (Arrow)</td><td>{ESC}[C</td></tr>
<tr><td>{ESC}C (See Note)</td></tr>
<tr><td rowspan="2">Left (Arrow)</td><td>{ESC}[D</td></tr>
<tr><td>{ESC}D (See Note)</td></tr>
<tr><td>Home</td><td>{ESC}[1~</td></tr>
<tr><td>End</td><td>{ESC}[4~</td></tr>
<tr><td>PgUp</td><td>{ESC}[5~</td></tr>
<tr><td>PgDn</td><td>{ESC}[6~</td></tr>
<tr><td>Tab</td><td>Ctrl+I ($09)</td></tr>
<tr><td>Shift+Tab</td><td>{ESC}[Z</td></tr>
<tr><td>Enter</td><td>Ctrl+M ($0D)</td></tr>
</table>

Note:  On some older DEC video terminals, the arrow keys send {ESC}A through
{ESC}D instead of the ANSI sequences {ESC}[A through {ESC}[D.

Repository Contents
-------------------
* **/src/**  -- Source files for the Elf/OS man program.
  * man.asm - Main assembly source file.
  * brws_file.asm - Assembly source file for man browser file routines.
  * brws_util.asm - Assembly source file for man browser utility routines.
  * brws_keys.asm - Assembly source file for man browser key handler routines.
  * build.bat - Windows batch file to assemble and create the Elf/OS man program.
  * clean.bat - Windows batch file to delete the executable and the associated build files.
* **/src/include/**  -- Include files for the graphics display programs and their libraries.
  * brws_def.inc - Definitions for Elf/OS broswe source files.
  * ops.inc - Opcode definitions for Asm/02.
  * bios.inc - Bios definitions from Elf/OS
  * kernel.inc - Kernel definitions from Elf/OS
* **/bin/**  -- Binary files for Elf/OS man program.
  * man.elfos - Elf/OS binary file for the Elf/OS man program
* **/pages/** -- topic files for use with the man program.
* **/lbr/** -- library archive file with man page topic files. Unpack these files with the command *lbr e libname* where libname is the archive name _without_ the .lbr extension.

References
----------
* [ANSI Escape Sequences](https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797)
* [Wikipedia ANSI escape code](https://en.wikipedia.org/wiki/ANSI_escape_code)
* [VT102 User Guide](https://vt100.net/docs/vt102-ug/)
* [VT102, VT100 and other DEC Video Terminals](https://vt100.net/)
* [Build Your Own Text Editor](https://viewsourcecode.org/snaptoken/kilo/index.html)
* [Antirez Kilo Editor](http://antirez.com/news/108)

License Information
-------------------
This code is public domain under the MIT License, but please buy me a beverage
if you use this and we meet someday (Beerware).

References to any products, programs or services do not imply
that they will be available in all countries in which their respective owner operates.

Any company, product, or services names may be trademarks or services marks of others.

All libraries used in this code are copyright their respective authors.

This code is based on a Elf/OS kernel written by Mike Riley and created with the Asm/02 assembler and Link/02 linker also written by Mike Riley.

Elf/OS
Copyright (c) 2004-2026 by Mike Riley

Mini/DOS
Copyright (c) 2024-2026 by David Madole


Kilo Editor
Copyright (c) 2016-2026 by Salvatore Sanfilippo

Elf-Elfos-Edit
Copyright (c) 2004-2026 by Mike Riley

Asm/02 1802 Assembler
Copyright (c) 2004-2026 by Mike Riley

Link/02 1802 Linker
Copyright (c) 2004-2026 by Mike Riley

VT102 User Guide
Copyright (c) 1982 by Digital Equipment Corporation

Many thanks to the original authors for making their designs and code available as open source.

This code, firmware, and software is released under the [MIT License](http://opensource.org/licenses/MIT).

The MIT License (MIT)

Copyright (c) 2026 by Gaston Williams

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

**THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.**
