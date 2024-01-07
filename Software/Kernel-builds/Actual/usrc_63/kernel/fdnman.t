          lib     environment.h          sttl    Fdn        Managers          pag          name    fdnman          global  asnfdn,rdfdn,fdnbf,tstprm,frefdn,setfdnx          global  unlfdn,lckfdn,alfdn,frfdn,fndmnt,updfdn** asnfdn** Assign an fdn table entry to the fdn specified.* The fdn number is in Y, and the device number is* in D.  This routine falls through to 'rdfdn' if* there is not currently an entry in the table.* Ultimately, return is made with X pointing to the* fdn table entry.** [iget]asnfdn    lbsr    fndfdn     look for existing entry          bne     asnfd6     'ne' means none found          pshs    d,y        save fdn info          lda     fstat,x    get modes          bita    #FMNT      is it mounted on?          bne     asnfd4          ora     #FLOCK     set locked status          sta     fstat,x    save status          inc     frefct,x   bump the reference cnt          puls    d,y,pc     return*asnfd4    puls    d,y        reset fdn info          lbsr    fndmnt     do mount indirection          bra     asnfdn     repeat process*asnfd6    ldx     fdnfre+ffwdl get first free entry          bne     asnfd8          pshs    y,d        save fdn info          ldy     #lbolt     sleep on lbolt          ldb     #NFDNPR    set priority          lbsr    sleep      go to sleep!          puls    y,d        reset fdn info          bra     asnfdn     repeat whole process*asnfd8    std     fdevic,x   set in device number          sty     fnumbr,x   set in fdn number          ldd     ffwdl,x    get fwd link          std     fdnfre+ffwdl remove from free list          bne     asnfd9     last free fdn?          std     fdnfre+2   set back link nullasnfd9    ldd     fdnbsy+ffwdl put in busy list          stx     fdnbsy+ffwdl at head of list          std     ffwdl,x    set fwd link          lda     #FLOCK     lock the fdn          sta     fstat,x          lda     #1         set reference cnt to 1          sta     frefct,x   fall thru to rdfdn          pag** rdfdn** Read the fdn data from disk into the fdn table* entry pointed at by X.  This routine is entered* from above only.*rdfdn     pshs    x          save fdn pointer          bsr     fdnbf      find fdn 4·1:³32ı172923272ı97ı89´9<9°ğ21:³32ı0²292ıı619ı1¸<ħ:91·¸<20ş0:72·:9<8:ĥ9<3²ş1:³32ı42°²2ı619ı392²ħ3392²:¸1:³32ı8:ĥ9<8192ş:ı7ı23278:ĥ9<    get the fdn entry          lda     #$ff       set a bad device number          sta     fdevic,x   to disassociate fdn from device          lbsr    frefdn     free it up          ldx     #0         return 0 fdn ptr          rts                return** fdnbf** Find the buffer which contains the specified fdn.**[bread]fdnbf     pshs    x          save fdn pointer          clr     FD_stat          ldd     fdevic,x   get device number          pshs    d          save it          ldd     fnumbr,x   get fdn number          addd    #15        calc disk address          lsra    there      are 8 fdn's per block          rorb          lsra          rorb          lsra          rorb          tfr     d,x        save block number in x          puls    d          get device number          ldy     #0         set msb of block number          inc     FD_stat          lbsr    rdbuf      read in block          lda     bfflag,y   check io error          bita    #BFERR          bne     fdnbf4     'ne' if error          tfr     y,x        save buffer ptr          ldy     0,s        point to fdn entry          ldd     fnumbr,y   get fdn number          decb    dec        by one          andb    #7         calc buffer offset          lda     #64        which is (fdn&7)*64          mul     offset     now in d          tfr     d,u        we want it in u          leay    fmode,y    point to data area          ldd     #FDNSIZ-fmode set data xfr count          leas    2,s        fix stack          inc     FD_stat          sez     set        return status          rts                return*fdnbf4    lbsr    freebf     free up the buffer          pshs    a          lda     #$88          sta     FD_stat          puls    a          clz     set        error status          puls    x,pc       return          global  FD_statFD_stat   fcb     0** fndfdn** Look in the fdn table for the fdn of device in D* and fdn number in Y.  Return a pointer (X) to the* entry if found (also 'eq' status), otherwise* return 'ne' status showing not found.  If entry* exists but is locked, sleep til ok.*fndfdn    ldx     #fdnbsy    get list headerfndfd2    ldx     ffwdl,x    follow link          beq     fndfd4     if empty, do nxt list          cmpy    fnumbr,x   is it right fdn number?          bne     fndfd2          cmpd    fdevic,x   does device match?          bne     fndfd2          pshs    d          save device number          lda     fstat,x    get status          bita    #FLOCK     is it locked?          puls    d          beq     fndfd3     if eq, then ok          pshs    y,d        save fdn info          lda     fstat,x    get status again          ora     #FWLCK     set wait bit          sta     fstat,x    save status          ldb     #FDNPR     set priority          tfr     x,y        point to fdn          lbsr    sleep      sleep on fdn          puls    y,d        reset fdn info          bra     fndfdn     repeat search*fndfd3    rts                return eq status*fndfd4    pshs    u          save u reg          ldx     #fdnfre    get free listfndfd6    tfr     x,u        save last entry          ldx     ffwdl,x    follow link          beq     fndfd8     end of list?          cmpy    fnumbr,x   fdn number match?          bne     fndfd6          cmpd    fdevic,x   devic number match?          bne     fndfd6          pshs    d          save device          ldd     ffwdl,x    get fwd link          std     ffwdl,u    remove from list          bne     fndfd7     end of list?          cmpu    #fdnfre    only one in list?          bne     fndf65          std     fdnfre+2   set list null          bra     fndfd7*fndf65    stu     fdnfre+2   set new bk linkfndfd7    ldd     fdnbsy+ffwdl link into busy list          std     ffwdl,x    set fwd link          stx     fdnbsy+ffwdl put at list head          sez     set        eq status          puls    d,u,pc     return*fndfd8    clz     set        ne status          puls    u,pc       return** tstprm** Check mode permission on inode pointer.* Mode is READ, WRITE or EXEC.* In the case of WRITE, the* read-only status of the file* system is checked.* Also in WRITE, prototype text* segments cannot be written.* The mode is shifted to select* the owner/other fields.* The super user is granted all* permissions.* Test permission to manipulate the file in the* specified manner.  B contains the permission* bit and x is pointing to the fdn requested.* Return 'eq' status if ok to access.**[access]tstprm    pshs    b          save permission bit          bitb    #FACUW     check write type          beq     tstpr1     not writing?          ldd     fdevic,x   get device number          pshs    x          save fdn pointer          jsr     fndsir     find its sir          tst     swprot,x   is it read-only?          puls    x          reset fdn ptr          bne     tstpr6     if so - exit error          ldb     fstat,x    get status          bitb    #FTEXT     is it busy text?          bne     tstpr6     if so - errortstpr1    ldb     0,s        get permissions          bitb    #FACUE     check execute permission          bne     tstp15     jump if set** test for .badblocks, not any permission bits set*          lda     facces,x   check for "execute only"          bpl     tstp15     not .badblocks          bitb    #(FACUR|FACUW)|((FACUR|FACUW)<<3) must not have any read/write perms          bne     tstpr8     screwy error if sotstp15    ldd     uuid       get user's id          bne     tstpr4     is it system manager?          ldb     0,s        get permission bit          bitb    #FACUE     execute permission?          beq     tstpr2          lda     facces,x   get access codes          bita    #FACUE|(FACUE<<3) is ex bit set          bne     tstpr2     if so, ok          lda     fmode,x    get modes          bita    #FSDIR     is fdn a directory?          beq     tstpr6     if not, no good!tstpr2    sez     set        ok status          puls    b,pc       return* is the caller the file owner?tstpr4    cmpd    fouid,x    is this guy file owner?          beq     tstpr5          ldb     0,s        get permission bit          aslb    shift      to 'others' position          aslb          aslb          stb     0,s        put back over oldtstpr5    ldb     0,s        get permission bit          bitb    facces,x   check access code          bne     tstpr2     if ne, oktstpr6    ldb     #EPRM      set permission errortstpr7    stb     uerror          clz     set        no good          puls    b,pc       returntstpr8    ldb     #ENOFL     No file - execute only and other access          bra     tstpr7          pag** setfdnx** Set a FDN to be an "execute only" file.*  D - Complement of file descriptor*setfdnx   coma          comb    get        real file descriptor          pshs    d          save FD          jsr     tstsu      must be the system manager          puls    d          bne     10f        jump if not          jsr     getdes     map descriptor onto in core FDN          cmpx    #0         legal file descriptor?          bne     20f        yes - continue10        rts                return error exit*20        ldx     ofnodp,x   get FDN pointer          lda     facces,x   turn on "execute only" bit          ora     #$80          sta     facces,x          lda     fstat,x    mark FDN modified          ora     #FMOD          sta     fstat,x          rts                all done          pag** frefdn** Disassociate from the fdn table entry pointed* at by X.  If this is the last reference to the* entry, update the fdn info on disk if required,* and free up the table entry.**[iput]frefdn    lda     frefct,x   get the reference count          deca    dec        by one          bne     frefd8     is this the last ref?          lda     fstat,x    get status          ora     #FLOCK     lock this entry          sta     fstat,x    save new status          lda     fdirlc,x   get dir link count          bgt     frefd4     if >0 go ahead          lbsr    rmvfil     else remove the file          clr     fmode,x    clear out modes          pshs    x          save fdn          ldd     fdevic,x   get device number          ldy     fnumbr,x   get fdn number          lbsr    frfdn      free up the disk fdn          puls    x          reset fdn ptrfrefd4    lbsr    updfdn     update the fdn info          bsr     unlfdn     unlock the fdn          clr     fstat,x    clear out the status          ldy     #fdnbsy    point to busy listfrefd5    cmpx    ffwdl,y    look for this guy          beq     frefd6          ldy     ffwdl,y    follow link          bne     frefd5     if not end, loop          ldx     #fdngon    point to string          lbra    blowup     fdn not in table!frefd6    ldd     ffwdl,x    get link          std     ffwdl,y    remove from list          clra    --         ldd #0 set 0 link          clrb          std     ffwdl,x    makes end of list          ldy     fdnfre+2   get back link          bne     frefd7     last in list?          stx     fdnfre     set new free list          stx     fdnfre+2   set back too          bra     frefd8frefd7    stx     ffwdl,y          stx     fdnfre+2   set new back linkfrefd8    dec     frefct,x   dec the reference count          pag** unlfdn** Unlock the fdn pointed at by X.*unlfdn    lda     fstat,x    get status          anda    #!FLOCK    clear lock bit          sta     fstat,x    set back new status          bita    #FWLCK     someone waiting?          beq     unlfd2          anda    #!FWLCK    clear wait bit          sta     fstat,x    set new status          pshs    x          save pointer          ldy     0,s        point to fdn          lbsr    wakeup     wakeup those waiting          puls    x,pc       return*unlfd2    rts                return** lckfdn** Lock the fdn pointed at by Y.  If already locked,* sleep on the fdn.*lckfdn    lda     fstat,y    get status          bita    #FLOCK     is it locked?          beq     lckfd2     if not, we got it          ora     #FWLCK     set wait lock status          sta     fstat,y    save new status          ldb     #FDNPR     set priority          pshs    y          save fdn pointer          lbsr    sleep      sleep on fdn          puls    y          reset fdn          bra     lckfdn     repeat*lckfd2    ora     #FLOCK     lock the fdn          sta     fstat,y    save the new status          rts                return          pag** alfdn** Allocate an fdn from the list of available fdns* in the sir.  If none in list, fill the list* by reading the fdns on the disk.  Enter with* the device number in D.  Exit with the fdn table* entry pointed at by X.*alfdn     pshs    d          save device number          lbsr    fndsir     find the sir          beq     alfdn6     none found?alfdn2    lda     slkfdn,x   is fdn list locked?          beq     alfdn3          pshs    x          save sir          leay    slkfdn,x   point to lock          ldb     #FDNPR     set priority          lbsr    sleep      go sleep          puls    x          reset sir          bra     alfdn2     repeat*alfdn3    lda     snfdn,x    get list count          beq     alfdn5     is list empty?alfd35    leay    scfdn,x    point to fdn list          deca    dec        the count          sta     snfdn,x    save new total          asla    multiply   offset by 2          ldy     a,y        get fdn number          pshs    x          save sir          ldd     2,s        get the device number          lbsr    asnfdn     get an fdn table entry          cmpx    #0         no entry avail?          beq     alfdn7          pshs    x          save fdn entry          leay    fmode,x    point to disk part          lda     #FDNSIZ-fmode set counteralfdn4    clr     0,y+       clear out table entry          deca    dec        the count          bne     alfdn4     finished?          ldx     0,s        point to fdn          lda     #FBUSY     set fdn busy          sta     fmode,x          lda     #FMOD      set modified flag          sta     fstat,x          ldy     2,s        point to sir          ldd     sfdnc,y    get total fdn count          subd    #1         dec by one          std     sfdnc,y    save new value          lda     #1         set update flag          sta     supdt,y          lbsr    updfdn     updata the fdn on disk          clz     set        status          puls    x,y        reset regs          puls    d,pc       return          pag** Get to this part of alfdn if no entries left in* sir free fdn list.  Read the fdns off the disk* to rebuild the sit list.*alfdn5    ldd     0,s        get the device number          bsr     filfdn     fill up the fdn list          lda     #1         set update flag          sta     supdt,x          lda     snfdn,x    get list count          bne     alfd35     repeat if have some          lda     #EDFUL     set error          sta     uerror          ldx     #0         set null fdnalfdn6    puls    d,pc       return*alfdn7    leas    2,s        reset stack          puls    d,pc       return** frfdn** Free the fdn whose number is in Y, from the* device in D.*frfdn     pshs    d,y        save data          lbsr    fndsir     find the sir          beq     frfdn4     no sir?          pshs    x          save the sir          ldd     sfdnc,x    get total count          addd    #1         increase by 1          std     sfdnc,x    save new value          tst     slkfdn,x   is fdn list locked?          bne     frfdn2          lda     snfdn,x    get list count          cmpa    #CFDN      is it max?          beq     frfdn2     if so, exit          asla    calc       offset          leay    scfdn,x    point to list          leay    a,y        point to entry          ldd     4,s        get fdn number          std     0,y        save in list          inc     snfdn,x    bump list countfrfdn2    puls    x          clean up stack          lda     #1         set update flag          sta     supdt,xfrfdn4    puls    d,y,pc     return          pag** filfdn** Fill the fdn list in the sir pointed at by X.* The device associated with the sir is in D.*filfdn    pshs    d,x        save data          inc     slkfdn,x   lock the fdn list          ldd     #2         set starting disk block (first fdn)          pshs    d          save          clrb    set        counter to 0          pshs    d          save it** here we check against .badblocks ** 20221206 CS*          ldd     4,s        get DEVICE for .badblocks          ldy     #BADBFD    FDN for .badblocks          jsr     asnfdn*          clra    --         ldd #0 scan - starting with block # 0          clrb          pshs    d          reference .badblocks fdn          pshs    d          - logical block #          pshs    d          - physical block #          pshs    d          - 32 bit          stx     6,s        allocate and test          beq     filfd2     not available* check it is REALLY .badblocks!          lda     facces,x          cmpa    #%10000000 special permission pattern          beq     09f        it, is          jsr     unlfdn     if it is not, it can be even _this_ directory          bra     filfd2     which would lock up the system*09        ldy     #0         fdn high block# always 0          ldx     4,s        get next logical block # from file          clr     umaprw          jsr     mapfil     - returns next physical block # in file          beq     filfd2     skip if no more          stx     2,s        save block # on stack          sty     0,s** loop here to fill free fdn list in SIR*filfd2    ldx     10,s       get FDN block #          tst     1,s        FDN block #'s are small (no high byte ever!)          bne     2f          cmpx    2,s        check block #          bne     2f         jump - not a bad block*          clra    --         ldd #0 yes - don't use it!          clrb          std     0,s          std     2,s          ldd     4,s        bump logical block # in .badblocks          addd    #1          std     4,s          ldd     8,s        fix up fdn count          addd    #512/64    fdn's / block          std     8,s*          ldu     6,s        get .badblocks fdn again          beq     2f         not available          ldy     #0          ldx     4,s        find next bad block          clr     umaprw          jsr     mapfil          beq     filf45     jump if no more          stx     2,s          sty     0,s          bra     filf45     try next block***2         ldy     #0         set to read FDN block for scan          ldd     12,s       get DEVICE code          jsr     rdbuf      read FDN block Y.X.D          pshs    y          save buffer ptr          ldx     0,s        point to buffer          lbsr    mapbpt     map in buffer          ldb     #512/64    set fdns/block counter          pag** This part of filfdn reads the blocks of the* fdn list on the disk until either the fdn* list in the sir is full (CFDN entries), or* the end of the fdn list on the disk is reached.*filfd3    inc     11,s       bump the fdn counter          bne     filf35          inc     10,s       bump hi part of countfilf35    tst     0,x        is entry busy?          bne     filfd4          pshs    b          save counter          ldy     17,s       get the sir pointer          lda     snfdn,y    get the list counter          inc     snfdn,y    bump the list counter          leay    scfdn,y    point to fdn list          asla    calc       offset          pshs    a          save offset          leay    a,y        point to this cell          ldd     12,s       get the fdn number          std     0,y        save in fdn list          puls    d          cmpa    #((CFDN-1)*2) is list full?          beq     filfd5filfd4    leax    64,x       move to next entry in block          decb    dec        the counter          bne     filfd3     repeat til done          puls    y          get the buffer ptr          lbsr    freebf     free up the bufferfilf45    ldd     10,s       get the block number          ldx     14,s       point to sir          cmpd    sszfdn,x   end of fdn list?          bhi     filfd6          addd    #1         bump to next block          std     10,s       save block number          lbra    filfd2     repeat process** done*filfd5    puls    y          get buffer          lbsr    freebf     free it up*filfd6    leas    6,s        pop file map pointer          ldx     0,s++      get .badblocks FDN pointer          beq     3f         jump if not there          jsr     frefdn     free the FDN*3         leas    4,s        clean up stack          ldy     2,s        get the sir ptr          leay    slkfdn,y   point to fdn lock          clr     0,y        unlock the list          lbsr    wakeup     wakeup those sleeping          puls    d,x,pc     return          pag** fndmnt** Look for the specified fdn in the mount table.* X is pointing to the fdn entry.  Returns with* the mounted device number in D and the fdn* number of its root fdn in Y (1).*fndmnt    ldy     mtable     point to table          ldb     smnt       get mount countfndmn2    cmpx    mnodep,y   look for fdn ptr          beq     fndmn4          leay    MSTSIZ,y   move to next entry          decb    dec        the mount count          bne     fndmn2     repeat          ldx     #mntgon    point to message          lbra    blowup     device not there!fndmn4    ldd     mdevic,y   get device number          ldy     #1         set root fdn number          rts     return          pag** updfdn** Update the fdn on the disk.  X points to the* fdn in the fdn table.*updfdn    pshs    x          save fdn pointer          lda     fstat,x    get fdn status          bita    #FMOD      has it been modified?          beq     updfd6     if not, no update          anda    #!FMOD     clear mod bit          sta     fstat,x    save new status          ldd     fdevic,x   get device number          lbsr    fndsir     find its sir          lda     swprot,x   is it write ptotected?          bne     updfd6     if so, no update          ldx     0,s        point to fdn          lbsr    fdnbf      find fdn in buffer          bne     updfd6     error?          pshs    x          save buffer header          pshs    x,u        save xfr info          lbsr    cpystb     copy fdn info to buffer          puls    x,u        reset header and offset          ldy     #stimh     point to system time          ldd     #4         set xfr count          leau    FDNSIZ-fmode,u point to fdn time          lbsr    cpystb     copy table info to buffer          puls    y          get buffer header          lbsr    wbflat     write out the bufferupdfd6    puls    x,pc       return