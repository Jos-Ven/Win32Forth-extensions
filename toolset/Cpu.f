(( History:
November 21st, 2001  Initial release by Jos v.d. Ven
December 29th, 2012  extensively extendend and updated by Marcel Hendrix
February 25th, 2013  Minor change to format strings by Jos v.d. Ven ))

anew  cpu.f            \ For Win32Forth.
needs ReformatStrings.f

decimal

code cpuid ( initial_EAX_value   - ebx edx ecx eax )
  mov   eax, ebx        \ put initial_EAX_value in eax
  push  edx             \ save edx ( up ) cpuid will use edx for feature
  cpuid
  sub   ebp, # 4
  mov   0    [ebp], edx \ move edx to the returnstack
  pop   edx             \ restore edx ( up )
  push  ebx
  mov   ebx, 0 [ebp]    \ move the old edx from the returnstack to ebx
  add   ebp, # 4
  push  ebx             \ push ebx on the stack
  push  ecx             \ push ecx in nos
  mov   ebx, eax        \ put eax in tos
next c;

\ -- vendor$: ebx edx ecx from cpuid when initial_EAX_value = 0
: vendor$ ( ebx esx ecx - adr count )
     pad 8 + !
     pad 4 + !
     pad !
     pad 12
 ;

: id-vendor-cpu        ( -- addr count )
        0 cpuid drop vendor$ ;

: decode-cpu-version        \ -- Reserved Type Family Model Stepping
                        \ Short: R T F M S
        1 cpuid >r 3drop
        r@ $FFFFC000 and #14 rshift
        r@ $3000 and     #12 rshift
        r@ $0F00 and       8 rshift
        r@ $00F0 and       4 rshift
        r> $000F and ;

: cache       ( -- L2 ) 2 cpuid 2drop nip  #255 and ;
: dec.        ( n - ) base @ swap . base ! ;
: 20ltype...: ( adr cnt -- ) 22 ltype...: ;

: .cache2 ( -- )
        $80000006 cpuid DROP NIP NIP ( ecx ) $FFFFFFFF AND
        DUP #16 RSHIFT              s" L2 Cache Size" 20ltype...: U. ." KB, "
        DUP $FF AND                 s" Line size"     20ltype...: DEC. ." bytes. "
            #12 RSHIFT #15 AND      s" Associativity" 20ltype...: B. ;

: 32B!+ ( u addr1 -- addr2 ) dup>r ! r> 4 + ;

: store ( u addr1 -- addr2 ) OVER $20202020 = IF  NIP  ELSE  32B!+  ENDIF ;

: brand ( -- c-addr u )
        $80000002 cpuid pad store  >R ROT R> store  store store   >R
        $80000003 cpuid R>  store  >R ROT R> store  store store   >R
        $80000004 cpuid R>  store  >R ROT R> store  store store
        PAD TUCK - ;

