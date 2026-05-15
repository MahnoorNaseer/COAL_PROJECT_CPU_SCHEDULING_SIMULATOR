include emu8086.inc   ; Includes EMU8086 library macros such as PRINT, PRINTN, SCAN_NUM, etc.
org 100h              ; Sets the origin address for a COM program.

jmp MAIN              ; Skips over the data section and jumps directly to the MAIN procedure.

; ===================== DATA =====================
    at              db 5 dup(0)  ; arrival time
    bt              db 5 dup(0)  ; burst time
    wt              db 5 dup(0)  ; waiting time
    tat             db 5 dup(0)  ; turn around time
    rt              db 5 dup(0)  ; remaining time
    ct              db 5 dup(0)  ; completion time
    p               db 5 dup(0)  ; priority for priority Scheduling
    pid             db 5 dup(0)  ; Array to store Process IDs (1, 2, 3, ...).
    
    visited         db 5 dup(0)  ; burst time done once cpu was assigned
    remaining_bt    db 5 dup(0)  ; remaining burst time was cpu was taken and assigned to another process
    
    temp_pc         db ?         ; Stores the number of processes entered by the user.
    tq              db ?         ; time quantum for Rounds Robin
    choice          db ?         ; choice for the scheduling algroithm you want to run
    choice_rerun    db ?         ; choice for the scheduling algroithm you want to run again
    
    
    total_wt        dw 0         ; total waiting time for average calculation
    total_rt        dw 0         ; total response time for average calculation of response time
    total_tat       dw 0         ; total turn around time for average calculation of tat

; ===================== MAIN =====================
MAIN:   CALL INPUT  ; Takes number of processes and their Arrival Time, Burst Time, and Priority. 
        CALL MENU   ; Displays menu and executes selected scheduling algorithm.
        rerun_choice:   PRINTN                                    ; New line. 
                        PRINTN "Do you want to choose another algorithm and test it? "
                        PRINTN                                    ; New line.
                        PRINT "IF yes enter y if no press n: "    ; Prompt user for rerun choice.
                        mov ah,01h                                ; Read user input from keyboard, Input character/value stored in AL register.
                        int 21h                                   ; interrupt will be invoked and user will enter the character 
                        mov choice_rerun, al                      ; Save user input into variable choice_rerun.
                        cmp choice_rerun, 'y'                     ; Compare user input with character 'y'.
                        je Yes_Label                              ; If input = 'y', jump to Yes_Label.
                        cmp choice_rerun, 'n'                     ; Compare user input with character 'n'.
                        je No_Label                               ; If input = 'n', jump to No_label.
                        cmp choice_rerun, 'Y'                     ; Compare user input with character 'y'.
                        je Yes_Label                              ; If input = 'Y', jump to Yes_Label.
                        cmp choice_rerun, 'N'                     ; Compare user input with character 'n'.
                        je No_Label                               ; If input = 'N', jump to No_label.        
                        jmp invalid_rerun_choice                  ; If input != 'N', jump to invalid_rerun_choice label.
        invalid_rerun_choice:    PRINTN                   ; New line.
                                 PRINTN                   ; New line.
                                 CALL CLEAR_SCREEN        ; Clears the console screen
                                 PRINT "Please enter your choice for re-run again: "
                                 jmp rerun_choice         ; Goto the rerun_choice label   
        Yes_Label:  CALL CLEAR_SCREEN    ; Clears the console screen
                    CALL INPUT           ; Takes number of processes and their Arrival Time, Burst Time, and Priority.
                    CALL MENU            ; Displays menu and executes selected scheduling algorithm.
                    jmp rerun_choice
        No_Label:   CALL CLEAR_SCREEN                               ; Clears the console screen.
                    PRINTN                                          ; New line.
                    PRINTN "Thank You for using our Simulator."     ; Ending Message.
                    PRINTN "Have a Good Day :) "                    ; Graceful Ending.
        end:    mov ah,4ch  ; DOS function 4Ch = terminate program.
                int 21h     ; Calls DOS interrupt to exit.

; ===================== INPUT =====================
INPUT PROC
    PRINT "Enter number of processes (max 5): "
    CALL SCAN_NUM   ; Reads number from keyboard, Result is stored in CX, low byte CL.
    PRINTN          ; Prints a blank line.
    mov temp_pc,cl  ; Save process count into temp_pc.
    mov si,0        ; SI is used as array index.
    INPUT_LOOP: PRINTN                      ; Prints a blank line.
                PRINT "Process "            ; Display "Process ".
                mov ax,si                   ; Copy index into AX.
                inc ax                      ; Convert zero-based index to process number starting from 1.
                CALL PRINT_NUM_UNS          ; Print process number.
                PRINTN ":"                  ; Print colon and newline.
                    mov ax,si               ; Copy index again.
                    inc ax                  ; Process number = SI + 1.
                    mov pid[si],al          ; Store process ID.
                    PRINT "Arrival Time: "  ; Prompt for arrival time.
                    CALL SCAN_NUM           ; Read arrival time into CL.
                    mov at[si],cl           ; Store arrival time.
                    PRINTN                  ; New line.
                    PRINT "Burst Time: "    ; Prompt for burst time.
                    CALL scan_num           ; Read burst time.
                    mov bt[si],cl           ; Store burst time.
                    PRINTN                  ; New line.
                    PRINT "Priority: "      ; Prompt for priority.
                    CALL scan_num           ; Read priority.
                    mov p[si],cl            ; Store priority.
                    PRINTN                  ; New line.
                    inc si                  ; Move to next process.
                    xor ax,ax               ; Clear AX.
                    mov al,temp_pc          ; Load number of processes.
                    cmp si,ax               ; Compare current index with total processes.
                    jl INPUT_LOOP           ; Continue if SI < temp_pc.
    RET   ; Return to caller.
    INPUT ENDP

