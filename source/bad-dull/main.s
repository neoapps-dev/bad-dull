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
    movw %ax, %fs # Set FS to 0x40

stackinit:
    movw $0x7C00, %sp # Set Stack Pointer (SP)

    movb %dl, disk # Store Disk Number

init:
    sti # Enable Interrupts

    movb $0, %ah # Select Disk Read Function
    movb $3, %al # Read 3 Sectors

    int $0x10 # Read from Disk

main:
    movb $0x42, %ah # Select Disk Read Function
    movb disk, %dl # Select Disk Number
    movw $dap, %si # Set Disk Address Packet

    int $0x13 # Read from Disk
    jc halt # Halt on Error

    push %es # Save ES

    movw $0xB800, %ax # Set ES to Video Memory
    movw %ax, %es # Set ES to Video Memory

    xorw %di, %di # Zero DI

    movw $0x2000, %si # Set SI to 0x2000
    movw $25, %cx # Set CX to 25 (Number of Rows)

row:
    push %cx # Push CX to Stack
    movw $5, %cx # Set CX to 5 (Number of Columns)

col:
    lodsb # Load Byte from SI into AL
    movb %al, %bl # Move AL to BL
    movw $8, %bp # Set BP to 8 (Number of Bits)

bit:
    shlb $1, %bl # Shift BL Left by 1 Bit
    movl $0x00200020, %eax # Set Default Black Character Pair
    jnc 1f # Jump if Carry Flag is Not Set (Black)
    movl $0x0FDB0FDB, %eax # Set White Character Pair if Carry Set
1:
    stosl # Write 32-bit Character Pair and Auto-Increment DI by 4
    dec %bp # Decrement BP
    jnz bit # Jump to Bit if BP is Not Zero
    loop col # Loop Columns
    pop %cx # Pop CX from Stack
    loop row # Loop Rows
    pop %es # Pop ES from Stack

    movw %fs:0x6C, %bx # Store Current Cursor Position in BX
w1:
    movw %fs:0x6C, %ax # Store Current Cursor Position in AX
    cmp %bx, %ax # Compare AX and BX
    je w1 # Jump to W1 if AX and BX are Equal
    movw %fs:0x6C, %bx # Store Current Cursor Position in BX
w2:
    movw %fs:0x6C, %ax # Store Current Cursor Position in AX
    cmp %bx, %ax # Compare AX and BX
    je w2 # Jump to W2 if AX and BX are Equal

    incl lba # Increment LBA

    jmp main # Loop

halt:
    hlt # Halt

    jmp halt # Loop

.align 4

dap:
    .byte 0x10
    .byte 0
    .word 1
    .word 0x2000
    .word 0x0000

lba:
    .quad 1

disk:
    .byte 0

.fill 446 - (. - _start), 1, 0 # Padding

# Protective MBR

.byte 0x00 # Boot Indicator (0x00 = Inactive)
.byte 0x00, 0x02, 0x00 # Starting CHS (0/0/2)
.byte 0xEE # Partition Type (0xEE = GPT Protective)
.byte 0xFF, 0xFF, 0xFF # Ending CHS (Maximum)
.long 0x00000001 # Starting LBA (Sector 1, GPT Header)
.long 0x000007FF # Sector Count

.fill 16, 1, 0 # Second Partition Entry (Empty)

.fill 16, 1, 0 # Third Partition Entry (Empty)

.fill 16, 1, 0 # Fourth Partition Entry (Empty)

.word 0xAA55 # MBR Magic