\ -- regsel: 0 = edx, 1 = ecx
: features ( bit regsel short/long -- c-addr u )
        >r SWAP 2* +
    CASE
          0 OF   S" fpu"         S" Onboard x87 FPU"                                              ENDOF
          1 OF   S" pni"         S" Prescott New Instructions (SSE3)"                             ENDOF
          2 OF   S" vme"         S" Virtual mode extensions (VIF)"                                ENDOF
          3 OF   S" pclmulqdq"   S" PCLMULQDQ support"                                            ENDOF
          4 OF   S" de"          S" Debugging extensions (CR4 bit 3)"                             ENDOF
          5 OF   S" dtes64"      S" 64-bit debug store (edx bit 21)"                              ENDOF
          6 OF   S" pse"         S" Page size extensions"                                         ENDOF
          7 OF   S" monitor"     S" MONITOR and MWAIT instructions (SSE3)"                        ENDOF
          8 OF   S" tsc"         S" Time Stamp Counter"                                           ENDOF
          9 OF   S" ds_cpl"      S" CPL qualified debug store"                                    ENDOF
        #10 OF   S" msr"         S" Model-specific registers"                                     ENDOF
        #11 OF   S" vmx"         S" Virtual Machine eXtensions"                                   ENDOF
        #12 OF   S" pae"         S" Physical Address Extension"                                   ENDOF
        #13 OF   S" smx"         S" Safer Mode Extensions (LaGrande)"                             ENDOF
        #14 OF   S" mce"         S" Machine Check Exception"                                      ENDOF
        #15 OF   S" est"         S" Enhanced SpeedStep"                                           ENDOF
        #16 OF   S" cx8"         S" CMPXCHG8 (compare-and-swap) instruction"                      ENDOF
        #17 OF   S" tm2"         S" Thermal Monitor 2"                                            ENDOF
        #18 OF   S" apic"        S" Onboard Advanced Programmable Interrupt Controller"           ENDOF
        #19 OF   S" ssse3"       S" Supplemental SSE3 instructions"                               ENDOF
        #20 OF   S" (reserved)"  S" (reserved)"                                                   ENDOF
        #21 OF   S" cid"         S" Context ID"                                                   ENDOF
        #22 OF   S" sep"         S" SYSENTER and SYSEXIT instructions"                            ENDOF
        #23 OF   S" (reserved)"  S" (reserved)"                                                   ENDOF
        #24 OF   S" mtrr"        S" Memory Type Range Registers"                                  ENDOF
        #25 OF   S" fma"         S" Fused multiply-add (FMA3)"                                    ENDOF
        #26 OF   S" pge"         S" Page Global Enable bit in CR4"                                ENDOF
        #27 OF   S" cx16"        S" CMPXCHG16B instruction"                                       ENDOF
        #28 OF   S" mca"         S" Machine check architecture"                                   ENDOF
        #29 OF   S" xtpr"        S" Can disable sending task priority messages"                   ENDOF
        #30 OF   S" cmov"        S" Conditional move and FCMOV instructions"                      ENDOF
        #31 OF   S" pdcm"        S" Perfmon & debug capability"                                   ENDOF
        #32 OF   S" pat"         S" Page Attribute Table"                                         ENDOF
        #33 OF   S" (reserved)"  S" (reserved)"                                                   ENDOF
        #34 OF   S" pse36"       S" 36-bit page huge pages"                                       ENDOF
        #35 OF   S" pcid"        S" Process context identifiers (CR4 bit 17)"                     ENDOF
        #36 OF   S" pn"          S" Processor Serial Number"                                      ENDOF
        #37 OF   S" dca"         S" Direct cache access for DMA writes[8][9]"                     ENDOF
        #38 OF   S" clflush"     S" CLFLUSH instruction (SSE2)"                                   ENDOF
        #39 OF   S" sse4_1"      S" SSE4.1 instructions"                                          ENDOF
        #40 OF   S" (reserved)"  S" (reserved)"                                                   ENDOF
        #41 OF   S" sse4_2"      S" SSE4.2 instructions"                                          ENDOF
        #42 OF   S" dts"         S" Debug store: save trace of executed jumps"                    ENDOF
        #43 OF   S" x2apic"      S" x2APIC support"                                               ENDOF
        #44 OF   S" acpi"        S" Onboard thermal control MSRs for ACPI"                        ENDOF
        #45 OF   S" movbe"       S" MOVBE instruction (big-endian, Intel Atom only)"              ENDOF
        #46 OF   S" mmx"         S" MMX instructions"                                             ENDOF
        #47 OF   S" popcnt"      S" POPCNT instruction"                                           ENDOF
        #48 OF   S" fxsr"        S" FXSAVE, FXRESTOR instructions, CR4 bit 9"                     ENDOF
        #49 OF   S" tscdeadline" S" APIC supports one-shot operation using a TSC deadline value"  ENDOF
        #50 OF   S" sse"         S" SSE instructions (a.k.a. Katmai New Instructions)"            ENDOF
        #51 OF   S" aes"         S" AES instruction set"                                          ENDOF
        #52 OF   S" sse2"        S" SSE2 instructions"                                            ENDOF
        #53 OF   S" xsave"       S" XSAVE, XRESTOR, XSETBV, XGETBV"                               ENDOF
        #54 OF   S" ss"          S" CPU cache supports self-snoop"                                ENDOF
        #55 OF   S" osxsave"     S" XSAVE enabled by OS"                                          ENDOF
        #56 OF   S" ht"          S" Hyper-threading"                                              ENDOF
        #57 OF   S" avx"         S" Advanced Vector Extensions"                                   ENDOF
        #58 OF   S" tm"          S" Thermal monitor automatically limits temperature"             ENDOF
        #59 OF   S" f16c"        S" CVT16 instruction set (half-precision) FP support"            ENDOF
        #60 OF   S" ia64"        S" IA64 processor emulating x86"                                 ENDOF
        #61 OF   S" rdrnd"       S" RDRAND (on-chip random number generator) support"             ENDOF
        #62 OF   S" pbe"         S" Pending Break Enable (PBE# pin) wakeup support"               ENDOF
        #63 OF   S" hypervisor"  S" Running on a hypervisor (always 0 on a real CPU)"             ENDOF
     ENDCASE
    r> IF  2SWAP  ENDIF  2DROP ;