MENU PROC
    PRINTN                                            ; Blank line.
    PRINTN "Choose the algorithm you want to run: "   ; Display menu heading.
    PRINTN "1. FCFS Scheduling (Non-Preemptive)"      ; Option 1.
    PRINTN "2. SJF Scheduling (Non-Preemptive)"       ; Option 2.
    PRINTN "3. Round Robin Scheduling (Preemptive)"    ; Option 3.
    PRINTN "4. Priority Scheduling (Non-Preemptive)"  ; Option 4.
    PRINTN "5. Priority Scheduling (Preemptive)"      ; Option 5.
    PRINTN                                            ; Blank line.
    Choice_label:   PRINT  "Enter your Choice: "      ; Prompt user.
                    CALL SCAN_NUM                     ; Read menu choice into CL.
                        mov choice,cl                 ; Save user choice.
                        cmp choice,0                  ; Check if choice <= 0.
                        jle invalid                   ; Invalid if 0 or negative.
                        cmp choice,6                  ; Check if choice >= 5.
                        jge invalid                   ; Invalid if greater than 4.
                        cmp choice,1                  ; FCFS?
                        je FCFS_CALL                  ; Jump to FCFS.
                        cmp choice,2                  ; SJF?
                        je SJF_CALL                   ; Jump to SJF.
                        cmp choice,3                  ; Round Robin?
                        je RR_CALL                    ; Jump to RR.
                        cmp choice,4                  ; Priority Scheduling?
                        je PS_CALL                    ; Jump to Priority Scheduling.
                        cmp choice,5                  ; Priority Scheduling Preemptive?
                        je Pre_PS_CALL                ; Jump to Priority Scheduling Preemptive.
    RET                                               ; Return if somehow none matched.
    FCFS_CALL:  CALL FCFS                 ; Execute FCFS.
                RET
    SJF_CALL:   CALL SJF                  ; Execute SJF.
                RET
    RR_CALL:    PRINTN                    ; Blank line.
                PRINT "Enter Quantum: "   ; Ask for time quantum.
                CALL SCAN_NUM             ; Read quantum into CL.
                    mov tq,cl             ; Save time quantum.
                    CALL RR               ; Execute Round Robin.
                    RET
    PS_CALL:    CALL PS                   ; Execute Priority Scheduling.
                RET
    Pre_PS_Call:    CALL PRE_PS           ; Execute Priority Scheduling Premptive.
                    RET
    invalid:    PRINTN                    ; Blank line.
                PRINT "Choice entered is invalid. Please choose between 1-5."    ; Show error message.
                JMP Choice_label                                                 ; Return to menu selection.
    RET
    MENU ENDP
