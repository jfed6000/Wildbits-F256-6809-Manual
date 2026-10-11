********************************************************************
* hello - the smallest useful NitrOS-9 program
*
* Prints a line to standard output and exits. Start a new program by
* copying this file.
*
* Build:   make                  (writes build/hello)
* Install: make install DISK=l2_wildbitsjr2.dsk
* Run:     hello                 (from the shell)
*
* When NitrOS-9 starts the program:
*   U and DP point to the bottom of the data area ("size" bytes)
*   S points to the top of the data area
*   X points to the parameters, ending with a carriage return
*   D holds the length of the parameters

                    nam       hello
                    ttl       Print a line and exit

                    ifp1
                    use       defsfile
                    endc

tylg                set       Prgrm+Objct         a program, in 6809 object code
atrv                set       ReEnt+rev           re-entrant: one copy can serve many processes
rev                 set       $00
edition             set       1

                    mod       eom,name,tylg,atrv,start,size

* Data area. NitrOS-9 allocates it when the program starts; the stack
* grows down from its top.
                    org       0
                    rmb       200                 stack
size                equ       .

name                fcs       /hello/             module name, last character has bit 7 set
                    fcb       edition

msg                 fcc       /Hello from NitrOS-9 on the Wildbits 6809!/
                    fcb       C$CR
msglen              equ       *-msg

start               leax      msg,pcr             X = text, addressed relative to the PC
                    ldy       #msglen             Y = maximum number of bytes
                    lda       #1                  path 1 = standard output
                    os9       I$WritLn            write up to and including the CR
                    bcs       exit                on error, B holds the error code
                    clrb                          B = 0: no error
exit                os9       F$Exit              end the process, returning B to the shell

                    emod
eom                 equ       *
                    end
