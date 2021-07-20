ENTRY(_boot2_main)

MEMORY {
    FLASH_BOOT2 : ORIGIN = 0x10000000, LENGTH = 256
    FLASH : ORIGIN = 0x10000100, LENGTH = 2M - 256
    RAM : ORIGIN = 0x20000000, LENGTH = 264K
}

SECTIONS {

    /DISCARD/ : {
        *(.ARM.exidx)
    }

    .boot2 : {
        __boot2_start = .;
        KEEP(*(.boot2._boot2_main))
        __boot2_end = .;
        ASSERT(__boot2_end - __boot2_start <= 252, "Assert hit!: The second bootloader is too large (expected 252 bytes or less).")
    } > FLASH_BOOT2

    .boot2_fill : {
        FILL(0x00);
        . = ORIGIN(FLASH_BOOT2) + LENGTH(FLASH_BOOT2) - 1;
        BYTE(0x00);
    } > FLASH_BOOT2

    .text : {
        __test_start = .;
        __start = .;
        KEEP(*(.text.start))
        *(.text*)
        __text_end = .;
    } > FLASH

    .rodata : {
        __rodata_start = .;
        *(.rodata*)
        __rodata_end = .;
    } > FLASH
    
    .data : {
        __data_start = .;
        *(.data*)
        __data_end = .;
    } > RAM
    
    . = ALIGN(4);

    .bss : {
        __bss_start = .;
        *(.bss*)
        __bss_end = .;
    } > RAM
    
    .stack : {
        __stack_end = .;
        __stack_start = ORIGIN(RAM) + LENGTH(RAM) - 4;
    } > RAM
}