; ===================== FCFS =====================
FCFS PROC
    PRINTN                                       ; Print a blank line for spacing.
    PRINTN                                       ; Print a blank line.
    PRINTN "======== FCFS Scheduling ========"   ; Display the heading for FCFS Scheduling.
    mov bl,temp_pc                               ; sort by arrival time, Load the total number of processes into BL.
    dec bl                                       ; Outer loop runs (number of processes - 1) times for bubble sort.
    OUTER_SORT:     cmp bl,0                     ; Check whether all sorting passes are completed.
                    je SORT_DONE                 ; If BL = 0, sorting is finished.
                    mov si,0                     ; Initialize SI to 0 to start from the first element.
                    mov bh,bl                    ; Copy BL into BH for the inner loop counter.
    INNER_SORT:     mov al,at[si]                ; Load current process arrival time into AL.
                    mov ah,at[si+1]              ; Load next process arrival time into AH.
                    cmp al,ah                    ; Compare current arrival time with next arrival time.
                    jbe NO_SWAP                  ; If current arrival time <= next arrival time, no swap is needed.
                    xchg al,at[si+1]             ; swap AT, Exchange AL with the next arrival time.
                    mov at[si],al                ; Store swapped arrival time into current position.
                    mov al,bt[si]                ; swap BT, Load current burst time into AL.
                    xchg al,bt[si+1]             ; Exchange burst times.
                    mov bt[si],al                ; Store swapped burst time.
                    mov al,pid[si]               ; swap PID, Load current process ID.
                    xchg al,pid[si+1]            ; Exchange process IDs.
                    mov pid[si],al               ; Store swapped process ID.
    NO_SWAP:    inc si                  ; Move to the next array index.
                dec bh                  ; Decrease inner loop counter.
                jnz INNER_SORT          ; Repeat inner loop until BH becomes zero.
                dec bl                  ; Decrease outer loop counter.
                jmp OUTER_SORT          ; Start the next bubble sort pass.
    SORT_DONE:  CALL PRINT_GANTT_START  ; Print the Gantt chart heading and initial time 0.
                mov dl,0                ; DL will hold the current CPU time, initialized to 0.
                mov si,0                ; Reset SI to the first process.
                mov bl,temp_pc          ; Load total number of processes into BL.
    FCFS_LOOP:  cmp bl,0                ; Check whether all processes have been executed.
                je FCFS_DONE            ; If no processes remain, finish FCFS.
                mov al,at[si]           ; handle CPU idle gap, Load arrival time of current process.
                cmp dl,al               ; Compare current CPU time with arrival time.
                jae FCFS_OK             ; If CPU time >= arrival time, process can start immediately.
                mov dl,al               ; Otherwise, CPU remains idle until the process arrives.
    FCFS_OK:    mov al,dl               ; compute metrics, Copy current time to AL.
                sub al,at[si]           ; Waiting Time = Current Time - Arrival Time.
                mov wt[si],al           ; Store Waiting Time.
                mov rt[si],al           ; In FCFS, Response Time = Waiting Time.
    ; --- GANTT PRINT START ---
                PRINT "--P"             ; Print process label prefix.
                mov al, pid[si]         ; Load process ID.
                CALL PRINT_NUM_UNS      ; Print process ID.
                PRINT "--"              ; Print suffix.
                add dl, bt[si]          ; Current time updated here, Current Time = Current Time + Burst Time.
                mov al, dl              ; Load updated current time.
                CALL PRINT_NUM_UNS      ; Print completion time after this process.
    ; --- GANTT PRINT END ---            
                mov ct[si], dl          ; Store Completion Time.
                mov al,ct[si]           ; Load Completion Time.
                sub al,at[si]           ; Turnaround Time = Completion Time - Arrival Time.
                mov tat[si],al          ; Store Turnaround Time.
                inc si                  ; Move to the next process.
                dec bl                  ; Decrease remaining process count.
                jmp FCFS_LOOP           ; Repeat for next process.
    FCFS_DONE:  CALL PRINT_TABLE        ; Display the scheduling results table.
                CALL AVERAGES           ; Display average WT, RT, and TAT.
    RET         ; Return to caller.
    FCFS ENDP

; ===================== SJF =====================
SJF PROC
    PRINTN                                    ; Print a blank line for spacing.
    PRINTN                                    ; Print a blank line.
    PRINT "======== SJF Scheduling ========"  ; Display the title for SJF Scheduling.
    mov si,0                                  ; reset visited, Initialize SI to 0, SI will be used as the index to access arrays.
    mov bl,temp_pc                            ; Load total number of processes into BL.
    RESET_LOOP:     cmp bl,0                ; Check whether all elements of visited[] have been reset.
                    je RESET_DONE           ; If BL = 0, all processes are marked as unvisited.
                    mov visited[si],0       ; Mark current process as not visited (not executed yet).
                    inc si                  ; Move to the next process index.
                    dec bl                  ; Decrease the counter.
                    jmp RESET_LOOP          ; Repeat until all entries are reset.
    RESET_DONE:     CALL PRINT_GANTT_START  ; Print Gantt chart heading and initial time 0.
                    mov dl,0                ; DL stores the current CPU time, Initially, CPU time starts at 0.
                    mov bh,0                ;BH stores the number of completed processes.
    SJF_MAIN:   mov al,temp_pc      ; Load total number of processes.
                cmp bh,al           ; Compare completed processes with total processes.
                je SJF_DONE         ; If all processes are completed, finish SJF.
                mov si,0            ; Reset SI to scan all processes from the beginning.
                mov bp,0FFFFh       ; BP stores the index of the shortest job found, 0FFFFh means "no valid process found yet."
                mov bl,255          ; BL stores the shortest burst time found so far, Initialize with largest possible byte value.
                mov cl,temp_pc      ; CL is the loop counter for scanning all processes.
    SJF_FIND:   cmp cl,0            ; Check if all processes have been scanned.
                je FIND_DONE        ; If yes, proceed to execute the selected process.
                mov al,visited[si]  ; Load visited status of current process.
                cmp al,1            ; Check if the process has already been executed.
                je NEXT_PROCESS     ; Skip this process if it is already completed.        
                mov al,at[si]       ; Load arrival time of current process.
                cmp al,dl           ; Compare arrival time with current CPU time.
                ja NEXT_PROCESS     ; Skip if the process has not arrived yet.       
                mov al,bt[si]       ; Load burst time of current process.
                cmp al,bl           ; Compare burst time with the shortest burst time found so far.
                jae NEXT_PROCESS    ; Skip if current burst time is greater than or equal to BL.        
                mov bl,al           ; Update shortest burst time.
                mov bp,si           ; Save the index of this shortest process.
    NEXT_PROCESS:   inc si        ; Move to the next process.
                    dec cl        ; Decrease the number of processes left to check.
                    jmp SJF_FIND  ; Continue scanning.
    FIND_DONE:  cmp bp,0FFFFh       ; Check if no suitable process was found.
                je CPU_IDLE         ; If no process has arrived yet, CPU remains idle.
                mov si,bp           ; Load the selected process index into SI.
                mov visited[si],1   ; Mark this process as completed. 
                mov al,dl           ; Load current CPU time.
                sub al,at[si]       ; Waiting Time = Current Time - Arrival Time.
                mov wt[si],al       ; Store Waiting Time.
                mov rt[si],al       ; In non-preemptive SJF, Response Time = Waiting Time.
    ; --- GANTT PRINT START ---
                PRINT "--P"         ; Print process prefix.
                mov al, pid[si]     ; Load process ID.
                CALL PRINT_NUM_UNS  ; Print process ID.
                PRINT "--"          ; Print process suffix.
                add dl, bt[si]      ; Execution finishes here, Advance current CPU time by burst time.
                mov al, dl          ; Load updated CPU time.
                CALL PRINT_NUM_UNS  ; Print completion time of this process.
    ; --- GANTT PRINT END ---
                mov ct[si], dl      ; Store Completion Time.
                mov al,ct[si]       ; Load Completion Time.
                sub al,at[si]       ; Turnaround Time = Completion Time - Arrival Time.
                mov tat[si],al      ; Store Turnaround Time.
                inc bh              ; Increase count of completed processes.
                jmp SJF_MAIN        ; Repeat scheduling for remaining processes.
    CPU_IDLE:   inc dl              ; No process is ready, Increment current time by 1.
                jmp SJF_MAIN        ; Check again for available processes. 
    SJF_DONE:   CALL PRINT_TABLE    ; Display all process details and calculated metrics.
                CALL AVERAGES       ; Display average Waiting Time, Response Time, and Turnaround Time.
    RET         ; Return to the caller.
    SJF ENDP

