include emu8086.inc
org 100h

jmp MAIN

; ===================== DATA =====================

at              db 5 dup(0)
bt              db 5 dup(0)
wt              db 5 dup(0)
tat             db 5 dup(0)
rt              db 5 dup(0)
ct              db 5 dup(0)
p               db 5 dup(0) ;priority
pid             db 5 dup(0)

visited         db 5 dup(0)
remaining_bt    db 5 dup(0)

temp_pc         db ?
tq              db ?
choice          db ?

total_wt        dw 0
total_rt        dw 0
total_tat       dw 0

; ===================== MAIN =====================

MAIN:

    call INPUT
    call MENU

    mov ah,4ch
    int 21h

; ===================== INPUT =====================

INPUT PROC
    PRINT "Enter number of processes (max 5): "
    CALL SCAN_NUM
    PRINTN
    mov temp_pc,cl
    mov si,0
    INPUT_LOOP: PRINTN
                PRINT "Process "
                mov ax,si
                inc ax
                CALL PRINT_NUM_UNS
                PRINTN ":"
                    mov ax,si
                    inc ax
                    mov pid[si],al
                    ; Arrival Time
                    PRINT "Arrival Time: "
                    CALL SCAN_NUM
                    mov at[si],cl
                    PRINTN
                    ; Burst Time
                    print "Burst Time: "
                    call scan_num
                    mov bt[si],cl
                    PRINTN
                    ; priority
                    print "Priority: "
                    call scan_num
                    mov p[si],cl
                    PRINTN
                    inc si                
                    xor ax,ax
                    mov al,temp_pc
                    cmp si,ax
                    jl INPUT_LOOP
    RET
    INPUT ENDP

MENU PROC
    PRINTN
    PRINTN "Choose the algorithm you want to run: "
    PRINTN "1. FCFS Scheduling"
    PRINTN "2. SJF Scheduling"
    PRINTN "3. Round Robin Scheduling"
    PRINTN "4. Priority Scheduling"
    PRINTN "Enter your Choice: "
    CALL SCAN_NUM
        mov choice,cl
        cmp choice,1
        je FCFS_CALL
        cmp choice,2
        je SJF_CALL
        cmp choice,3
        je RR_CALL
        cmp choice,4
        je PS_CALL
    RET
    FCFS_CALL:  CALL FCFS
                RET
    SJF_CALL:   CALL SJF
                RET
    RR_CALL:    PRINTN
                PRINT "Enter Quantum: "
                CALL SCAN_NUM
                    mov tq,cl
                    CALL RR
                    RET
    PS_CALL:    CALL PS
                RET
    RET
    MENU ENDP
; ===================== FCFS =====================

FCFS PROC
    PRINTN
    PRINTN "======== FCFS Scheduling ========"
    mov bl,temp_pc    ; sort by arrival time
    dec bl
    OUTER_SORT:     cmp bl,0
                    je SORT_DONE
                    mov si,0
                    mov bh,bl
    INNER_SORT:     mov al,at[si]
                    mov ah,at[si+1]
                    cmp al,ah
                    jbe NO_SWAP
                    xchg al,at[si+1]  ; swap AT
                    mov at[si],al
                    mov al,bt[si]     ; swap BT
                    xchg al,bt[si+1]
                    mov bt[si],al
                    mov al,pid[si]    ; swap PID
                    xchg al,pid[si+1]
                    mov pid[si],al
    NO_SWAP:    inc si
                dec bh
                jnz INNER_SORT
                dec bl
                jmp OUTER_SORT 
    SORT_DONE:  CALL PRINT_GANTT_START 
                mov dl,0
                mov si,0
                mov bl,temp_pc
    FCFS_LOOP:  cmp bl,0
                je FCFS_DONE
                mov al,at[si]  ;handle CPU idle gap
                cmp dl,al
                jae FCFS_OK
                mov dl,al
    FCFS_OK:    mov al,dl    ; compute metrics
                sub al,at[si]
                mov wt[si],al
                mov rt[si],al
                 ; --- GANTT PRINT START ---
                print "--P"
                mov al, pid[si]
                call PRINT_NUM_UNS
                print "--"
                add dl, bt[si] ; Current time updated here
                ; --- GANTT PRINT END ---
                mov al, dl
                call PRINT_NUM_UNS
                mov ct[si], dl
                mov al,ct[si]
                sub al,at[si]
                mov tat[si],al
                inc si
                dec bl
                jmp FCFS_LOOP
    FCFS_DONE:  CALL PRINT_TABLE
                CALL AVERAGES
    RET
    FCFS ENDP
