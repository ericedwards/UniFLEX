          lib     ./environment.h          if      (IOP=1)          opt     nol          lib     ../include/macdefs.h          lib     ../include/task.h          lib     ../include/tty.h          lib     ../include/sysdefs.h          lib     ../include/fio_codes.h        data          opt     lis          sttl    IOP        Interface          pag          data          global  iop_open,iop_close,iop_write,iop_read,iop_spcl          global  strm4iop,find_dn          global  iop_getd,iop_setd* during intialistation strm is added with # of iop ttys'* when initialisation is done strm is restoredstrm4iop  fcb     0          original strm value (tty on CPU)*** iop_open - Open a terminal on the IOP*   D = Device #*iop_open  pshs    d,x,y,u          lbsr    iop_fdv    compute device #          bcc     00f        jump if OK to open*          bra     14f*          ldb     #TTYOPR    hang up task          ldy     iop_open   ** this will never happen! **          jsr     sleep*00        pshs    d,y,u      save IOP parameters*05        ldb     #O_OPEN    send "open device" request          jsr     fio_msg          cmpb    #E_SYSBSY  if IOP saturated, try again          bne     10f*          jsr     p_iopbsy  print message          bra     05b*10        tstb          bpl     15f*14        lda     #EBDEV     yes - return error          sta     uerror          bra     20f*15        ldy     utask      set controlling terminal          ldd     tstty,y          bne     20f        jump if already set*          ldb     7,s         is this a terminal?          subb    #IOPTDMIN          cmpb    IOP0BASE+NUM_TRM    CPU tty's + IOP tty's          bhs     20f         no - don't screw up the tables          ldb     7,s         renew B*          ldx     ttytab     compute "TTY" table address          lda     #TTYSIZ          mul          leax    d,x          stx     tstty,y    set controlling terminal          ldd     6,s        restore device #          std     tdevic,x   set fake entry in TTY table20        puls    d,y,u      clean up stack*99        puls    d,x,y,u,pc** iop_close - Close a terminal at the IOP*iop_close pshs    d,x,y,u          lbsr    iop_fdv    compute device #          bcs     99f        jump if error          pshs    d,u,y      save IOP parameters*00        ldb     #O_CLOSE   send "close device" request          jsr     fio_msg          cmpb    #E_SYSBSY  if IOP saturated, try again          bne     10f*          jsr     p_iopbsy  print message          bra     00b*10        puls    d,u,y      clean up stack*99        puls    d,x,y,u,pc** iop_write - Write data to a terminal on the IOP*iop_write pshs    d,x,y,u          lbsr    iop_fdv    compute device #          bcs     99f        jump if error*          pshs    d,u,y      save IOP parameters Y - IOP control*00        ldd     uicnt      any data left?          beq     90f        no - exit*          cmpd    #1         single character write?          beq     50f        yes - special case*          ldb     #O_RQWR    send "request write data" request          jsr     fio_msg          cmpb    #E_IOERR   I/O Error? (possible on printers)          beq     80f*          cmpb    #E_SYSBSY  if IOP saturated, try again          bne     05f*          jsr     p_iopbsy  print message          bra     00b*05        jsr     get_F_S    allocate FIFO and a transaction slot          lda     #0         start queueing characters*10        pshs    a,x,y,u    save registers          lbsr    cpass      get character          puls    a,x,y,u    restore registers          bmi     20f        jump if no more*          jsr     FIFO_put   place character in FIFO          inca               update count          cmpa    #FIFO_SIZE          bne     10b*20        tsta               anything in FIFO?          beq     30f        no - exit*25        ldb     #O_WRITE   set Write code          jsr     fio_msg    signal IOP          cmpb    #E_SYSBSY  if IOP saturated, try again          bne     27f*          jsr     p_iopbsy  print message          bra     25b*27        jsr     FIFO_unlock release interlock          bra     00b        continue*30        jsr     FIFO_unlock release FIFO          bra     90f        exit* -- Special case for single character write50        pshs    x,y,u      save registers          lbsr    cpass      fetch character from user          puls    x,y,u      restore registers          lda     #O_WRC     write single character          exg     a,b        a=data, b=command          jsr     fio_msg    issue command          cmpb    #E_IOERR          bne     90f*80        lda     #EIO       some sort of I/O error          sta     uerror*90        puls    d,u,y      clean up stack*99        puls    d,x,y,u,pc** iop_read - Read data from a terminal at the IOP*iop_read  pshs    d,x,y,u          lbsr    iop_fdv    get IOP params          lbcs    99f        exit if error*          pshs    d,y,u      save IOP params*00        ldd     uicnt      how many more characters needed          beq     90f        exit if none*          ldb     #O_RQRD    inform IOP we need data          jsr     fio_msg          cmpb    #R_RD1C    single character returned?          beq     50f        yes - go process it*          jsr     get_F_S    allocate FIFO          ldd     uicnt      how much data to read?          cmpd    #FIFO_SIZE can move no more than FIFO          blo     05f*          ldd     #FIFO_SIZE*05        tfr     b,a        set request max size          ldb     #O_SEND    tell IOP to send data          pshs    a          save size of request          jsr     fio_msg          cmpa    #0         EOF?          beq     20f        yes - go process it*          pshs    a,b        save input count, response type*10        pshs    a,x,y,u    save registers          jsr     FIFO_get   get character          lbsr    passc send to user          puls    a,x,y,u    restore registers          deca    any        more this load?          bne     10b        yes - go get 'em*          jsr     FIFO_unlock & release it to world          puls    a,b        a=size returned, b=response code          cmpa    ,s+        less than requested amount          bne     90f        exit if not the same (must be less)*          cmpb    #R_SNDMC   Make sure there are more chars available          beq     00b*          bra     90f        exit* -- IOP returned EOF20        jsr     FIFO_unlock          puls    a          clean up stack          bra     90f        exit* -- Single character returned50        tfr     a,b        get character          pshs    x,y,u      save registers          lbsr    passc move to user          puls    x,y,u      restore registers90        puls    d,y,u      clean up stack* -- Try to even loading          ldy     utask          clr     tsact,y* --99        puls    d,x,y,u,pc** the transfer 6 bytes are used for ttyset/ttyget* the last two bytes are used to pass baudrate info* iop_spcl - Perform TTYSET/TTYGET for an IOP terminal* D = maj/min* X - =0 if doing ttyset*    <>0 if ttyget*iop_spcl  pshs    d,x,y,u          lbsr    iop_fdv    # on return Y=IOP0, U=mami, d=mami 0 rel          bcs     99f        jump if error00        pshs    d,y,u      save registers  D has 0 relative device          jsr     get_F_S    allocate FIFO and a transaction slot*          ldx     6+2,s      get ttyset/get parameter          cmpx    #0         ttyset?          bne     50f        no - do ttyget* SET          lda     #6         move ttyset data into FIFO          ldx     #usarg0*10        ldb     ,x+        move data          jsr     FIFO_put   into FIFO          deca          bne     10b*          ldx     #usarg0     from          ldd     6,s        device major/minor           bsr     ttyshad    shadow values in tty tables*10        ldb     #O_TTYS    send "ttyset" request          jsr     fio_msg          bra     90f        exit* GET50        ldb     #O_TTYG    send "ttyget" request          jsr     fio_msg*          pshs    x*          lda     #6         move data from FIFO into buffer60        jsr     FIFO_get   get data from FIFO          stb     ,x+          deca          bne     60b*          puls    x          ldd     6,s        device major/minor          bsr     ttyshad    set shadow registers*90        jsr     FIFO_unlock release FIFO buffer          puls    d,u,y      clean up stack*99        puls    d,x,y,u,pc** iop_getd, get special port data X is dest buffer*iop_getd   equ     *          pshs  d,x,y,u          lbsr  iop_fdv         Y=IOP0 U=mami, D=mami 0 rel         bcs    10f*          pshs  d,y,u          jsr   get_F_S         allocate fifo and transaction slot*          ldb   #O_PGETD          jsr   fio_msg*          ldx   6+2,s          lda   #401        jsr   FIFO_get          stb   0,x+          deca          bne   01b*08        jsr   FIFO_unlock          puls  d,y,u*10        puls  d,x,y,u,pc** iop_setd, set special port data, X is dest buffer*iop_setd  equ   *          pshs  d,x,y,u          lbsr  iop_fdv          bcs   10b*          pshs  d,y,u          jsr   get_F_S          fif and transaction buffer*          ldx   6+2,s          lda   #401        ldb   0,x+          jsr   FIFO_put          deca          bne   01b*          ldb   #O_PSETD          jsr   fio_msg*          bra   08b** D=maj/min, X = src* ttyshad, save ttyset/get values in tty tables*ttyshad   equ     *          pshs    d,x,y          ldy     ttytab          lda     #TTYSIZ          mul          leay    d,y          ldd     0,x          stb     tdelay,y          sta     tflags,y          ldd     2,x          sta     tcncl,y          stb     tbksp,y          ldd     4,x          anda    #$1c       config bits          sta     tbaud,y          andb    #HLDBTS          pshs    b          ldb     tstate,y          andb    #(!HLDBTS)&$ff    clear hold processing bits          orb     0,s+          stb     tstate,y          puls    d,x,y,pc** iop_fdv - Find device info for IOP terminal*    D - device #*    jsr iop_fdv*    B - device # (0..N)*    U - Sequence #/Terminal #*    Y - FIO interlock*    <Carry> if illegal device #*iop_fdv   pshs    d          save device #          subb    #IOPTDMIN          bmi     98f          cmpb    IOP0BASE+NUM_TRM          bhs     98f          stb     1,s        put corrected value 0 relative!          ldu     0,s        get device code          ldy     #IOP0          clc     no         error99        puls    d,pc       return*98        sec                error          puls    d,pc** find_dn - compute device # for a terminal on an IOP*   B - relative device #*   Y - IOP control address*   jsr find_dn*   D - absolute device #*find_dn   pshs    d,x,y,u    save registers          clra          addb    #IOPTDMIN          std     0,s        set return value          puls    d,x,y,u,pc return*p_iopbsy pshs    d,x,y,u          ldx     #00f***!!     jsr     Pdata          ldx     #$FFFF10        leax    -1,x          bne     10b*99        puls    d,x,y,u,pc*00        fcc     $d,'IOP Saturated!',0** findBRG - Find Baud rate generators*findBRG   rts        else*        datastrm4iop  fcb     0          original strm value (tty on CPU)        nop         endif         end