; ===================== ROUND ROBIN =====================
RR PROC
    PRINTN                                              ; Print a blank line for spacing.
    PRINTN                                              ; Print a blank line.
    PRINTN "======== Round Robin Scheduling ========"   ; Display the heading for Round Robin Scheduling.
    mov si,0                                            ; initialize remaining burst, Initialize SI to 0, SI is used as an index to access process arrays. 
    mov bl,temp_pc                                      ; Load total number of processes into BL.
    INIT_RR:    cmp bl,0                    ; Check whether all processes have been initialized.
                je INIT_DONE                ; If BL = 0, initialization is complete.
                mov al,bt[si]               ; Load Burst Time of the current process.
                mov remaining_bt[si],al     ; Copy Burst Time into remaining_bt, Initially, remaining burst time= original burst time.
                mov rt[si],255              ; Set Response Time to 255, This special value means the process has not executed yet.
                inc si                      ; Move to the next process.
                dec bl                      ; Decrease process counter.
                jmp INIT_RR                 ; Repeat initialization for all processes.
    INIT_DONE:  CALL PRINT_GANTT_START  ; Print Gantt chart heading and initial time 0.
                mov dl,0                ; DL stores the current CPU time.
                mov bh,0                ; BH stores the number of completed processes.
    RR_MAIN:    mov al,temp_pc    ; Load total number of processes.
                cmp bh,al         ; Compare completed processes with total processes.
                je RR_DONE        ; If all processes are completed, finish scheduling.
                mov si,0          ; Reset SI to start scanning from the first process.
                mov bl,temp_pc    ; Load total number of processes into BL.
                mov bp,0          ; BP acts as a flag: 0 = no process executed in this cycle, 1 = at least one process executed.
    RR_LOOP:    cmp bl,0                   ; Check if all processes have been checked.
                je RR_IDLE_CHECK           ; If yes, determine whether CPU was idle.
                mov al,remaining_bt[si]    ; Load remaining burst time.
                cmp al,0                   ; Check if process is already finished.
                je RR_NEXT                 ; Skip if no remaining burst time.
                mov al,at[si]              ; Load Arrival Time.
                cmp al,dl                  ; Compare arrival time with current CPU time.
                ja RR_NEXT                 ; Skip if process has not arrived yet.
                mov bp,1                   ; Set flag to indicate a process has executed.
                cmp byte ptr rt[si],255    ; first response, Check if this is the first time the process gets CPU.
                jne SKIP_RT                ; If response time already recorded, skip.
                mov al,dl                  ; Load current CPU time.
                sub al,at[si]              ; Response Time = Current Time - Arrival Time.
                mov rt[si],al              ; Store Response Time.
    SKIP_RT:    mov al,remaining_bt[si]    ; Load remaining burst time.
                cmp al,tq                  ; Compare remaining burst time with time quantum.
                jae FULL_QUANTUM           ; If remaining_bt >= tq, use full quantum.
                mov ch,al                  ; Otherwise, execute only the remaining burst time.
                jmp EXECUTE                ; Jump to execution.
    FULL_QUANTUM:   mov ch,tq    ; Set execution time = time quantum.
    EXECUTE:     ; ----- for Gantt Chart Start -----
                 PRINT "--P"                        ; Print process prefix.
                 xor ax, ax                         ; Clear AX.
                 mov al, pid[si]                    ; Load Process ID.
                 CALL PRINT_NUM_UNS                 ; Print Process ID.
                 PRINT "--"                         ; Print suffix.
                 add dl, ch                         ; Advance current CPU time by execution time.
                 xor ax, ax                         ; Clear AX.
                 mov al, dl                         ; Load updated CPU time.
                 CALL PRINT_NUM_UNS                 ; Print current time in Gantt chart.
                 ; ----- for Gantt Chart Start -----
                 sub byte ptr remaining_bt[si],ch   ; Reduce remaining burst time by executed amount. 
                 mov al,remaining_bt[si]            ; Load updated remaining burst time.
                 cmp al,0                           ; Check if process is finished.
                 jne RR_NEXT                        ; If not finished, move to next process.
                 inc bh                             ; Increase completed process count.
                 mov ct[si], dl                     ; Store Completion Time.
                 mov al,dl                          ; Load Completion Time.
                 sub al,at[si]                      ; Turnaround Time = Completion Time - Arrival Time.
                 mov tat[si],al                     ; Store Turnaround Time.
                 sub al,bt[si]                      ; Waiting Time = Turnaround Time - Burst Time.
                 mov wt[si],al                      ; Store Waiting Time.
    RR_NEXT:    inc si          ; Move to the next process.
                dec bl          ; Decrease loop counter.
                jmp RR_LOOP     ; Continue scanning processes.
    RR_IDLE_CHECK:  cmp bp,1         ; Check if any process executed in this cycle.
                    je RR_MAIN       ; If yes, start next scheduling cycle.
                    inc dl           ; If no process was ready, CPU remains idle, Increment current time by 1.
                    jmp RR_MAIN      ; Start next scheduling cycle.
    RR_DONE:    CALL PRINT_TABLE  ; Display process metrics table.
                CALL AVERAGES     ; Display average WT, RT, and TAT.
    RET         ; Return to caller.
    RR ENDP

