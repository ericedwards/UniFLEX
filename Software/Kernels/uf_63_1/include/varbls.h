          sttl    System     Variables          pag     ** Miscellaneous System Variables*** All in this block are in system page (SYSPAG).*          base    SYSPAG<<12irqvec    rmb     2          irq vectorswivec    rmb     2          swi vectorsw2vec    rmb     2          swi2 vectorsw3vec    rmb     2          swi3 vectornmivec    rmb     2          nmi vectorfrqvec    rmb     2          firq vectorcputyp    rmb     1          cpu typecpumod	  rmb	   1	    cpu mode (6309/6809) ###usrtop    rmb     1          segment number of current user top pagekernel    rmb     1          flag set if in kernal address space*chproc    rmb     1          scheduling flagchgvec    rmb     2          change tasks vectorcorcnt    rmb     1          core segment countlstmem    rmb     2          end marker of memory tableteluch    rmb     1          tell rom to change user map ###rndval	rmb	2			random number ###sbpag     rmb     1          current system buffer pagerunlst    rmb     2          head of linked list of running tasksslplst    rmb     4          head of sleep linked list*rtdir     rmb     2          pointer to fdn of root directorygentid    rmb     2          generic for unique task id'srdytci    rmb     1          ready to come in flagrdytgo    rmb     1          ready to go out flagjobpri    rmb     1          scheduling infostimh     rmb     2          system time - hi partstiml     rmb     2          system time - lo partlbolt     rmb     1          lightning bolt event flagtzone     rmb     2          time zone bias (minutes)dstflg    rmb     1          daylight savings flaghertz     rmb     1          clock tick counter*restim    rmb     1          task residence timeupdlck    rmb     1          lock for sys updatertdev     rmb     2          device of rootpipdev    rmb     2          pipe deviceswapdv    rmb     2          swap deviceswploc    rmb     2          location of swap spacecfreel    rmb     2          clist free headercbufct    rmb     1          clist buffer countlcbuf     rmb     1          last char buffer counttmhead    rmb     2          timeout list head*tmavl     rmb     2          timeout available listtmlst     rmb     2          last timeout slotmemfst    rmb     2          first avail memory segmentmemlst    rmb     2          last avail memory segmentsyspnt    rmb     2          temp system map pointertxttab    rmb     2          start of text tabletimtab    rmb     2          start of timeout tablemtable    rmb     2          start of mount table*tsktab    rmb     2          start of task tabletskend    rmb     2          end of task tablehdrtab    rmb     2          start of header tablecbuffr    rmb     2          start of character bufferfdntab    rmb     2          start of fdn tableofiles    rmb     2          start of open file tablettytab    rmb     2          start of tty tablesttqtab    rmb     2          start of tty q headers*fdnbsy    rmb     2          head of busy fdn'sfdnfre    rmb     4          head of free fdn'sfstsir    rmb     2          list of sir blockstgtbuf    rmb     6          buffer for ttygetlkbeg     rmb     2          begin of lock table*lkend     rmb     2          end of lock tabletmtupf    rmb     1          auto update flagtmtuct    rmb     1          auto update counterswpend    rmb     2          end of swap table pointerswpbeg    rmb     3          swap space start addressswpsiz    rmb     2          swap space block countswpisz    rmb     1          swap in sizeswpptr    rmb     2          swap table pointer*swppag    rmb     MAXPAGES+1 swap mem mapswpint    rmb     MAXPAGES+1 swap in mem mapswpbuf    rmb     28         swap buffer headerinargx    rmb     1          count of 'in arg expansion' tasksdpoolb    rmb     2          data pool startdpoole    rmb     2          data pool endexctbl    rmb     2          start of exec namessabbsy    rmb     1          accounting buffer busyactfil    rmb     2          accounting file tablesbttim    rmb     4          system boot timestablk    rmb     4          status - blocks transferedstafre    rmb     3          status - blocks freedstadsk    rmb     3          status - disk waitsstaswp    rmb     2          status - swap inssystmp    rmb     2          system temporarymaptbl    rmb     2          mem map table startunstlvl   rmb     1           pathname resolve nesting level (scripts)pretim    rmb     1         timer IRQ pretimer, as at comes at 100 Hz