; ===================== SJF =====================

SJF PROC

    printn
    printn "======== SJF Scheduling ========"

    ; reset visited

    mov si,0
    mov bl,temp_pc

RESET_LOOP:

    cmp bl,0
    je RESET_DONE

    mov visited[si],0

    inc si
    dec bl
    jmp RESET_LOOP

RESET_DONE:     

call PRINT_GANTT_START  

    mov dl,0
    mov bh,0

SJF_MAIN:

    mov al,temp_pc
    cmp bh,al
    je SJF_DONE

    mov si,0

    mov bp,0FFFFh
    mov bl,255

    mov cl,temp_pc

SJF_FIND:

    cmp cl,0
    je FIND_DONE

    mov al,visited[si]
    cmp al,1
    je NEXT_PROCESS

    mov al,at[si]
    cmp al,dl
    ja NEXT_PROCESS

    mov al,bt[si]
    cmp al,bl
    jae NEXT_PROCESS

    mov bl,al
    mov bp,si

NEXT_PROCESS:

    inc si
    dec cl
    jmp SJF_FIND

FIND_DONE:

    cmp bp,0FFFFh
    je CPU_IDLE

    mov si,bp

    mov visited[si],1

    mov al,dl
    sub al,at[si]

    mov wt[si],al
    mov rt[si],al  
    
    
    ; --- GANTT PRINT START ---
    print "--P"
    mov al, pid[si]
    call PRINT_NUM_UNS
    print "--"
    ; -------------------------

    add dl, bt[si] ; Execution finishes here

    ; --- GANTT PRINT END ---
    mov al, dl
    call PRINT_NUM_UNS
    ; -----------------------

    mov ct[si], dl

    

    mov al,ct[si]
    sub al,at[si]

    mov tat[si],al

    inc bh

    jmp SJF_MAIN

CPU_IDLE:

    inc dl
    jmp SJF_MAIN

SJF_DONE:

    call PRINT_TABLE
   
    call AVERAGES

    ret

SJF ENDP

; ===================== ROUND ROBIN =====================

RR PROC

    printn
    printn "===== Round Robin Scheduling ====="

    ; initialize remaining burst

    mov si,0
    mov bl,temp_pc

INIT_RR:

    cmp bl,0
    je INIT_DONE

    mov al,bt[si]
    mov remaining_bt[si],al

    mov rt[si],255

    inc si
    dec bl
    jmp INIT_RR

INIT_DONE:
           
           
           call PRINT_GANTT_START  
    mov dl,0
    mov bh,0

RR_MAIN:

    mov al,temp_pc
    cmp bh,al
    je RR_DONE

    mov si,0
    mov bl,temp_pc

    mov bp,0

RR_LOOP:

    cmp bl,0
    je RR_IDLE_CHECK

    mov al,remaining_bt[si]
    cmp al,0
    je RR_NEXT

    mov al,at[si]
    cmp al,dl
    ja RR_NEXT

    mov bp,1

    ; first response
    cmp byte ptr rt[si],255
    jne SKIP_RT

    mov al,dl
    sub al,at[si]

    mov rt[si],al

SKIP_RT:

    mov al,remaining_bt[si]

    cmp al,tq
    jae FULL_QUANTUM

    mov ch,al
    jmp EXECUTE

FULL_QUANTUM:

    mov ch,tq

EXECUTE:

    ;  for Gantt Chart ---
    print "--P"
    xor ax, ax
    mov al, pid[si]
    call PRINT_NUM_UNS
    print "--"
    ; ---------------------------------------

    add dl, ch
    
    
    xor ax, ax
    mov al, dl
    call PRINT_NUM_UNS
    ; ---------------------------------------

    sub byte ptr remaining_bt[si],ch

    

    mov al,remaining_bt[si]
    cmp al,0
    jne RR_NEXT

    inc bh
               
    mov ct[si], dl
    mov al,dl
    sub al,at[si]

    mov tat[si],al

    sub al,bt[si]

    mov wt[si],al