; ==================== Priority Scheduling ==============
PS PROC
    PRINTN                                           ; Print a blank line for spacing.
    PRINTN                                           ; Print a blank line.
    PRINTN "======== Priority Scheduling ========"   ; Display heading for Priority Scheduling.
    mov si, 0                                        ; Reset visited array, Initialize SI as index for visiting array.
    mov bl, temp_pc                                  ; Load total number of processes into BL.
    PS_RESET:   cmp bl, 0            ; Check if all visited[] values are reset.
                je PS_START          ; If BL = 0, move to scheduling phase.
                mov visited[si], 0   ; Mark current process as not visited.
                inc si               ; Move to next process index.
                dec bl               ; Decrease counter.
                jmp PS_RESET         ; Repeat until all processes are reset.
    PS_START:   CALL PRINT_GANTT_START    ; Print Gantt chart header and initial time 0.
                mov dl, 0                 ; Current Time (Clock), DL = current CPU time (clock starts at 0).
                mov bh, 0                 ; Completed Processes Counter, BH = number of completed processes.
    PS_MAIN:    mov al, temp_pc   ; Load total number of processes.
                cmp bh, al        ; Compare completed processes with total processes.
                je PS_DONE        ; Exit if all processes are finished, f all processes are completed, finish scheduling.
                mov si, 0         ; Reset index to scan all processes again.
                mov bp, 0FFFFh    ; Best Process Index, BP = best process index (invalid initial value).
                mov bl, 255       ; Best Priority Value (Lower is better i.e. lower number = higher priority), BL = best (lowest) priority value found so far.
                mov cl, temp_pc   ; CL = loop counter for scanning processes.
    PS_FIND:    cmp cl, 0             ; Check if all processes have been checked.
                je PS_EXEC_CHECK      ; If done scanning, move to execution step.
                mov al, visited[si]   ; Check if process is already finished, Load visited status of current process.    
                cmp al, 1             ; Check if process already executed.
                je PS_NEXT_FIND       ; Skip if already completed.
                mov al, at[si]        ; Check if process has actually arrived by current time (dl), Load arrival time.    
                cmp al, dl            ; Check if process has arrived yet.
                ja PS_NEXT_FIND       ; Skip if arrival time > current time.
                mov al, p[si]         ; Compare priorities (Assuming 1 is higher priority than 3), Load priority of current process.
                cmp al, bl            ; Compare current process priority with the "best" found so far, Compare current priority with best priority. 
                jae PS_NEXT_FIND      ; If current priority is higher (larger number), skip it, If current priority is worse (higher number), skip it.
                mov bl, al            ; If we found a better (lower) priority, save its index, Update best priority found.
                mov bp, si            ; Store index of best process.
    PS_NEXT_FIND:   inc si        ; Move to next process.
                    dec cl        ; Decrease loop counter.
                    jmp PS_FIND   ; Continue searching.
    PS_EXEC_CHECK:  cmp bp, 0FFFFh       ; Check if no valid process was found.
                    je PS_IDLE           ; If no process available, CPU is idle.       
                    ; --- STACK USAGE ---
                    push bp              ; Push selected process index to stack
                    pop si               ; Pop it into SI for execution
                    mov visited[si], 1   ; Mark selected process as completed.
                    ; Compute Metrics
                    mov al, dl           ; Load current time.
                    sub al, at[si]       ; Waiting Time = Current Time - Arrival Time.
                    mov wt[si], al       ; Store Waiting Time.
                    mov rt[si], al       ; Response Time = Waiting Time (non-preemptive).
    ; -------- Gantt Chart Print Start --------
                    PRINT "--P"          ; Print process prefix.
                    mov al, pid[si]      ; Load process ID.
                    CALL PRINT_NUM_UNS   ; Print process ID.
                    PRINT "--"           ; Print separator i.e. suffix.
                    add dl, bt[si]       ; Update Clock, Advance CPU time by burst time (non-preemptive execution).
                    mov al, dl           ; Load updated time.
                    CALL PRINT_NUM_UNS   ; Print completion time in Gantt chart.
    ; -------- Gantt Chart Print End ---------                
                    ; Save Completion Data
                    mov ct[si], dl       ; Store Completion Time.
                    mov al, ct[si]       ; Load Completion Time.
                    sub al, at[si]       ; Turnaround Time = Completion Time - Arrival Time.
                    mov tat[si], al      ; Store Turnaround Time.
                    inc bh               ; Increase completed process counter.
                    jmp PS_MAIN          ; Repeat scheduling until all processes are done.
    PS_IDLE:    inc dl         ; CPU sits idle, so increment time i.e. increase time by 1.
                jmp PS_MAIN    ; Continue checking processes.
    PS_DONE:    CALL PRINT_TABLE     ; Print final process table (AT, BT, WT, RT, TAT).
                CALL AVERAGES        ; Print average metrics.
    RET         ; Return to caller.
    PS ENDP

