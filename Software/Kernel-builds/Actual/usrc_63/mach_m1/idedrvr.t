        opt     nol        lib     gendrvr.h        opt     lis        lib     idedrvr.h        if      (IDE=1)        sttl     IDE Drivers        pag        name    idedrvr        global  ideopen,ideclose,ideio,ideint        global  idecop,ideccl,idecsp,idecrd,idecwr        global  idedt,idechb,idebase,idecio* IDE driver that can do DMA and PIO transfers (NO!)* it uses info from the SIR to decide which method is applicable* Device Tables** dtdfl rmb     2       device buffer fwd link* dtdbl rmb     2       device buffer bwd link* dtqfl rmb     2       device io queue fwd link* dtqbl rmb     2       device io queue bwd link* dtbusy        rmb     1       device busy flag* dtrtry        rmb     1       device error retry count* dtspr rmb     2       device spare byteidedt   rzb     DVTSIZ          device table* buffer header for character deviceidechb  rzb     HDRSIZ          buffer header** block ioidebtb  fcb     0,0,0,0,0,0,0,0    ide controller 0 open table        fcb     0,0,0,0,0,0,0,0    ide controller 1 open table* char ioidectb  fcb     0,0,0,0,0,0,0,0    ide controller 0 open table        fcb     0,0,0,0,0,0,0,0    ide controller 1 open tableidebase fdb     basead0         one controlleridepart fdb     dumtbl          pointer to partition infoidecmd  fcb     0               IDE last command byteidedrv  fcb     0               drive select bitidecur  fcb     0               current drive select (B)idelcp  fcb     0               copy of latch contentsdumtbl  fcb     0,0,0,0         dummy partition for bootBDtable fdb     0               Block Device Table address** open the ide disk drive - insure the device is online, etc.* B contains device minor*ideopen        cmpb    #IDEmax        lbhi    idcope          illegal        jsr     ide_dn          set drive parms, curdrv        ldx     #idebtb        tst     b,x             already open?        beq     ideop2        inc     b,x        bra     iderts** first open of the device(partition)* ide_dn sets idepart to dummy table on first open* ide_dn sets drive select bit*ideop2  pshs    b               save device #* check if drive is on-line        ldu     idebase         check drive present        clra        ldb     idedrv          select bit        std     ideadr3,u       select drive        exg     x,y        exg     x,y             delay*        ldd     idecmst,u       get status        cmpb    #IDERDY+IDEDSC        bne     ideop4* with 0 count ide_fdn uses zero-offset for block address        ldb     0,s             device#        jsr     iderpar         update partition info        bne     ideop4          error* we have read in the partition table, activate it        ldb     0,s             device#        ldx     #idebtb        inc     b,x             set open status        bsr     ide_dn          re-set the disk parms (now real partition)* check partition table validity        ldx     idepart        ldd     0,x             if zero than no partition table present        cmpa    #$a5        beq     idepr1          not a partition entry* check if no partition AND drive 0/4        pshs    b        ldb     1,s             minor        bitb    #%00000011      should be 0 only        puls    b        bne     ideop4          should NOT be drives 1,2,3/5,6,7 etc        tstb        bne     ideop4        ldd     2,x        bne     ideop4* if entry is 000000, we accept itidepr1  cmpb    #$ff            uninitialized partition        beq     ideop4          yes, error        leas    1,s* get drive info now        rtsideop4  lda     #EIO            indicate device offline        sta     uerror          stuff into user error flag        ldb     0,s        ldx     #idebtb        clr     b,x             clear open status        leas    1,s*idertsidecsp  rts                     dummy 'special' routine* ide close  B is device minorideclose        ldx     #idebtb        dec     b,x             clear open status        bpl     idecl1        clr     b,xidecl1  rts                     return** preset important variables, base address, partition entry*ide_dn  pshs    d,x        stb     idecur          selected drive        clra                    preload        bitb   #%00000100       2nd drive?(part 4...7)        beq    01f        lda    #IDE_DSL         drive #1 on current controller01      sta    idedrv           drive select bit*        ldx     #basead0        init first controller        bitb    #%00001000      2nd controller?        beq     03f        ldx     #basead1        set 2nd controller03      stx     idebase         controller base address*        ldx     #idebtb         was device already open        tst     b,x             if ref count=0 read partition info        beq     02f*        andb    #%00001111      else final partition        aslb                    * 4 (entry size)        aslb        ldx     partptr         kernel partition table pointer        abx04      stx     idepart         set current partition base        puls    d,x,pc*02      ldx     idebase        tst     idecur        beq     08f        lda     #L_RESET        sta     dmaltc,x        ldd     #5006      subd    #1        bne     06b        clr     dmaltc,x08      ldd     idecmst,x        tstb        bmi     08b             wait for IDEBSY  to go        ldx     #dumtbl         zero offset        bra     04b** iderpar, read disk partition table* is read each time any partition is opened*iderpar pshs    b,x,y,u         B=device        clra        ldb     idecur          drive select        andb    #%00001100      make it choose partition 0 of a drive        ldx     #0        tfr     x,y             block 0 X.Y = blockno, D=device        jsr     rdbuf        lda     bfflag,y        bita    #BFERR          error?        bne     iderp01         non-zero return*        pshs    y               save buf ref        ldx     0,s             src-buf ptr        ldu     #PARTOFF        offset to partition in block        ldb     2,s             device info        aslb        aslb                    * 4        andb    #%00110000      board/disk select        ldy     partptr  3²ş5²ı72ĥ:0ħ6262°ĵ1<:7:0ħ622·:9<622¨ İ*& Ĵ( İ*"§*1·ĥ¸62ş2:0ħ627·224ıµ59ı1¸<ħ:98:ĥ9<59ı392²ħ31ĥ90=2ı792ş:ı7´²2ı88:ĥ91<<:8134ı2:¸$˘"7¸2ı0ş4··:74·4ş4°ş2:90·9³2ı´²2´·9ş<!":0ħ629°ğ2!67ħµ"2ğ4ħ²*0ħ620ddress        inc     idedt+dtbusy    mark busy        ldb     bfdvn+1,y       get device #        lbsr    ide_dn          set up for drive        ldu     idebase*        ldd     bfxfc,y         get transfer count        cmpd    #512            is it regular block transfer?        bne     ideswap          if not - do swap*        ldd     #1              1 sector        std     idescnt,u        ldd     bfadr,y        std     dmaadh,u        A15...A0*        lda     bfxadr,y        high address in core** common part for normal R/W and swapping in a LOOP*idecon  anda    #$0f            save address bits* set address and mode A19...A16        ldb     bfflag,y get buffer flags        bitb    #BFRWF          (read=1)        bne     l003        ora     #L_DMAEN+L_INTEN   write        ldb     #IDEDWR        bra     l004l003    ora     #L_DREAD+L_DMAEN+L_INTEN        ldb     #IDEDRDl004    stb     idecmd          set command        sta     idelcp          keep copy        sta     dmaltc,u        A19...A16 + control bits* disk block #        ldx     idepart         point to partition info        clra      62113161µ<0²21<9ş24²2°²9:62113161µ<0²1ħ<9ş24²2°²9:62113161´<0²1ħ<9ş24²2°²9:621¤˘"ŻĤ! 7ı14²2²9;9ş24²2°²9:620ħ4²2ħĥ²ĥ9ş24²2ħĥış:9:9:0µ²1°ı27³4²29ğ°¸92¸ş²ış´²2ığ°p        cmpd    #16        bhi     iderr1          error        lda     bfflag,y        check special io        bmi     iderr1* memory address        ldx     bfadr,y         get swap map table        ldb     0,x+        stx     bfadr,y        cmpb    DSKTRM          always end of list marker!        beq     idedon          done*        lda     #16             shift 4 bits left        mul        pshs    a        tfr     b,a        clrb        std     dmaadh,u        ldd     #8              4K block        std     idescnt,u        puls    a        bra     idecon          A holds A19...A16B** interrupt process*ideint        ldu     idebase        controller address        lda     idelcp          get copy        anda    #255-(L_DMAEN)        sta     idelcp          save new        staa    dmaltc,u        kill any pending action        ldb     idedrv         std     ideadr3,u      select drive        ldd     idecmst,u   get status into B        lda     idedt+dtbusy        bne     idei01idefin  rtsidei01  ldy     idedt+dtqfl     get last transacion        beq     idefin        bitb    #IDEERR         error bit?        bne     iderr1        ldd     bfxfc,y         are we swapping        cmpd    #512        bne     nxtswp        bra     idedoniderr1  lda     bfflag,y        ora     #BFERR        sta     bfflag,y*idedon  clr     idedt+dtbusy    set unbusy        clr     idecmd          no pending action        ldx     BDtable        jmp     BDioendnxtswp  ldd     bfblck,y        update block address        addd    #8              4K        std     bfblck,y        lda     bfblch,y        adca    #0        sta     bfblch,y        ldd     bfxfc,y         get transfer count        bra     ideswap sttl IDE Winchester Character Drivers pag** open - close - and special*idecop   equ    *         cmpb   #IDEmax         bhi    idcope         ldx    #idectb         abx         tst    0,x         bne    idcop1* do initialisation here         inc    0,x*idcop1   rtsidcope   lda    #EBARG         sta    uerror         rtsideccl   equ    *         cmpb   #IDEmax         bhi    idcope         ldx    #idectb         abx         clr    0,x         rts** read*idecrd  pshs    d               save device number        ldy     #idechb         local character buffer        jsr     blkgtb          get buffer header        puls    d               reset dev number        jsr     idecn           go configure header        tst     uerror          any errors?        beq     iderd4        pshs    y        ldy     #idechb        jsr     blkfrb          release buffer        puls    y,pc            error returniderd4  pshs    a               save task info        orb     #BFRWF          set read mode        andb    #!BFSPC&$ff     clear special mode        stb     bfflag,y        save in buffer        bra     idecio           go do it** write*idecwr  pshs    d               save device number        ldy     #idechb         local character buffer        jsr     blkgtb          configure buffer        puls    d        jsr     idecn           go configure header        tst     uerror          any errors?        beq     idewr4        pshs    y        ldy     #idechb        jsr     blkfrb          release buffer        puls    y,pc            error returnidewr4  pshs    a               save task statusidecio  ldb     #IDEmajor        bra     blkcio          fall thru** idecnf** Configure the buffer header pointed at by Y.* This routine sets up the character device info* from the user block and puts it in the buffer* header such that the device drivers can use* the information for the data transfer.* this routine is specific for the IDE device*idecn   std     bfdvn,y         save device number        ldd     uicnt           get xfr count        std     bfxfc,y         save in header        cmpd    #512            is it 512 byte op?        beq     idecn3          if not - erroridebar  lda     #EBARG          set error        sta     uerror        rts                     returnidecn2  lda     bfflag,y        get flags        ora     #BFSPC          set special bit for drivers        sta     bfflag,y        save new flagsidecn3  jmp     blkcnf        endif        if      ((IDE|FLP|LOOP|RAMDSK)=1)        global  blkcio,blkgtb,blkfrb,blkcnf** these are generic routines used for block device character* drivers** blkcio** Perform the io specified by the buffer header* Y= buffer header* B =block device major* on STACK, old task mode bits*blkcio  pshs    y               save buffer        lda     #BLKSIZ        mul        ldx     #blktab        abx* Y=bufhdr, X=blktab        jsr     [blkio,x]       call block io routine        ldy     0,s             reset buffer        jsr     fnshio          finish io, reset BFREQ        jsr     wakbuf          awake buffer sleepers        puls    y               reset ptr        lda     bfflag,y        get flags        anda    #!(BFALOC|BFREQ|BFSPC)&$ff clear out busy bits        sta     bfflag,y        save new flags        puls    a               get task modes        ldx     utask           get task entry location        sta     tsmode,x        save task modes        ldd     #0              reset data count to 0        std     uicntfchio6  rts                     return** blkgtb** Get the character buffer header.  If it is busy,* Y =  buffer header* if busy, sleep on it.*blkgtb  equ     *        pshs    cc,y            save status        seti        lda     bfflag,y        get buffer flags        bita    #BFALOC         is buffer busy?        beq     idegb2        ora     #BFREQ          set request buffer bit        sta     bfflag,y        puls    cc              reset status        ldb     #BUFPR          set priority        jsr     sleep           go sleep for buffer        puls    y               restore y        bra     blkgtb          repeatidegb2  lda     #BFALOC         set busy status        sta     bfflag,y        puls    cc,y,pc         return** blkfrb  - free Character buffer* Y = buffer header*blkfrb  pshs    d,x,y,u       save registers        lda     bfflag,y        get flags        anda    #!(BFALOC|BFREQ|BFSPC)&$ff clear out busy bits        sta     bfflag,y        save new flags        jsr     wakbuf          awake buffer sleepers        puls    d,x,y,u,pc    return** block generic config routine*blkcnf  ldd     uipos2          get file position        std     bfblck,y        save as block number        lda     uipos+1         store upper part        sta     bfblch,y* set memory address        ldd     uistrt          get start address of xfr        std     bfadr,y         save in header A7...A0        jsr     mapupg          find user page        std     bfxadr,y        save in header A19...A8*        ldx     utask           point to task entry        lda     tsmode,x        get mode bits        pshs    a               save        ora     #TLOCK          set lock bit (keep in mem)        sta     tsmode,x        save new mode        ldb     bfflag,y        get flags        puls    a,pc            return        endif        end