\ -- Raise 2 to the power x.
: 2^x  ( x -- 2^x ) 1 swap lshift ;
8  constant bs

: .features ( long/short -- )
        0 0 LOCALS| edx ecx long? |
        1 cpuid ( ebx edx ecx eax ) DROP TO ecx TO edx DROP
        #32 0 ?DO  ecx I 2^x AND IF  I 1 long? features 70 ListItem long? IF CR ELSE ',' EMIT ENDIF  ENDIF  LOOP
        #32 0 ?DO  edx I 2^x AND IF  I 0 long? features 70 ListItem long? IF CR ELSE ',' EMIT ENDIF  ENDIF  LOOP
        long? 0= IF  BS EMIT  ENDIF ;

: .cache1 ( cache -- )
  s" Cache description" 20ltype...:
  CASE
     $00 OF ." Null descriptor. "                                                                 ENDOF
     $01 OF ." Instruction TLB: 4K-Byte Pages, 4-way set associative, 32 entries."                ENDOF
     $02 OF ." Instruction TLB: 4M-Byte Pages, 4-way set associative, 2 entries."                 ENDOF
     $03 OF ." Data TLB: 4K-Byte Pages, 4-way set associative, 64 entries."                       ENDOF
     $04 OF ." Data TLB: 4M-Byte Pages, 4-way set associative, 8 entries."                        ENDOF
     $05 OF ." data TLB, 4M pages, 4 ways, 32 entries."                                           ENDOF
     $06 OF ." 1st-level instruction cache: 8K Bytes, 4-way set associative, 32 byte line size."  ENDOF
     $08 OF ." 1st-level instruction cache: 16K Bytes, 4-way set associative, 32 byte line size." ENDOF
     $09 OF ." code L1 cache, 32 KB, 4 ways, 64 byte lines."                                      ENDOF
     $0A OF ." 1st-level data cache: 8K Bytes, 2-way set associative, 32 byte line size."         ENDOF
     $0B OF ." code TLB, 4M pages, 4 ways, 4 entries."                                            ENDOF
     $0C OF ." 1st-level data cache: 16K Bytes, 4-way set associative, 32 byte line size."        ENDOF
     $0D OF ." data L1 cache, 16 KB, 4 ways, 64 byte lines (ECC)"                                 ENDOF
     $0E OF ." data L1 cache, 24 KB, 6 ways, 64 byte lines."                                      ENDOF
     $10 OF ." data L1 cache, 16 KB, 4 ways, 32 byte lines (IA-64)"                               ENDOF
     $15 OF ." code L1 cache, 16 KB, 4 ways, 32 byte lines (IA-64)"                               ENDOF
     $1A OF ." code and data L2 cache, 96 KB, 6 ways, 64 byte lines (IA-64)"                      ENDOF
     $21 OF ." code and data L2 cache, 256 KB, 8 ways, 64 byte line."                             ENDOF
     $22 OF ." code and data L3 cache, 512 KB, 4 ways (!), 64 byte lines, dual-sectored."         ENDOF
     $23 OF ." 3rd-level cache: 1M Bytes, 8-way set associative, 64 byte line size."              ENDOF
     $25 OF ." 3rd-level cache: 2M Bytes, 8-way set associative, 64 byte line size."              ENDOF
     $29 OF ." 3rd-level cache: 4M Bytes, 8-way set associative, 64 byte line size."              ENDOF
     $2C OF ." data L1 cache, 32 KB, 8 ways, 64 byte lines."                                      ENDOF
     $30 OF ." code L1 cache, 32 KB, 8 ways, 64 byte lines."                                      ENDOF
     $39 OF ." code and data L2 cache, 128 KB, 4 ways, 64 byte lines, sectored."                  ENDOF
     $3A OF ." code and data L2 cache, 192 KB, 6 ways, 64 byte lines, sectored."                  ENDOF
     $3B OF ." code and data L2 cache, 128 KB, 2 ways, 64 byte lines, sectored."                  ENDOF
     $3C OF ." code and data L2 cache, 256 KB, 4 ways, 64 byte lines, sectored."                  ENDOF
     $3D OF ." code and data L2 cache, 384 KB, 6 ways, 64 byte lines, sectored."                  ENDOF
     $3E OF ." code and data L2 cache, 512 KB, 4 ways, 64 byte lines, sectored."                  ENDOF
     $40 OF ." No 2nd-level or else no 3rd-level cache."                                          ENDOF
     $41 OF ." 2nd-level cache: 128K Bytes, 4-way set associative, 32 byte line size."            ENDOF
     $42 OF ." 2nd-level cache: 256K Bytes, 4-way set associative, 32 byte line size."            ENDOF
     $43 OF ." 2nd-level cache: 512K Bytes, 4-way set associative, 32 byte line size."            ENDOF
     $44 OF ." 2nd-level cache: 1M Byte, 4-way set associative, 32 byte line size."               ENDOF
     $45 OF ." 2nd-level cache: 2M Byte, 4-way set associative, 32 byte line size."               ENDOF
     $46 OF ." code and data L3 cache, 4096 KB, 4 ways, 64 byte lines."                           ENDOF
     $47 OF ." code and data L3 cache, 8192 KB, 8 ways, 64 byte lines."                           ENDOF
     $48 OF ." code and data L2 cache, 3072 KB, 12 ways, 64 byte lines."                          ENDOF
     $49 OF ." code and data L3 cache, 4096 KB, 16 ways, 64 byte lines (P4) "
           ." or code and data L2 cache, 4096 KB, 16 ways, 64 byte lines (Core 2)."               ENDOF
     $4A OF ." code and data L3 cache, 6144 KB, 12 ways, 64 byte lines."                          ENDOF
     $4B OF ." code and data L3 cache, 8192 KB, 16 ways, 64 byte lines."                          ENDOF
     $4C OF ." code and data L3 cache, 12288 KB, 12 ways, 64 byte lines."                         ENDOF
     $4D OF ." code and data L3 cache, 16384 KB, 16 ways, 64 byte lines."                         ENDOF
     $4E OF ." code and data L2 cache, 6144 KB, 24 ways, 64 byte lines."                          ENDOF
     $4F OF ." code TLB, 4K pages, ???, 32 entries."                                              ENDOF
     $50 OF ." Instruction TLB: 4-KByte and 2-MByte or 4-MByte pages, 64 entries."                ENDOF
     $51 OF ." Instruction TLB: 4-KByte and 2-MByte or 4-MByte pages, 128 entries."               ENDOF
     $52 OF ." Instruction TLB: 4-KByte and 2-MByte or 4-MByte pages, 256 entries."               ENDOF
     $55 OF ." code TLB, 2M/4M, fully, 7 entries."                                                ENDOF
     $56 OF ." L0 data TLB, 4M pages, 4 ways, 16 entries."                                        ENDOF
     $57 OF ." L0 data TLB, 4K pages, 4 ways, 16 entries."                                        ENDOF
     $59 OF ." L0 data TLB, 4K pages, fully, 16 entries."                                         ENDOF
     $5A OF ." L0 data TLB, 2M/4M, 4 ways, 32 entries."                                           ENDOF
     $5B OF ." Data TLB: 4-KByte and 4-MByte pages, 64 entries."                                  ENDOF
     $5C OF ." Data TLB: 4-KByte and 4-MByte pages,128 entries."                                  ENDOF
     $5D OF ." Data TLB: 4-KByte and 4-MByte pages,256 entries."                                  ENDOF
     $60 OF ." data L1 cache, 16 KB, 8 ways, 64 byte lines, sectored."                            ENDOF
     $66 OF ." 1st-level data cache: 8KB, 4-way set associative, 64 byte line size."              ENDOF
     $67 OF ." 1st-level data cache: 16KB, 4-way set associative, 64 byte line size."             ENDOF
     $68 OF ." 1st-level data cache: 32KB, 4-way set associative, 64 byte line size."             ENDOF
     $70 OF ." Trace cache: 12K-uop, 8-way set associative."                                      ENDOF
     $71 OF ." Trace cache: 16K-uop, 8-way set associative."                                      ENDOF
     $72 OF ." Trace cache: 32K-uop, 8-way set associative."                                      ENDOF
     $73 OF ." trace L1 cache, 64 K?OPs, 8 ways."                                                 ENDOF
     $76 OF ." code TLB, 2M/4M pages, fully, 8 entries."                                          ENDOF
     $77 OF ." code L1 cache, 16 KB, 4 ways, 64 byte lines, sectored (IA-64)"                     ENDOF
     $78 OF ." code and data L2 cache, 1024 KB, 4 ways, 64 byte lines."                           ENDOF
     $79 OF ." 2nd-level cache: 128KB, 8-way set associative, sectored, 64 byte line size."       ENDOF
     $7A OF ." 2nd-level cache: 256KB, 8-way set associative, sectored, 64 byte line size."       ENDOF
     $7B OF ." 2nd-level cache: 512KB, 8-way set associative, sectored, 64 byte line size."       ENDOF
     $7C OF ." 2nd-level cache: 1MB, 8-way set associative, sectored, 64 byte line size."         ENDOF
     $7D OF ." code and data L2 cache, 2048 KB, 8 ways, 64 byte lines."                           ENDOF
     $7E OF ." code and data L2 cache, 256 KB, 8 ways, 128 byte lines, sect. (IA-64)."            ENDOF
     $7F OF ." code and data L2 cache, 512 KB, 2 ways, 64 byte lines."                            ENDOF
     $80 OF ." code and data L2 cache, 512 KB, 8 ways, 64 byte lines."                            ENDOF
     $81 OF ." code and data L2 cache, 128 KB, 8 ways, 32 byte lines."                            ENDOF
     $82 OF ." 2nd-level cache: 256K Bytes, 8-way set associative, 32 byte line size."            ENDOF
     $83 of ." code and data L2 cache, 512 KB, 8 ways, 32 byte lines."                            ENDOF
     $84 OF ." 2nd-level cache: 1M Byte, 8-way set associative, 32 byte line size."               ENDOF
     $85 OF ." 2nd-level cache: 2M Byte, 8-way set associative, 32 byte line size."               ENDOF
     $86 OF ." code and data L2 cache, 512 KB, 4 ways, 64 byte lines."                            ENDOF
     $87 OF ." code and data L2 cache, 1024 KB, 8 ways, 64 byte lines."                           ENDOF
     $88 OF ." code and data L3 cache, 2048 KB, 4 ways, 64 byte lines (IA-64)."                   ENDOF
     $89 OF ." code and data L3 cache, 4096 KB, 4 ways, 64 byte lines (IA-64)."                   ENDOF
     $8A OF ." code and data L3 cache, 8192 KB, 4 ways, 64 byte lines (IA-64)."                   ENDOF
     $8D OF ." code and data L3 cache, 3072 KB, 12 ways, 128 byte lines (IA-64)."                 ENDOF
     $90 OF ." code TLB, 4K...256M pages, fully, 64 entries (IA-64)."                             ENDOF
     $96 OF ." data L1 TLB, 4K...256M pages, fully, 32 entries (IA-64)."                          ENDOF
     $9B OF ." data L2 TLB, 4K...256M pages, fully, 96 entries (IA-64)."                          ENDOF
     $B0 OF ." code TLB, 4K pages, 4 ways, 128 entries."                                          ENDOF
     $B1 OF ." code TLB, 4M pages, 4 ways, 4 entries and code TLB, 2M pages, 4 ways, 8 entries."  ENDOF
     $B2 OF ." code TLB, 4K pages, 4 ways, 64 entries."                                           ENDOF
     $B3 OF ." data TLB, 4K pages, 4 ways, 128 entries."                                          ENDOF
     $B4 OF ." data TLB, 4K pages, 4 ways, 256 entries."                                          ENDOF
     $BA OF ." data TLB, 4K pages, 4 ways, 64 entries."                                           ENDOF
     $C0 OF ." data TLB, 4K/4M pages, 4 ways, 8 entries."                                         ENDOF
     $CA OF ." L2 code and data TLB, 4K pages, 4 ways, 512 entries."                              ENDOF
     $D0 OF ." code and data L3 cache, 512-kb, 4 ways, 64 byte lines."                            ENDOF
     $D1 OF ." code and data L3 cache, 1024-kb, 4 ways, 64 byte lines."                           ENDOF
     $D2 OF ." code and data L3 cache, 2048-kb, 4 ways, 64 byte lines."                           ENDOF
     $D6 OF ." code and data L3 cache, 1024-kb, 8 ways, 64 byte lines."                           ENDOF
     $D7 OF ." code and data L3 cache, 2048-kb, 8 ways, 64 byte lines."                           ENDOF
     $D8 OF ." code and data L3 cache, 4096-kb, 8 ways, 64 byte lines."                           ENDOF
     $DC OF ." code and data L3 cache, 1536-kb, 12 ways, 64 byte lines."                          ENDOF
     $DD OF ." code and data L3 cache, 3072-kb, 12 ways, 64 byte lines."                          ENDOF
     $DE OF ." code and data L3 cache, 6144-kb, 12 ways, 64 byte lines."                          ENDOF
     $E2 OF ." code and data L3 cache, 2048-kb, 16 ways, 64 byte lines."                          ENDOF
     $E3 OF ." code and data L3 cache, 4096-kb, 16 ways, 64 byte lines."                          ENDOF
     $E4 OF ." code and data L3 cache, 8192-kb, 16 ways, 64 byte lines."                          ENDOF
     $EA OF ." code and data L3 cache, 12288-kb, 24 ways, 64 byte lines."                         ENDOF
     $EB OF ." code and data L3 cache, 18432-kb, 24 ways, 64 byte lines."                         ENDOF
     $EC OF ." code and data L3 cache, 24576-kb, 24 ways, 64 byte lines."                         ENDOF
            ." Cache type is unknown."
  ENDCASE ;

