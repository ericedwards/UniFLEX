        lib     environment.h        lib     ../include/inttab.h        lib     ../include/sysdefs.h        lib     idedrvr.h        if      (IOP=1)        lib     ../include/fio.h        endif        data        sttl    Device Interrupt Handlers        pag        name    inthan        global  irqhan,frqhan,idle_tsk** irqhan** Machine interrupt handler* The irg interrupt handler is called after initial* system setup to process an irq type interrupt.*** memory trap should be handled with highest priority*irqhan  equ     **        lda     #$80                     get clock mask        bita    trpctrl                   highest priority        bmi     irqmtr* next check timer tick, this one arrives at 10 mS interval!        bita    timctrl                  check clock int        beq     irqha0                  no - try something else* handle debug acia, (polling)        if   (DBG=1)   jsr  debugi1        endif*        lda     timdata                 reset timer interrupt        jmp     clkint                  go process interrupt* check IDE controllerirqha0        if      (IDE=1)        ldu     idebase        lda     idestat,u        lbmi    ideint        endif* check IOP        if      (IOP=1)        ldy     #IOP0        ldu     fio_dba,y        ldb     fio_cpuF,u              test interrupt        lbne    fio_irq*        else        lda     IOP0BASE+$fe            IOP->CPU        endif* check UIO        if      (UIO=1)        ldy     #UIO0        ldu     fio_dba,y        ldb     fio_cpuF,u        lbne    uio_irq*        else        lda     UIO0BASE+$fe            UIO->CPU        endif*        if      (FLP=1)        ldu     #flpdpr        lda     flpint,u        lbne    flpirq         endif**       lda     SPI0BASE+$3fe        lda     NWP0BASE+$3fe* check INT from serial devicesirqha1  ldx     #inttab                 point to table        lda     0,x+                    get countirqha2  ldb     intype,x                check device type        ldb     inmask,x                get mask        andb    [instat,x]              check status        beq     irqha99                 jump if not interrupt        ldd     indev,x                 get device number        jmp     [inhand,x]              goto routine*irqha99 leax    INTSIZ,x                get to next entry        deca                            dec the count        lbne    irqha2                  repeat til done*        rts                             *** Unexpected interrupt - what else to do?? **** illegal memory access trap*irqmtr  equ     *         lda    trpdata         tst    <kernel     only if it came from user.....        bne    01f        ldd     #FALTS        jmp     swiha2                  post SIGNAL01      rts** frqhan** Handle the firq interrupt.  Works like irq.*frqhan  ldx     #fnttab                 point to tablefrqha2  ldb     inmask,x                get mask        andb    instat,x                check status        beq     frqha99        ldd     indev,x        jmp     [inhand,x]frqha99 leax    INTSIZ,x                next entry        cmpx    #fntend                 end of table?        bne     frqha2                  loop til done        rts                             return** idle_tsk** CPU Idle task*idle_tsk pshs   d,x,y,u                 save registers        jsr     dorand                  update random registers99      puls    d,x,y,u,pc              return