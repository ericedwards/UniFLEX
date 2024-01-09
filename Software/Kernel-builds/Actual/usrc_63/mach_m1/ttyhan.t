       lib     ttyhan.h       sttl    tty handlers pag       name    ttyhan       global  ttyren,ttyst,ttyout,ttyin,ttyrd,ttywrt,flusho       global  ttyi27 Boo-Hiss!!!** All code in this section is the common tty handler* code.  The device dependent code resides with the* drivers.  This handler package requires an ACIA be used* for all character type devices.*** ttyren** Re-enable the tty output after a timeout operation.* Upon entry, x should point to the tty structure.*ttyren lda     tstate,x    check state       bita    #HOLD       bne     ttyst9       anda    #!TIMOUT    clear time out       sta     tstate,x    reset state       ldy     taddr,x       beq     ttys55       jsr     ttenxr      enable xmit interrupts pag** ttyst** TTY start will output a character to the terminal.* Upon entry, x should point to the tty structure in* use.  Getc is called for the character.*ttyst  ldy     taddr,x     get device address       beq     ttys55       jsr     ttxbsy      test xmit busy?       beq     ttys55ttyst1 lda     tstate,x       bita    #TIMOUT       bne     ttyst9       ldy     tqout,x     get out q       lbsr    getc        get character       bmi     ttyst9       lda     tflags,x       bita    #RAW        test raw mode       bne     ttyst2       tstb                char negative?       bmi     ttyst6ttyst2 ldy     taddr,x     get device address       jmp     ttputc      write characetrttys55 rtsttyst6 cmpb    #$ff        is it special hold char?       bne     ttyst7       lda     tstate,x    get states       bita    #XANY       allowing any restart char?       bne     ttys65      branch if so       bita    #ESCOFF     doing ESC processing?       beq     ttys65      branch if so       bita    #XONXOF     doing XON/XOFF processing?       beq     ttys55      swallow character if no hold processingttys65 ora     #TIMOUT|HOLD set hold mode       sta     tstate,x    reset states       bra     ttyst9ttyst7 andb    #$7f        mask hi bit       ldy     #ttyren       lbsr    timout      do time out       lda     tstate,x       ora     #TIMOUT     set time out       sta     tstate,xttyst9 ldy     taddr,x     get port       jmp     ttdisx      disable xmit interrupts pag** ttyout** Put the character in b into the output q.  Upon* entry, x should point to the tty structure.  Tab* expansions, upper case mapping, and special character* handling are all done here.*ttyout lda     cbufct      check buffers       cmpa    lcbuf       bhi     ttyo05       lda     [tqout,x]   get out q count       cmpa    #CHRLIM     limit?       blo     ttyou1ttyo05 pshs    b       lbsr    flusht      flush this guy       puls    bttyou1 lda     tflags,x    get flags       bita    #RAW        raw mode?       beq     ttyo12       lda     tstate,x    no hold in RAW mode       anda    #!HOLD       sta     tstate,x       ldy     tqout,x     point to out q       lbsr    putc        put char in q       lbra    ttyoue      go finishttyo12 cmpb    #$ff        special hold char?       beq     ttyou6        lda     tbaud,x        anda    #%00011100   extract acia config        cmpa    #%00010000   check 8 bits NOP        beq     10f        cmpa    #%00010100        beq     10f        andb    #$7f mask parity bit10      cmpb   #TABCH       bne     ttyou2       lda     tflags,x    check mode       bita    #XTABS      expand tabs?       beq     ttyou2ttyo14 ldb     #SPACE       bsr     ttyout      output it       lda     tcolm,x     check column       bita    #7       bne     ttyo14       rtsttyou2 lda     tflags,x    check mode       bita    #LCASE      lower case mode?       beq     ttyou4       cmpb    #'a         lower case letter?       blo     ttyo22       cmpb    #'z       bhi     ttyo22       subb    #$20        make upper       bra     ttyou4ttyo22 ldy     #lcht       point to mapttyo23 cmpb    0,y++       bne     ttyo24       ldb     -1,y        get mapped char       pshs    b       ldb     #'\         output escape       bsr     ttyout       puls    b       bra     ttyou6ttyo24 tst     0,y         end of list?       bne     ttyo23ttyou4 cmpb    #CR       bne     ttyou6       lda     tflags,x    check mode       bita    #CRMOD       beq     ttyou6       ldb     #NL         convert to NL       lbsr    ttyout      output it       ldb     #CR         reset CRttyou6 ldy     tqout,x     point to out q       lbsr    putc       bpl     ttyou7       rts                 returnttyou7 cmpb    #CR       bhi     ttyou8       bne     ttyo75      is it cr?       clr     tcolm,x     clear out colum71���:���:<����1��1��4��4�:0�1�0�0��2���172�27�2�<�27�22�0�����620�:1��6�<3��1��:��1���:�0�20����6����67���14�9��0�20��0�24�:0��9�0�:1��6�<9��2�72��1��:���190�27�2�<�27�22�0�����:<���1��1�� ���4��4�1��:97�1�0���167�::<�����4�1�  tcolm,x     bump column countttyoue lda     tstate,x ** kludge for ACIA **       bita    #HOLD       bne     ttyoe1       ldy     taddr,x     get device address       jmp     ttenxr      enable xmit interruptsttyoe1 rts                 return** dodely** Do delay processing on output.*dodely cmpb    #$08        hardware backspace?       blo     ttyoue       bne     dodel2       tst     tcolm,x     column zero?       beq     ttyoue       dec     tcolm,x       bra     ttyouedodel2 lda     tdelay,x    get delay byte       beq     ttyoue      exit if no delays set       ldy     #dlcht      point to delay table       subb    #9          remove bias (char between 9 and $d)       aslb                multiply by 2       leay    b,y         get table entry       anda    0,y         mask delays flags       beq     ttyoue      none for this char?dodel4 lsra                shift count to lsb       bcc     dodel4       rola                put low bit back       ldb     1,y get     delay unit amount       mul                 calculate delay* flag delay as special character to process       orb     #$80        set hi bit for delays       ldy     tqout,x     point to out q       lbsr    putc        put in q       bra     ttyoue      go finish updlcht  fcb     DELTB,2       fcb     DELNL,1       fcb     DELVT,24       fcb     DELFF,28       fcb     DELCR,1lcht   fcc     "~^|!{(})`'"       fcb     0 pag** ttyin** Place the character in b on the input q.* Upon entry, x should point to the tty structure.* Signal processing and character mapping are* performed in this roiutine.*ttyin  lda     tflags,x    raw mode?       bita    #RAW       bne     ttyi44       andb    #$7f        mask par bitttyin0 cmpb    #SPACE      control char?       bhs     ttyi44      skip junk if sottyin2 cmpb    #QUITC       beq     ttyi25       cmpb    #INTRC       bne     ttyin3       ldd     #INTS       set signal       bra     ttyi27ttyi25 ldd     #QUITS      set signalttyi27 lbsr    intrpt      issue intrpt       jmp     flusht      flush buffersttyin3 cmpb    #HOLDC      is it HOLD character (ESC)?       bne     ttyi34       lda     tstate,x       bita    #ESCOFF     is ESC processing disabled?       bne     ttyi34       bita    #HOLD       holding??       beq     ttyi3httyi3r anda    #!HOLD      clear hold mode       sta     tstate,x       jmp     ttyrenttyi3h ora     #TIMOUT|HOLD set HOLDing       sta     tstate,x       jmp     ttyrenttyi34 cmpb    #XOFFC      is it XOFF?       bne     ttyi36       lda     tstate,x       bita    #XONXOF     are we doing XON/XOFF?       beq     ttyin4       bita    #HOLD       already holding?       beq     ttyi3h      if not, turn on hold       lbra    ttyin9      if so, ignore characterttyi36 cmpb    #XONC       is it XON?       bne     ttyin4       lda     tstate,x       bita    #XONXOF     are we doing XON/XOFF?       beq     ttyin4       bita    #HOLD       are we holding?       bne     ttyi3r      if so, turn off hold       lbra    ttyin9      if not, ignore characterttyin4 cmpb    #CR         new line?       bne     ttyi44       clr     tcolm,x     clear out columnttyi44 lda     tstate,x    see if XANY set       bita    #XANY       beq     ttyi48      skip if not       bita    #HOLD       if so, are we holding?       bne     ttyi3r      if so, turn off holdttyi48 lda     [tqin,x]    check q count       cmpa    #CHRLIM     hit limit?       lbhs    flusht      flush this guy!       lda     cbufct      check buffer count       cmpa    lcbuf       lbhi    flusht      if overflow, flush!       lda     tflags,x    check mode       bita    #RAW        raw mode?       beq     ttyin5       ldy     tqin,x      get in q       lbsr    putc        put char in q       ldy     tqin,x      get in q       pshs    b           save char       lbsr    wakeup      awaken those waiting       puls    b           get character       inc     tdel,x      bump delimiter count       rts                 returnttyin5 bita    #LCASE       beq     ttyin6       cmpb    #'A         capital letter?       blo     ttyin6       cmpb    #'Z       bhi     ttyin6       addb    #$20        make lower casettyin6 ldy     tqin,x      point to input q       lbsr    putc       lda     tflags,x    check mode       bita    #SCHR       single char mode?       bne     ttyi65       cmpb    #CR       bhi     ttyin7       beq     ttyi65       cmpb    #EOTCH       bne     ttyin7ttyi65 ldy     tqin,x      point to input q       pshs    b       lbsr    wakeup      wake up waiting       inc     tdel,x      bump countttyi67 puls    b           reset charttyin7 cmpb    tcncl,x     kill character?       bne     ttyin8       lda     tflags,x    check mode       bita    #SCHR       single character?       bne     ttyin8       ldb     #'^         output '^x\n'       lbsr    ttyout       ldb     #'x       lbsr    ttyout       ldb     #CR       lbsr    ttyout       jmp     ttystttyin8 lda     tflags,x    check mode       bita    #ECHO       beq     ttyin9       cmpb    tbksp,x     back space?       bne     ttyi85       bita    #BSECH      echo bs?       beq     ttyi85       ldb     #$08        set bs       lbsr    ttyout       ldb     #SPACE      set space       lbsr    ttyout       ldb     #$08        reset charttyi85 lbsr    ttyout      echo character       jmp     ttyst       start outputttyin9 rts                 return pag** flusht** Flush all queues belonging to this terminal.*flusht ldy     tqproc,x    get procd qflush1 lbsr    getc        get character       bpl     flush1       ldy     tqout,x     point to out qflush2 lbsr    getc        flush out q       bpl     flush2       ldy     tqin,x      get input q       lbsr    wakeup      wakeup input q waiters       ldy     tqout,x     wake up out q waiters       lbsr    wakeup       ldy     tqin,x      flush input qflush3 lbsr    getc       bpl     flush3       clr     tdel,x      clear delim count       lda     tstate,x    get states       anda    #!(HOLD|TIMOUT) clear hold mode       sta     tstate,x       jmp     ttyst** flusho** Flush all this guys queues after waiting for the* output q to empty.*flusho lda     tstate,x    check state       bita    #HOLD       holding?       beq     fluso1fluso0 anda    #!(HOLD|TIMOUT)       sta     tstate,x    clear hold       lbsr    ttyren      kick outputfluso1 lda     [tqout,x]   check char count       beq     flusht       lda     tstate,x    check for hold       bita    #HOLD       bne     fluso0 if 0 *** I don't think this can work here - GDT 4/1/85 *** pshs x save ptr ldx taddr,x get device address jsr ttiscts check for CTS puls x reset tty ptr beq flusht if not - just flush the guy endif       ldy     tqout,x     point to out q       ldb     #TTYOPR     set priority       pshs    x           save x       lbsr    sleep       puls    x       bra     fluso1** xtprcq** Transfer characters from input q to procd q.  If not* in raw mode, do escape, backspace, and cancel* processing.  Enter with x pointing to tty structure.*xtprcq pshs    cc          save cc       seti                mask ints       tst     tdel,x      delimiters yet?       bne     xtprc0       ldy     tqin,x      sleep on input q       ldb     #TTYIPR       pshs    x           save x       lbsr    sleep       puls    x       puls    cc          reset cc       bra     xtprcqxtprc0 puls    cc          reset cc       tst     [tqin,x]    input q empty?       bne     xtprc1       dec     tdel,x      dec the del count       bra     xtprcq      repeat testxtprc1 ldy     utask       get task entry       clr     tsact,y     zero activity counter* tst tsage,y age zero?* beq xtpr15* dec tsage,y dec the age*xtpr15       ldy     #prcbuf+2   point to buffer       pshs    y       clrb       pshs    b           delimiter flagxtprc2 tst     0,s         delimiter?       beq     xtpr22       clr     0,s         clear del flag       tst     tdel,x      check del count       beq     xtpr21      if 0 - skip       dec     tdel,x      dec the del countxtpr21 lda     tflags,x    get flags       bita    #RAW|SCHR   in raw mode?       lbeq    xtprc5xtpr22 ldy     tqin,x      point to in q       lbsr    getc        get a character       bmi     xtprc5      none left?       cmpb    #CR         check for delim       beq     xtpr25       cmpb    #EOTCH       bne     xtprc3       inc     0,s         set del flag       lda     tflags,x    get flags       bita    #SCHR       single char mode?       bne     xtprc2xtpr25 inc     0,s         set del flagxtprc3 lda     tflags,x    check mode       bita    #RAW|SCHR       beq     xtpr31       inc     0,s         set del flag for each raw char       bra     xtpr45xtpr31 ldy     1,s         point to buffer       lda     -1,y        check previous       cmpa    #'\         escape?       bne     xtca32       cmpb    #EOTCH      is it eot?       beq     xtp315       cmpb    tbksp,x     backspace char?       beq     xtp315       cmpb    tcncl,x     cancel char?       bne     xtca32xtp315 leay    -1,y        backup over slash       sty     1,s         save new ptr       bra     xtpr45xtca32 cmpb    tbksp,x     backspace char?       bne     xtca33       cmpy    #prcbuf+2   buffer begin?       beq     xtprc2       leay    -1,y        backup pointer       sty     1,s       bra     xtprc2xtca33 cmpb    #EOTCH      eot char?       beq     xtprc2       cmpb    tcncl,x     cancel char?       bne     xtprc4       puls    b       puls    y       lbra    xtprc1      repeat allxtprc4 cmpb    #$20        check for control char       bhs     xtpr45       cmpb    #CR         is it cr?       beq     xtpr45       cmpb    #9          is it tab char?       beq     xtpr45       lda     tflags,x    get flags       bita    #CNTRL      control char ignore?       lbne    xtprc2xtpr45 ldy     1,s         get pointer       stb     0,y+        transfer char       sty     1,s         save pointer       cmpy    #prcbuf+PRCSIZ overflow??       lblo    xtprc2xtprc5 puls    b           remove del flag from stack       ldy     tqproc,x    get procd q       pshs    x       ldx     #prcbuf+2   point to processed bufxtprc6 cmpx    2,s         end of buffer?       bhs     xtprc7       ldb     0,x+        get character       lbsr    putc       bra     xtprc6xtprc7 ldd     #-1         set good       puls    x,y,pc      return pag** ttyrd** Main terminal read routine.  Control is passed to here* from the device driver routine which calculates the* tty structure location.  This structure is pointed to* by x.*ttyrd  tst     [tqproc,x]  check q count       bne     ttyrd2       lbsr    xtprcq      fill procd q       beq     ttyrd3ttyrd1 tst     [tqproc,x]  check q count       beq     ttyrd3ttyrd2 ldy     tqproc,x    point to procd q       lbsr    getc       lbsr    passc       put in user buffer       bpl     ttyrd1      repeatttyrd3 rts                 return pag** ttywrt** The main terminal write routine.  Control is passed* to here from the device driver routine which calculates* the ttys structure location and passes it in x.*ttywrt lbsr    cpass       get char from user       bmi     ttywr5       pshs    b           save itttywr2 lda     [tqout,x]   check q count       cmpa    #OQHI       too many here?       bls     ttywr3       pshs    cc          save status       sei                 mask ints       lbsr    ttyst       start output       puls    cc          reset cc       lda     tdelay,x    replaces **'d code 5/9/83       bita    #$40        ** Special FLUSH bit **       beq     ttyw25**  ldd uuida super user ??? (kludge here ******)**  addd uuid ** Effective & Actual id = 0**  bne ttyw25**  ldy utask get task entry**  cmpx tstty,y sending to someone elses tty?**  beq ttyw25 if not - skip       jsr     flusho      flush this guy       bra     ttywr2      repeatttyw25 ldy     tqout,x     point to out q       pshs    x           save x       ldb     #TTYOPR     set priority       lbsr    sleep       ldx     utask       **** experimental *****       clr     tsact,x     zero activity counter ****       puls    x       bra     ttywr2ttywr3 puls    b           reset characterttywr4 lbsr    ttyout      output it       bra     ttywrt      repeatttywr5 pshs    cc          save cc       sei                 mask ints       lbsr    ttyst       give output a kick       puls    cc,pc       return