: .cpu        ( -- )
          s" Vendor id cpu" 20ltype...: id-vendor-cpu TYPE
          s" Brand string"  20ltype...: brand TYPE
          decode-cpu-version
                s" Type"    20ltype...: 3 ROLL . ROT ." Family:" . ." Model:" SWAP . ." Stepping:" . DROP
          cache .cache1
          .cache2
          s" Feature strings long"  20ltype...: TRUE  .features
          s" Feature strings short" 20ltype...: FALSE .features  ;

: cpu_feature   ( - feature )        1 cpuid 2drop nip ;
: tsc?          ( - true/false )    cpu_feature #8 and ;

code tsc  ( - tsc_low tsc_high )  \ tsc = Time Stamp Counter Pentium
  push ebx      \ save tos
  push edx
  rdtsc         \ uses edx and eax
  mov ebx, edx  \ edx to tos
  pop edx       \ restore edx
  push eax      \ eax to nos
 next c;

: get-priority  ( - priority_class )  call GetCurrentProcess call GetPriorityClass ;
: set-priority  ( priority_class - )  call GetCurrentProcess call SetPriorityClass drop  ;

: clockcount ( ms - clockcount_low clockcount_high )
        get-priority >r tsc? not abort" No TSC present."
        REALTIME_PRIORITY_CLASS set-priority 30 ms
        tsc rot call Sleep tsc
        r> set-priority
        rot drop  d- dabs ;