RR_NEXT:

    inc si
    dec bl
    jmp RR_LOOP

RR_IDLE_CHECK:

    cmp bp,1
    je RR_MAIN

    inc dl
    jmp RR_MAIN

RR_DONE:

    call PRINT_TABLE 
    
    call AVERAGES

    ret

RR ENDP

; ==================== Priority Scheduling ==============

PS PROC
    
    RET
    PS ENDP

; ===================== PRINT TABLE =====================

PRINT_TABLE PROC

    mov total_wt,0
    mov total_rt,0
    mov total_tat,0

    printn
    printn "=========================================="
    printn "PID   AT    BT    WT    RT    TAT"
    printn "=========================================="

    mov si,0
    mov bl,temp_pc

PT_LOOP:

    cmp bl,0
    je PT_DONE

    ; PID (Column 1)
    xor ax,ax
    mov al,pid[si]
    call PRINT_NUM_UNS
    print "     " ; 5 spaces

    ; AT (Column 2)
    xor ax,ax
    mov al,at[si]
    cmp al, 10
    jae PRINT_AT
    print " "        ; Leading space for single digit
PRINT_AT:
    call PRINT_NUM_UNS
    print "    "    ; 4 spaces

    ; BT (Column 3)
    xor ax,ax
    mov al,bt[si]
    cmp al, 10
    jae PRINT_BT
    print " "        ; Leading space for single digit
PRINT_BT:
    call PRINT_NUM_UNS
    print "    "    ; 4 spaces

    ; WT (Column 4)
    xor ax,ax
    mov al,wt[si]
    cmp al, 10
    jae PRINT_WT
    print " "        ; Leading space for single digit
PRINT_WT:
    call PRINT_NUM_UNS
    print "    "    ; 4 spaces

    ; RT (Column 5)
    xor ax,ax
    mov al,rt[si]
    cmp al, 10
    jae PRINT_RT
    print " "        ; Leading space for single digit
PRINT_RT:
    call PRINT_NUM_UNS
    print "    "    ; 4 spaces

    ; TAT (Column 6)
    xor ax,ax
    mov al,tat[si]
    cmp al, 10
    jae PRINT_TAT
    print " "        ; Leading space for single digit
PRINT_TAT:
    call PRINT_NUM_UNS
    printn

    ; total WT
    xor ax,ax
    mov al,wt[si]
    add total_wt,ax

    ; total RT
    xor ax,ax
    mov al,rt[si]
    add total_rt,ax

    ; total TAT
    xor ax,ax
    mov al,tat[si]
    add total_tat,ax

    inc si
    dec bl
    jmp PT_LOOP

PT_DONE:

    printn "=========================================="

    ret

PRINT_TABLE ENDP

; ===================== AVERAGES =====================

AVERAGES PROC

    printn
    printn "===== AVERAGES ====="

    ; Average WT
    print "Average WT : "

    mov ax,total_wt
    xor dx,dx

    mov bl,temp_pc
    div bl

    xor ah,ah
    call PRINT_NUM_UNS
    printn

    ; Average RT
    print "Average RT : "

    mov ax,total_rt
    xor dx,dx

    mov bl,temp_pc
    div bl

    xor ah,ah
    call PRINT_NUM_UNS
    printn

    ; Average TAT
    print "Average TAT: "

    mov ax,total_tat
    xor dx,dx

    mov bl,temp_pc
    div bl

    xor ah,ah
    call PRINT_NUM_UNS
    printn

    ret

AVERAGES ENDP

; ===================== PRINT GANTT CHART =====================

PRINT_GANTT_START PROC
    printn
    printn "===== GANTT CHART ====="
    print "0" ; This prints the very first time stamp
    ret
PRINT_GANTT_START ENDP

DEFINE_SCAN_NUM
DEFINE_PRINT_NUM_UNS

end MAIN