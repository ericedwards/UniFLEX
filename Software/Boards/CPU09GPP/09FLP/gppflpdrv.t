*
* GPPFLPDRV, ROM code for CPU09GPP with 09FLP add-on
*
* 2021-03-05: write track, no retry. return error if drive/diskette absent
*
* 2021-04-30: minor bug fixes, different approach for WD2791
*
* 2021-08-31: correction in fseek, ready test now OK
*
* 2021-11-12: added double step, 40 track disk in 80 track drive
*
* 2021-12-04: implemented read track, flpdrvr.t is already done
*
* 2021-12-07: buffer clear read-track, ttyset to disable error check
*
*
* supports:  read block 128,256,512 byte size
*            write block 128,256,512 byte size
*            read track 125kBit, 250kBit, 500 kBit rate
*            write track 125kBit, 250 kBit, 500 kBit rate
*
*            supports 8", 5.25" and 3.5" in single /
*            double side and single / double / high density
*
*            runs with Interrupts disabled
*            almost no 63X09 code
*
*
* compatibillity with FLEX improved
*
*
*
        lib     gppflpdrv.h

        ifc     &a,'DBG'
romots  equ  $f804
romoth  equ  $f802
romotc  equ  $f806
        endif

* for a WD2793 (default) leave this at 0
* for a WD2791 set it to 1
WD2791  set     0

MXDMSK  equ     %00000001       max drive mask 0,1
MXSTPM  equ     %00000011       max step rate mask
*
SBDCRC  equ     %10000000       side info, disable CRC
SBDSID  equ     %00000001       side infi, double (other) side
DBDSTP  equ     %00010000       dens info, double step
DBDDEN  equ     %00000001       dens info, doubel dens
*
FDSTP1  equ     %00010101       FDC TYPE 1 status mask
FDSTZR  equ     %00000100       FDC TYPE 1, track zero





        org     RAMBASE

lside   rmb     1       actual latch side
track   rmb     1
sector  rmb     1
latch   rmb     1       latch backup
curdrv  rmb     1       last selected drive
diserr  rmb     1       disable (read) error check
trktab  rmb     4       track numbers / drive
ltctab  rmb     4       latch settings /drive
*
pstep   rmb     1       debug for progress
wrkprm  rmb     2       pointer to drive info table entry
retry   rmb     1       retry count
steprt  rmb     1               step rate modifier
*
drvtab  equ     *
dtrack  rmb     2
ddens   rmb     2

        rmb     STACKSZ
romstck equ     *

RAMEND  equ     *

        org     BUFFER
trkbuf  rmb     12500           track buffer

        org     ROMBASE

*
* configuration constants
*
rretry  fcb     2
* drive 0 and 1 obey the IBM PC selects
drvsel  fcb     LA_DS0,LA_DS1 driver select bytes
* drive 2 and 3 have no specific setup
        fcb     %00000100,%00001000
*
parstab fcb     CMDRSC,0
        fdb     do_rdsc
        fcb     CMDWSC,0
        fdb     do_wrsc
        fcb     CMDRTK,0
        fdb     do_rdtk
        fcb     CMDWTK,0
        fdb     do_wrtk
        fdb     0,0             end of table

dens    equ     flpdpr+fltden
side    equ     flpdpr+fltsid
size    equ     flpdpr+fltsiz
xfer    equ     flpdpr+fltxfr
driv    equ     flpdpr+fldriv
step    equ     flpdpr+flpstp
stat    equ     flpdpr+flstat
open    equ     flpdpr+flnwop
func    equ     flpdpr+flrflg
addrh   equ     flpdpr+flblkh
addrm   equ     flpdpr+flblkm
addrl   equ     flpdpr+flblkl
tiop    equ     flpdpr+flptel
fiop    equ     flpdpr+flpint

*
* cold start
*
reset   equ     *
        orcc    #$50
        lds     #romstck
        lda     #fdbasp
        tfr     a,dp
        setdp   fdbasp
* NATIVE 63X09 !!
        fcb     $11,$3d,$03     6309
*
        ldx     #flpdpr         go clear the Dual Port Ram
        clra
        clrb
