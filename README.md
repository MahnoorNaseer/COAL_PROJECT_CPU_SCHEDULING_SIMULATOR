# CPU Scheduling Simulator

### x86 Assembly (COAL) Semester Project

A console-based CPU scheduling simulator written entirely in **x86 Assembly language** using the **emu8086** environment. This project implements and visualizes four classic CPU scheduling algorithms, complete with Gantt chart output and performance metrics.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Algorithms Implemented](#algorithms-implemented)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Output Explained](#output-explained)
- [Technical Details](#technical-details)
- [Limitations](#limitations)
- [Authors](#authors)

---

## Overview

This project was developed as a semester project for a **Computer Organization and Assembly Language (COAL)** course. It demonstrates how CPU scheduling algorithms work at a low level by implementing them directly in x86 Assembly using the `emu8086` macro library.

The simulator accepts up to **5 processes** with their arrival times, burst times, and priorities, then executes the chosen scheduling algorithm, displaying a Gantt chart and a detailed results table.

---

## Features

- Supports up to **5 concurrent processes**
- Interactive **menu-driven interface**
- Real-time **Gantt chart** visualization in the console
- Detailed **per-process metrics table** (WT, RT, TAT)
- Computed **average statistics** (displayed as floating-point decimals)
- Handles **CPU idle time** (gaps between process arrivals)
- Fully implemented in **x86 Assembly** using `emu8086.inc`

---

## Algorithms Implemented

| #   | Algorithm                                        | Status      |
| --- | ------------------------------------------------ | ----------- |
| 1   | **FCFS** — First Come First Served               | Implemented |
| 2   | **SJF** — Shortest Job First (Non-Preemptive)    | Implemented |
| 3   | **RR** — Round Robin (with configurable quantum) | Implemented |
| 4   | **PS** — Priority Scheduling                     | Implemented |

### Algorithm Details

**1. FCFS (First Come First Served)**
Processes are sorted by arrival time and executed in order. If the CPU is idle when a process arrives, it waits accordingly.

**2. SJF (Shortest Job First)**
Among all processes that have arrived, the one with the shortest burst time is selected next. Handles CPU idle periods when no process is ready.

**3. Round Robin**
Each process gets a configurable time quantum. Processes cycle through the ready queue, and the simulator tracks remaining burst time per process. Response time is recorded on the first execution of each process.

**4. Priority Scheduling**
Both premptive and non-premptive priority scheduling is implemented.

---

## Project Structure

```
COAL_PROJECT_CPU_SCHEDULING_SIMULATOR/
│
├── CPU SCHEDULING.asm       # half done project (clean version)
├── CPU SCHEDULING.asm.txt   # Average was converted to float point representation
├── priorityscheduling.asm   # Addition priority scheduling module
├── final code.asm           # Final consolidated version
└── README.md
```

## Getting Started

### Prerequisites

- [emu8086](https://emu8086-microprocessor-emulator.en.softonic.com/) — x86 emulator and assembler
- Windows OS (emu8086 is Windows-native)

### Installation & Running

1. **Clone the repository:**

   ```
   git clone https://github.com/MahnoorNaseer/COAL_PROJECT_CPU_SCHEDULING_SIMULATOR.git
   ```

2. **Open emu8086** and load the file:
   - Go to `File → Open`
   - Select `CPU SCHEDULING.asm` (or `final code.asm`)

3. **Assemble and Run:**
   - Click `Emulate` to assemble
   - Click `Run` to execute the program in the virtual console

---

## Usage

When the program starts, it will prompt you to:

1. **Enter the number of processes** (1–5):

   ```
   Enter number of processes (max 5): 3
   ```

2. **Enter details for each process:**

   ```
   Process 1:
   Arrival Time: 0
   Burst Time: 5
   Priority: 2
   ```

3. **Choose a scheduling algorithm:**

   ```
   Choose the algorithm you want to run:
   1. FCFS Scheduling
   2. SJF Scheduling
   3. Round Robin Scheduling
   4. Priority Scheduling
   Enter your Choice: 1
   ```

4. _(For Round Robin only)_ **Enter the time quantum:**
   ```
   Enter Quantum: 2
   ```

---

## Output Explained

### Gantt Chart

A text-based Gantt chart is printed showing process execution order and timestamps:

```
===== GANTT CHART =====
0--P1--5--P3--8--P2--12
```

### Results Table

```
==========================================
PID  AT   BT   WT   RT   TAT
==========================================
 1    0    5    0    0    5
 3    2    3    3    3    6
 2    4    4    4    4    8
==========================================
```

| Column  | Meaning         |
| ------- | --------------- |
| **PID** | Process ID      |
| **AT**  | Arrival Time    |
| **BT**  | Burst Time      |
| **WT**  | Waiting Time    |
| **RT**  | Response Time   |
| **TAT** | Turnaround Time |

### Averages

```
===== AVERAGES =====
Average WT : 2.33
Average RT : 2.33
Average TAT: 6.33
```

Averages are computed and displayed as floating-point values (integer + two decimal places).

---

## Technical Details

- **Language:** x86 Assembly (16-bit, DOS COM format)
- **Assembler/Emulator:** emu8086
- **Memory model:** `org 100h` (COM program)
- **Library:** `emu8086.inc` — provides `PRINT`, `SCAN_NUM`, `PRINT_NUM_UNS`, `PRINTN` macros
- **Data storage:** Fixed-size byte arrays (`db 5 dup(0)`) for process attributes
- **Sorting:** Bubble sort (FCFS sorts by arrival time)
- **Floating-point display:** Integer division + remainder × 100 technique (no FPU used)

---

## Limitations

- Maximum of **5 processes** supported (hardcoded array sizes)
- All timing values must be **single-byte integers** (0–255)
- **Priority Scheduling** is not yet fully implemented (input is collected but not used for scheduling)
- No preemptive SJF (SRTF) — only non-preemptive SJF is included
- Runs only in **emu8086** (not compatible with NASM/MASM without modification)

---

## Report

The full project report (including algorithm analysis, flowcharts, and results) is available on Overleaf:

[![Overleaf](https://www.overleaf.com/read/jdqdtbqxsqgm#ddf0a6)]

## Authors

Developed by **Mahnoor Naseer** and contributors as part of a COAL (Computer Organization and Assembly Language) semester project.

---

> _"The beauty of assembly is that nothing is hidden — every clock cycle is intentional."_
