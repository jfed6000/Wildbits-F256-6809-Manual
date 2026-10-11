********************************************************************
* bgcolor - change a hardware register from a NitrOS-9 program
*
* Sets text background color 0 to dark blue, the same color the raw
* skeleton uses. On a default screen the background turns blue.
*
* Under Level 2 a program's 64K map holds only its own memory and the
* fixed I/O at $FE00-$FFFF. To reach a device block such as the VICKY
* registers (block $FC), the program asks NitrOS-9 to map the block into
* its address space with F$MapBlk, and releases it with F$ClrBlk when
* done. Raw programs write the MMU instead; see examples/raw/skeleton.asm.
*
* Build:   make                  (writes build/bgcolor)
* Install: make install DISK=l2_wildbitsjr2.dsk
* Run:     bgcolor

                    nam       bgcolor
                    ttl       Set text background color 0

                    ifp1
                    use       defsfile
                    endc

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       $00
edition             set       1

                    mod       eom,name,tylg,atrv,start,size

                    org       0
mapaddr             rmb       2                   where F$MapBlk put the VICKY block
                    rmb       200                 stack
size                equ       .

name                fcs       /bgcolor/
                    fcb       edition

* Map the block holding the text color lookup tables. F$MapBlk takes the
* first block in X and the number of blocks in B, and returns the address
* in U. U is also the data area pointer, so save it first; the data area
* stays reachable through DP.
start               pshs      u
                    ldx       #TEXT_LUT_BLK       block $FC
                    ldb       #1                  one 8K block
                    os9       F$MapBlk
                    bcs       fail
                    stu       <mapaddr
                    puls      u

* Each entry in a color lookup table is 4 bytes: blue, green, red, unused.
                    ldx       <mapaddr
                    leax      TEXT_LUT_BG,x       background table, entry 0
                    lda       #$60                blue
                    sta       ,x
                    clr       1,x                 green
                    clr       2,x                 red

* Give the address range back to NitrOS-9.
                    ldu       <mapaddr
                    ldb       #1
                    os9       F$ClrBlk
                    clrb
                    os9       F$Exit

fail                puls      u                   B holds the error code
                    os9       F$Exit

                    emod
eom                 equ       *
                    end