01      std     0,x++
        cmpx    #flpdpr+flptel
        blo     01b
*
        ldx     #RAMBASE
02      std     0,x++
        cmpx    #RAMEND
        blo     02b
* set default disk type
        ldx     #flpdfl
        stx     wrkprm          set pointer
****************************************************************
*
* normally the driver loops here
*
****************************************************************
warm    equ     *
        orcc    #$50
        lds     #romstck
*
01      jsr     flpcmd          new message from main CPU
        beq     01b             wait
* load system set values
        ldb     step
        andb    #MXSTPM         step bits
        stb     steprt
* save previous settings for track register and latch
        jsr     seldrv          save old setttings
        ldb     <fo2trk
        stb     0,x
        ldb     latch
        stb     4,x
* restore the correct setting for the current drive
        ldb     driv            get drive  0,1
        andb    #MXDMSK
        stb     curdrv
        jsr     seldrv
        ldb     0,x
        stb     <fo2trk
        ldb     4,x
        stb     latch
* set drive select bits
        ldb     curdrv
        ldx     #drvsel
        abx
        ldb     latch
        andb    #$f8            leave these intact
        pshs    b
        ldb     0,x
        orb     0,s+
        stb     latch           clean higher bits
*
* update other settings
*
        lda     rretry          rom setting
        sta     retry
* test 5"/8"
        ldb     latch
        lda     side
        bita    #LA_8_5         5/8" select
        beq     setd2
        orb     #LA_8_5
        bra     setd3
*
setd2   andb    #255-LA_8_5
setd3   orb     #$80
        stb     latch
        stb     <fo4lat          set latch
*
        anda    #SBDCRC        disable read error check
        sta     diserr
*
* everything is set
*
        jsr     chkrdy          see if drive is on-line
        sta     stat
        beq     03f
        bra     fend1
* if new open force restore
03      lda     open            new open?
        beq     04f             yes, skip forced restore
*
* retry loops here
*
skretry jsr     restore         restore drive
        anda    #FDSTP1
        cmpa    #FDSTZR         should be there
        bne     flerr
*
04      clr     open            remove flag
*
        ldb     #1              set progress
        stb     pstep
*
        clr     stat            initialize return status
*
        jsr     chkrdy          drive still ready?
        tsta
        bne     flerr
*
06      jsr     srchpm          scan drive table
*
        ldb     #2
        stb     pstep
        lda     func            check command for valid
        anda    #CMDMSK
        ldx     #parstab        search function
21      cmpa    0,x
        beq     20f
        leax    4,x
        tst     0,x
        bne     21b
*
        lda     #FD_ERR+63
        sta     stat
        bra     fend1
*
20      jsr     [2,x]
*
flerr   sta     stat
*
fend    ldb     #7
        stb     pstep
        tsta                    error
        beq     fend1
        dec     retry
        lbne    skretry
fend1   nop
        bsr     flpack          tell main CPU about it
*
        jmp     warm

*
* seldrv
*
seldrv  pshs    b
        ldx     #drvtab
        ldb     curdrv
        abx
        puls    b,pc

*
*  write MAILBOX to other CPU I'm done
*
flpack  ldb     #8
        stb     pstep
        clr     tiop            acknowledge main CPU
        lda     #$ff
        sta     fiop            tell him I'am done
        rts

*
* flpcmd, test MAILBOX for new data from main CPU
*
flpcmd  lda     tiop            command present?
        rts

*
* Y = fdcbase
*
do_rdsc equ     *
        ldb     #3
        stb     pstep
*
        jsr     clcpos          block# -> trk/sec/sid
        tsta
        bne     frder           error
*
        ldb     #4
        stb     pstep
        jsr     fseek
        tsta
        bne     frder
*
        ldb     #5
        stb     pstep
        ldu     #flpdpr+flpfifo where data is to land
        lda     #FD_SRD
        jsr     frdblk
*
frder   rts

*
* Y = fdcbase
*
do_wrsc equ     *
        ldb     #3
        stb     pstep
*
        jsr     clcpos          block# -> trk/sec/sid
        tsta
        bne     fwder           error
