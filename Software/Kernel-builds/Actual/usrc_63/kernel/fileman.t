          lib     environment.h          sttl    File       Managers          pag          name    fileman          global  open,filopn,dvopnb,dvopnc,genprm          global  getdes,makdes,create,crfil,read,write          global  rwset,dvclsc,dvclsb,close,cpnwd,unlinr          global  chdir,crtsd,link,unlink,seek,dup,chown          global  tstown,chprm,chkacc,tstsu,dups,getfil          global  open3,close2 UGH!!!** open** Open a file.  This is the system call for file* opens.  All preparation has been done by the os* call manager.  The file descriptor is returned* to the caller in D.*open      ldb     #1         set user flag          lbsr    pthnm      process the file name          cmpx    #0         file found?          beq     open3      if not, error          ldd     usarg1     get arg #1 (0 is the first)          lbsr    genprm     test permissions          bne     open2      'ne' means no permission          pshs    a,x        save perm bits and fdn          lbsr    unlfdn     unlock the fdn          lbsr    getfil     get a file slot          puls    a,y        reset fdn ptr          bne     filopn     go open file          tfr     y,x        get fdnopen2     lbra    frefdn     free fdn & exitopen3     lda     uerror     is error set?          bne     open4          lda     #ENOFL     set no file error          sta     uerroropen4     rts     return** doopn** Do the open on a special file if necessary.* If the fdn is for a character or block device,* call the appropriate open routines from the* device drivers.*doopn     pshs    x,y        save file & fdn          lda     fmode,y    get mode bits          bita    #FSBLK     is it block device?          beq     doopn2          ldd     ffmap,y    get device number          bsr     dvopnb     do block open          puls    x,y,pc     returndoopn2    bita    #FSCHR     is it character device?          beq     doopn4          ldd     ffmap,y    get device number          bsr     dvopnc     do character opendoopn4    puls    x,y,pc     return          pag** dvopnb** Device open for block devices.  This routine* is only called from above.  D has the device* number.*dvopnb    cmpa    #BLKDEV    legal major device #          bhs     dvopnerr   no - set error          pshs    d          save device          ldx     #blktab    point to block table          ldb     #BLKSIZ    set table size          mul     calculate  table offset          leax    d,x        point to this guy          puls    d          reset device number          jmp     [blkopn,x] call open routine** dvopnc** Device open for character devices.  D has the* device number upon entry.*dvopnc    cmpa    #CHRDEV    legal major device #          bhs     dvopnerr   no - set error          pshs    d          save device number          ldx     #chrtab    point to character table          ldb     #DEVSIZ    set entry size          mul     calculate  table entry          leax    d,x        point to entry          puls    d          reset device number          jmp     [devopn,x] go do open** dvopnerr - Illegal major device # specified*dvopnerr  pshs    d          save device #          lda     #EBARG     return "Bad argument" error          sta     uerror          puls    d,pc       return          pag** filopn** Do final file open.  Set up has been done by* either 'open' or 'create'.  On entry, X has* file pointer, Y has fdn pointer, and A has* the r/w codes.*filopn    sta     ofmode,x   set file mode          sty     ofnodp,x   set fdn pointer          bsr     doopn      do device open* here add code for named pipes          lda     fmode,y          bita    #FNAMPIP   test named pipe          beq     01f          bita    #(FSBLK+FSCHR+FSDIR) test special file          bne     02f          pshs    y          leay    facces,y   wake sleepers          jsr     wakeup          puls    y          lda     ofmode,x   set pipe flag in file struct          ora     #OFPIPE          sta     ofmode,x03        lda     frefct,y   check links to node          cmpa    #2          bhs     01f        not yet, wait for other side          pshs    y          ldb     #TTYIPR    sleep on inode          leay    facces,y          jsr     sleep          puls    y          bra     03b01          tst     uerror     is there an error?          beq     filop6     if not, return02          ldb     urglst+UB  get file desc.          pshs    x          save file          ldx     #ufiles    point to file list          aslb    find       this file          leax    b,x          clr     0,x        clear out entry          clr     1,x          puls    x          point to file table entry          dec     ofrfct,x   22ħ92³1·ş·::39<<392²:¸:42327619ı392³27³4ĥ7¸9:992ş:ı73²ş22ı#²ş:4234ĥ292¸92ı²·:2²1<:4234ĥ222ıħı4¸:7ı4·")2ş:ı7,87´·:4·3:734ĥ27ı7:ĥ6³²ş22ı1ĥ¸2Ş§#$Ĥ)4ı22ıħ4·90·3²1673²ş22    if not, errorgetde1    lda     #EBADF     set error          sta     uerror          ldx     #0         set null file ptr          rts     returngetde2    ldx     #ufiles    point to file list          aslb    calc       position          ldx     b,x        get file pointer          beq     getde1     no file?          rts     return     ok from here          pag** getfil** Make a new file table entry for a new file.* Return the file pointer in X (or 0 if error).*getfil    bsr     makdes     get a new file desc.          bne     getfi5     error?          clr     urglst+UA  clear return D          stb     urglst+UB          ldx     ofiles     point to open file table          lda     sfdn       set file entry countgetfi3    tst     ofrfct,x   check ref count          beq     getfi6     if 0, we found one!          leax    FSTSIZ,x   move to next entry          deca    dec        the count          bne     getfi3     repeat          lda     #ETMFL     set too many error          sta     uerrorgetfi5    ldx     #0         set null pointer          rts     return     errorgetfi6    inc     ofrfct,x   bump ref count          clra    --         ldd #0 clear table data          clrb          std     ofpost,x   clear out position ptr          std     ofpos2,x          stx     0,y        set ino in user file table          rts     return** makdes** Make a new file descriptor.  Return the desc* in B and the user file slot pointed at by Y.*makdes    ldy     #ufiles    point to user file list          clrb    clear      countermakde2    tst     0,y        look for empty slot          beq     makde4     this one?          leay    2,y        move to next entry          incb    bump       desc count          cmpb    #UNFILS    past end of list?          bne     makde2     if not, loop          lda     #ETMFL     set too many error          sta     uerrormakde4    rts     return          pag** genprm** General routine for checking the r/w permissions* of an open or create sys call.  On entry, X points* at the fdn and B has the r/w code (0=read, 1=write,* and 2=r&w).  Exit with 'ne' if no permission.* A will have fdn R/W mode bits set.*genprm    pshs    b          save r/w status          clr     0,-s       save a slot          cmpb    #4         check legal value          bhs     genprm99   error          cmpb    #3         treat 3 == 2          bne     00f          ldb     #200        cmpb    #1         is it write?          blo     genpr2          ldb     fmode,x    get fdn modes          bitb    #FSDIR     is it directory?          bne     genpr6     if so, error!          ldb     #FACUW     set write permission          stb     0,s          lbsr    tstprm     test the permission          bne     genpr5     error?genpr2    ldb     1,s        get r/w code          beq     genpr3     is it read?          cmpb    #2         r/w?          bne     genpr4genpr3    ldb     #FACUR     set read permission          tfr     b,a          ora     0,s        or in with other          sta     0,s        save total permission          lbsr    tstprm     test permission          bne     genpr5     error?genpr4    sez     show       okgenpr5    puls    d,pc       returngenpr6    ldb     #EISDR     set errorgenpr7    stb     uerror          puls    d,pc       returngenprm99  ldb     #EBARG     illegal argument          bra     genpr7          pag** create** Create a file.  This is the system call entry for* file creation.*create    ldb     #1         set user flag          lbsr    pthnmc     look for specd file          tstb    file       name processed?          beq     creat3     b=0 => no name!          cmpx    #0         check if name found          beq     creat5     x=0 => not found          lda     fmode,x    get mode          bita    #FSDIR     is it directory?          beq     creat0     if not, ok          lda     #EISDR     set error          bra     crea35     go reportcreat0    ldd     #1         set write status          bsr     genprm     check write permission          bne     creat2     error?          pshs    x          save file ptr          lbsr    rmvfil     remove all file blocks          ldx     0,s        reset file ptrcreat1    lbsr    unlfdn     unlock the fdn          lbsr    getfil     get file pointer          puls    y          reset fdn pointer          bne     creat7     error?          tfr     y,x        if error, clean upcreat2    lbra    frefdn     free the fdn entry*creat3    lda     uerror     check for error          beq     creat4          lda     #EPRM      set permission errorcrea35    sta     uerrorcreat4    cmpx    #0         fdn set?          bne     creat2     if so, free it          rts     return     - errorcreat5    tst     uerror     error?          beq     creat6          rts     return     errorcreat6    ldd     usarg1     get arg 1          andb    #$3f       get perm bits          clra    set        permission only          bsr     crfil      do file creation          pshs    x          save file pointer          cmpx    #0         no file?          bne     creat1     should be a file!          ldx     ulstdr     get 60ış24ı619ı392³27392²:4232762<9²ş2ı97ı92ş:ı762°ı91ĥ2°·9ş0ħµ9:992ş:ı72ı97ıħı2°ş620§£+İ$Ş9²ş;ı4ş26·²2619034ĥ7¸73·7¸2·34ĥ280³1ı34ĥ"70ħş:°ĥ34ĥ21ı2°ş4··'·2·:9<"40s the file* creation mode.  This is 'ord' with 'udperm' to get* the overall file permission status.*crfil     pshs    d          save mode          ldx     ulstdr     get last dir ptr          beq     crfil2     is it null?          ldd     fdevic,x   get device number          lbsr    alfdn      alocate an fdn          cmpx    #0         any found?          bne     crfil3crfil2    puls    d,pc       return - errorcrfil3    puls    d          get modes          ora     #FBUSY     set busy bit          andb    udperm     set defaults          std     fmode,x    sets acc too!          lda     #1         set dir count          sta     fdirlc,x          ldd     uuid       get user id          std     fouid,x    set in the file (owner)crfil4    lda     fstat,x    get status          ora     #FMOD      set modify flag          sta     fstat,x    save new status          ldd     fnumbr,x   get fdn number          std     ufdn       save for dir entry          pshs    x          save fdn          lbsr    cpnwd      copy name to dir          ldd     #ufdn      point to this new entry          std     uistrt     set start address for xfr          ldd     #DIRSIZ+2  set xfr data count          std     uicnt      save it          clr     uiosp      set system space flag          ldd     ufdel      check for deleted slot          beq     crfil6          std     uipos2     set file positioncrfil6    ldy     ulstdr     point to dir fdn          lbsr    filwr      write the new dir          tfr     y,x          lbsr    frefdn     free up the fdn          puls    x,pc       return          pag** read** System call entry for doing file read.*read      ldb     #OFREAD    set read mode          bsr     rwset      setup for read          beq     rwfin4     error?          lda     ofmode,x   check file mode          bita    #OFPIPE    is this a pipe?          lbne    piprd      do pipe read if so          jsr     rwdat      setup data          pshs    x          save file ptr        if      (NET=1)          ldb     #OFSOCK          bitb    ofmode,x          beq     01f          ldu     ofnodp,x   get device reference          lbsr    wskrd      socket read          bra     rwfin        endif01        lbsr    filrd      go read file** rwfin** Finish up a read or write operation.*rwfin     ldd     usarg1     get arg 1          subd    uicnt      fix up data count          puls    x          get file pointer          pshs    d          save count          addd    ofpos2,x   set new file position          std     ofpos2,x          bcc     rwfin2     need to bump hi half?          ldd     ofpost,x   get hi part of pos          addd    #1         bump by 1          std     ofpost,x   save new posrwfin2    puls    d          get count          std     urglst+UA  set byte read (in D)          lda     fmode,y    get fdn modes          bita    #FSCHR|FSBLK is it a device?          bne     rwfin6     if so, just return          tfr     y,x        get fdn pointer          lbra    unlfdn     unlock & returnrwfin4    clra    --         ldd #0 set 0 read count          clrb          std     urglst+UA  set in Drwfin6    rts     return          pag** write** System routine for doing file writes.*write     ldb     #OFWRIT    set write mode          bsr     rwset      do write setup          beq     rwfin4     error?          lda     ofmode,x   get file mode          bita    #OFPIPE    is it a pipe?          lbne    pipwr      if so, do pipe write          bsr     rwdat      setup data          pshs    x          save file pointer        if      (NET=1)          ldb     #OFSOCK          bitb    ofmode,x          beq     01f          ldu     ofnodp,x          jsr     wskwr      write to socket          bra     rwfin        endif01        lbsr    filwr      write data to file          bra     rwfin      go finish up** rwset** Setup pointers for a system read or write operation.* On entry, B has read or write mode code.  On exit* X points to the open file entry and Y points to the* active fdn.*rwset     pshs    b          save mode          ldb     urglst+UB  get file descriptor          clra          lbsr    getdes     get file for this des          puls    b          reset modes          beq     rwset5     no file found?          bitb    ofmode,x   is mode ok?          beq     rwset4     if not, error          ldy     ofnodp,x   get fdn pointer          lda     #1         set user space flag          sta     uiosp          ldd     usarg0     get starting address          std     uistrt          ldd     usarg1     get data count          std     uicnt      save for xfr          clz     set        return status          rts     returnrwset4    lda     #EBADF     set bad file error          sta     uerror     set errorrwset5    sez     set        error status          rts     return          pag** rwdat** Set up data for read or write operation.*rwdat     pshs    x,y        save file data          ldd     ofpost,x   get file position          std     uipos      save as start pos          ldd     ofpos2,x          std     uipos2          lda     fmode,y    get fdn modes          bita    #FSCHR|FSBLK is it a device?          bne     rwdat2     if so, don't lock fdn!          lbsr    lckfdn     lock this guys fdnrwdat2    puls    x,y,pc     return** dvclsc** Close the special character device whose device* number is in D.*dvclsc    pshs    d          save dev number          ldx     #chrtab    point to char table          ldb     #DEVSIZ    set entry size          mul     find       this entry          leax    d,x        point to entry          puls    d          reset dev number          jmp     [devcls,x] go close it** dvclsb** Close the block device whose number is in D.*dvclsb    pshs    d          save device number          ldx     #blktab    point to block table          ldb     #BLKSIZ    set entry size          mul     find       entry          leax    d,x        point to entry          puls    d          reset device number          jmp     [blkcls,x] go close itdvclb4    rts     return          pag** close** Main system call for file closing.*close     ldd     urglst+UA  get file desc number          pshs    b          lbsr    getdes     get file for desc          puls    b          lbeq    close8     error?* found file info in X          ldy     #ufiles    point to file list          aslb    find       this entry          leay    b,y        point to this entry          clra    --         ldd #0 clear out entry          clrb          std     0,y          ldu     #ufiles    -- Files 0..2 closed?          ldd     ,u++          bne     close2          ldd     ,u++          bne     close2          ldd     ,u          bne     close2          ldu     utask      yes - disassociate from any terminal          std     tstty,uclose2    pshs    x          save file pointer          ldu     0,s        point to file entry          lbsr    ulft       unlock any records          ldx     0,s        reset file pointer          ldy     ofnodp,x   get fdn pointer          beq     close5     no entry?  silent return          lda     ofmode,x   get file mode          bita    #OFPIPE    is it pipe?          beq     clos25* is pipe          pshs    y          save fdn pointer          lda     fmode,y    get fdn mode          anda    #!(FPRDF|FPWRF) clear pipe bits          sta     fmode,y    save new mode          leay    fmode,y    awaken pipe reader          lbsr    wakeup          ldy     0,s        reset fdn pointer          leay    facces,y   awaken pipe writer          lbsr    wakeup          puls    y          ldx     0,s        reset file pointer* Y is fdn or wzsock!clos25    dec     ofrfct,x   dec the file ref count          bne     close5     if not 0, silent return        if      (NET=1)          lda     #OFSOCK          bita    ofmode,x          beq     01f          jsr     wskcl      close sock        endif01        lbsr    lckfdn     lock the fdn          pshs    y          save fdn pointer          lda     fmode,y    get mode          bita    #(FSCHR|FSBLK) is it special?          beq     close4* device node          ldb     frefct,y   get reference count          cmpb    #1         is this last ref?          bne     close4          bita    #(FSBLK)   is it block device?          bne     close3          ldd     ffmap,y    get device number          lbsr    dvclsc     close the device          bra     close4close3* -- Force all buffers out for block device          puls    x          get fdn pointer          ldd     ffmap,x    get device #          pshs    d          save device code          jsr     frefdn     free up fdn          ldd     0,s        make sure the device is free          bsr     ckbusy     see if device is busy or special          beq     close35    it is - don't free buffers          ldd     0,s        get device #          jsr     fabufs     free all buffers (in unmount)close35   puls    d          restore device #          jsr     dvclsb     close the device          puls    x,pc       clean up stack/returnclose4    puls    x          point to fdn          lbsr    frefdn     free the fdnclose5    puls    x,pc       returnclose8    rts     return** ckbusy - Check to see if the device in D is busy*    Return (EQ) if device is special (root, pipe*    or swap) or is mounted.*ckbusy    cmpd    rtdev      is it root device?          beq     99f          cmpd    pipdev     is it pipe device?          beq     99f          cmpd    swapdv     is it swap device          beq     99f          pshs    d          save device #          ldx     mtable     search mount table          ldb     smnt          pshs    b          ldd     1,s        restore device code10        ldy     msir,x     get sir pointer          beq     20f        can't be mounted without an sir          cmpd    mdevic,x   is this the device?          beq     90f        yes - return EQ for busy20        leax    MSTSIZ,x   move to next mount entry          dec     0,s        end of list?          bne     10b        no - continue          lda     #1         yes - return NE for not busy90        leas    3,s        clean up stack99        rts          pag** cpnwd** Copy dir name to udname from uwrkbf.*cpnwd     ldx     #uwrkbf    point to name          ldy     #udname    point to slot          ldb     #DIRSIZ    set countcpnwd2    lda     0,x+       transfer name          sta     0,y+          decb    dec        the count          bne     cpnwd2          rts     return** chdir** Change user's default directory.  This is a* system call.*chdir     ldb     #1          lbsr    pthnm      find dir name          cmpx    #0         was it found?          lbeq    open3      if not, error          lda     fmode,x    get mode          bita    #FSDIR     is it a directory?          beq     chdir4          ldb     #FACUE     check for execute perm          lbsr    tstprm     is it ok?          bne     chdir5          lbsr    unlfdn     unlock this fdn          pshs    x          save the fdn          ldy     ucrdir     get current dir          lbsr    lckfdn     lock it          ldx     ucrdir     get current dir          lbsr    frefdn     free it up          puls    x          get new fdn          stx     ucrdir     save as current dir          rts     returnchdir4    lda     #ENDR      not dir error          sta     uerror     set errorchdir5    lbra    frefdn     free up the fdn          pag** crtsd** Create a new directory or special file.* This is a system call.*crtsd** lbsr    tstsu      is this super user?**        beq     crtsd1     error?**        rts     returncrtsd1    ldb     #1          lbsr    pthnmc     look for file name          tstb    root       specified?          lbeq    creat3     error?          cmpx    #0         file found?          bne     crtsd6     if so, error          tst     uerror     was there an error?          bne     crts44*          ldd     usarg1     get mode-perm bytes          bita    #(FSCHR|FSBLK) is it a special file?          beq     crtsd3* it is a device          pshs    d          save perms          lbsr    tstsu      is it superuser          puls    d          bne     crts44* it is a device AND superuser          anda    #(FSCHR|FSBLK) mask mode byte          cmpa    #(FSCHR|FSBLK) both specified?          lbeq    creat3     if so, error          bra     crtsd4crtsd3    anda    #(FSDIR|FNAMPIP)          cmpa    #(FSDIR|FNAMPIP)          lbeq    creat3     post errorcrtsd4    ldd     usarg1     renew perms          lbsr    crfil      create a new file          cmpx    #0         was it successful?          bne     crts45          ldx     ulstdr     get last dir          beq     crts44     jump if not found          lbsr    frefdn     free the fdncrts44    rts     return     - errorcrts45    lda     fmode,x    get fdn mode          bita    #(FSCHR|FSBLK) is it special?          beq     crtsd5          ldd     usarg2     get device number          std     ffmap,x    save in fdncrtsd5    lbra    frefdn     free up fdn & returncrtsd6    lda     #EFLX      file exists error          sta     uerror     set error          bra     crtsd5     go finish          pag** link** Link to file system call.*link      ldb     #1         set mem space          lbsr    pthnm      find file          cmpx    #0         not found?          lbeq    open3      report error          lda     fmode,x    get fdn mode          bita    #FSDIR     is it directory?          beq     link2          lbsr    tstsu      if so, must be su          bne     link9      error if notlink2     pshs    x          save fdn          lbsr    unlfdn     unlock the fdn          ldd     usarg1     get new file name          std     ucname     save in name pointer          ldb     #1          lbsr    pthnmc     create new file name          cmpx    #0         file found?          bne     link5      if so, error          tst     uerror     was there an error?          bne     link6      if so, exit          ldx     ulstdr     get last dir          ldd     fdevic,x   get device number          puls    x          reset old fdn          cmpd    fdevic,x   on same device?          bne     link8      if not, error          lda     fdirlc,x   get dir link count          cmpa    #127       is it max?          beq     link4          inc     fdirlc,x   bump link countlink4     pshs    x          save fdn          lbsr    crfil4     make new entry          bra     link6link5     lbsr    frefdn     free up the fdn          lda     #EFLX      file exists errorlink55    sta     uerror     set in errorlink6     puls    x          reset the fdn ptr          lbra    frefdn     free the fdn & returnlink8     pshs    x          save fdn pointer          ldx     ulstdr     point to active dir          lbsr    frefdn     free it up          puls    x          reset fdn ptr          lda     #EXDEV     crossed device error          sta     uerrorlink9     lbra    frefdn     free the fdn & return          pag** unlink** Unlink from file system call.*unlink    ldb     #1         set mem space          lbsr    pthnm      look for file nameunlinr    cmpx    #0         file not found?          lbeq    open3      if not, error          pshs    x          save fdn          tstb    null       file name?          beq     unlin8     if so - error          ldb     #FACUW     set write perm bit          lbsr    tstprm     test write permission          bne     unlin6     error?          ldd     ufdn       get fdn number          cmpd    fnumbr,x   unlinking '.'?          bne     unlin2          inc     frefct,x   bump ref count          bra     unlin3unlin2    ldd     fdevic,x   get device number          ldy     ufdn       get fdn number          lbsr    asnfdn     assign an fdn table entry          cmpx    #0         no entry?          beq     unlin6*          ldd     fnumbr,x   trying to delete ".badblocks"?          cmpd    #BADBFD          bne     unlin3     no          ldb     fmode,x          cmpb    #FBUSY     regular file          bne     unlin3     is not          ldb     facces,x   .badblocks has special permissions!          cmpb    #$80          beq     unlin9     -- yes - don't allow it!!!*unlin3    pshs    x          save new fdn          ldd     fdevic,x   get device number          ldy     2,s        get original fdn          cmpd    fdevic,y   mounted file?          bne     unlin7     if so, error          ldd     uipos2     get dir position          subd    #DIRSIZ+2  back up to this entry          std     uipos2     save new pos          ldd     #2         set up xfr count          std     uicnt          ldd     #nulfdn    point to null fdn          std     uistrt     set as start address          lbsr    filwr      go write dir          ldx     0,s        reset fdn pointer          lda     fdirlc,x   get link count          cmpa    #127       is it max?          beq     unlin4          dec     fdirlc,x   dec the link countunlin4    lda     fstat,x    get fdn status          ora     #FMOD      set mod flag          sta     fstat,x    save new statusunlin5    puls    x          release file fdn          lbsr    frefdnunlin6    puls    x          release parent directory fdn          lbra    frefdnunlin7    lda     #EPRM      set error          sta     uerror          bra     unlin5     finish upunlin9    lbsr    frefdn     release file fdnunlin8    lda     #EPRM      set error          sta     uerror          bra     unlin6     exit cleanup          pag** seek** Seek to position in file system call.*seek      ldb     urglst+UB  get file descriptor          clra          lbsr    getdes     get the file          beq     seek6      no file?          lda     ofmode,x   get file mode          bita    #OFPIPE    is it pipe?          beq     seek2          lda     #ESEEK     set seek error          bra     seek55seek2     ldy     ofnodp,x   get fdn pointer          ldd     usarg1     get lo offset          pshs    d          save it          ldd     usarg0     get hi offset          pshs    d          save it          ldd     usarg2     get key byte          beq     seek7      is it zero?          cmpb    #1         is it from cur pos?          bne     seek4          ldd     ofpos2,x   get lo offset          addd    2,s        add to seek cnt          std     2,s          ldd     ofpost,x   get hi offset          bra     seek45seek4     cmpb    #2         is it from file end?          bne     seek5          ldd     fsize+2,y  get hi part of size          addd    2,s        add in seek count          std     2,s          ldd     fsize,y    get lo part of sizeseek45    adcb    1,s        add in seek count          adca    0,s          std     0,s        save result          bra     seek7      go finishseek5     leas    4,s        remove seek argument          lda     #EBARG     error = "bad argument"seek55    sta     uerrorseek6     rts     returnseek7     ldd     0,s++      get new hi offset          bmi     seek8      if negative - error          std     ofpost,x   save in file table          std     urglst+UX  set for return x          puls    d          get lo part          std     ofpos2,x   save in file table          std     urglst+UA  set for return d          rts     returnseek8     leas    2,s        clean stack          lda     #ESEEK     set seek error          bra     seek55** dup** Duplicate open file system call.*dup       ldb     urglst+UB  get file desc.          clra          lbsr    getdes     get file for des          beq     dupof4     no file?          pshs    x          save file ptr          lbsr    makdes     get new file slot          puls    x          reset file ptr          bne     dupof4     error?          stx     0,y        save file ptr in file slot          inc     ofrfct,x   bump reference cnt          stb     urglst+UB  save new file desc.          clr     urglst+UAdupof4    rts     return** tstown** Test owner of file named in ucname.  Return* pointer in x to file if current user is* either file owner os super user.*tstown    ldb     #1         set mem space          lbsr    pthnm      find file specd          cmpx    #0         no file found?          lbeq    open3      if not, error          ldd     uuid       get user id          beq     tstow4     if su, ok          cmpd    fouid,x    check against file's owner          beq     tstow4     if same, ok          lbsr    frefdn     free the fdn          lda     #EPRM      set error          sta     uerror          ldx     #0         set errortstow4    rts     return          pag** chown** Change the owner of a file.  This is a system call.*chown     bsr     tstsu      is it su?          beq     chown2     if so, ok          rts     else       return errorchown2    ldb     #1         set mem space          lbsr    pthnm      find file specd          cmpx    #0         file found?          lbeq    open3      if not, error          ldd     usarg1     get new owner id          std     fouid,x    set in file          bra     chprm4     go finish up** chprm** Change the mode and access bits of a file.*chprm     bsr     tstown     is this guy owner?          cmpx    #0         if null, error          bne     chprm2          rts     return     errorchprm2    ldd     usarg1     get mode-access bits          andb    #$7f       mask access bits          lda     facces,x   get file's access bits          anda    #!$7f      clear out bits          pshs    a          orb     0,s+       put in new access bits          stb     facces,x   save new accesschprm4    lda     fstat,x    get file status          ora     #FMOD      set mod bit          sta     fstat,x    save new status          lbra    frefdn     free fdn & return          pag** chkacc** Check file access permissions - system call.*chkacc    ldb     #1         set mem space          lbsr    pthnm      process path name          cmpx    #0         file found?          lbeq    open3      if not, rpt error          ldd     uuid       get user id          pshs    d          save it          ldd     uuida      get actual user id          std     uuid       make it regular user id          ldd     usarg1     get perm bits          pshs    b          ldb     #FACUR     check for read request          bitb    0,s          beq     chkac2     if not, go ahead          lbsr    tstprm     else test read permission          bne     chkac4     error?chkac2    ldb     #FACUW     check write perm          bitb    0,s        request write check?          beq     chkac3          lbsr    tstprm     test write perm          bne     chkac4     error?chkac3    ldb     #FACUE     check for execute perm          bitb    0,s        execute requested?          beq     chkac4          lbsr    tstprm     test exec permchkac4    puls    b          clean up stack          puls    d          get user id back          std     uuid          lbra    frefdn     free up the fdn          pag** tstsu** Test if this guy is super user.  If not* set error and return 'ne' status.*tstsu     ldd     uuid       get user id          beq     tstsu2     if eq, ok          lda     #EPRM      set perm error          sta     uerrortstsu2    rts     return** dups** Dups system call*dups      ldb     urglst+UB  get file desc          clra    make       16 bits          cmpd    urglst+UX  same file already?          beq     dups6          lbsr    getdes     get file for this desc          beq     dups4      no file?          pshs    x          save file pointer          ldd     urglst+UX  get new file desc          lbsr    getdes     see if there is a file          beq     dups2      if not, skip ahead          lbsr    close2     close the filedups2     clr     uerror     reset error status          ldd     urglst+UX  get new desc          std     urglst+UD  save for return in d          aslb    find       file slot          ldy     #ufiles    point to open files          leay    b,y        find selected one          puls    x          get file pointer          stx     0,y        save in list          inc     ofrfct,x   bump file reference countdups4     rts     returndups6     clz     set        status          rts     return** nulfdn** Used for file name deletion*nulfdn    fdb     0