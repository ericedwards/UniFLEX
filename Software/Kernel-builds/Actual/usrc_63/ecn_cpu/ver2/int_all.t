          sttl    Interrupt  All Tasks          pag** Interrupt all tasks associated with a given device*   A - Device #*   jsr int_all* Note: The current task is skipped, along with* the system and the interrupt handler task (1).*int_all   pshs    d,x,y          ldb     NUM_TSK          subb    #2          ldx     tsktab          leax    2*TSKSIZ,x*10        cmpa    tsdev,x    is this guy associated with the device?          bne     20f*          cmpx    utask      make sure I don't get blown away          beq     20f*          pshs    d,x          jsr     xmtint     interrupt task          puls    d,x*20        leax    T)����<72�::0����22��0�<�6��2�:0������172��1��8:�9�2<<�81�92�:�7