*
        ldb     #4
        stb     pstep
        jsr     fseek
        tsta
        bne     fwder
*
        ldb     #5
        stb     pstep
        ldu     #flpdpr+flpfifo where data is present
        lda     #FD_SWR
        jsr     fwrblk
*
fwder   rts

*
* We read the designated track into buffer and transfer
* that back to the System
*
do_rdtk equ     *
        pshs    x,y,u
*  clear track buffer
        ldwe    size
        ldx     #trkbuf
        clr     0,-s
        tfm4    S,X
        leas    1,s
*
        lda     #1              no retry!
        sta     retry
        ldb     #3
        stb     pstep
*
        lda     addrl           track address << 1 + side bit
        clrb
        lsra                    strip side bit
        bcc     08f
        incb                    set side select
08      stb     lside           read  track on other side
*
        sta     track
        bne     18f             make sure we  start at track 00
        jsr     restore         restore if target is 0
*
18      lda     #1              set sector register
        sta     sector
*
        jsr     fseek           should set latch
        tsta
        bne     10f
*
* do actual Read Track here
*
        ldb     #4
        stb     pstep
        ldu     #trkbuf         do read into large buffer
        lda     #FD_RTR
        jsr     frdblk
        tsta
        beq     20f
        tst     diserr          if error and not set, abort
        beq     10f
*
* copy trkbuf data to DPR, first direct, next on INT's
*
20      cmpx    size            set size of result is smaller
        bhs     21f
        stx     size
21      ldb     #5
        stb     pstep
        ldx     #trkbuf         data source
03      ldd     xfer            is updated by kernel driver
        cmpd    size            did we enough?
        bhs     02f
*
        ldu     #flpdpr+flpfifo
        ldwi    BUFSIZ          immediate load
        tfm1    X,U             data to main side
        clra
        jsr     flpack          tell him  I have it
*
01      tst     <fo4sta         keep motor running
        jsr     flpcmd          wait for him to grab it
        beq     01b             postbox empty
        bra     03b             loop until all
*
02      clra                    set no error
*
10      puls    x,y,u,pc

*
* We arrive here when the DPR contains the first BUFSIZ
* bytes of the track image
*
do_wrtk equ     *
        pshs    x,y,u
        ldx     #trkbuf
*
* copy DPR data to trkbuf
*
03      nop
        ldu     #flpdpr+flpfifo
        ldwi    BUFSIZ          immediate load
        tfm1    U,X
        ldd     xfer            is updated by kernel driver
        cmpd    size            we have all
        bhs     02f
        clra
        jsr     flpack          tell hime I took it
*
01      tst     <fo4sta         keep motor running
        jsr     flpcmd          wait for next data
        beq     01b             postbox empty
        bra     03b             loop until all
*
* all data present
*
02      nop                     TRAP
        lda     #1              no retry!
        sta     retry
        ldb     #3
        stb     pstep
*
        lda     addrl           track address << 1 + side bit
        clrb
        lsra                    strip side bit
        bcc     08f
        incb
08      stb     lside           format track on other side
*
        sta     track
        bne     18f             make sure we  start at track 00
        jsr     restore         restore if target is 0
*
18      lda     #1
        sta     sector
*
        ldb     #4
        stb     pstep
        jsr     fseek
        tsta
        bne     10f
*
* restore the registers for the write
*
        ldb     #5
        stb     pstep
        ldu     #trkbuf
        lda     #FD_WTR
        jsr     fwrblk
*
10      puls    x,y,u,pc

*
* code routine, to read one dataset from FDC
* U = buffer address,
* Y = base address hardware
* A = command
*
* can read sector or track
* drive select, density and such alreay set up
* time out from INT fdc
*
frdblk  equ     *
        pshs    x,y,u
        ldb     #31  very long              create timeout
        ldx     #0              65536*2*25/4 cycles
*
        if      (WD2791=1)
        coma
        endif
        sta     <fo2cmd
*
01      orcc    #$50            disable ints
        bra     03f
* loop here
02      lda     <fo2dat         get data
        if      (WD2791=1)
        coma
        endif
        sta     0,u+             transfer