; ===================== PREEMPTIVE PRIORITY SCHEDULING =====================
PRE_PS PROC
    PRINTN                                                     ; Print empty line
    PRINTN                                                     ; Print empty line
    PRINTN "======== Preemptive Priority Scheduling ========"  ; Display heading/title
    mov si, 0                                                  ; SI = 0 (used as array index)
    mov bl, temp_pc                                            ; BL = total number of processes
    INIT_PP_DATA:   cmp bl, 0                 ; Check if all processes initialized
                    je INIT_PP_DONE           ; If yes, jump to initialization complete
                    mov al, bt[si]            ; Load burst time of current process
                    mov remaining_bt[si], al  ; Copy burst time into remaining burst time array
                    mov rt[si], 255           ; 255 signifies "not yet started", Set response time = 255
                    mov wt[si], 0             ; Initialize waiting time = 0
                    inc si                    ; Move to next process index
                    dec bl                    ; Decrease process counter
                    jmp INIT_PP_DATA          ; Repeat loop for next process
    INIT_PP_DONE:   CALL PRINT_GANTT_START    ; Print starting part of Gantt chart
                    mov dl, 0                 ; DL = current system time (clock starts at 0)
                    mov bh, 0                 ; Counter for Completed Processes, BH = completed process counter
    PP_MAIN_LOOP:   mov al, temp_pc     ; Load total process count
                    cmp bh, al          ; Check if all processes are finished, Compare completed count with total count
                    je PRE_PS_FINISH    ; If all completed, finish scheduling            
                    mov si, 0           ; Reset index to scan processes
                    mov bp, 0FFFFh      ; Best Process Index (initially invalid), BP stores best process index, 0FFFFh means "no valid process selected yet" 
                    mov bl, 255         ; Best Priority found so far (lower is better i.e. Lower priority value = higher priority), BL stores best priority found so far
                    mov cl, temp_pc     ; CL = loop counter for process scanning
    PP_FIND_BEST:   cmp cl, 0                 ; Have all processes been checked?
                    je PP_CHECK_SELECTION     ; If yes, evaluate selected process
    ; 1. Check if process has remaining work
                    mov al, remaining_bt[si]  ; Load remaining burst time
                    cmp al, 0                 ; Check if process already completed
                    je PP_NEXT_PROCESS        ; If completed, skip process
    ; 2. Check if process has arrived yet
                    mov al, at[si]            ; Load arrival time of process
                    cmp al, dl                ; Compare arrival time with current time
                    ja PP_NEXT_PROCESS        ; If arrival time > current time, process has not arrived yet            
    ; 3. Check priority (Lower number = Higher Priority)
                    mov al, p[si]             ; Load priority of current process
                    cmp al, bl                ; Compare with best priority found so far
                    jae PP_NEXT_PROCESS       ; If current priority is worse or equal, skip process                    
    ; Found a better candidate
                    mov bl, al                ; Update best priority
                    mov bp, si                ; Store current process index as best process
    PP_NEXT_PROCESS:    inc si              ; Move to next process
                        dec cl              ; Decrease loop counter
                        jmp PP_FIND_BEST    ; Continue searching
    PP_CHECK_SELECTION:     cmp bp, 0FFFFh       ; Was any process selected?
                            je PP_IDLE           ; No process is ready at this time, If not, CPU remains idle
                            mov si, bp           ; Load the chosen process index, SI = selected process index                       
    ; --- Handle Response Time (First time process gets CPU) ---
                            cmp rt[si], 255      ; Check if response time still uninitialized
                            jne PP_EXECUTE_UNIT  ; If already started before, skip RT calculation
                            mov al, dl           ; AL = current time
                            sub al, at[si]       ; Response Time = current time - arrival time
                            mov rt[si], al       ; Store response time                   
    PP_EXECUTE_UNIT:    ; --- Gantt Chart Update ---
                        PRINT "--P"                   ; Print process label prefix
                        mov al, pid[si]               ; Load process ID
                        CALL PRINT_NUM_UNS            ; Print process number
                        PRINT "--"                    ; Print formatting
                        inc dl                        ; Increment system time by 1 unit
                        dec byte ptr remaining_bt[si] ; Execute process for 1 time unit, Reduce remaining burst time by 1.                        
                        mov al, dl                    ; AL = updated time
                        CALL PRINT_NUM_UNS            ; Print current time on Gantt Chart                    
    ; --- Check if Process Finished ---
                        mov al, remaining_bt[si]      ; Load remaining burst time
                        cmp al, 0                     ; Is process completed?
                        jne PP_MAIN_LOOP              ; If work remains, re-run scheduler for possible preemption                    
    ; Process Finished Logic
                        inc bh                        ; Increment finished process counter
                        mov ct[si], dl                ; Record Completion Time i.e. Completion Time = current time                       
    ; Calculate TAT = CT - AT
                        mov al, dl                    ; AL = completion time
                        sub al, at[si]                ; Turnaround Time = completion - arrival
                        mov tat[si], al               ; Store turnaround time         
    ; Calculate WT = TAT - BT (Original Burst Time)
                        sub al, bt[si]                ; Waiting Time = turnaround - burst time
                        mov wt[si], al                ; Store waiting time
                        jmp PP_MAIN_LOOP              ; Continue scheduling remaining processes
    PP_IDLE:    inc dl               ; CPU is idle, just move the clock by 1, No process available
                jmp PP_MAIN_LOOP     ; Retry scheduling
    PRE_PS_FINISH:  CALL PRINT_TABLE    ; Display results table
                    CALL AVERAGES       ; Display average WT/TAT/RT
    RET
