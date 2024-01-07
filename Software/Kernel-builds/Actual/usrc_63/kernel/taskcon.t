          lib     environment.h          sttl    Task       Controllers          pag          name    taskcon          global  exec,fork,wait,term,lexit** exec** System call to initiate a new task.  The current* task is overlayed with the new file.** sys exec,filename,args**      filename fcc "/bin/ls",0                 >> usarg0*          arg0  fcc "ls",0*      arg1  fcc "baba",0*      arg2  fcc "ccd",0*          args  fdb  arg0,arg1,arg2,0          >> usarg1**P_TRC     equ     0exec          if    (/Ş)!59ı8:90ħ²31ħ2˘ĵ2ħ42ı22·24³6219²ş6²ĥ·ı<9¸0ħ²619ı8:47667·µş¸34ĥ270ĥ²4³(/Ş)!59ı8:90ħ²31ħ2¨0ş470ĥ²897ħ²ıı²²2·24³1ĥ¸<;°ı4ş37ş·2612¸7¸2·4³77ş2ı97ı4³(/Ş)!59ı8:90ħ²31ħ2£7ş·234ĥ22·24³89´9 x          save file          lda     fmode,x    get file mode          bita    #(FSBLK|FSCHR|FSDIR) is it special?          bne     execr4     if so error          ldb     #FACUE     setup execute perm bit          lbsr    tstprm     test for execute permission          bne     execr2     if not, error          ldy     0,s        point to file          leas    -BHDSIZ,s  save room for bin header          sts     uistrt     set start pointer          ldd     #BHDSIZ    get header size          std     uicnt      set read count          ldd     #0         position to file begin          std     uipos          std     uipos2          sta     uiosp      set system space          if      P_TRC          jsr     ptrace          fcc     $d,'Reading Binary Header',0          endif          lbsr    filrd      go read in header          tst     uerror     any errors?          bne     execr1          leau    0,s        get data pointer          ldx     BHDSIZ,s   get file pointer          lbsr    tstbin     test binary file          bne     execr1     is it valid?          if      P_TRC          jsr     ptrace          fcc     $d,'Getting arguments',0          endif          lbsr    gtarg      get arguments          tst     uerror     was there an error?          beq     exec4      if not, jump aheadexecr1    leas    BHDSIZ,s   clean up stackexecr2    puls    x          get fdn pointer          lbra    frefdn     free up fdn & exitexecr4    lda     #ENOTB     set bad file error          sta     uerror     save in error          bra     execr2          pag** If we get here in exec, we are ok to load in the* new program and run it.  There is no turning back!*exec4     tfr     cc,a       save status          seti    mask       interrupts          if      P_TRC          jsr     ptrace          fcc     $d,'Changing user blocks',0          endif          lbsr    xmapsp     change to new user block          stb     usrtop     let system know about it          pshs    a          save status          lbsr    fremem     free old memory          ldb     usrtop     get new user block          stb     umem+USRHIP set in mem map          ldx     utask      point to task table entry          stb     tsutop,x   set user top here          inc     usizes     set stack size to 1          ldb     #1         set swap image size          stb     tssize,x   save in task entry          puls    cc         reset status          lbsr    fretxt     free text segment          clr     usizet     clear text size          ldd     bhsym,s    get text and sata sizes          if      P_TRC          jsr     ptrace          fcc     $d,'Assign memory',0          endif          lbsr    asnmem     assign new memory          ldb     bhsym+2,s  get stack size          beq     exec5      need to grow?          lbsr    grows      go grow stackexec5     ldb     bhsym,s    get text size          beq     exec55     is it null?          ldy     BHDSIZ,s   get fdn pointer          jsr     asntxt     assign text segmentexec55    leau    0,s        point to file data          if      P_TRC          jsr     ptrace          fcc     $d,'Loading program image',0          endif*! by calling fixarg early we can expand the memory* available for a process by about 3.5 KByte*          lbsr    fixarg     shift user args up first          leax    0,s        restore x*          lbsr    ldfil      load in binary file          lda     uerror     any error during load?          beq     exec57     no - keep going          cmpa    #EBBIG     special error?          bne     exec57          ldd     #(BARGS<<8)|$FF yes - blow the new task away          std     usarg0          leas    BHDSIZ,s   clean up stack          puls    x          get fdn pointer          lbsr    frefdn     free the fdn entry          lbra    lexitexec57    clr     uerror          ldx     BHDSIZ,s   get fdn pointer          lda     facces,x   get access bits          bita    #FXSET     set user id?          beq     exec6          ldd     fouid,x    get file's owner id          std     uuid       set in user block as user id          ldx     utask      point to task table          std     tsuid,x    save new id in task tableexec6     ldx     utask      get task entry          lda     tssize,x   get mem size          sta     umxmem     set max mem          ldd     actfil     is accounting active?          beq     exec65          ldd     uexnam     is name already set?          bne     exec65          jsr     getexe     get exec name table entry          stx     uexnam     set name          ldb     #8         set count          ldy     #uwrkbf    point to file nameexec62    lda     0,y+       get character          sta     0,x+       save in table          decb          bne     exec62     repeat?exec65    lda     #$80       set up new registers          ldx     #urglst    point to register list          sta     UCC,x      set cc reg          ldd     bhxfr,s    get transfer address          std     UPC,x      set new pc          ldd     #0          std     uprfsc     disable profiling          std     UD,x       clear d reg          std     UX,x       clear x reg          if      P_TRC          jsr     ptrace          fcc     $d,'Fix up arguments',0          endif*! lbsr fixarg relocate arg list          leas    BHDSIZ,s   clean up stack          puls    x          get fdn pointer          lbsr    frefdn     free the fdn entry          if      P_TRC          jsr     ptrace          fcc     $d,'Ready to go',0          endif          lbra    rstint     reset the ints & return          if      P_TRC** ptrace - Print a trace message*          global  ptraceptrace    pshs    d,x,y,u    save registers          ldx     8,s          jsr     Pdata      print message          ldx     8,s        set up return address00        tst     ,x+          bne     00b          stx     8,s          puls    d,x,y,u,pc return** pargs - print system call arguments*          global  pargspargs     pshs    d,x,y,u          ldx     #pargsm00          jsr     Pdata          ldd     usarg0          bsr     phex2          ldx     #pargsm01          jsr     Pdata          ldd     usarg1          bsr     phex2          ldx     #pargsm01          jsr     Pdata          ldd     usarg2          bsr     phex2          puls    d,x,y,u,pcphex2     pshs    d          lda     0,s          jsr     Phex          lda     1,s          jsr     Phex          puls    d,pc*pargsm00  fcc     $d,'System Call Arguments = $',0pargsm01  fcc     ', $',0          endif          pag** gtarg** Get arguments from user space and place in a* new user block segment.  Return the new block* number in b.*gtarg     tst     corcnt     any memory?          bne     gtarg2          inc     inargx     bump in arg count          jsr     argexp     do expansion swap          dec     inargx          bra     gtarg      repeatgtarg2    lbsr    getpag     get a new usr block page          pshs    b          save block number          lda     umem+USRHIP get current user block          lbsr    segcop     copy it to new segment          ldb     0,s        reset new block number          lda     #SBUF      set sbuffer designator          lbsr    mapspg     map new block to sbuffer          ldx     usarg1     get argument pointer          ldd     #0         set counter to 0          pshs    d,x        save parameters          ldy     #SBUFFR+4  point to sbuffergtarg3    lbsr    gtuwrd     get a word from user          std     0,y++      save arg pointer in sbuf          beq     gtarg4     end of args?          ldx     2,s        get arg pointer          leax    2,x        bump to next arg pointer          stx     2,s        save new pointer          cmpy    #SBUFFR+USTKO-STKREG-2 check for arg overflow          bhs     gtarg9          ldd     0,s        get arg counter          addd    #1         bump by 1          std     0,s        save new count          bra     gtarg3     repeatgtarg4    puls    d,x        clean up stack          pshs    y          save buffer pointer          ldy     #SBUFFR+2  reset buffer pointer          std     0,y++      save arg count in user blockgtar45    ldx     0,y        get arg pointer          beq     gtarg7     finished?          ldd     0,s        get data pointer          anda    #$0f       mask off page number          ora     #USRHIP_4  set in users hi page          std     0,y++      set new data pointer          pshs    y          save position          ldy     2,s        point to next buffer address          pshs    x          save arg pointergtarg5    lbsr    gtubyt     get arg byte from user          stb     0,y+       save in user block          beq     gtarg6     finished?          cmpy    #SBUFFR+USTKO-STKREG buffer overflow?          bhs     gtarg8          ldx     0,s        get arg pointer          leax    1,x        bump to next byte          stx     0,s        save new value          bra     gtarg5     repeatgtarg6    sty     4,s        save new buffer end          puls    x,y        reset stack          bra     gtar45     repeat for next arggtarg7    puls    y          point to end of data          ldd     #0         set up 0 word          std     0,y++      mark end of arg list with 0          sty     SBUFFR     save end pointer in buffer          puls    b,pc       returngtarg8    leas    2,s        clean stackgtarg9    leas    4,s        clean stack          puls    b          get allocated usr block          lbsr    givpag     free it up          lda     #EARGC     set arg oflow error          sta     uerror          rts     return          pag** tstbin** Test if file to be loaded is binary, and if* so, what type.  On entry, U is pointing to* a block of data which is the 'binhdr' structure.* On exit, bhsym,u thru bhsym+2,u has the size* of the text, data, and stack segments, resp.* X points to the FDN of the file being executed.*tstbin    lda     bhhdr,u    get header byte          cmpa    #BNHEAD    is it correct?          bne     tstbi8          lda     bhdes,u    get descriptor byte          cmpa    #$10       check range of desc.          blo     tstbi8          cmpa    #$12          bhi     tstbi8     report any errors          lda     facces,x   check permissions          bpl     tstbi1     jump if "execute only" bit not set          ldd     bhsrn,u    must have a serial # if set          beq     tstbi8     -- errortstbi1    ldd     bhsrn,u    get serial number of file          beq     tstbi2     is it null?          subd    unisrn     does sn match system sn?          beq     tstbi2     yes - jump          subd    bhsrn,u    check for UniFLEX serial # = -1 (Universal key)          subd    #1          bne     tstbi8     if not, error!tstbi2    lda     bhdes,u    get descriptor          bita    #BHDRO     read only text?          bne     tstbi4     go ahead if so          ldd     bhtxt,u    get text size          addd    bhdat,u    add to data size          std     bhdat,u    save as new data size          ldd     #0         clear out text size          std     bhtxt,utstbi4    ldd     bhtxt,u    get text size          beq     tstbi5     if zero, jump ahead          std     usarg3     save text size          subd    #1          rpt    4           shift 4 places          lsra          incatstbi5    sta     bhsym,u    save text segment count          ldd     bhdat,u    get data size          addd    bhbss,u    add in bss section          bcs     tstbi9     overflow?          beq     tstbi6     no data?          subd    #1          rpt     4          lsra          incatstbi6    sta     bhsym+1,u  save data segment count          ldd     bhstk,u    get stack size          beq     tstbi7     is it zero?          subd    #1          rpt     4          lsra          incatstbi7    sta     bhsym+2,u  save stack segment count          adda    bhsym,u    add up all segments          adda    bhsym+1,u          cmpa    #USRHIP    too many segments?          bhi     tstbi9     if so, error          clra    set        true          rts     returntstbi8    lda     #ENOTB     set not binary error          sta     uerror          rts     error      returntstbi9    lda     #EBBIG     set bin too big          sta     uerror     set as error          rts     return** fixarg** Fix the location of the arguments.  gtarg left* them at the bottom of the user block.  They* need moved up to final resting place.*fixarg    ldb     usrtop     get new user block          lda     #SBUF      map into SBUFFER          lbsr    mapspg          ldy     SBUFFR     get arg end pointer          ldx     #SBUFFR+USTKO point to user stack startfixar2    lda     0,-y       move data up in memory          sta     0,-x          cmpy    #SBUFFR+2  end of data?          bne     fixar2     loop til done          ldb     #STKREG    set reg count for 63X09fixar4    clr     0,-x       clear out regs on stack          decb    dec        the counter          bne     fixar4          tfr     x,d          pshs    x          save stack pos          anda    #$0f       mask page bits          ora     #USRHIP_4  set so in stack page          std     usp        save as new stack pointer          leax    STKREG+2,x point to args          tfr     x,d          subd    #SBUFFR+4  find offsetfixar6    ldy     0,x        get an arg          beq     fixar7     end of list?          leay    d,y        add in offset          sty     0,x++      save new arg pointer          bra     fixar6     repeat loopfixar7    ldx     #SBUFFR    point to block startfixar8    clr     0,x+       zero out unused parts          cmpx    0,s        finished?          bne     fixar8          puls    d,pc       return          pag** ldfil** Load a binary file into memory.  If absolute* call lafil.  U points to binary header data.*ldfil     ldd     #0         set up initial load params          std     uipos      clear hi position word          std     uistrt     set address of 0          sta     uerror     make sure starting with clean slate...          lda     #1         set memory space = user          sta     uiosp      set mem space byte          lda     bhdes,u    get the descriptor          bita    #BHDAB     is it absolute?          bne     lafil          lda     usizet     get text size          clrb          asla    shift      to hi nibble          asla          asla          asla          std     uistrt     set start load address          ldd     #BHDSIZ    calculate read count          addd    bhtxt,u    add in text size          std     uipos2     set as position          ldd     bhdat,u    get data size          std     uicnt      set byte count          ldy     BHDSIZ,u   get fdn pointer          lbra    filrd      go read in data** lafil** Read in absolute binary file.*lafil     ldd     #BHDSIZ    set position          std     uipos2          ldy     BHDSIZ,u   get fdn pointer          pshs    y          save it          leas    -ABHDSZ,s  save stack room for abs headerlafil2    ldd     #ABHDSZ    set header size count          std     uicnt      set data count          sts     uistrt     set read address          clr     uiosp      set for system space          ldy     ABHDSZ,s   get fdn pointer          lbsr    filrd      read in abs header          ldd     absct,s    get data count          beq     lafil4     is it null?          std     uicnt      set data count* patch to capture malformed headers          cmpd    fsize+2,y  check with size in inode          bhs     lafil6     error*          ldd     absad,s    get load address          cmpa    #USRHIP_FC  validate address          blo     lafil25lafil6    lda     #EBBIG          sta     uerror          bra     lafil4lafil25   std     uistrt     set for load          inc     uiosp      set for user space          ldy     ABHDSZ,s   get fdn pointer          lbsr    filrd      read in record          bra     lafil2     repeatlafil4    leas    ABHDSZ,s   clean up stack          puls    y,pc       return** getexe** Get an exec name table entry - return in x.*getexe    ldx     exctbl     get table start          ldb     stsk       get max task countgetex2    tst     0,x        slot empty?          beq     getex4          leax    8,x        bump to next entry          decb    dec        the count          bne     getex2          ldx     #noxnms    point to panic          jmp     blowup     blowup!getex4    rts     return          pag** fork** System call for doing a task fork*fork      clr     0,-s       set counter to zero          ldx     tsktab     point to task table          ldd     uuid       get user id          ldy     #0         set a null pointerfork1     tst     tsstat,x   check entry's status          bne     fork2      if != 0 then busy          cmpy    #0         have we found an entry yet?          bne     fork3          leay    0,x        remember this empty entry          bra     fork3fork2     cmpd    tsuid,x    is this task one of this guys?          bne     fork3          inc     0,s        if so, count itfork3     leax    TSKSIZ,x   bump to next entry          cmpx    tskend     end of task table?          bne     fork1      if not, repeatfork5     puls    b          get task counter          cmpb    smxj       too many tasks for this guy?          bls     fork6          ldd     uuid       are we user id 0?          bne     fork9      if not, errorfork6     cmpy    #0         did we find a task slot?          beq     fork9      if not, error          ldd     utask      get user's task entry          pshs    d,y        save pointers          lbsr    lfork      generate new task          puls    x,y        reset data pointers          cmpd    #1         are we the new task          beq     fork8      if so, jump ahead          ldd     tstid,y    get childs task id          std     urglst+UD  return in Dfork7     ldd     urglst+UPC get user pc (original task)          addd    #2         bump by 2          std     urglst+UPC save new value          rts     return     (original task)* NEWfork8     ldd     tstid,x    this is new task          std     urglst+UD  return task id          ldx     #utimu     point to timer bytes          ldb     #utimsc+4-utimu set byte countfork85    clr     0,x+       zero out times          decb          bne     fork85          ldd     stimh      get start time          std     ustart     set in task          ldd     stiml          std     ustart+2          ldd     #0         zero info in task          std     uexnam          std     uiocnt          ldx     utask      get task entry          lda     tssize,x   get mem size          sta     umxmem     set max mem value          rts     return     (new task)fork9     lda     #ETMTS     set too many error          sta     uerror          bra     fork7      return to original          pag** wait** System call for task wait.*wait      clr     0,-s       zero a counter          ldx     utask      point to task entry          ldd     tstid,x    get task id          ldx     tsktab     point to task tablewait2     cmpd    tstidp,x   look for tasks whose parent          bne     wait4      id equals the current tasks id          inc     0,s        found one, so count it          pshs    a          lda     tsstat,x   get task's status          cmpa    #TTERM     is it terminated?          puls    a          beq     wait6      if so, we found a dead child!wait4     leax    TSKSIZ,x   move to next task          cmpx    tskend     end of list?          bne     wait2      repeat til all          lda     0,s+       get task counter          bne     wait5      any found?          lda     #ENCHD     if not, no children tasks!          sta     uerror     set error          rts     returnwait5     ldy     utask      point to task          ldb     #WAITPR    set priority          lbsr    sleep      sleep for child          bra     wait       repeat searchwait6     ldd     tstid,x    get task id          std     urglst+UD  return to caller in D          ldd     #0         finish off the child now          std     tstty,x    by zeroing out data          std     tstid,x          std     tstidp,x   clear parent          std     tsalrm,x   and alarm counter          sta     tssgnl,x          std     tsstat,x          ldu     tsswap,x   get swap ptr          beq     wait8      if zero - jump ahead          pshs    x,y        need to get time info from data pool          clr     0,u+       free pool buffer          ldx     #utimuc    point to this guys childs time          jsr     dotim1     update time info          leax    4,x        bump to next time slot          leau    4,u          jsr     dotim1     update time slot          puls    x,y        reset the ptr junkwait8     ldd     tstext,x   get termination status          std     urglst+UX  return to caller in X          puls    a,pc       return          pag** term, lexit** System call for task exit (termination)*term      ldd     urglst+UD  get exit status          clra    --         only low 8 bits count!          std     usarg0     save as argumentlexit     ldd     actfil     doing accounting?          beq     lexit1          jsr     wrtact     write out acc infolexit1    ldx     #usigs     point to interrupt table          ldb     #SIGCNT    set counter          pshs    b          save the count          ldd     #1         set ignored interruptlexit2    std     0,x++      set ignored          dec     0,s        dec the count          bne     lexit2          puls    b          reset stack          ldy     #ufiles    point to open file listlexit3    ldx     0,y++      get file pointer          beq     lexit4     is it null?          pshs    y          save position          ldd     #0         set file to null          std     -2,y          lbsr    close2     close t4234ĥ28:ĥ9<92ı²ş:0ħ6287´·:2ıĥ2ĵ4ş1ĥ¸<ş³4ĥ2ı*§#$Ĥ)2·27³64ış17262ĵ4ş3          lbsr    fretxt     free the text segments          ldy     ucrdir     get current directory          lbsr    lckfdn     lock its fdn          ldx     ucrdir     point to current dir          lbsr    frefdn     free its fdn          ldy     utask      point to task entry          lda     #TTERM     set terminated status          sta     tsstat,y          ldd     tstidp,y   get parent's task idlexit5    ldx     tsktab     point to task tablelexit6    cmpd    tstid,x    look for parent task in table          beq     lexit7          leax    TSKSIZ,x   bump to next task entry          cmpx    tskend     end of list?          bne     lexit6          ldd     #1         set parent task id as 1          bra     lexit5     repeat search (real parent dead!)lexit7    pshs    x,y        save some stuff          bsr     prpgat     propagate time info up tree          ldy     tsktab     point to tasks          leay    TSKSIZ,y   point to task #1          lbsr    wakeup     wake it up          puls    y          get parent's task entry          lbsr    wakeup     wakeup parent          ldb     umapno     get task map #          pshs    b          save on stack          ldx     1,s        get current task entry          bsr     ochld      orphan children          lbsr    fremem     free up tasks memory          puls    x,b        get task entry, map #          lbsr    fremap     free mem map register          lbra    rsched     re-schedule the cpu          pag** prpgat** Propagate a childs user and system time info* up to his parent.* Modified 2-9-81: There was a serious bug which occured* when a terminating task's parent was swapped.  This* routine would grab that task's user-top (which was not* valid) and update the time there.*prpgat    ldd     usarg0     get exit status          std     tstext,y   save in text slot          ldd     #0         zero out alarm          std     tsalrm,y          std     tsswap,y   zero swap map          lda     tsmode,x   get parent's mode          bita    #TCORE     is he swapped??          bne     prpga4     if not - jump ahead          bsr     fnddp      find a data pool buffer          bne     prpga2     if none found -          rts     just       return (no big loss)prpga2    stx     tsswap,y   save data ptr in swap ptr          inc     0,x+       mark buffer used          bra     prpga6prpga4    ldb     tsutop,x   get user top location          lda     #SBUF      map in system buffer          lbsr    mapspg          ldx     #utimuc-(USERBL&$F000)+SBUFFR point to time infoprpga6    ldy     #utimu     point to user time          ldu     #utimuc    and childs user time          bsr     dotim      update user time          leay    3,y        point to system time          leax    4,x          leau    4,u** dotime** Update the time counters pointed at by x and y.*dotim     ldd     1,y        get task time lo          addd    2,u        add ti childs time lo          std     2,u        save result          ldb     0,y        get task time hi          lda     #0         make 16 bits long (preserve carry)          adcb    1,u        add to childs hi          adca    0,u          std     0,u        save resultdotim1    ldd     2,u        get total tasks time lo          addd    2,x        add to parents times          std     2,x        save in parents          ldd     0,u        get hi part          bcc     dotim2          addd    #1         add in carrydotim2    addd    0,x        get hi total          std     0,x        save result hi          rts     return          pag** ochld** Orphan any children tasks who may be associated* with the task whose table entry is in x.*ochld     ldd     tstid,x    get task id          ldx     tsktab     point to task tableochld2    cmpd    tstidp,x   parent to this one?          bne     ochld4          pshs    d          save id          ldd     #1         set parent id to task #1          std     tstidp,x          puls    d          reset idochld4    leax    TSKSIZ,x   bump to next task          cmpx    tskend     end of list?          bne     ochld2     repeat          rts     return** fnddp** Find a data pool buffer.  If one found, return in X* and 'NE' status.*fnddp     ldx     dpoolb     get pool start addressfnddp2    tst     0,x        this slot busy?          beq     fnddp4     if not - jump ahead          leax    DPLSIZ,x   bump to next entry          cmpx    dpoole     end of pool?          bne     fnddp2     repeat          rts     return     'EQ' (not found)fnddp4    ldd     #0         zero out buffer          std     1,x          std     3,x          std     5,x          std     7,x          inca    set        'NE' (found one)          rts     return** argexp** Do expansion swap since we need a block for the new* usr block in exec.  Called from 'gtarg'.*argexp    sts     umark2     save stack          ldx     utask      get task entry          ldb     #1         set for mem free          jsr     swpout     swap out task          lda     tsmode,x   get modes          ora     #TSWAPO|TARGX set mode          sta     tsmode,x          jmp     change     change tasks** wrtact** Write task accounting info to accounting file.*wrtact    tst     sabbsy     is buffer busy?          beq     wrtac2          ldy     #sabbsy    point to flag          ldb     #BUFPR     set priority          jsr     sleep      sleep til free          bra     wrtactwrtac2    ldd     actfil     is it active?          beq     wrtac8          inc     sabbsy     set busy status          ldb     #SABSIZ    set count          ldx     #sabufr    point to bufferwrtac4    clr     0,x+       zero the buffer          decb          bne     wrtac4          ldx     #sabufr    point to buffer start          ldy     #wrttbl    point to write tablewrtac5    ldu     0,y++      get address          ldb     0,y+       get byte count          bsr     wrtxfr     transfer bytes          cmpy    #wrtend    end of transfer?          bne     wrtac5          ldy     utask      get task entry          ldy     tstty,y    get tty entry          ldd     tdevic,y   get device number          tsta    is         major device 0 (is it tty?)          beq     wrtac6     if so - ok          ldb     #255       set no tty valuewrtac6    stb     sabufr+actty save in buffer          leax    2,x        skip spare bytes          ldu     uexnam     any name?          beq     wrtac7          ldb     #8         set count          bsr     wrtxfr          clr     [uexnam]   free entrywrtac7    clr     uiosp      set system space          ldd     #sabufr    point to buffer          std     uistrt     set io start addr          ldd     #SABSIZ    set xfr count          std     uicnt          ldx     actfil     get file table          ldy     ofnodp,x   get fdn          ldd     ofpost,x   get file position          std     uipos          ldd     ofpos2,x          std     uipos2          jsr     filwr      go write file          ldx     actfil     get file pointer          ldd     ofpos2,x   add in xfr count          addd    #SABSIZ          std     ofpos2,x          bcc     wrtac8          ldd     ofpost,x   get hi part          addd    #1          std     ofpost,xwrtac8    ldy     #sabbsy    wakeup any waiting          clr     0,y          jmp     wakeup     and return** wrtxfr** Transfer B bytes from u to x.*wrtxfr    lda     0,u+       get a byte          sta     0,x+       save it          decb    dec        the count          bne     wrtxfr          rts     return** wrttbl*wrttbl    fdb     uuida          fcb     2          fdb     ustart          fcb     4          fdb     stimh          fcb     4          fdb     utims          fcb     3          fdb     utimu          fcb     3          fdb     usarg0          fcb     2          fdb     usarg0          fcb     1          fdb     umxmem          fcb     1          fdb     uiocnt          fcb     2wrtend    equ     *          end of table