* poll fdc for DRQ
03      lda     <fo4sta
        asla
        bcs     02b             DRQ
        bmi     90f
        leax    1,x             count up
        bne     03b
        decb                    at zero dec B
        bne     03b             if zero abort
* end of command
90      cmpu    4,s            nothing got?
        beq     98f            unexpected
* normal end of read
97      lda     <fo2cmd        read status
        if      (WD2791=1)
        coma
        endif
        stu     0,s             preset X
*
95      tst     diserr
        beq     99f
        anda    #%11100111      remove CRC/RNF error (if any)
*
99      puls    x,y,u,pc       A = result status

* timeout occurred
98      lda     #FD_FI0         force interrupt
        if      (WD2791=1)
        coma
        endif
        sta     <fo2cmd
        jsr     delay
        lda     #$10            not found
        bra     95b

*
* code routine, to write one dataset to the FDC
* U = buffer address
* Y = hardware base
* A = command
*
* drive select, density and such alreay set up
* time out from INT fdc
*
fwrblk  equ     *
        pshs    x,y,u
*
        if      (WD2791=1)
        coma
        endif
        sta     <fo2cmd
*
01      orcc    #$50            disable ints
        bra     03f

02      lda     0,u+
        if      (WD2791=1)
        coma
        endif
        sta     <fo2dat         put data
*
03      lda     <fo4sta
        bmi     02b
        bita    #ST_INT         INT
        beq     03b
*
        lda     <fo2cmd         read status
        if      (WD2791=1)
        coma
        endif
*
99      puls    x,y,u,pc

*
* clcpos, transfer block# into track/sector/side
*
* Y = fdcbase
*
clcpos  equ     *
        pshs    x,y,u
        clr     lside           result side of calc
        ldd     addrm           block# M/L
*
        ldx     size            check special addressing
        cmpx    #256
        beq     21f
        cmpx    #128
        bne     20f
*
*  absolute addressing
*
21      sta     track
        stb     sector
        lda     side            from ttyset
        anda    #%00000011      DS or Biased
        beq     88f
        inc     lside           set side 1
        bra     88f
*
* regular 512 byte block to track/sector
*
20      ldx     wrkprm          fresh copy of drive params
*
        clr     track           track = 0
*
02      subd    3,x             sec/trk
        bmi     01f
*
        inc     track           up track #
        bra     02b
*
01      addd    3,x             adjust
* sector in B, track# on stack
        lda     side            is double sided?
        bita    #%00000011      DS or biased
        beq     05f             no
*
        lsr     track          track# / 2
        bcc     05f            even track
* odd track, add bias
        inc     lside
* TEST Biased here!
        lda     side
        bita    #%00000010
        bne     05f             no
        addb    4,x            biased sector#
*
05      incb                    1 relative
        stb     sector          set sector#
*
08      lda     track
        cmpa    2,x             test against max
        bhi     91f
* normal return
88      clra                    set OK
        puls    x,y,u,pc
* errors
91      lda     #FS_SKER        track > max
        puls    x,y,u,pc

*
* fseek, move head to track#, set registers
* Y = hardware base
*
fseek   equ     *
        pshs    x,y,u
        lda     lside
        bita    #SBDSID
        beq     lsk1
        oime    LA_SID,latch     1 = side 1
        bra     lsk2
lsk1    aime    !LA_SID,latch 0 = side 0
*
lsk2    lda     dens
        bita    #DBDDEN
        bne     lsk3
        oime    LA_SDN,latch
        bra     lsk4
lsk3    aime    !LA_SDN,latch
*
lsk4    lda     latch
        sta     <fo4lat
*
        lda     sector
        if      (WD2791=1)
        coma
        endif
        sta     <fo2sec        set sector register
*
        lda     track
        if      (WD2791=1)
        coma
        endif
        cmpa    <fo2trk
        beq     04f
*
* test double step function,
*
        ldb     dens
        bitb    #DBDSTP       double step
        beq     lsk10
* it is double step
        ldb     <fo2trk       logical track#
        if      (WD2791=1)
        comb
        endif
        aslb                  *2
        if      (WD2791=1)
        comb
        endif
        stb     <fo2trk       physical track#
        asla