PRE_PS ENDP

; ===================== PRINT TABLE =====================
PRINT_TABLE PROC
    mov total_wt,0    ; Initialize total waiting time to 0.
    mov total_rt,0    ; Initialize total response time to 0.
    mov total_tat,0   ; Initialize total turnaround time to 0.
    PRINTN            ; Print a blank line.
    PRINTN            ; Print a blank line.
    PRINTN "=========================================="   ; Print table top border.
    PRINTN "PID   AT    BT    WT    RT    TAT"            ; Print table column headers.
    PRINTN "=========================================="   ; Print separator line under headers.
    mov si,0          ; SI is used as index for arrays.
    mov bl,temp_pc    ; BL holds number of processes to iterate through.
    PT_LOOP:    cmp bl,0             ; Check if all processes have been printed.
                je PT_DONE           ; If BL == 0, exit loop.
                ; PID (Column 1)
                xor ax,ax            ; Clear AX register.
                mov al, pid[si]      ; Load process ID into AL.
                CALL PRINT_NUM_UNS   ; Print PID.
                PRINT "     "        ; 5 spaces, Print spacing after PID column.            
                ; AT (Column 2)
                xor ax,ax            ; Clear AX.
                mov al,at[si]        ; Load Arrival Time.
                cmp al, 10           ; Check if value is two-digit.
                jae PRINT_AT         ; If >= 10, no leading space needed.
                PRINT " "            ; Leading space for single digit, If single digit, print leading space for alignment.
    PRINT_AT:   CALL PRINT_NUM_UNS      ; Print Arrival Time.
                PRINT "    "            ; 4 spaces, Print spacing after AT column.
                ; BT (Column 3)
                xor ax,ax               ; Clear AX.
                mov al,bt[si]           ; Load Burst Time.
                cmp al, 10              ; Check if two-digit number.
                jae PRINT_BT            ; If >= 10, skip leading space.
                PRINT " "               ; Leading space for single digit, Print alignment space for single digit.
    PRINT_BT:   CALL PRINT_NUM_UNS  ; Print Burst Time.
                PRINT "    "        ; 4 spaces, Print spacing after BT column.
                ; WT (Column 4)
                xor ax,ax           ; Clear AX.
                mov al,wt[si]       ; Load Waiting Time.
                cmp al, 10          ; Check if two-digit.
                jae PRINT_WT        ; Skip spacing if needed.
                PRINT " "           ; Leading space for single digit, Print alignment space.
    PRINT_WT:   CALL PRINT_NUM_UNS  ; Print Waiting Time.
                PRINT "    "        ; 4 spaces, Print spacing after WT column.            
                ; RT (Column 5)
                xor ax,ax           ; Clear AX.
                mov al,rt[si]       ; Check Response Time.
                cmp al, 10          ; Check formatting.
                jae PRINT_RT        ; Skip space if not needed.
                PRINT " "           ; Leading space for single digit, Print alignment space
    PRINT_RT:   CALL PRINT_NUM_UNS  ; Print Response Time.
                PRINT "    "        ; 4 spaces, Print spacing after RT column.
                ; TAT (Column 6)
                xor ax,ax           ; Clear AX.
                mov al,tat[si]      ; Load Turnaround Time.
                cmp al, 10          ; Check if single or double digit.
                jae PRINT_TAT       ; If >= 10, skip leading space.
                PRINT " "           ; Leading space for single digit, Print alignment space.
    PRINT_TAT:  CALL PRINT_NUM_UNS  ; Print Turnaround Time.
                PRINTN              ; Move to next line after printing full row.
                ; total WT
                xor ax,ax           ; Clear AX.
                mov al,wt[si]       ; Load WT for current process.
                add total_wt,ax     ; Add to total waiting time.
                ; total RT
                xor ax,ax           ; Clear AX.
                mov al,rt[si]       ; Load RT.
                add total_rt,ax     ; Add total response time.       
                ; total TAT
                xor ax,ax           ; Clear AX.
                mov al,tat[si]      ; Load TAT.
                add total_tat,ax    ; Add to total turnaround time.        
                inc si              ; Move to next process index.
                dec bl              ; Decrease remaining process count.
                jmp PT_LOOP         ; Repeat loop for all processes.
    PT_DONE:    PRINTN "=========================================="
    RET
    PRINT_TABLE ENDP