: clock-test ( -- )
        0 locals| sum_clockcount |
        cr ." Clock test: " 1 0
            do  0 to  sum_clockcount 3 dup>r 0
                      do  100 clockcount d>f 100000e f/ f>s +to sum_clockcount
                      loop
                1+ sum_clockcount space r> / 1 u,.r s" ,000,000" type
            loop ;

\s Example:

 .cpu cr clock-test  abort  shows on my PC:


Vendor id cpu.........:GenuineIntel
Brand string..........:Intel(R) Core(TM) i7 CPU 960  @ 3.20GHz
Type..................:0 Family:6 Model:10 Stepping:5
Cache description.....:data L1 cache, 32 KB, 8 ways, 64 byte lines.
L2 Cache Size.........:256 KB,
Line size.............:64 bytes.
Associativity.........:110
Feature strings long..:Prescott New Instructions (SSE3)
64-bit debug store (edx bit 21)
MONITOR and MWAIT instructions (SSE3)
CPL qualified debug store
Virtual Machine eXtensions
Enhanced SpeedStep
Thermal Monitor 2
Supplemental SSE3 instructions
CMPXCHG16B instruction
Can disable sending task priority messages
Perfmon & debug capability
SSE4.1 instructions
SSE4.2 instructions
POPCNT instruction
Onboard x87 FPU
Virtual mode extensions (VIF)
Debugging extensions (CR4 bit 3)
Page size extensions
Time Stamp Counter
Model-specific registers
Physical Address Extension
Machine Check Exception
CMPXCHG8 (compare-and-swap) instruction
Onboard Advanced Programmable Interrupt Controller
SYSENTER and SYSEXIT instructions
Memory Type Range Registers
Page Global Enable bit in CR4
Machine check architecture
Conditional move and FCMOV instructions
Page Attribute Table
36-bit page huge pages
CLFLUSH instruction (SSE2)
Debug store: save trace of executed jumps
Onboard thermal control MSRs for ACPI
MMX instructions
FXSAVE, FXRESTOR instructions, CR4 bit 9
SSE instructions (a.k.a. Katmai New Instructions)
SSE2 instructions
CPU cache supports self-snoop
Hyper-threading
Thermal monitor automatically limits temperature
Pending Break Enable (PBE# pin) wakeup support

Feature strings short.:pni,dtes64,monitor,ds_cpl,vmx,est,tm2,ssse3,
cx16,xtpr,pdcm,sse4_1,sse4_2,popcnt,fpu,vme,de,pse,tsc,msr,pae,mce,
cx8,apic,sep,mtrr,pge,mca,cmov,pat,pse36,clflush,dts,acpi,mmx,fxsr,
sse,sse2,ss,ht,tm,pbe

Clock test:  3,203,000,000