*
* track is no the same, do SEEK
*
lsk10   sta     <fo2dat
        lda     #FD_SEK
        ora     steprt          update steprate
        if      (WD2791=1)
        coma
        endif
        sta     <fo2cmd
*
01      lda     <fo4sta
        bita    #ST_INT
        beq     01b
*
*
*
        ldb     dens
        bitb    #%00010000    double step
        beq     04f
*
        ldb     <fo2trk       physical track#
        if      (WD2791=1)
        comb
        endif
        asrb                  /2
        if      (WD2791=1)
        comb
        endif
        stb     <fo2trk       logical track#
*
*
*
04      lda     <fo2cmd
        if      (WD2791=1)
        coma
        endif

        anda    #!(FS_TRK0|FS_IDX|FS_HLD)    remove these from status
* check if we need to pass write protect
        ldb     func
        bitb    #%00010000           command is read
        beq     02f
        anda    #!FS_WRP
*
02      puls    x,y,u,pc

*
* chkrdy, check if drive is ready
* Y = fdcbase
*
chkrdy  ldb     #7              multiply
        lda     latch
        sta     <fo4lat
        jsr     delay
*
10      ldx     #$7fff          long delay
*
11      lda     latch
        sta     <fo4lat
        lda     <fo2cmd
        if      (WD2791=1)
        coma
        endif
        bpl     12f
*
        leax    -1,x            decrement counter
        bne     11b
*
        decb                    multiply
        bne     10b
*
        lda     #FS_NRDY
        rts
*
12      clra
        rts

*
* trigger headload delay from outside FDC
* like when drive select is changed
*
trghlt  pshs    a
        lda     latch
        anda    #$7f            trigger headsettling delay
        sta     <fo4lat
        exg     x,x
        ora     #$80
        sta     <fo4lat
        puls    a,pc

*
* restore, set drive at track 0
* Y = fdcbase
*
restore lda     #FD_RST
        ora     steprt          adjust
        if      (WD2791=1)
        coma
        endif
        sta     <fo2cmd
20      lda     <fo4sta
        tst     <fo4lat         ??
        bita    #ST_INT
        beq     20b
        lda     <fo2cmd
        if      (WD2791=1)
        coma
        endif
        bita    #00000100
        bne     21f
        clr     track           update info
21      rts

*
* delay, spend some time , no registers affected
*
delay   bsr     del1
del1    bsr     del2
del2    pshs    d,x,y,u
        puls    d,x,y,u,pc

*
* srchpm, search drive param table, used for track/sector calculations
* Y = fdcbase
*
srchpm  pshs    x,y,u
        ldx     #fltabl         start table
        ldd     side            get ttyset/ttyget bytes
        anda    #%01000000      side bits 5/8" flag
        andb    #%11000001      dens bits HD,10s,DD
31      cmpd    0,x
        beq     30f
        leax    6,x             size of entry
        tst     2,x
        bne     31b
        ldx     #flpdfl
*
30      stx     wrkprm
        puls    x,y,u,pc

fltabl  equ     *
flpdfl  fcb     $00,$00,76,0,8,0      FD-XS
        fcb     $00,$01,76,0,16,0     FD-DX
        fcb     $40,$00,79,0,5,0      F5-SX
        fcb     $40,$01,79,0,9,0      F5-XD
        fcb     $40,$41,79,0,10,0     F5-XDE
        fcb     $00,$81,79,0,18,0     F3-XD
        fcb     $00,$c1,79,0,20,0     F3-XH
        fcb     0,0,0,0,0,0


* all process registers stacked
nmihnd  equ     *
        if      (DBG=1)

        rti
        endif

*
* signal any interrupt at location in DPR
*
rtiend  lda     #$55
        sta     flpdpr+$03f8    give warning in DPR
        rti

        org     VECTORS

        fdb     rtiend
        fdb     rtiend
        fdb     rtiend
        fdb     rtiend
        fdb     rtiend
        fdb     rtiend
        fdb     nmihnd
        fdb     reset

        end
