*******************************************************************************
* skeleton.asm - a minimal raw 6809 program for the Wildbits Jr2 and K2
*
* Runs on the bare machine, without NitrOS-9. It masks interrupts, sets up
* text mode, clears the screen, prints a message and then loops forever.
* Copy it to start a new raw program.
*
* Build:  lwasm --6809 --format=raw -o skeleton.bin skeleton.asm
*
* The output is an 8K image of CPU addresses $E000-$FFFF (RAM block 7),
* ending with the 6809 vectors at $FFF0. Load it with FoenixMgr:
*
*   fnxmgr --boot ram                              (once, until power-off)
*   fnxmgr --binary skeleton.bin --address 00E000
*
* "--boot ram" makes slot 7 map RAM block 7 instead of flash block $7F at
* reset, so the CPU takes its reset vector from this image. Each upload
* holds the CPU in reset and releases it when done, which starts the
* program. "fnxmgr --boot flash" returns to the normal flash boot.
*
* Core: FNX6809 RC24.
*******************************************************************************

*------------------------------------------------------------------------------
* Hardware addresses
*------------------------------------------------------------------------------

* Interrupt controller: four groups of eight sources
INT_PENDING_0   equ     $FE20           ; pending, groups 0-3 (write 1 to clear)
INT_MASK_0      equ     $FE2C           ; masks, groups 0-3 (1 = masked)

* MMU
MMU_MEM_CTRL    equ     $FFA0           ; b5:4 LUT to edit, b1:0 active LUT
MMU_SLOT_0      equ     $FFA8           ; slot n register is at MMU_SLOT_0+n

* VICKY master control
VKY_MSTR_CTRL_0 equ     $FFC0           ; b0 text mode on
VKY_MSTR_CTRL_1 equ     $FFC1           ; b2:0 video mode, 0 = 640x480 (80x60 text)
VKY_BRDR_CTRL   equ     $FFC4           ; b0 border on
VKY_CRSR_CTRL   equ     $FFD0           ; b0 text cursor on

* Device blocks: map one into a slot to reach it
VICKY_BLK       equ     $FC             ; VICKY registers and tables
TEXT_BLK        equ     $FE             ; text characters, one byte per cell
COLOR_BLK       equ     $FF             ; text colors, one byte per cell

* Offsets in VICKY_BLK: 16 entries of 4 bytes each (blue, green, red, unused)
TEXT_LUT_FG     equ     $1700           ; text foreground colors
TEXT_LUT_BG     equ     $1740           ; text background colors

*------------------------------------------------------------------------------
* Program settings
*------------------------------------------------------------------------------

COLUMNS         equ     80
ROWS            equ     60
SCREEN_SIZE     equ     COLUMNS*ROWS

FG_COLOR        equ     15              ; text foreground color index
BG_COLOR        equ     0               ; text background color index
TEXT_COLOR      equ     FG_COLOR*16+BG_COLOR

* Slot 2 ($4000-$5FFF) is the window this program maps device blocks into.
WINDOW          equ     $4000
WINDOW_SLOT     equ     MMU_SLOT_0+2
WINDOW_HOME     equ     2               ; block slot 2 maps at reset

STACK_TOP       equ     $E000           ; the stack grows down into block 6

*------------------------------------------------------------------------------
* Program
*------------------------------------------------------------------------------

                org     $E000

Start           orcc    #$50            ; mask IRQ and FIRQ in the CPU
                lds     #STACK_TOP

* Mask every interrupt-controller source and clear anything pending.
                ldx     #INT_PENDING_0
                lda     #$FF
                ldb     #4              ; four groups
@group          sta     INT_MASK_0-INT_PENDING_0,x
                sta     ,x+
                decb
                bne     @group

* Use LUT 0 for both translation and editing. At reset it maps slots 0-7
* to RAM blocks 0-7.
                clr     MMU_MEM_CTRL

* Text mode, 80x60, no border, no cursor.
                lda     #$01
                sta     VKY_MSTR_CTRL_0
                clr     VKY_MSTR_CTRL_1
                clr     VKY_BRDR_CTRL
                clr     VKY_CRSR_CTRL

* Set the two colors this program uses: white text on dark blue.
                lda     #VICKY_BLK
                sta     WINDOW_SLOT
                ldx     #WINDOW+TEXT_LUT_FG+FG_COLOR*4
                ldd     #$FFFF          ; blue, green
                std     ,x
                sta     2,x             ; red
                ldx     #WINDOW+TEXT_LUT_BG+BG_COLOR*4
                ldd     #$6000          ; blue, green
                std     ,x
                clr     2,x             ; red

* Clear the screen: spaces in every cell, all in TEXT_COLOR.
                lda     #TEXT_BLK
                sta     WINDOW_SLOT
                lda     #' '
                bsr     FillWindow
                lda     #COLOR_BLK
                sta     WINDOW_SLOT
                lda     #TEXT_COLOR
                bsr     FillWindow

                lda     #WINDOW_HOME
                sta     WINDOW_SLOT

* Print a message.
                lda     #2              ; row
                ldb     #4              ; column
                ldx     #Message
                bsr     PrintAt

* Your program starts here.

Forever         bra     Forever

*------------------------------------------------------------------------------
* FillWindow: store A in the first SCREEN_SIZE bytes of the window.
*------------------------------------------------------------------------------

FillWindow      ldx     #WINDOW
                ldy     #SCREEN_SIZE
@loop           sta     ,x+
                leay    -1,y
                bne     @loop
                rts

*------------------------------------------------------------------------------
* PrintAt: print a zero-terminated string.
*   A = row, B = column, X = string. Changes A, B, X, Y.
*------------------------------------------------------------------------------

PrintAt         pshs    b               ; save the column
                ldb     #COLUMNS
                mul                     ; D = row * COLUMNS
                addb    ,s+             ; add the column
                adca    #0
                addd    #WINDOW
                tfr     d,y             ; Y = first cell
                lda     #TEXT_BLK
                sta     WINDOW_SLOT
@loop           lda     ,x+
                beq     @done
                sta     ,y+
                bra     @loop
@done           lda     #WINDOW_HOME
                sta     WINDOW_SLOT
                rts

Message         fcn     "Hello from the Wildbits 6809!"

*------------------------------------------------------------------------------
* Interrupt handlers. All interrupts are masked, so these only return.
*------------------------------------------------------------------------------

Ignore          rti

*------------------------------------------------------------------------------
* 6809 vectors. $FE00-$FFEF is fixed I/O, so the CPU never sees the padding
* before them; it only makes the image one continuous 8K block.
*------------------------------------------------------------------------------

                fill    $FF,$FFF0-*
                fdb     Ignore          ; $FFF0 reserved
                fdb     Ignore          ; $FFF2 SWI3
                fdb     Ignore          ; $FFF4 SWI2
                fdb     Ignore          ; $FFF6 FIRQ
                fdb     Ignore          ; $FFF8 IRQ
                fdb     Ignore          ; $FFFA SWI
                fdb     Ignore          ; $FFFC NMI
                fdb     Start           ; $FFFE RESET
