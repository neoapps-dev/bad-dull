# source/bad-dull/main.s

.global _start

.section ., "awx", @progbits

.code16

_start:
    cli # Clear Interrupts

    ljmp $0x0000, $seginit # Normalize Code Segment (CS)

seginit:
    xorw %ax, %ax # Zero AX
    movw %ax, %ds # Clear Data Segment (DS)
    movw %ax, %es # Clear Extra Segment (ES)

    movw %ax, %ss # Clear Stack Segment (SS)

    movw %ax, %fs # Clear F Segment (FS)
    movw %ax, %gs # Clear G Segment (GS)

    movw $0x40, %ax # Set AX to 0x40
    movw %ax, %fs # Set FS to BIOS Data Area Segment 0x40

stackinit:
    movw $0x7C00, %sp # Set Stack Pointer (SP)

    movb %dl, disk # Store BIOS Boot Drive Number

init:
    sti # Enable Interrupts

    movb $0, %ah # Select Set Video Mode Function
    movb $3, %al # Select Video Mode 3 (80x25 16-color Text Mode)

    int $0x10 # Set Video Mode

main:
    movb $0x42, %ah # Select Extended Disk Read Function
    movb disk, %dl # Select BIOS Boot Drive Number
    movw $dap, %si # Set Disk Address Packet

    int $0x13 # Read Sectors from Disk
    jc halt # Halt on Disk Read Error

    push %es # Save ES

    movw $0xB800, %ax # Set AX to VGA Text Video Memory Segment
    movw %ax, %es # Set ES to VGA Text Video Memory Segment

    xorw %di, %di # Zero DI

    movw $0x2000, %si # Set SI to Frame Buffer
    movw $25, %cx # Set CX to 25 (Number of Rows)

row:
    push %cx # Save Row Counter
    movw $5, %cx # Set CX to 5 (Source Bytes per Row)

col:
    lodsb # Load Source Byte from SI into AL
    movb %al, %bl # Copy Source Byte to BL
    movw $8, %bp # Set BP to 8 (Number of Bits in Source Byte)

bit:
    shlb $1, %bl # Shift BL Left by 1 Bit
    movl $0x00200020, %eax # Set Default Black Character Pair
    jnc 1f # Jump if Carry Flag is Not Set (Black)
    movl $0x0FDB0FDB, %eax # Set White Character Pair if Carry Flag is Set
1:
    stosl # Write 32-bit Character Pair and Auto-Increment DI by 4
    dec %bp # Decrement Bit Counter
    jnz bit # Jump to Bit if Counter is Not Zero
    loop col # Loop Through Source Bytes
    pop %cx # Restore Row Counter
    loop row # Loop Through Rows
    pop %es # Restore ES

    movw %fs:0x6C, %bx # Store Current BIOS Timer Tick Count in BX
w1:
    movw %fs:0x6C, %ax # Read Current BIOS Timer Tick Count into AX
    cmp %bx, %ax # Compare Current Timer Tick Count with Previous Count
    je w1 # Wait Until Timer Tick Count Changes
    movw %fs:0x6C, %bx # Store Updated BIOS Timer Tick Count in BX
w2:
    movw %fs:0x6C, %ax # Read Current BIOS Timer Tick Count into AX
    cmp %bx, %ax # Compare Current Timer Tick Count with Previous Count
    je w2 # Wait Until Another Timer Tick Occurs

    incl lba # Increment Logical Block Address (LBA)

    jmp main # Loop

halt:
    hlt # Halt CPU

    jmp halt # Loop

.align 4

dap:
    .byte 0x10 # DAP Size (16 Bytes)
    .byte 0 # Reserved
    .word 1 # Number of Sectors to Read
    .word 0x2000 # Destination Offset
    .word 0x0000 # Destination Segment

lba:
    .quad 1 # Starting Logical Block Address (LBA)

disk:
    .byte 0 # BIOS Boot Drive Number

.fill 446 - (. - _start), 1, 0 # Pad Boot Code and Data to 446 Bytes

# Protective MBR

.byte 0x00 # Boot Indicator (Inactive)
.byte 0x00, 0x02, 0x00 # Starting CHS (0/0/2)
.byte 0xEE # Partition Type (GPT Protective)
.byte 0xFF, 0xFF, 0xFF # Ending CHS (Maximum)
.long 0x00000001 # Starting LBA (Sector 1, GPT Header)
.long 0x000007FF # Number of Sectors in Partition

.fill 16, 1, 0 # Second Partition Entry (Empty)

.fill 16, 1, 0 # Third Partition Entry (Empty)

.fill 16, 1, 0 # Fourth Partition Entry (Empty)

.word 0xAA55 # Boot Sector Signature
