ICALC - Simple 16-bit integer calculator
Usage: icalc

Notes: After minimon is loaded you will get a '>' prompt.
       The command :bye will return to Elf/OS

expr      - evaluate expr and print its results as both decimal and hex
:var=expr - evaluate expr and assign it to variable var
:bye      - exit

expr = term op term op term op ...

Valid terms:
     abs( - absolute value of expression
     sgn( - sign function of expression
     high - high byte of following term
      low - low byte of following term
        ~ - Invert bits of following term
      num - decimal number
     %num - binary number
     $num - hex number
     numH - hex number (must start with 0-9)
    rnum  - r0-r10 will result in 0-10, ra-rf will result in 10-15
   'char' - ASCII value of character
    var   - value contained with specified variable

Valid operations:
        + - Addition
        - - Subtraction
        * - Multiplication
        / - Division
        % - Modulo
       << - shift left
       >> - shift right
        > - Greater than
       >= - Greater or equal
        < - Less than
       <= - Less or equal
        = - equal to
       == - Equal to
       <> - Not equal to
       != - Not equal to
        & - And
       && - And
        | - Or
       || - Or
        ^ - Xor
          . - byte selector

Operator precedence:
  LOW  HIGH  SGN()  ABS
  .
  / % *
  + -
  << >>
  & | ^ ~
  = == <> != > >= < <=
  && ||

Precedence can be altered with the use of parenthesis

Sample session:

Ready
: icalc

>4*(2+3)
20  ($0014)

>:x=4*(2+3)

>x
20  ($0014)

>x << 2
80  ($0050)

>x > 20
0  ($0000)

>x > 10
-1  ($FFFF)

>high 1026
4  ($0004)

>low 1026
2  ($0002)

>1026.1
4  ($0004)

>1026.0
2  ($0002)

>r5*10
50  ($0032)

>%1010_0101
165  ($00A5)

>$1234
4660  ($1234)

>~5
-6  ($FFFA)

Notes: Since this is using the expression evaluator from Asm/02, the following variables also provide values: [month] [day] [year] [hour] [minute] [second] [build]  In the case of the date time variables, these will be set to the current time when the program is run if an RTC is present.  [build] will always be 0.  These values are certainly not useful for a calculator program, but again this was created as a test of the expression evaluator from Asm/02 after porting it to 1802 code.  I wanted to thoroughly test it before using it within the assembler since this is a pretty complicated section of code and I wanted to debug it in an easier way than using it within the assembler.