; ===================== AVERAGES =====================
AVERAGES PROC
    ; Start of the procedure that calculates and prints, the average Waiting Time (WT), average Response Time (RT), and average Turnaround Time (TAT).
    PRINTN                                ; Print a blank line.
    PRINTN "======== AVERAGES ========"   ; Display the heading for the averages section.
    ; Average WT
    PRINT "Average WT : "                 ; Print label for Average Waiting Time.
    mov ax, total_wt                      ; Load the total waiting time into AX.
    CALL PRINT_FLOAT_DIV                  ; Divide total_wt by number of processes (temp_pc), and print the result with two decimal places.
    ; Average RT
    PRINT "Average RT : "                 ; Print label for Average Response Time.
    mov ax, total_rt                      ; Load the total response time into AX.
    CALL PRINT_FLOAT_DIV                  ; Divide total_rt by number of processes, and print the result with two decimal places.
    ; Average TAT
    PRINT "Average TAT: "                 ; Print label for Average Turnaround Time.
    mov ax, total_tat                     ; Load the total turnaround time into AX.
    CALL PRINT_FLOAT_DIV                  ; Divide total_tat by number of processes, and print the result with two decimal places.
    RET                                   ; Return to the calling procedure.
    AVERAGES ENDP                   

; ===================== PRINT FLOAT DIVISION =====================
PRINT_FLOAT_DIV PROC
    ; Procedure to print a floating-point-like division result
    ; (total time / number of processes) in decimal format.
    push ax                  ; Save AX register (used for division and calculations).
    push bx                  ; Save BX register.
    push cx                  ; Save CX register.
    push dx                  ; Save DX register.
    cmp byte ptr temp_pc,0   ; Check if number of processes is 0 (division by zero case).
    je DIV_ZERO              ; If temp_pc == 0, jump to error handling.
    ; numerator = 0
    cmp ax,0                 ; Check if numerator (AX) is 0.
    jne CONTINUE             ; If not zero, continue normal calculation.
    PRINT "0.00"             ; If numerator is zero, directly print 0.00.
    PRINTN                   ; Move to next line.
    jmp DONE                 ; Skip remaining calculations.
    CONTINUE:   mov bl,temp_pc      ; Load divisor (number of processes) into BL.
                xor ah,ah           ; Clear AH to prepare AX for division.
                div bl              ; AL = integer part, AH = remainder , Divide AX by BL.
                mov cl,ah           ; SAVE remainder in CL for fractional calculation.
                ; print integer part
                xor ah,ah           ; Clear AH to avoid garbage values.
                CALL PRINT_NUM_UNS  ; Print integer part of the division result.          
                PRINT "."           ; Print decimal point. 
                ; fractional = (remainder * 100) / divisor
                xor ax,ax           ; Clear AX.
                mov al,cl           ; restore saved remainder into AL.
                mov bl,100          ; We multiply remainder by 100 to get 2 decimal precision.
                mul bl              ; AX = remainder * 100            
                mov bl,temp_pc      ; Load divisor again.
                div bl              ; AL = decimal part, Divide (remainder * 100) by number of processes, AL now contains decimal part.            
                ; leading zero
                cmp al,10           ; Check if decimal part is single digit.
                jae PRINT_DECIMAL   ; If >= 10, skip leading zero.          
                PRINT "0"           ; Print leading zero for formatting (e.g., 0.05 instead of .5). 
    PRINT_DECIMAL:  xor ah,ah            ; Clear AH before printing.
                    CALL PRINT_NUM_UNS   ; Print decimal part.
                    PRINTN               ; Move to next line.
                    jmp DONE             ; Finish procedure.
    DIV_ZERO:   PRINT "Error"            ; Handle division by zero case.
    DONE:   pop dx     ; Restore DX register.
            pop cx     ; Restore CX register.
            pop bx     ; Restore BX register.
            pop ax     ; Restore AX register.
    RET     ; You did NOT pass arguments via stack that is why we didnot write RET 4 
    PRINT_FLOAT_DIV ENDP  

; ===================== PRINT GANTT CHART =====================
PRINT_GANTT_START PROC
    PRINTN                                  ; Print a blank line for spacing.
    PRINTN                                  ; Print a blank line for spacing.
    PRINTN "======== GANTT CHART ========"  ; Display the heading/title of the Gantt chart section.
    PRINT "0"                               ; This prints the very first time stamp, Print the starting time of the CPU schedule (time = 0), This represents the initial point of the timeline.
    RET                                     ; Return from the procedure to the caller.
    PRINT_GANTT_START ENDP

DEFINE_SCAN_NUM       ; Macro provided by emu8086 library, Used to read numeric input from the user.
DEFINE_PRINT_NUM_UNS  ; Macro provided by emu8086 library, Used to print unsigned numbers on the screen.
DEFINE_CLEAR_SCREEN   ; Macro provided by emu8086 library, Used to Clear the Screen  