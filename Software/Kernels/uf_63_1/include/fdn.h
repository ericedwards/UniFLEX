          pag     ** File descriptor node table (fdn)** The fdn table contains all of the information* known about an active file.*          base    0         * struct fdnffwdl     rmb     2          forward list linkfstat     rmb     1          * see below *fdevic    rmb     2          device where fdn residesfnumbr    rmb     2          fdn number (device address)frefct    rmb     1          reference countfmode     rmb     1          * see below *facces    rmb     1          * see below *fdirlc    rmb     1          directory entry countfouid     rmb     2          owner's user idfsize     rmb     4          file sizeffmap     rmb     MAPSIZ*DSKADS file mapFDNSIZ    equ     *          fdn structure size* stat codesFLOCK     equ     %00000001  fdn is lockedFMOD      equ     %00000010  fdn has been modifiedFTEXT     equ     %00000100  this is a text segmentFMNT      equ     %00001000  fdn is mounted onFWLCK     equ     %00010000  task awaiting lock* mode codesFBUSY     equ     %00000001  fdn is used (busy)FSBLK     equ     %00000010  block special fileFSCHR     equ     %00000100  character special fileFSDIR     equ     %00001000  directory type fileFPRDF     equ     %00010000  pipe read flagFPWRF     equ     %00100000  pipe write flag* access codesFACUR     equ     %00000001  user readFACUW     equ     %00000010  user writeFACUE     equ     %00000100  user executeFACOR     equ     %00001000  other readFACOW     equ     %00010000  other writeFACOE     equ     %00100000  other executeFXSET     equ     %01000000  uid execute set