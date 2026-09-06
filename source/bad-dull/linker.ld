PHDRS {
    "." PT_LOAD FLAGS(6);
}

ENTRY(_start)

SECTIONS {
    . = 0x7C00;

    "." : { *(".") }

    .shstrtab : { *(.shstrtab) }

    /DISCARD/ : { *(*) }
}
