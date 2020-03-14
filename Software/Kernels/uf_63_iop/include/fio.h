 sttl FIO Simulation Structure pag*** Control structure used to simulate Z8038 FIO* is now performed by CY7C130 dual port RAM where (1024 * 8)* the RAM size is limited to the (upper) 256 bytes, which* contains the Interrupt handshake locations** -- As seen by Main 6809 CPU (UniFLEX)*FIFO_SIZE       equ     128             Size of FIFO buffer                ifnc    &a,'IOPCPU'      non-kernel IOP driver build                base    $0000           -- Dual port RAM                else                org     $0000           -- Shared Dual Port RAM                endif************************************************************iop_cpu         rmb     1               IOP -> CPU Mailbox celliop_cpu1        rmb     1               -- Additional celliop_cpu2        rmb     1               --iop_cpu3        rmb     1               --************************************************************cpu_iop         rmb     1               CPU -> IOP Mailbox cell          message codecpu_iop1        rmb     1               -- Additional cell    sequence #cpu_iop2        rmb     1               --                    message specific datacpu_iop3        rmb     1               --                    terminal #************************************************************fifo_cnt        rmb     1               Count of data in FIFOfifo_get        rmb     2               FIFO consumer pointerfifo_put        rmb     2               FIFO producre pointer                rmb     16-(*-iop_cpu)  ** Filler **fifo            rmb     FIFO_SIZE       actual FIFO                rmb     $100-(*-iop_cpu)-7* IOP Configuration constantsNUM_TSK         rmb     1               Number of tasksNUM_CL          rmb     1               Number of CLISTSNUM_TRM         rmb     1               Number of terminals              initialized from IOPNUM_NEC         rmb     1               Number of NEC/Qume printersNUM_PPR         rmb     1               Number of parallel printers* should end up at the two top locations in the DUALPORT RAMiop_cpuF        rmb    1       INT + non-zero   contains info AND set CPU IRQ when writtencpu_iopF        rmb    1       INT + non-zero   contains info AND set IOP IRQ when written**************************************************************                ifc    &a,'IOP'** IOP Task Priority*   -- Set to make task uninterruptable while*   -- actually using the IOP*IOPPRI          set     15** IOP Control structures** Transaction slots                base    0tran_seq        rmb     1               Transaction sequence #tran_resp       rmb     1               Transaction response codetran_val        rmb     1               Transaction specific value (returned character, etc)tran_oval       rmb     1               Output specific valuetran_msg        rmb     1               Message code senttran_dev        rmb     1               Device code*TRAN_SIZ        equ     *                endifMAX_TRAN        equ     24              Max # concurrent transactions / IOP                ifc    &a,'IOP'* IOP Control                base    0iop_mbx         rmb     2               Mailbox interlock - Task id of lockeriop_fifo        rmb     2               FIFO interlock - Task id of lockeriop_int         rmb     1               Set non-zero if message interrupt was missediop_tflg        rmb     1               Waiting on transaction slot semaphoreiop_dba         rmb     2               base address of deviceiop_tran        rmb     MAX_TRAN*TRAN_SIZE      transaction slots*IOP_SIZE        equ     *                endif